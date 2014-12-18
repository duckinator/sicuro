require 'sicuro/version'
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
    runtime/file_system

    reader
].each do |file|
  require "sicuro/#{file}"
end

class Sicuro
  # Executes +code+ in a sandboxed environment, and returns the
  # resulting +Evaluation+.
  #
  # +code+::          the code to run.
  # +[new_stdin]+::   a StringIO that is treated as $stdin.
  # +[new_stdout]+::  a StringIO that is treated as $stdout.
  # +[new_stderr]+::  a StringIO that is treated as $stderr.
  # +[lib_dirs]+::    An Array of directories to be made available
  #                   inside the sandbox. Note that this allows *any*
  #                   code in these directories to be executed.
  #
  # Returns an +Evaluation+ containing the results of executing +code+.
  def eval(code, new_stdin = nil, new_stdout = nil, new_stderr = nil, lib_dirs = [])

    new_stdin  ||= StringIO.new
    new_stdout ||= StringIO.new
    new_stderr ||= StringIO.new

    i, o, e, t, pid = nil
    out_reader, err_reader = nil

    start = Time.now

    Timeout.timeout(@timelimit) do
      i, o, e, t = Open3.popen3(RUBY_USED, '-I', SICURO_LIB_DIR, '-e', wrap_code(code, lib_dirs))
      pid = t.pid

      out_reader = Reader.new(o, new_stdout)
      err_reader = Reader.new(e, new_stderr)

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

  # :nodoc:
  # Wraps +code+ so that it will be executed with the sandbox constraints.
  def wrap_code(code, lib_dirs)
    <<-EOF
      # FIXME: Make this less hacky after load paths are set reasonably.
      require #{__FILE__.inspect.gsub('/base.rb', '.rb')}
      s=Sicuro.new(#{@res_memlimit}, #{@virt_memlimit}, #{@timelimit})
      s.send(:safe_eval, #{code.inspect}, #{lib_dirs.inspect})
    EOF
  end

  # :nodoc:
  # The portion that actually enforces the majority of the sandbox
  # constraints.
  #
  # TODO: Since safe_eval itself cannot be tested, separate out what can.
  def safe_eval(code, lib_dirs)
    file = File.join(Standalone::ENV['HOME'], 'code.rb')
    Standalone::Runtime::FileSystem.add_file(file, code)

    lib_dirs.each do |dir|
      Standalone::Runtime::FileSystem.add_real_directory(dir, '*.rb', true)
    end

    result = nil
    old_stdout = $stdout
    old_stderr = $stderr
    old_stdin  = $stdin

    # RAM limit
    unless @res_memlimit.zero?
      # Resident memory: how much RAM is being actively used (I think?).
      Process.setrlimit(Process::RLIMIT_RSS, @res_memlimit * 1024 * 1024)

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

    %w[constants methods file_system].each do |file|
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

    out_reader = RewindingReader.new($stdout, old_stdout)
    err_reader = RewindingReader.new($stderr, old_stderr)
    in_reader  = Reader.new($stdin,  old_stdin)

    require 'sicuro/runtime/whitelist'
    result = ::Kernel.eval(code, TOPLEVEL_BINDING, file)
    $done = true

    out_reader.join
    err_reader.join
  rescue Exception => e
    old_stderr.puts "#{e.class}: #{e.message}"
    old_stderr.puts e.backtrace.join("\n")
  end

  # :nodoc:
  # A recursive function to determine if a process has terminated,
  # attempts to terminate it if it has not.
  #
  # Returns +true+ if the process is terminated in the first 3 attempts,
  # or raises a +SandboxIntegrityError+.
  #
  # If it takes more than 1 attempt to terminate the process,
  # it will print a warning.
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
end
