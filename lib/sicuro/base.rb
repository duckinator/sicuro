require 'timeout'
require 'open3'
require 'rbconfig'

module Sicuro
  # Ruby executable used.
  RUBY_USED = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'] + RbConfig::CONFIG['EXEEXT'])

  # Sicuro::Eval is used to nicely handle stdout/stderr of evaluated code
  class Eval
    attr_accessor :out, :err
  
    def initialize(out, err)
      @out, @err = out, err.chomp
    end
    
    def to_s
      if @err.empty? || @err == '""'
        @out
      else
        @err
      end
    end
    
    def inspect
      if @err.empty? || @err == '""'
        @out.inspect
      else
        @err.inspect
      end
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
  # `default_ruby` is the executable evaluated code should run as by default.
  # This defaults to the ruby executable that was used to run.
  def self.setup(timelimit=5, memlimit=nil, memlimit_upper_bound=nil, default_ruby=nil)
    @@timelimit = timelimit
    @@memlimit  = memlimit
    memlimit_upper_bound ||= 100
    @@default_ruby = default_ruby || RUBY_USED
    
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
    
    prefix = ''
    
    current_time = Time.now.strftime("%I:%M:%S %p")
    
    unless $DEBUG
      # The following makes it use "sicuro ([identifier; ]current_time)" as the
      # process name. Likely only actually does anything on *nix systems.
      prefix = "$0 = 'sicuro ("
      prefix += "#{identifier}; " if identifier
      prefix += "#{current_time})';"
    end
    
    libs.each do |x|
      prefix += "require '#{x}';"
    end
    
    prefix +=
      "require #{__FILE__.inspect};" +
      "Sicuro.setup(#{@@timelimit.inspect}, #{memlimit.inspect});"
      
    prefix +=
      "#{precode};" +
      "print Sicuro._safe_eval(#{code.inspect}, #{memlimit.inspect})"
  end
  
  # Runs the specified code, returns STDOUT and STDERR as a single string.
  # Automatically runs Sicuro.setup if needed.
  #
  # `code` is the code to run.
  #
  # `memlimit` is the memory limit for this specific code. Default is `@@memlimit`
  #  as determined by Sicuro.setup
  #
  # `ruby_executable` is the exaecutable to use. Default is `@@default_ruby`, as
  # determined by Sicuro.setup
  #
  # `identifier` is a unique identifier for this code (ie, if used an irc bot,
  # the person's nickname). When specified, it tries setting the process name to
  # "sicuro (#{identifier}, #{current_time})", otherwise it tries setting it to
  # "sicuro (#{current_time})"
  #
  def self.eval(code, libs = nil, precode = nil, memlimit = nil, ruby_executable = nil, identifier = nil)
    begin
      ruby_executable ||= @@default_ruby
      
      i, o, e, t, pid = nil
      
      Timeout.timeout(@@timelimit) do
        i, o, e, t = Open3.popen3(ruby_executable)
        pid = t.pid
        out_reader = Thread.new { o.read }
        err_reader = Thread.new { e.read }
        i.write _code_prefix(code, libs, precode, memlimit, identifier)
        i.close
        Eval.new(out_reader.value, err_reader.value)
      end
    rescue Timeout::Error
      Eval.new('', '<timeout hit>')
    rescue NameError
      Sicuro.setup
      retry
    ensure
      i.close unless i.closed?
      o.close unless o.closed?
      e.close unless e.closed?
      t.kill  if t.alive?
      Process.kill('KILL', pid) rescue nil # TODO: Handle this correctly
    end
  end
  
  # Same as eval, but get only stdout
  def self.eval_out(*args)
    self.eval(*args).out
  end
  
  # Same as eval, but get only stderr
  def self.eval_err(*args)
    self.eval(*args).err
  end
  
  # Simple testing abilities.
  #
  # >> Sicuro.assert("print 'hi'", "hi")
  # => true
  #
  def self.assert(code, output, *args)
    Sicuro.eval(code, *args).out == output
  end
  
  # Use Sicuro.eval instead. This does not provide a strict time limit or call Sicuro.setup.
  # Used internally by Sicuro.eval
  def self._safe_eval(code, memlimit)
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
    
    # Undefine FakeFS
    [:FakeFS, :RealFile, :RealFileTest, :RealFileUtils, :RealDir].each do |x|
      Object.instance_eval{ remove_const x }
    end
    
    out_io, err_io, result, error = nil
    
    begin
      out_io = $stdout = StringIO.new
      err_io = $stderr = StringIO.new
      code = '$SAFE = 3; BEGIN { $SAFE=3 };' + code
      
      result = ::Kernel.eval(code, TOPLEVEL_BINDING)
    rescue Exception => e
      error = "#{e.class}: #{e.message}"
    ensure
      $stdout = STDOUT
      $stderr = STDERR
    end
    
    output = out_io.string
    error ||= err_io.string
    
    if output.empty?
      print result.inspect
    else
      print output
    end
    warn error
=begin
    if output.empty?
      if error
        error
      else
        result.inspect
      end
    else
      output
    end
=end
  end
end
