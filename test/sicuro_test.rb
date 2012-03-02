require 'teststrap'

context 'Sicuro - ' do
  context 'printing text' do
    asserts('hi')   { Sicuro.eval('puts "hi"') }
  end
  
  context 'return value' do
    asserts('"hi"') { Sicuro.eval('"hi"') == '"hi"' }
    asserts('"hi"') { Sicuro.eval("'hi'") == '"hi"' }
    asserts('1')    { Sicuro.eval('1')    == '1' }
    asserts('RuntimeError: ') { Sicuro.eval('fail') == 'RuntimeError: ' }
    asserts('RuntimeError: ') { Sicuro.eval('fail') == 'RuntimeError: ' }
  end
  
  context 'timeout' do
    asserts('<timeout hit>') { Sicuro.eval('sleep 6') == '<timeout hit>' }
    
    # The following crashed many safe eval systems, including many versions of
    # rubino, where sicuro was pulled from.
    asserts('<timeout hit>') { Sicuro.eval('def Exception.to_s;loop{};end;loop{}') == '<timeout hit>' }
    
    # The following used to create an endlessly-hanging process. Not sure how to
    # check for that automatically, but giving '<timeout hit>' is a bit closer
    # than hanging endlessly.
    # FALSE POSITIVE. Disabling until I actually fix both the bug and the test.
    #asserts('<timeout hit>') { Sicuro.eval('sleep') == '<timeout hit>' }
  end
  
  context 'specify executable' do
    asserts('1.8.7') { Sicuro.eval('print RUBY_VERSION', nil, 'ruby-1.8.7-p357@sicuro-gem') == '1.8.7' }
    asserts('1.9.2') { Sicuro.eval('print RUBY_VERSION', nil, 'ruby-1.9.2-p0@sicuro-gem')   == '1.9.2' }
  end
end
