require 'teststrap'

context 'Sicuro - ' do
  context 'printing text' do
    asserts('hi')   { Sicuro.eval('puts "hi"') }
  end
  
  context 'return value' do
    asserts('"hi"') { Sicuro.eval('"hi"') }
    asserts('"hi"') { Sicuro.eval("'hi'") }
    asserts('1')    { Sicuro.eval('1') }
    asserts('RuntimeError: ') { Sicuro.eval('fail') }
    asserts('RuntimeError: ') { Sicuro.eval('fail') }
  end
  
  context 'timeout' do
    asserts('<timeout hit>') { Sicuro.eval('sleep 6') }
    
    # The following crashed many safe eval systems, including many versions of
    # rubino, where sicuro was pulled from.
    asserts('<timeout hit>') { Sicuro.eval('def Exception.to_s;loop{};end;loop{}') }
    
    # The following used to create an endlessly-hanging process. Not sure how to
    # check for that automatically, but giving '<timeout hit>' is a bit closer
    # than hanging endlessly.
    asserts('<timeout hit>') { Sicuro.eval('sleep') }
  end
  
  context 'specify executable' do
    asserts('"1.8.7"') { Sicuro.eval('print RUBY_VERSION', nil, 'ruby-1.8.7-p357@sicuro-gem') }
    asserts('"1.9.2"') { Sicuro.eval('print RUBY_VERSION', nil, 'ruby-1.9.2-p0@sicuro-gem')   }
  end
end
