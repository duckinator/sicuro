describe Sicuro do
  context 'helpers' do
    it "assert('print true', 'true')" do
      Sicuro.assert('print true', 'true').should == true
    end
  end
end
