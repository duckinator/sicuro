require 'teststrap'

context 'Sicuro - ' do
  setup { Sicuro }
  
  context 'printing text' do
    asserts(:eval_value, 'puts "hi"').equals("hi\n")
  end
  
  context 'return value' do
    asserts(:eval_value, '"hi"').equals('"hi"')
    asserts(:eval_value, "'hi'").equals('"hi"')
    asserts(:eval_value, '1'   ).equals('1')
    asserts(:eval_value, 'fail').equals('RuntimeError: ')
  end
  
  context 'libs' do
    asserts(:eval_value, 'Set', ['set']).equals('"Set"')
  end
  
  context 'precode' do
    asserts(:eval_value, 'Set', nil, 'require "set"').equals('"Set"')
  end

  context 'wrapper functions' do
    asserts(:eval_stdout, 'puts 1').equals("1\n")
    asserts(:eval_stderr, 'warn 1').equals("1\n")
    asserts(:eval_return, '1').equals(1)
    asserts(:eval_exception, 'raise').equals('RuntimeError: ')
    asserts(:eval_inspect, '1').equals('#<Sicuro::Eval stdin="1" value="1">')
  end
  
  context 'exceptions' do
    asserts(:eval_exception, 'undefined').equals("NameError: undefined local variable or method `undefined' for main:Object")
    asserts(:eval_exception, ':').equals("SyntaxError: <main>:4: syntax error, unexpected $end, expecting tSTRING_CONTENT or tSTRING_DBEG or tSTRING_DVAR or tSTRING_END\n      }; :\n          ^")
    asserts(:eval_exception, 'a=[];loop{a<<a}').equals("NoMemoryError: failed to allocate memory")
  end
  
  context 'timeouts (this *will* take a while)' do
    asserts(:eval_value, 'sleep 6').equals('<timeout hit>')
    
    # The following crashed many safe eval systems, including many versions of
    # rubino, where sicuro was pulled from.
    asserts(:eval_value, 'def Exception.to_s;loop{};end;loop{}').equals('<timeout hit>')
    
    # The following used to create an endlessly-hanging process. Not sure how to
    # check for that automatically, but giving '<timeout hit>' is a bit closer
    # than hanging endlessly.
    # FALSE POSITIVE. Disabling until I actually fix both the bug and the test.
    #asserts(:eval_value, 'sleep').equals('<timeout hit>')  
  end
end
