require 'timeout'
require 'open3'
require 'rbconfig'
require 'json'

require File.join(File.dirname(__FILE__), 'trusted', 'constants.rb')
require File.join(File.dirname(__FILE__), 'trusted', 'kernel_methods.rb')
require File.join(File.dirname(__FILE__), 'monkeypatches.rb')

require File.join(File.dirname(__FILE__), 'internal', 'eval.rb')
require File.join(File.dirname(__FILE__), 'internal', 'helper_functions.rb')

class Sicuro
  # Ruby executable used.
  RUBY_USED = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'] + RbConfig::CONFIG['EXEEXT'])

  # Various defaults for all of Sicuro.
  DEFAULT_LIBS = []
  DEFAULT_PRECODE = ''
  DEFAULT_TIMEOUT = 5
  DEFAULT_MEMLIMIT_UPPER_BOUND = 100

  # Replace the real require() with something that raises a NotImplementedError.
  # This way we can avoid removing it entirely.
  def dummy_require(*args)
    raise ::NotImplementedError
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
  # URL: http://github.com/duckinator/sicuro/issues
  #
  # `memlimit_upper_bound` is the upper limit of memory detection, in MegaBytes.
  # Default is specified as DEFAULT_MEMLIMIT_UPPER_BOUND.
  #
  def setup(timelimit=DEFAULT_TIMEOUT, memlimit=nil, memlimit_upper_bound=DEFAULT_MEMLIMIT_UPPER_BOUND)
    @@timelimit = timelimit
    @@memlimit  = memlimit

    if @@memlimit.nil?
      5.step(memlimit_upper_bound, 5) do |i|
        if assert('print 1', '1', nil, nil, i)
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
  # TODO: Using `def _code_prefix(code, libs=DEFAULT_LIBS, precode=DEFAULT_PRECODE, ...)
  #       breaks to the point that 0 tests pass, due to using >100MB RAM.
  #       Someone needs to find out why.
  def _code_prefix(code, libs = nil, precode = nil, memlimit = nil, identifier = nil)
    memlimit ||= @@memlimit
    libs     ||= DEFAULT_LIBS
    precode  ||= DEFAULT_PRECODE

    identifier += '; ' if identifier

    prefix = ''

    unless $DEBUG
      # The following makes it use "sicuro ([identifier; ]current_time)" as the
      # process name. Likely only actually does anything on *nix systems.
      prefix = "$0 = 'sicuro (#{identifier}#{Time.now.strftime("%r")})';"
    end

    prefix += <<-EOF
      require #{__FILE__.inspect}
      s=Sicuro.new
      s.setup(#{@@timelimit.inspect}, #{memlimit.inspect})
      print s._safe_eval(#{code.inspect}, #{libs.inspect}, #{precode.inspect}, #{memlimit.inspect})
    EOF
  end

  # Wrapper function for Sicuro.new.eval(*args).
  # Originally for backwards-compatibility, kept because I (@duckinator) feel it
  # is much nicer than the full Sicuro.new.eval(*args) version.
  def self.eval(*args)
    self.new.eval(*args)
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
  def eval(code, libs = nil, precode = nil, memlimit = nil, identifier = nil)

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
          # Nothing at all was returned.
          # This often happens on Kernel#exit!
          return Eval.new({
            'stdin'     => code,
            'stdout'    => '',
            'stderr'    => '',
            'return'    => nil,
            'exception' => nil
          }, pid)
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
    setup
    retry
  ensure
    if Sicuro.process_running?(pid)
      Process.kill('KILL', pid) rescue nil
      if Sicuro.process_running?(pid)
        warn "[SICURO ERROR] Could not kill process ##{pid} after 3 attempts!"
      end
    end
  end

  # stdout, stderr, and exception catching for unsafe Kernel#eval
  # Used internally by Sicuro._safe_eval
  def _unsafe_eval(code, binding)
    out_io, err_io, result, exception = nil

    begin
      out_io = $stdout = StringIO.new
      err_io = $stderr = StringIO.new
      code = "BEGIN {
        eigenclass = class << Kernel; self end
        (::Kernel.methods - ::Object.methods - #{$TRUSTED_KERNEL_METHODS.inspect}).each do |x|
          ::Kernel.send(:remove_method, x.to_sym)
          eigenclass.send(:remove_method, x.to_sym)
        end
        ::Kernel.module_eval { alias require Sicuro.dummy_require }
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

  def _generate_json(code, stdout, stderr, result, exception)
    JSON.generate({
      'stdin'     => code,
      'stdout'    => stdout,
      'stderr'    => stderr,
      'return'    => result,
      'exception' => exception
    })
  end

  # Use Sicuro.eval instead. This does not provide a strict time limit or call Sicuro.setup.
  # Used internally by Sicuro.eval
  # TODO: Since _safe_eval itself cannot be tested, separate out what can.
  def _safe_eval(code, libs, precode, memlimit)
    # RAM limit
    Process.setrlimit(Process::RLIMIT_AS, memlimit*1024*1024)

    # CPU time limit. 5s means 5s of CPU time.
    Process.setrlimit(Process::RLIMIT_CPU, @@timelimit)
    ::Kernel.trap(:XCPU) do # I believe this is triggered when you hit RLIMIT_CPU
      raise Timeout::Error
      exit!
    end

    # Things we want, or need to have, available in eval
    require 'stringio'
    require 'pp'

=begin
    %w[constants].each do |file|
      require File.join(File.dirname(__FILE__), 'runtime', file + '.rb')
    end
=end

    # We require FakeFS here but we activate it only after resolving our external libs
    begin
      require 'fakefs/safe'
    rescue LoadError
      require 'rubygems'
      retry
    end

    required_for_custom_libs = [:FakeFS, :Gem, :FileUtils, :File, :Pathname, :Dir, :RbConfig, :IO, :FileTest]
    (Object.constants - $TRUSTED_CONSTANTS - required_for_custom_libs).each do |x|
      Object.instance_eval { remove_const x }
    end

    ::Kernel.eval(precode, TOPLEVEL_BINDING)

    libs.each do |lib|
      require lib
    end

    FakeFS.activate!

    # Without Gem we won't require unresolved gems, therefore we restore the original require.
    # This allows us to lazy-require other trusted components from the same $LOAD_PATH.
    # NOTE: This is replaced with Sicuro.dummy_require by Sicuro#_code_prefix.
    ::Kernel.module_eval { alias require gem_original_require }

    required_for_custom_libs.each do |x|
      Object.instance_eval { remove_const x }
    end

    stdout, stderr, result, exception = _unsafe_eval(code, TOPLEVEL_BINDING)

    print _generate_json(code, stdout, stderr, result, exception)
  rescue => e
    print _generate_json('', '', '', nil, "#{e.class}: #{e.message}")
  end
end
