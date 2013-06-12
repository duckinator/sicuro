describe Sicuro do
  context 'eval.so gem compatibility' do
    Sicuro.run(language: 'ruby', code: '"test"').to_s.should == '"test"'

    it 'raises an ArgumentError if you try a languageb esides ruby' do
      expect { Sicuro.run(language: 'not_ruby', code: 'puts "test"') }.to raise_exception(ArgumentError)
    end
  end
end
