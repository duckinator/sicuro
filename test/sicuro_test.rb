require 'teststrap'

context 'Sicuro - ' do
  setup { s = Sicuro.new; s.setup; s }

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
    asserts(:eval_return, 'puts').equals(nil)
  end

  context 'libs' do
    asserts(:eval_value, 'Set', ['set']).equals('"Set"')
  end

  context 'precode' do
    asserts(:eval_value, 'Set', nil, 'require "set"').equals('"Set"')
  end

  context 'wrapper functions' do
    asserts("Sicuro.eval('puts \"hi\"')") do
      Sicuro.eval('puts "hi"').value
    end.equals("hi\n")
    asserts(:eval_stdout, 'puts 1').equals("1\n")
    asserts(:eval_stderr, 'warn 1').equals("1\n")
    asserts(:eval_return, '1').equals(1)
    asserts(:eval_exception, 'raise').equals('RuntimeError: ')
    asserts(:eval_inspect, '1').equals('#<Sicuro::Eval stdin="1" value="1">')
  end

  context 'exceptions' do
    asserts(:eval_exception, 'undefined').equals("NameError: undefined local variable or method `undefined' for main:Object")
    asserts(:eval_exception, ':').equals("SyntaxError: <main>:5: syntax error, unexpected $end, expecting tSTRING_CONTENT or tSTRING_DBEG or tSTRING_DVAR or tSTRING_END\n      }; :\n          ^")
    asserts(:eval_exception, 'a=[];loop{a<<a}').equals("NoMemoryError: failed to allocate memory")
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

  context 'unsafe Kernel methods are removed' do
    asserts(:eval_exception, "Kernel.open('.')").equals("NoMethodError: undefined method `open' for Kernel:Module")
  end

  context 'unsafe constants are removed' do
    asserts 'FakeFS is not defined' do
      # I hate you, ruby 1.9.2 :(
      valid = [
                "NameError: uninitialized constant FakeFS",
                "NameError: uninitialized constant Object::FakeFS"
              ]
      valid.include?(Sicuro.new.eval_exception('FakeFS'))
    end
  end

  context 'innards work as expected' do
    asserts 'setup(5, nil, 1.0/(1024*1024))' do
      topic.setup(5, nil, 1.0/(1024*1024)).value
    end.raises(RuntimeError)

    asserts '_unsafe_eval("1", TOPLEVEL_BINDING)' do
      topic._unsafe_eval("1", TOPLEVEL_BINDING)[2] # [2] == returned value
    end.equals(1)

    asserts '_unsafe_eval("raise", TOPLEVEL_BINDING)' do
      topic._unsafe_eval("raise", TOPLEVEL_BINDING)[3] # [3] == exceptions
    end.equals("RuntimeError: ")

    asserts(:_generate_json, 1, 2, 3, 4, 5).equals('{"stdin":1,"stdout":2,"stderr":3,"return":4,"exception":5}')
  end

end
