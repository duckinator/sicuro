describe Sicuro do
  context 'helpers' do
    it "assert('print true', 'true')" do
      Sicuro.assert('print true', 'true').should == true
    end

    it "sandbox_error('test')" do
      capture(:stderr) { Sicuro.sandbox_error('test') }.should == "[SANDBOX WARNING] test\n"
    end

    it "sandbox_error(['test'])" do
      capture(:stderr) { Sicuro.sandbox_error(['test']) }.should == "[SANDBOX WARNING] test\n"
    end

    it "sandbox_error(1)" do
      capture(:stderr) { Sicuro.sandbox_error(1) }.should == "[SANDBOX WARNING] 1\n"
    end

    it 'raises a Sicuro::SandboxError when passing true to sandbox_error' do
      expect {
        capture(:stderr) {
          Sicuro.sandbox_error('test', true)
        }
      }.to raise_exception(Sicuro::SandboxError, 'test')
    end
  end
end
