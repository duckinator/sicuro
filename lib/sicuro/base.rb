require 'timeout'
require 'open3'
require 'rbconfig'
require 'json'


%w[
    trusted/constants
    trusted/public_methods
    trusted/private_methods
    trusted/globals

    internal/eval
    internal/helper_functions
    internal/exceptions

    runtime/constants
    runtime/methods
].each do |x|
  require File.join(File.dirname(__FILE__), "#{x}.rb")
end

class Sicuro
  attr_accessor :memlimit, :timelimit

  # Ruby executable used.
  RUBY_EXE = RbConfig::CONFIG['ruby_install_name'] + RbConfig::CONFIG['EXEEXT']
  RUBY_USED = File.join(RbConfig::CONFIG['bindir'], RUBY_EXE)

  # Set the memory (in MBs) and time (in seconds) limits for Sicuro.
  # Defaults are 100MB and 5 seconds.
  def initialize(memlimit = 100, timelimit = 5)
    @memlimit  = memlimit
    @timelimit = timelimit
  end

  # This prepends the code that actually makes the evaluation safe.
  # Odds are, you don't want this unless you're debugging Sicuro.
  def _code_prefix(code, libs, precode, identifier)
    identifier += '; ' if identifier

    <<-EOF
      # Make it use "sicuro ([identifier; ]current_time)" as the process name.
      $0 = 'sicuro (#{identifier}#{Time.now.strftime("%r")})' if #{$DEBUG}

      require #{__FILE__.inspect}
      s=Sicuro.new(#{@timelimit}, #{@memlimit})
      print s._safe_eval(#{code.inspect}, #{libs.inspect}, #{precode.inspect},
                         #{memlimit.inspect})
    EOF
  end

  # Runs the specified code, returns STDOUT and STDERR as a single string.
  #
  # `code`: the code to run.
  #
  # `libs`: array of libs to include before setting up the safe eval process.
  #
  # `precode`: code ran before setting up the safe eval process.
  #
  # `identifier`: a unique identifier for this code (ie, if used an irc bot,
  # the person's nickname). When specified, it tries setting the process name to
  # "sicuro (#{identifier}, #{current_time})", otherwise it tries setting it to
  # "sicuro (#{current_time})"
  #
  def eval(code, libs = [], precode = '', identifier = nil)
    i, o, e, t, pid = nil

    Timeout.timeout(@timelimit) do
      i, o, e, t = Open3.popen3(RUBY_USED)
      pid = t.pid
      out_reader = Thread.new { o.read }
      err_reader = Thread.new { e.read }
      i.write _code_prefix(code, libs, precode, identifier)
      i.close
      str = out_reader.value
      err = err_reader.value

      if str.empty?
        if !err.empty?
          str = _generate_json(code, '', err, '', nil)
        else
          # Nothing at all was returned.
          # This often happens on Kernel#exit!
          str = _generate_json(code, '', '', 'nil', nil)
        end
      end

      Eval.new(JSON.parse(str), pid)
    end
  rescue Timeout::Error
    error = "Timeout::Error: Code took longer than %i seconds to terminate." %
                @timelimit

    if Sicuro.process_running?(pid)
      Process.kill('KILL', pid) rescue nil
    end

    Eval.new(_generate_json(code, '', error, '', nil), pid)
  ensure
    if Sicuro.process_running?(pid)
      Process.kill('KILL', pid) rescue nil
      if Sicuro.process_running?(pid)
        Sicuro.sandbox_error("Could not kill process ##{pid} after 3 attempts!", true)
      end
    end
  end

  # stdout, stderr, and exception catching for unsafe Kernel#eval
  # Used internally by Sicuro._safe_eval
  def _unsafe_eval(code, binding)
    result, exception = nil

    begin
      result = ::Kernel.eval("require 'sicuro/runtime/whitelist'; #{code}", binding)
    rescue Exception => e
      exception = "#{e.class}: #{e.message}"
    end

    [result, exception]
  end

  def _generate_json(code, stdout, stderr, result, exception)
    JSON.generate({
      'stdin'     => code,
      'stdout'    => stdout,
      'stderr'    => stderr,
      'return'    => result.inspect,
      'exception' => exception
    })
  end

  # Used internally by Sicuro.eval. You should probably use Sicuro.eval instead.
  # This does not provide a strict time limit.
  # TODO: Since _safe_eval itself cannot be tested, separate out what can.
  def _safe_eval(code, libs, precode, memlimit)
    # RAM limit
    Process.setrlimit(Process::RLIMIT_AS, memlimit*1024*1024)

    # CPU time limit. 5s means 5s of CPU time.
    Process.setrlimit(Process::RLIMIT_CPU, @timelimit)
    ::Kernel.trap(:XCPU) do # This should be triggered when you hit RLIMIT_CPU.
      raise Timeout::Error
      exit!
    end

    # Things we want, or need to have, available in eval.
    require 'stringio'
    require 'pp'

=begin
    %w[constants].each do |file|
      require File.join(File.dirname(__FILE__), 'runtime', file + '.rb')
    end
=end

    # Require FakeFS here, but wait to resolve external libs before activating.
    begin
      require 'fakefs/safe'
    rescue LoadError
      require 'rubygems'
      retry
    end

    ::Sicuro::Runtime::Constants.reset

    required_for_custom_libs = [:FakeFS, :Gem, :FileUtils, :File, :Pathname,
                                :Dir, :RbConfig, :IO, :FileTest]

    unsafe_constants = Object.constants - $TRUSTED_CONSTANTS -
                       required_for_custom_libs

    unsafe_constants.each do |x|
      next unless Object.const_defined?(x)
      Object.instance_eval { remove_const x }
    end

    ::Kernel.eval(precode, TOPLEVEL_BINDING)

    libs.each do |lib|
      require lib
    end

    FakeFS.activate!

    required_for_custom_libs.each do |x|
      Object.instance_eval { remove_const x }
    end

    old_stdout = $stdout
    old_stderr = $stderr
    old_stdin  = $stdin

    $stdout = StringIO.new
    $stderr = StringIO.new
    $stdin  = StringIO.new

    Object.instance_eval do
      [:STDOUT, :STDERR, :STDIN].each { |x| remove_const x }
    end
    Object.const_set(:STDOUT, $stdout)
    Object.const_set(:STDERR, $stderr)
    Object.const_set(:STDIN,  $stdin)

    result, exception = _unsafe_eval(code, TOPLEVEL_BINDING)

    stdout = $stdout.string
    stderr = $stderr.string
    stdin  = $stdin.string

    $stdout = old_stdout
    $stderr = old_stderr
    $stdin  = old_stdin

    Object.instance_eval do
      [:STDOUT, :STDERR, :STDIN].each { |x| remove_const x }
    end
    Object.const_set(:STDOUT, $stdout)
    Object.const_set(:STDERR, $stderr)
    Object.const_set(:STDIN,  $stdin)

    print _generate_json(code, stdout, stderr, result, exception)
  rescue => e
    print _generate_json('', '', '', nil, "#{e.class}: #{e.message}")
  end

  def inspect
    "#<#{self.class} memlimit=#{@memlimit} timelimit=#{@timelimit}>"
  end
end
