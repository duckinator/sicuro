require File.join(File.dirname(__FILE__), 'version')
require 'timeout'
require 'open3'
require 'rbconfig'
require 'stringio'

require 'enc/trans/single_byte' if RUBY_ENGINE == 'ruby'

require 'standalone'

%w[
    constants

    evalso

    trusted/constants
    trusted/methods
    trusted/globals

    internal/eval
    internal/helper_functions
    internal/exceptions

    runtime/methods
    runtime/dummyfs
].each do |x|
  require File.join(File.dirname(__FILE__), "#{x}.rb")
end

class Sicuro
  attr_accessor :memlimit, :timelimit

  # Set the memory (in MBs) and time (in seconds) limits for Sicuro.
  # Defaults are 200MB and 5 seconds.
  def initialize(memlimit = nil, timelimit = nil)
    @memlimit  = memlimit  || 200
    @timelimit = timelimit || 5

    Sicuro.add_files_to_dummyfs
  end

  # This prepends the code that actually makes the evaluation safe.
  # Odds are, you don't want this unless you're debugging Sicuro.
  def _code_prefix(code)
    <<-EOF
      require #{__FILE__.inspect}
      s=Sicuro.new(#{@memlimit}, #{@timelimit})
      s._safe_eval(#{code.inspect})
    EOF
  end

  # Runs the specified code, returns STDOUT and STDERR as a single string.
  #
  # `code`: the code to run.
  #
  # `new_stdin`:  a StringIO that is treated as $stdin.
  # `new_stdout`: a StringIO that is treated as $stdout.
  # `new_stderr`: a StringIO that is treated as $stderr.
  def eval(code, new_stdin = nil, new_stdout = nil, new_stderr = nil)

    new_stdin  ||= StringIO.new
    new_stdout ||= StringIO.new
    new_stderr ||= StringIO.new

    i, o, e, t, pid = nil
    out_reader, err_reader = nil

    start = Time.now

    Timeout.timeout(@timelimit) do
      i, o, e, t = Open3.popen3(RUBY_USED)
      pid = t.pid

      out_reader = Thread.new do
        ret = ''
        until o.eof?
          s = o.read(1)
          ret += s
          new_stdout.write s
        end
        ret
      end

      err_reader = Thread.new do
        ret = ''
        until e.eof?
          s = e.read(1)
          ret += s
          new_stderr.write s
        end
        ret
      end

      i.write _code_prefix(code)
      i.close
      out_reader.join
      err_reader.join
    end

    duration = Time.now - start

    # We aim to be API-compatible with eval.so, so we want to return the
    # wall time as milliseconds. Time-Time yields seconds, so multiply by 1000.
    # We then call .to_i because we want an int, not a float.
    wall_time = (duration * 1000).to_i

    stdout = out_reader.value
    stderr = err_reader.value

    Eval.new(code, stdout, stderr, wall_time, pid)
  rescue Timeout::Error
    error = "Timeout::Error: Code took longer than %i seconds to terminate." %
                @timelimit

    if Sicuro.process_running?(pid)
      Process.kill('KILL', pid) rescue nil
    end

    Eval.new(code, '', error, wall_time, pid)
  end

  # Used internally by Sicuro.eval. You should probably use Sicuro.eval instead.
  # This does not provide a strict time limit.
  # TODO: Since _safe_eval itself cannot be tested, separate out what can.
  def _safe_eval(code)
    file = File.join(Standalone::ENV['HOME'], 'code.rb')
    Standalone::DummyFS.add_file(file, code)

    result = nil
    old_stdout = $stdout
    old_stderr = $stderr
    old_stdin = $stdin

    # RAM limit
    Process.setrlimit(Process::RLIMIT_AS, @memlimit * 1024 * 1024) unless @memlimit.zero?

    # CPU time limit. 5s means 5s of CPU time.
    Process.setrlimit(Process::RLIMIT_CPU, @timelimit) unless @timelimit.zero?
    ::Kernel.trap(:XCPU) do # This should be triggered when you hit RLIMIT_CPU.
      raise Timeout::Error
      exit!
    end

    ::Standalone.enable!
    ::Sicuro::Runtime::Methods.replace_all!

    %w[constants methods dummyfs].each do |file|
      require "sicuro/runtime/#{file}"
    end

    unsafe_constants = Object.constants - $TRUSTED_CONSTANTS

    unsafe_constants.each do |x|
      Object.instance_eval { remove_const x }
    end

    Object.constants.each do |constant|
      next unless Object.const_defined?(constant)

      next if [:NIL, :TRUE, :FALSE, :NilClass].include?(constant)

      trusted = $TRUSTED_METHODS[constant] || []

      const = Object.const_get(constant)
      const = const.class unless const.is_a?(Class) || const.is_a?(Module)

      if const.is_a?(Module)
        const.module_eval do
          (const.methods + const.private_methods - $TRUSTED_METHODS_ALL - trusted).each do |meth|
            # FIXME: This is a hack because we need STDIN (the IO class) to be
            #        left alone for eval() to work.
            next if [:STDIN, :STDOUT, :STDERR].include?(constant)

            m = meth.to_sym.inspect

            eval("public #{m}; undef #{m}")
          end
        end
      else
        const.instance_eval do
          (const.methods + const.private_methods - $TRUSTED_METHODS_ALL - trusted).each do |meth|
            next if [:STDIN, :STDOUT, :STDERR].include?(constant)

            m = meth.to_sym.inspect

            #next unless method_defined?('define_method')
            #define_method(meth) {}

            #remove_method(meth) rescue nil
            eval("public #{m}; undef #{m}")
            #puts "Removing #{constant}.#{meth}"
            #undef_method meth if respond_to?(meth)
          end
        end
      end
    end

    (global_variables - $TRUSTED_GLOBALS).each do |var|
      ::Kernel.eval("#{var.to_s}.freeze") 
    end

    $stdout = StringIO.new
    $stderr = StringIO.new
    $stdin = StringIO.new

    Object.instance_eval do
      [:STDOUT, :STDERR, :STDIN].each { |x| remove_const x }
    end
    Object.const_set(:STDOUT, $stdout)
    Object.const_set(:STDERR, $stderr)
    Object.const_set(:STDIN, $stdin)

    $done = false

    reader = lambda do |from, to|
      Thread.new do
        ret = ''
        pos = 0

        from.rewind

        loop do
          s = from.read
          ret += s
          pos += s.length

          to.write s
          to.flush

          from.pos = pos

          break if $done
        end

        s = from.read
        ret += s
        to.write s

        ret
      end
    end

    out_reader = reader.call($stdout, old_stdout)

    err_reader = reader.call($stderr, old_stderr)

    require 'sicuro/runtime/whitelist'
    result = ::Kernel.eval(code, TOPLEVEL_BINDING, file)
    $done = true

    out_reader.join
    err_reader.join
  rescue Exception => e
    old_stderr.puts "#{e.class}: #{e.message}"
    old_stderr.puts e.backtrace.join("\n")
  end

  def inspect
    "#<#{self.class} memlimit=#{@memlimit} timelimit=#{@timelimit}>"
  end
end
