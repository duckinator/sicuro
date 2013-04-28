describe Sicuro do
  context 'eval.so gem compatibility' do
    Sicuro.run(:ruby, '"test"').to_s.should == '"test"'

    it 'raises an ArgumentError if you try a languageb esides ruby' do
      expect { Sicuro.run(:not_ruby, "puts 'test'") }.to raise_exception(ArgumentError)
    end
  end
end
