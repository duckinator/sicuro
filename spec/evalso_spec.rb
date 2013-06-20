describe Sicuro do
  context 'eval.so gem compatibility' do
    it 'raises an ArgumentError if you try a language besides ruby' do
      expect { Sicuro.run(language: 'not_ruby', code: 'puts "test"') }.to raise_exception(ArgumentError)
    end
  end
end
