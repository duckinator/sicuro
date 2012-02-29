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

    asserts('2.prime?') { Sicuro.eval('2.prime?') }.matches(/^NoMethodError:/)
    asserts('2.prime? with require "prime"') do
      Sicuro.setup(5, 10, "require 'prime'")
      Sicuro.eval("2.prime?")
    end.equals("true")
  end
  
  context 'timeout' do
    asserts('<timeout hit>') { Sicuro.eval('sleep 6') }
    
    # The following crashed many safe eval systems, including many versions of
    # rubino, where sicuro was pulled from.
    asserts('<timeout hit>') { Sicuro.eval('def Exception.to_s;loop{};end;loop{}') }
  end
end
