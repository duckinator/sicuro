require 'teststrap'

context 'Sicuro - ' do
  setup { Sicuro }
  
  context 'printing text' do
    asserts(:eval_out, 'puts "hi"').equals("hi\n")
    
    # 1.8.7 equivalents
    asserts(:eval_out, 'puts "hi"', nil, nil, nil, 'ruby-1.8.7-p357@sicuro-gem').equals("hi\n")
  end
  
  context 'return value' do
    asserts(:eval_out, '"hi"').equals('"hi"')
    asserts(:eval_out, "'hi'").equals('"hi"')
    asserts(:eval_out, '1'   ).equals('1')
    asserts(:eval_err, 'fail').equals('RuntimeError: ')
    
    # 1.8.7 equivalents
    asserts(:eval_out, '"hi"', nil, nil, nil, 'ruby-1.8.7-p357@sicuro-gem').equals('"hi"')
    asserts(:eval_out, "'hi'", nil, nil, nil, 'ruby-1.8.7-p357@sicuro-gem').equals('"hi"')
    asserts(:eval_out, "1",    nil, nil, nil, 'ruby-1.8.7-p357@sicuro-gem').equals('1')
    asserts(:eval_err, "fail", nil, nil, nil, 'ruby-1.8.7-p357@sicuro-gem').equals('RuntimeError: (eval):1: ')
  end
  
  context 'timeout' do
    asserts(:eval_err, 'sleep 6').equals('<timeout hit>')
    
    # The following crashed many safe eval systems, including many versions of
    # rubino, where sicuro was pulled from.
    asserts(:eval_err, 'def Exception.to_s;loop{};end;loop{}').equals('<timeout hit>')
    
    # The following used to create an endlessly-hanging process. Not sure how to
    # check for that automatically, but giving '<timeout hit>' is a bit closer
    # than hanging endlessly.
    # FALSE POSITIVE. Disabling until I actually fix both the bug and the test.
    #asserts('<timeout hit>'), 'sleep').equals('<timeout hit>')
    
    
    # 1.8.7 equivalents
    asserts(:eval_err, 'sleep 6', nil, nil, nil, 'ruby-1.8.7-p357@sicuro-gem').equals('<timeout hit>')
    asserts(:eval_err, 'def Exception.to_s;loop{};end;loop{}',nil, nil, nil, 'ruby-1.8.7-p357@sicuro-gem').equals('<timeout hit>')
    #asserts(:eval_out, 'sleep', nil, nil, nil, 'ruby-1.8.7-p357@sicuro-gem').equals('<timeout hit>')
  end
  
  context 'specify executable' do
    asserts(:eval_out, 'print RUBY_VERSION', nil, nil, nil, 'ruby-1.8.7-p357@sicuro-gem').equals('1.8.7')
    asserts(:eval_out, 'print RUBY_VERSION', nil, nil, nil, 'ruby-1.9.2-p0@sicuro-gem'  ).equals('1.9.2')
  end
  
  context 'libs' do
    asserts(:eval_out, 'Set', ['set']).equals('Set')
    asserts(:eval_out, 'Set', nil, 'require "set"').equals('Set')
    
    # 1.8.7 equivalents
    asserts(:eval_out, 'Set', ['set'], nil, nil,         'ruby-1.8.7-p357@sicuro-gem').equals('Set')
    asserts(:eval_out, 'Set', nil, 'require "set"', nil, 'ruby-1.8.7-p357@sicuro-gem').equals('Set')
  end
end
