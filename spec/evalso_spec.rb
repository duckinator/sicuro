describe Sicuro do
  context 'eval.so gem compatibility' do
    it 'mimics Evalso.run' do
      Sicuro.run(language: 'ruby', code: 'print "test".inspect').to_s.should == '"test"'
    end

    it 'raises an ArgumentError if you try a language besides ruby' do
      expect { Sicuro.run(language: 'not_ruby', code: 'puts "test"') }.to raise_exception(ArgumentError)
    end
  end
end
