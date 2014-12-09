require File.join(File.dirname(__FILE__), 'version')
require 'timeout'
require 'open3'
require 'rbconfig'
require 'stringio'

require 'enc/trans/single_byte' if RUBY_ENGINE == 'ruby'

require 'standalone'

%w[
    constants
    utils

    evalso

    trusted/constants
    trusted/methods
    trusted/globals

    evaluation

    runtime/methods
    runtime/dummyfs
].each do |x|
  require File.join(File.dirname(__FILE__), "#{x}.rb")
end

class Sicuro
  # Runs the specified code, returns STDOUT and STDERR as a single string.
  #
  # `code`: the code to run.
  #
  # `new_stdin`:  a StringIO that is treated as $stdin.
  # `new_stdout`: a StringIO that is treated as $stdout.
  # `new_stderr`: a StringIO that is treated as $stderr.
  def eval(code, new_stdin = nil, new_stdout = nil, new_stderr = nil, lib_dirs = [])

    new_stdin  ||= StringIO.new
    new_stdout ||= StringIO.new
    new_stderr ||= StringIO.new

    i, o, e, t, pid = nil
    out_reader, err_reader = nil

    start = Time.now

    Timeout.timeout(@timelimit) do
      i, o, e, t = Open3.popen3(RUBY_USED, '-e', prefix_code(code, lib_dirs))
      pid = t.pid

      out_reader = reader(o, new_stdout)
      err_reader = reader(e, new_stderr)

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

    Evaluation.new(code, stdout, stderr, wall_time)
  rescue Timeout::Error
    error = "Timeout::Error: Code took longer than %i seconds to terminate." %
                @timelimit

    running_check(pid, code)

    Evaluation.new(code, '', error, wall_time)
  end

  private

  # This prepends the code that actually makes the evaluation safe.
  def prefix_code(code, lib_dirs)
    <<-EOF
      # FIXME: Make this less hacky after load paths are set reasonably.
      require #{__FILE__.inspect.gsub('/base.rb', '.rb')}
      s=Sicuro.new(#{@memlimit}, #{@timelimit})
      s.send(:safe_eval, #{code.inspect}, #{lib_dirs.inspect})
    EOF
  end

  # Used internally by Sicuro.eval.
  # This does not enforce the time limit.
  # TODO: Since safe_eval itself cannot be tested, separate out what can.
  def safe_eval(code, lib_dirs)
    file = File.join(Standalone::ENV['HOME'], 'code.rb')
    Standalone::DummyFS.add_file(file, code)

    lib_dirs.each do |dir|
      Standalone::DummyFS.add_real_directory(dir, '*.rb', true)
    end

    result = nil
    old_stdout = $stdout
    old_stderr = $stderr
    old_stdin  = $stdin

    # RAM limit
    unless @memlimit.zero?
      # Resident memory: how much RAM is being actively used (I think?).
      Process.setrlimit(Process::RLIMIT_RSS, @memlimit * 1024 * 1024)

      # Virtual memory: how much is allocated (I think?).
      Process.setrlimit(Process::RLIMIT_AS,  @virt_memlimit * 1024 * 1024)
    end

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

      method_name = const.is_a?(Module) ? :module_eval : :instance_eval

      const.module_eval do
        (const.methods + const.private_methods - $TRUSTED_METHODS_ALL - trusted).each do |method_name|
          # FIXME: This is a hack because we need STDIN (the IO class) to be
          #        left alone for eval() to work.
          next if [:STDIN, :STDOUT, :STDERR].include?(constant)

          m = method_name.to_sym.inspect

          # FIXME: Make this less horrifyingly gross.
            begin
              eval("public #{m}; undef #{m}")
            rescue NameError => e
              # Re-raise the error as long as it is not telling us
              # the method we are trying to remove is undefined.
              unless e.message.start_with?("undefined method `#{method_name.to_s}' ")
                raise
              end
            end


          #next unless method_defined?('define_method')
          #define_method(meth) {}

          #remove_method(meth) rescue nil
          #eval("public #{m}; undef #{m}")
          #puts "Removing #{constant}.#{meth}"
          #undef_method meth if respond_to?(meth)
        end
      end
    end

    (global_variables - $TRUSTED_GLOBALS).each do |var|
      ::Kernel.eval("#{var.to_s}.freeze") 
    end

    $stdout = StringIO.new
    $stderr = StringIO.new
    $stdin  = StringIO.new

    Object.instance_eval do
      [:STDOUT, :STDERR, :STDIN].each { |x| remove_const x }
    end
    Object.const_set(:STDOUT, $stdout)
    Object.const_set(:STDERR, $stderr)
    Object.const_set(:STDIN, $stdin)

    $done = false

    out_reader = rewinding_reader($stdout, old_stdout)
    err_reader = rewinding_reader($stderr, old_stderr)
    in_reader  = reader($stdin,  old_stdin)

    require 'sicuro/runtime/whitelist'
    result = ::Kernel.eval(code, TOPLEVEL_BINDING, file)
    $done = true

    out_reader.join
    err_reader.join
  rescue Exception => e
    old_stderr.puts "#{e.class}: #{e.message}"
    old_stderr.puts e.backtrace.join("\n")
  end

  # A recursive function to determine if a process has terminated,
  # attempts to terminate it if it has not.
  #
  # If `attempt` is greater than 1, it will print a warning.
  # If `attempt` is greater than 3, it will raise a SandboxError.
  # (Both of these are done through Sicuro::Utils.sandbox_error.)
  def running_check(pid, code, attempt = 1)
    # If it's the second or later attempt, wait in case it was in the
    # process of terminating
    sleep 0.5 if attempt > 1

    # No need to try to kill an already-running process
    return true unless Sicuro::Utils.process_running?(pid)

    begin
      Process.kill('KILL', @pid)
    rescue #Error::ESRCH
      nil
    end

    if attempt > 1
      _fatal = attempt >= 3

      Sicuro::Utils.sandbox_error("Attempt ##{attempt} to terminate process ##{pid}.", _fatal)
    end

    !Sicuro::Utils.process_running?(pid) || running_check(pid, code, attempt + 1)
  end


  def reader(from, to)
    Thread.new(from, to) do |from, to|
      ret = ''

      until from.eof?
        s = from.read
        ret += s

        to.write s
        to.flush
      end

      ret
    end
  end

  def rewinding_reader(from, to)
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
end
