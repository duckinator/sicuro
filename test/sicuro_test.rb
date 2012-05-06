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
  
  context 'timeout' do
    asserts(:eval_value, 'sleep 6').equals('<timeout hit>')
    
    # The following crashed many safe eval systems, including many versions of
    # rubino, where sicuro was pulled from.
    asserts(:eval_value, 'def Exception.to_s;loop{};end;loop{}').equals('<timeout hit>')
    
    # The following used to create an endlessly-hanging process. Not sure how to
    # check for that automatically, but giving '<timeout hit>' is a bit closer
    # than hanging endlessly.
    # FALSE POSITIVE. Disabling until I actually fix both the bug and the test.
    #asserts('<timeout hit>'), 'sleep').equals('<timeout hit>')  
  end
  
  context 'libs' do
    asserts(:eval_value, 'Set', ['set']).equals('"Set"')
  end
  
  context 'precode' do
    asserts(:eval_value, 'Set', nil, 'require "set"').equals('"Set"')
  end
end
