require 'timeout'
require 'open3'
require 'rbconfig'
require 'json'

require File.join(File.dirname(__FILE__), 'trusted_constants.rb')
require File.join(File.dirname(__FILE__), 'trusted_kernel_methods.rb')
require File.join(File.dirname(__FILE__), 'monkeypatches.rb')

module Sicuro
  # Ruby executable used.
  RUBY_USED = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'] + RbConfig::CONFIG['EXEEXT'])

  # Sicuro::Eval is used to nicely handle stdout/stderr of evaluated code
  class Eval
    attr_accessor :stdin, :stdout, :stderr, :return, :exception
  
    def initialize(hash, pid)
      @inspect_for_value = false
      @running_error     = nil
      @pid    = pid
      @stdin  = hash['stdin']
      @stdout = hash['stdout']
      @stderr = hash['stderr']
      @return = hash['return']
      @exception = hash['exception']
      
      if Sicuro.process_running?(pid)
        sleep 1
        Process.kill('KILL', pid) rescue nil
        if Sicuro.process_running?(pid)
          @running_error = "Process ##{pid} could not be terminated."
        else
          @running_error = "Process ##{pid} could not be terminated in Sicuro#eval, but was killed in Sicuro::Eval#new."
          # Should we `exit 1` if we get here?
        end
      end
      
      # This bit is positively horrifying, but it's very useful information, so...
      error_prefix   = '[SICURO ERROR] '
      if @running_error
        @running_error = "#{error_prefix}#{@running_error} THIS IS A BUG. Code:"
        @running_error += "\n" + @stdin.split("\n").map{|x| x.rjust(error_prefix.length + x.length)}.join("\n")
      end
      
      warn @running_error if @running_error
      
      @running = Sicuro.process_running?(pid)
    end
    
    def running?
      @running
    end
    
    def _get_return_value
      return @running_error if @running_error
      
      @inspect_for_value = false
      if !@stderr.nil? && ((!@stderr.is_a?(String)) || (@stderr.is_a?(String) && !@stderr.empty?))
        # @stderr is not nil and is not a String, or is a non-empty String
        @stderr
      elsif (!@exception.nil? && !@exception.is_a?(String)) || (@exception.is_a?(String) && !@exception.empty?)
        # @exception is not nil and is not a String, or is a non-empty String
        @exception
      elsif !@stdout.nil? && (!@stdout.is_a?(String) || !@stdout.empty?)
        @stdout
      else
        @inspect_for_value = true
        @return
      end
    end
    
    # Get a version suitable for printing.
    # Main difference between #value and #_get_return_value: with #value, 
    # if you get @return, it calls .inspect.
    def value
      ret = _get_return_value
      
      if @inspect_for_value
        ret.inspect
      else
        ret
      end
    end
    
    def inspect
      "#<#{self.class} stdin=#{stdin.inspect} value=#{value.inspect}>"
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
          return Eval.new({
            'stdin'     => code,
            'stdout'    => '',
            'stderr'    => err,
            'return'    => '',
            'exception' => nil
          }, pid)
        else
          # This means it used @@timelimit seconds of CPU time, so it was killed off
          # in the child process. We just pretend it was killed here, instead.
          raise Timeout::Error
        end
      end
      
      Eval.new(JSON.parse(str), pid)
    end
  rescue Timeout::Error
    error = "Timeout::Error: Code took longer than #{@@timelimit} seconds to terminate."
    if Sicuro.process_running?(pid)
      Process.kill('KILL', pid) rescue nil
    end
    
    Eval.new({
      'stdin'     => code,
      'stdout'    => '',
      'stderr'    => error,
      'return'    => '',
      'exception' => nil
    }, pid)
  rescue NameError
    Sicuro.setup
    retry
  ensure
    #i.close unless i.closed?
    #o.close unless o.closed?
    #e.close unless e.closed?
    #t.kill  if t.alive?
    
    if Sicuro.process_running?(pid)
      Process.kill('KILL', pid) rescue nil
      if Sicuro.process_running?(pid)
        warn "[SICURO ERROR] Could not kill process ##{pid} after 3 attempts!"
      end
    end
  end
  
  # Same as eval, but get only stdout
  def self.eval_stdout(*args)
    self.eval(*args).stdout
  end
  
  # Same as eval, but get only stderr
  def self.eval_stderr(*args)
    self.eval(*args).stderr
  end
  
  # Same as eval, but get only return value
  def self.eval_return(*args)
    self.eval(*args).return
  end
  
  # Same as eval, but get only exceptions
  def self.eval_exception(*args)
    self.eval(*args).exception
  end
  
  # Same as eval, but run #value on it
  def self.eval_value(*args)
    self.eval(*args).value
  end
  
  # Same as eval, but run #inspect on it
  # Yes, this one has NO use except testing.
  def self.eval_inspect(*args)
    self.eval(*args).inspect
  end
  
  # Same as eval, but run #running? on it
  # Yes, this one has NO use except testing.
  def self.eval_running?(*args)
    self.eval(*args).running?
  end
  
  # Simple testing abilities.
  #
  # >> Sicuro.assert("print 'hi'", "hi")
  # => true
  #
  def self.assert(code, output, *args)
    Sicuro.eval(code, *args).stdout == output
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
    
    [out_io.string, err_io.string, result, exception]
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
    
    stdout, stderr, result, exception = self._unsafe_eval(code, TOPLEVEL_BINDING)
    
    print JSON.generate({
      'stdin'     => code,
      'stdout'    => stdout,
      'stderr'    => stderr,
      'return'    => result,
      'exception' => exception
    })
  end
end
