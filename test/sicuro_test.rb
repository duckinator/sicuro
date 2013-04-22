require 'teststrap'

no_sandbox_impl = Sicuro::Runtime::Methods::NO_SANDBOXED_IMPL
load_error = "LoadError: cannot load such file -- dl"

context 'Sicuro - ' do
  setup { Sicuro.new }

  context 'replaced constants' do
    asserts(:eval_return, 'ENV').equals(Sicuro::Runtime::Constants::ENV.inspect)
  end

  context 'sandbox integrity' do
    # http://duckinator.net/blog/sicuro-untrusted-code-execution/

    asserts 'cannot load DL' do
      topic.eval("require 'dl'").to_s
    end.equals(load_error % 'dl')

    asserts 'DL cannot be used to kill entire process group' do
      topic.eval("require 'dl'; require 'dl/import'; module KillDashNine; extend DL::Importer; dlload '/lib/libc.so.6'; extern 'int kill(int, int)'; end; KillDashNine.kill(0, 9)").to_s
    end.equals(load_error % 'dl')
  end

  context 'printing text' do
    asserts(:eval_stdout, 'puts "hi"').equals("hi\n")
    asserts(:eval_stdout, 'print "hi"').equals("hi")

    asserts("warn() does not print to stdout") do
      topic.eval('warn "hi"').stdout == ''
    end

    asserts(:eval_stderr, 'warn "hi"').equals("hi\n")
  end

  context 'string representations' do
    asserts(:eval_value, '"hi"').equals('"hi"')
    asserts(:eval_value, "'hi'").equals('"hi"')
    asserts(:eval_value, '1'   ).equals('1')

    asserts("fail() raises a RuntimeError") do
      topic.eval('fail').to_s.start_with? "RuntimeError: "
    end

    asserts(:eval_value, 'nil').equals('nil')
    asserts(:eval_value, 'exit!').equals('nil')
    asserts(:eval_value, 'puts').equals("\n")
  end

  context 'return values' do
    asserts(:eval_return, 'nil'   ).equals('nil')
    asserts(:eval_return, 'exit!' ).equals('nil')
    asserts(:eval_return, 'puts'  ).equals('nil')
    asserts(:eval_return, 'puts 1').equals('nil')
    asserts(:eval_return, '1'     ).equals('1')
  end

  context 'wrapper functions' do
    asserts("eval('puts \"hi\"')") do
      topic.eval('puts "hi"').to_s
    end.equals("hi\n")

    asserts(:eval_stdout, 'puts 1').equals("1\n")
    asserts(:eval_stderr, 'warn 1').equals("1\n")
    asserts(:eval_return, '1').equals('1')

    asserts("raise prints to stderr") do
      topic.eval('raise').stderr.start_with? "RuntimeError: "
    end

    asserts("eval('1').inspect") do
      topic.eval('1').inspect =~ /#<Sicuro::Eval code="1" stdout="" stderr="" return="1" wall_time=\d+>/
    end
  end

  context 'exceptions' do
    asserts("referencing undefined variable raises NameError") do
      topic.eval('undefined').stderr.start_with? "NameError: undefined local variable or method `undefined' for main:Object"
    end

    # Verify if there is a syntax error. Don't check more than the first word,
    # given that it varies with ruby version and possibly interpreter.
    asserts "eval(':') raises a syntax error" do
      topic.eval(':').stderr.start_with? "SyntaxError: "
    end

    asserts "a=[];loop{a<<a} runs out of memory" do
      topic.eval('a=[];loop{a<<a}').stderr.start_with? "NoMemoryError: failed to allocate memory"
    end
  end

  context 'unsafe constants are removed' do
    (Object.constants - $TRUSTED_CONSTANTS).each do |constant|
      asserts "#{constant} is not defined" do
        topic.eval(constant.to_s).stderr.start_with? "NameError: uninitialized constant "
      end
    end
  end

  context 'unsafe globals are removed' do
    (global_variables - $TRUSTED_GLOBALS).each do |var|
      valid_outputs = [
        "NameError: #{var.to_s} is a read-only variable",
        "SyntaxError: <main>: Can't set variable #{var.to_s}"
      ]

      asserts "#{var.to_s} cannot set" do
        ret = topic.eval("#{var.to_s} = nil").stderr.split("\n")[0]
        valid_outputs.each do |x|
          valid_outputs.any? { |output| ret.start_with? output }
        end
      end

      asserts "#{var.to_s} cannot be appended to" do
        ret = topic.eval("#{var.to_s} << #{var.to_s}").stderr.split("\n")[0]
        valid_outputs.each do |x|
          valid_outputs.any? { |output| ret.start_with? output }
        end
      end
    end
  end

  context "STDIN, STDOUT, STDERR and friends are StringIO instances" do
    %w[STDIN STDOUT STDERR $stdin $stdout $stderr].each do |x|
      asserts(:eval_value, "#{x}.class").equals('StringIO')
    end
  end

  context 'timed-out code returns proper string' do
    asserts(:eval_value, 'sleep 6').equals('Timeout::Error: Code took longer than 5 seconds to terminate.')

    # The following crashed many safe eval systems, including many versions of
    # rubino, where sicuro was pulled from.
    asserts(:eval_value, 'def Exception.to_s;loop{};end;loop{}').equals('Timeout::Error: Code took longer than 5 seconds to terminate.')

    # The following used to create an endlessly-hanging process. Not sure how to
    # check for that automatically, but giving 'Timeout::Error: Code took longer than 5 seconds to terminate.' is a bit closer
    # than hanging endlessly.
    asserts(:eval_value, 'sleep').equals('Timeout::Error: Code took longer than 5 seconds to terminate.')
  end

  context 'timed-out code properly terminated' do
    denies(:eval_running?, 'sleep 6')

    # The following crashed many safe eval systems, including many versions of
    # rubino, where sicuro was pulled from.
    denies(:eval_running?, 'def Exception.to_s;loop{};end;loop{}')

    # The following used to create an endlessly-hanging process. Not sure how to
    # check for that automatically, but giving 'Timeout::Error: Code took longer than 5 seconds to terminate.' is a bit closer
    # than hanging endlessly.
    denies(:eval_running?, 'sleep')
  end

  context 'unsafe methods are removed' do
    $TRUSTED_METHODS.each do |const, methods|
      methods_to_check =  ::Kernel.methods - ::Object.methods - methods

      methods_to_check.each do |meth|
        asserts "#{const.to_s}.#{meth} is removed" do
          topic.eval("#{const.to_s}.#{meth}").stderr =~ /^NoMethodError: undefined method `#{meth}' for #{const.to_s}:(Class|Module|Object)/
        end
      end
    end
  end

end
