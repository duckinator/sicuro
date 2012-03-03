require 'teststrap'

context 'Sicuro - ' do
  setup { Sicuro }
  
  context 'printing text' do
    asserts(:eval, 'puts "hi"').equals("hi\n")
  end
  
  context 'return value' do
    asserts(:eval, '"hi"').equals('"hi"')
    asserts(:eval, "'hi'").equals('"hi"')
    asserts(:eval, '1'   ).equals('1')
    asserts(:eval, 'fail').equals('RuntimeError: ')
  end
  
  context 'timeout' do
    asserts(:eval, 'sleep 6').equals('<timeout hit>')
    
    # The following crashed many safe eval systems, including many versions of
    # rubino, where sicuro was pulled from.
    asserts(:eval, 'def Exception.to_s;loop{};end;loop{}').equals('<timeout hit>')
    
    # The following used to create an endlessly-hanging process. Not sure how to
    # check for that automatically, but giving '<timeout hit>' is a bit closer
    # than hanging endlessly.
    # FALSE POSITIVE. Disabling until I actually fix both the bug and the test.
    #asserts('<timeout hit>'), 'sleep').equals('<timeout hit>')
  end
  
  context 'specify executable' do
    asserts(:eval, 'print RUBY_VERSION', nil, 'ruby-1.8.7-p357@sicuro-gem').equals('1.8.7')
    asserts(:eval, 'print RUBY_VERSION', nil, 'ruby-1.9.2-p0@sicuro-gem'  ).equals('1.9.2')
  end
end
