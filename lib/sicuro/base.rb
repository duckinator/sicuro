require 'timeout'
require 'open3'
require 'rbconfig'
require 'json'

require File.join(File.dirname(__FILE__), 'trusted_constants.rb')
require File.join(File.dirname(__FILE__), 'trusted_kernel_methods.rb')

module Sicuro
  # Ruby executable used.
  RUBY_USED = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'] + RbConfig::CONFIG['EXEEXT'])

  # Sicuro::Eval is used to nicely handle stdout/stderr of evaluated code
  class Eval
    attr_accessor :output, :return, :error, :exception
  
    def initialize(hash)
      @output = hash['output']
      @return = hash['return']
      @error  = hash['error']
      @exception = hash['exception']
#p hash
#p @output,@return,@error,@exception
    end
    
    def _get_return_value
      if !@error.nil? && ((!@error.is_a?(String)) || (@error.is_a?(String) && !@error.empty?))
        # @error is not nil and is not a String, or is a non-empty String
        @error
      elsif (!@exception.nil? && !@exception.is_a?(String)) || (@exception.is_a?(String) && !@exception.empty?)
        # @exception is not nil and is not a String, or is a non-empty String
        @exception
      elsif !@output.nil? && (!@output.is_a?(String) || !@output.empty?)
        @output
      elsif @return.is_a?(String)
        @return.inspect
      else
        @return
      end
    end
    
    def to_s
      _get_return_value.to_s
    end
    
    def inspect
      puts to_s.inspect
      to_s.inspect
    end
  end

  # Set the time and memory limits for Sicuro.eval.
  #
  # Passing nil (default) for the `memlimit` (second argument) will start at 5MB,
  # and try to find the lowest multiple of 5MB that `puts 1` will run under.
  # If it fails at `memlimit_upper_bound`, it prints an error and exits.
  #
  # This is needed because apparently some systems require *over 50MB* to run
  # `puts 'hi'`, while others only require 5MB. I'm not quite sure what causes
  # this. If you have any ideas, please open an issue on github and explain them!
  # URL is: http://github.com/duckinator/sicuro/issues
  #
  # `memlimit_upper_bound` is the upper limit of memory detection, default is 100MB.
  #
  def self.setup(timelimit=5, memlimit=nil, memlimit_upper_bound=nil)
    @@timelimit = timelimit
    @@memlimit  = memlimit
    memlimit_upper_bound ||= 100
    
    if @@memlimit.nil?
      5.step(memlimit_upper_bound, 5) do |i|
        if Sicuro.assert('print 1', '1', nil, nil, i)
          @@memlimit = i
          warn "[MEMLIMIT] Defaulting to #{i}MB" if $DEBUG
          break
        end
        warn "[MEMLIMIT] Did not default to #{i}MB" if $DEBUG
      end
      
      if @@memlimit.nil?
        fail "[MEMLIMIT] Could not run `print 1` in #{memlimit_upper_bound}MB RAM or less."
      end
    end
  end
  
  # This appends the code that actually makes the evaluation safe.
  # Odds are, you don't want this unless you're debugging Sicuro.
  def self._code_prefix(code, libs = nil, precode = nil, memlimit = nil, identifier = nil)
    memlimit ||= @@memlimit
    libs     ||= []
    precode  ||= ''
    
    identifier += '; ' if identifier
    
    prefix = ''
    
    current_time = Time.now.strftime("%I:%M:%S %p")
    
    unless $DEBUG
      # The following makes it use "sicuro ([identifier; ]current_time)" as the
      # process name. Likely only actually does anything on *nix systems.
      prefix = "$0 = 'sicuro (#{identifier}#{current_time})';"
    end
    
    prefix += <<-EOF
      require #{__FILE__.inspect}
      Sicuro.setup(#{@@timelimit.inspect}, #{memlimit.inspect})
      print Sicuro._safe_eval(#{code.inspect}, #{memlimit.inspect}, #{libs.inspect}, #{precode.inspect})
    EOF
  end
  
  # Runs the specified code, returns STDOUT and STDERR as a single string.
  # Automatically runs Sicuro.setup if needed.
  #
  # `code` is the code to run.
  #
  # `libs` is an array of libraries to include before setting up the safe eval process (BE CAREFUL!),
  #
  # `precode` is code ran before setting up the safe eval process (BE INCREDIBLY CAREFUL!).
  #
  # `memlimit` is the memory limit for this specific code. Default is `@@memlimit`
  #  as determined by Sicuro.setup
  #
  # `identifier` is a unique identifier for this code (ie, if used an irc bot,
  # the person's nickname). When specified, it tries setting the process name to
  # "sicuro (#{identifier}, #{current_time})", otherwise it tries setting it to
  # "sicuro (#{current_time})"
  #
  def self.eval(code, libs = nil, precode = nil, memlimit = nil, identifier = nil)
    
    i, o, e, t, pid = nil
    
    Timeout.timeout(@@timelimit) do
      i, o, e, t = Open3.popen3(RUBY_USED)
      pid = t.pid
      out_reader = Thread.new { o.read }
      err_reader = Thread.new { e.read }
      i.write _code_prefix(code, libs, precode, memlimit, identifier)
      i.close
      str = out_reader.value
      err = err_reader.value
      
      if str.empty?
        if !err.empty?
          return Eval.new({'output'=>'', 'return'=>'', 'error'=>'', 'exception'=>err})
        else
          # This means it used @@timelimit seconds of CPU time, so it was killed off
          # in the child process. We just pretend it was killed here, instead.
          raise Timeout::Error
        end
      end
      
      Eval.new(JSON.parse(str))
    end
  rescue Timeout::Error
    Eval.new({'output'=>'', 'return'=>'', 'error'=>'<timeout hit>', 'exception'=>nil})
  rescue NameError
    Sicuro.setup
    retry
  ensure
    #i.close unless i.closed?
    #o.close unless o.closed?
    #e.close unless e.closed?
    #t.kill  if t.alive?
    Process.kill('KILL', pid) rescue nil # TODO: Handle this correctly
  end
  
  # Same as eval, but get only stdout
  def self.eval_output(*args)
    self.eval(*args).output
  end
  
  # Same as eval, but get only return value
  def self.eval_return(*args)
    self.eval(*args).return
  end
  
  # Same as eval, but get only stderr
  def self.eval_error(*args)
    self.eval(*args).error
  end
  
  # Same as eval, but get only exceptions
  def self.eval_exception(*args)
    self.eval(*args).exception
  end
  
  # Same as eval, but run #to_s on it
  def self.eval_str(*args)
    self.eval(*args).to_s
  end
  
  # Simple testing abilities.
  #
  # >> Sicuro.assert("print 'hi'", "hi")
  # => true
  #
  def self.assert(code, output, *args)
    Sicuro.eval(code, *args).output == output
  end
  
  # stdout, stderr, and exception catching for unsafe Kernel#eval
  # Used internally by Sicuro._safe_eval
  def self._unsafe_eval(code, binding)
    out_io, err_io, result, exception = nil
    
    begin
      out_io = $stdout = StringIO.new
      err_io = $stderr = StringIO.new
      code = "BEGIN {
        (Kernel.methods - Object.methods - #{$TRUSTED_KERNEL_METHODS.inspect}).each do |x|
          Kernel.send(:undef_method, x.to_sym)
        end        
      }; " + code
      
      result = ::Kernel.eval(code, binding)
    rescue Exception => e
      exception = "#{e.class}: #{e.message}"
    ensure
      $stdout = STDOUT
      $stderr = STDERR
    end
    
    [out_io.string, result, err_io.string, exception]
  end
  
  # Use Sicuro.eval instead. This does not provide a strict time limit or call Sicuro.setup.
  # Used internally by Sicuro.eval
  def self._safe_eval(code, memlimit, libs, precode)
    # RAM limit
    Process.setrlimit(Process::RLIMIT_AS, memlimit*1024*1024)
    
    # CPU time limit. 5s means 5s of CPU time.
    Process.setrlimit(Process::RLIMIT_CPU, @@timelimit)
    
    # Things we want, or need to have, available in eval
    require 'stringio'
    require 'pp'
    
    # fakefs goes last, because I don't think `require` will work after it
    begin
      require 'fakefs'
    rescue LoadError
      require 'rubygems'
      retry
    end
    
    required_for_custom_libs = [:FakeFS, :Gem]
    (Object.constants - $TRUSTED_CONSTANTS - required_for_custom_libs).each do |x|
      Object.instance_eval { remove_const x }
    end
    
    ::Kernel.eval(precode, TOPLEVEL_BINDING)
    
    libs.each do |lib|
      require lib
    end
    
    required_for_custom_libs.each do |x|
      Object.instance_eval { remove_const x }
    end
    
    output, result, error, exception = self._unsafe_eval(code, TOPLEVEL_BINDING)
    
    print JSON.generate({
      'output'    => output,
      'return'    => result,
      'error'     => error,
      'exception' => exception
    })
  end
end
