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

    runtime/whitelist
    runtime/constants
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

    pid = nil
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

    Evaluation.new(code, new_stdout.string, new_stderr.string, wall_time)
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

  def add_to_filesystem(file, code, lib_dirs)
    Standalone::Runtime::FileSystem.add_file(file, code)

    lib_dirs.each do |dir|
      Standalone::Runtime::FileSystem.add_real_directory(dir, '*.rb', true)
    end
  end

  def replace_io!
    $stdout = StringIO.new
    $stderr = StringIO.new
    $stdin  = StringIO.new

    Object.instance_eval do
      [:STDOUT, :STDERR, :STDIN].each { |x| remove_const x }
    end
    Object.const_set(:STDOUT, $stdout)
    Object.const_set(:STDERR, $stderr)
    Object.const_set(:STDIN, $stdin)
  end

  def enforce_constraints!
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
  end

  # :nodoc:
  # The portion that actually enforces the majority of the sandbox
  # constraints.
  #
  # TODO: Since safe_eval itself cannot be tested, separate out what can.
  def safe_eval(code, lib_dirs)
    file = File.join(Standalone::ENV['HOME'], 'code.rb')
    result = nil
    old_stdout, old_stderr, old_stdin = $stdout, $stderr, $stdin

    add_to_filesystem(file, code, lib_dirs)
    replace_io!
    enforce_constraints!
    ::Standalone.enable!
    ::Sicuro::Runtime::Methods.replace_all!
    # FIXME: Make it so things don't blow up when the next line is un-commented.
    #::Sicuro::Runtime::Constants.replace_all!
    ::Sicuro::Runtime.enforce_whitelist!

    out_reader = HorribleReader.new($stdout, old_stdout)
    err_reader = HorribleReader.new($stderr, old_stderr)
    in_reader  = Reader.new($stdin,  old_stdin)

    result = ::Kernel.eval(code, TOPLEVEL_BINDING, file)

    out_reader.close
    err_reader.close

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
