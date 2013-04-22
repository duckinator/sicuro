require 'timeout'
require 'open3'
require 'rbconfig'
require 'stringio'

%w[
    trusted/constants
    trusted/methods
    trusted/globals

    internal/eval
    internal/helper_functions
    internal/exceptions

    runtime/constants
    runtime/methods
    runtime/dummyfs
].each do |x|
  require File.join(File.dirname(__FILE__), "#{x}.rb")
end

class Sicuro
  attr_accessor :memlimit, :timelimit

  # Ruby executable used.
  RUBY_EXE = RbConfig::CONFIG['ruby_install_name'] + RbConfig::CONFIG['EXEEXT']
  RUBY_USED = File.join(RbConfig::CONFIG['bindir'], RUBY_EXE)

  # Set the memory (in MBs) and time (in seconds) limits for Sicuro.
  # Defaults are 50MB and 5 seconds.
  def initialize(memlimit = 50, timelimit = 5)
    @memlimit  = memlimit
    @timelimit = timelimit
  end

  # This prepends the code that actually makes the evaluation safe.
  # Odds are, you don't want this unless you're debugging Sicuro.
  def _code_prefix(code, identifier)
    identifier += '; ' if identifier

    <<-EOF
      # Make it use "sicuro ([identifier; ]current_time)" as the process name.
      $0 = 'sicuro (#{identifier}#{Time.now.strftime("%r")})' if #{$DEBUG}

      require #{__FILE__.inspect}
      s=Sicuro.new(#{@timelimit}, #{@memlimit})
      print s._safe_eval(#{code.inspect})
    EOF
  end

  # Runs the specified code, returns STDOUT and STDERR as a single string.
  #
  # `code`: the code to run.
  #
  # `identifier`: a unique identifier for this code (ie, if used an irc bot,
  # the person's nickname). When specified, it tries setting the process name to
  # "sicuro (#{identifier}, #{current_time})", otherwise it tries setting it to
  # "sicuro (#{current_time})"
  #
  def eval(code, identifier = nil)
    i, o, e, t, pid = nil
    out_reader, err_reader = nil

    start = Time.now

    Timeout.timeout(@timelimit) do
      i, o, e, t = Open3.popen3(RUBY_USED)
      pid = t.pid
      out_reader = Thread.new { o.read }
      err_reader = Thread.new { e.read }
      i.write _code_prefix(code, identifier)
      i.close

      # Wait for stdout and stderr to close.
      out_reader.join
      err_reader.join
    end

    duration = Time.now - start
    # We aim to be API-compatible with eval.so, so we want to return the
    # wall time as milliseconds. Time-Time yields seconds, so multiply by 1000.
    # We then call .to_i because we want an int, not a float.
    wall_time = (duration * 1000).to_i

    # Get the value of out_reader.
    # The last line is the return value, rest is stdout.
    lines   = out_reader.value.split("\n")
    stdout  = lines[0..-2].join("\n")
    _return = lines[-1] || 'nil'

    # Get the value of err_reader. This is all stderr, unlike with stdout.
    stderr  = err_reader.value

    Eval.new(code, stdout, stderr, _return, wall_time, pid)
  rescue Timeout::Error
    error = "Timeout::Error: Code took longer than %i seconds to terminate." %
                @timelimit

    if Sicuro.process_running?(pid)
      Process.kill('KILL', pid) rescue nil
    end

    Eval.new(code, '', error, nil, wall_time, pid)
  end

  # Used internally by Sicuro.eval. You should probably use Sicuro.eval instead.
  # This does not provide a strict time limit.
  # TODO: Since _safe_eval itself cannot be tested, separate out what can.
  def _safe_eval(code)
    result = nil
    old_stdout = $stdout
    old_stderr = $stderr
    old_stdin  = $stdin

    # RAM limit
    Process.setrlimit(Process::RLIMIT_AS, @memlimit * 1024 * 1024)

    # CPU time limit. 5s means 5s of CPU time.
    Process.setrlimit(Process::RLIMIT_CPU, @timelimit)
    ::Kernel.trap(:XCPU) do # This should be triggered when you hit RLIMIT_CPU.
      raise Timeout::Error
      exit!
    end

    ::Sicuro::Runtime::Constants.reset!
    ::Sicuro::Runtime::Constants::DummyFS.activate!
    ::Sicuro::Runtime::Methods.replace_all!

    %w[constants methods dummyfs].each do |file|
      require "sicuro/runtime/#{file}"
    end

    unsafe_constants = Object.constants - $TRUSTED_CONSTANTS

    unsafe_constants.each do |x|
      Object.instance_eval { remove_const x }
    end

    $TRUSTED_METHODS.each do |constant, methods|
      next unless Object.const_defined?(constant)

      const = Object.const_get(constant)

      const.instance_eval do
        (const.methods - methods).each do |meth|
          define_method(meth) {}

          eval("undef #{meth.to_sym}")
          #puts "Removing #{constant}.#{meth}"
          #undef_method meth if respond_to?(meth)
        end
      end
    end

    $stdout = StringIO.new
    $stderr = StringIO.new
    $stdin  = StringIO.new

    Object.instance_eval do
      [:STDOUT, :STDERR, :STDIN].each { |x| remove_const x }
    end
    Object.const_set(:STDOUT, $stdout)
    Object.const_set(:STDERR, $stderr)
    Object.const_set(:STDIN,  $stdin)

    begin
      result = ::Kernel.eval("require 'sicuro/runtime/whitelist'; #{code}", TOPLEVEL_BINDING)
    rescue Exception => e
      warn "#{e.class}: #{e.message}"
      warn e.backtrace.join("\n")
    end
  ensure
    out = $stdout.string
    old_stdout.print out
    old_stdout.puts
    old_stdout.puts  result.inspect
    old_stderr.print $stderr.string
  end

  def inspect
    "#<#{self.class} memlimit=#{@memlimit} timelimit=#{@timelimit}>"
  end
end
