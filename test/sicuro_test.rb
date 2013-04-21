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
      topic.eval("require 'dl'").value
    end.equals(load_error % 'dl')

    asserts 'DL cannot be used to kill entire process group' do
      topic.eval("require 'dl'; require 'dl/import'; module KillDashNine; extend DL::Importer; dlload '/lib/libc.so.6'; extern 'int kill(int, int)'; end; KillDashNine.kill(0, 9)").value
    end.equals(load_error % 'dl')
  end

  context 'printing text' do
    asserts(:eval_value, 'puts "hi"').equals("hi\n")
  end

  context 'return value' do
    asserts(:eval_value, '"hi"').equals('"hi"')
    asserts(:eval_value, "'hi'").equals('"hi"')
    asserts(:eval_value, '1'   ).equals('1')
    asserts(:eval_value, 'fail').equals('RuntimeError: ')
    asserts(:eval_value,  'nil').equals('nil')
    asserts(:eval_value,  'exit!').equals('nil')
    asserts(:eval_return, 'puts').equals('nil')
  end

  context 'wrapper functions' do
    asserts("Sicuro.eval('puts \"hi\"')") do
      topic.eval('puts "hi"').value
    end.equals("hi\n")
    asserts(:eval_stdout, 'puts 1').equals("1\n")
    asserts(:eval_stderr, 'warn 1').equals("1\n")
    asserts(:eval_return, '1').equals('1')
    asserts(:eval_exception, 'raise').equals('RuntimeError: ')
    asserts("eval('1').inspect") do
      topic.eval('1').inspect
    end.equals('#<Sicuro::Eval code="1" value="1">')
  end

  context 'exceptions' do
    asserts(:eval_exception, 'undefined').equals("NameError: undefined local variable or method `undefined' for main:Object")

    # Verify if there is a syntax error. Don't check more than the first word,
    # given that it varies with ruby version and possibly interpreter.
    asserts("eval(':')") do
        topic.eval_exception(':').split(' ')[0]
    end.equals("SyntaxError:")

    asserts(:eval_exception, 'a=[];loop{a<<a}').equals("NoMemoryError: failed to allocate memory")
  end

  context 'unsafe constants are removed' do
    # I hate you, ruby 1.9.2 :(
    valid = [
              "NameError: uninitialized constant %s",
              "NameError: uninitialized constant Object::%s"
            ]
    (Object.constants - $TRUSTED_CONSTANTS).each do |constant|
      asserts "#{constant} is not defined" do
        valid.map{|x| x % constant }.include?(topic.eval_exception(constant.to_s))
      end
    end
  end

  context 'unsafe globals are removed' do
    (global_variables - $TRUSTED_GLOBALS).each do |var|
      asserts "#{var.to_s} is frozen." do
        topic.eval_return "eval(#{var.to_s.inspect}).frozen?"
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

  context 'unsafe public methods are removed' do
    manually_overridden = {
      :Kernel => [:load, :require, :require_relative],
    }

    $TRUSTED_PUBLIC_METHODS.each do |const, methods|
      methods_to_check =  ::Kernel.methods - ::Object.methods -
                          methods - (manually_overridden[const] || [])

      methods_to_check.each do |meth|
        asserts "#{const.to_s}.#{meth} is removed" do
          topic.eval("#{const.to_s}.#{meth}").exception =~ /^NoMethodError: undefined method `#{meth}' for #{const.to_s}:(Class|Module|Object)/
        end
      end
    end
  end

  context 'unsafe private methods are removed' do
    manually_overridden = {
      # None.
    }

    $TRUSTED_PRIVATE_METHODS.each do |const, methods|
      methods_to_check =  ::Kernel.methods - ::Object.methods -
                          methods - (manually_overridden[const] || [])

      methods_to_check.each do |meth|
        asserts "#{const.to_s}.#{meth} is removed" do
          topic.eval("#{const.to_s}.#{meth}").exception =~ /^NoMethodError: undefined method `#{meth}' for #{const.to_s}:(Class|Module|Object)/
        end
      end
    end
  end

  context 'innards work as expected' do
    asserts(:_generate_json, 1, 2, 3, 4, 5).equals('{"code":1,"stdout":2,"stderr":3,"return":"4","exception":5}')
  end

end
