require 'timeout'
require 'open3'
require 'rbconfig'

module Sicuro
  # Ruby executable used.
  RUBY_USED = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'] + RbConfig::CONFIG['EXEEXT'])

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
        if Sicuro.assert('print 1', '1', i)
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
  def self._code_prefix(code, memlimit = nil)
    memlimit ||= @@memlimit
    "require #{__FILE__.inspect};" +
    "Sicuro.setup(#{@@timelimit.inspect}, #{memlimit.inspect});" +
    "print Sicuro._safe_eval(#{code.inspect}, #{memlimit.inspect})"
  end
  
  # Runs the specified code, returns STDOUT and STDERR as a single string.
  # Automatically runs Sicuro.setup if needed.
  def self.eval(code, memlimit = nil, ruby_executable = nil)
    begin
      ruby_executable ||= @@default_ruby
      
      Timeout.timeout(5) do
        Open3.capture2e(ruby_executable, :stdin_data => _code_prefix(code, memlimit)).first
      end
    rescue Timeout::Error
      '<timeout hit>'
    rescue NameError
      Sicuro.setup
      retry
    end
  end
  
  # Simple testing abilities.
  #
  # >> Sicuro.assert("print 'hi'", "hi")
  # => true
  #
  def self.assert(code, output, *args)
    Sicuro.eval(code, *args) == output
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
    
    output_io, result, error = nil
    
    begin
      output_io = $stdout = $stderr = StringIO.new
      code = '$SAFE = 3; BEGIN { $SAFE=3 };' + code
      
      result = ::Kernel.eval(code, TOPLEVEL_BINDING)
    rescue Exception => e
      error = "#{e.class}: #{e.message}"
    ensure
      $stdout = STDOUT
      $stderr = STDERR
    end
    
    output = output_io.string
    
    if output.empty?
      if error
        error
      else
        result.inspect
      end
    else
      output
    end
  end
end
