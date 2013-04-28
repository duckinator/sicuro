describe Sicuro do
  context 'helpers' do
    Sicuro.assert('true', 'true').should == true

    context 'sandbox_error passed a string' do
      $stderr.should_receive(:puts).with("[SANDBOX WARNING] test\n")
      Sicuro.sandbox_error('test')
    end

    context 'sandbox_error passed an array' do
      $stderr.should_receive(:puts).with("[SANDBOX WARNING] test\n")
      Sicuro.sandbox_error(['test'])
    end

    context 'sandbox_error passed a number' do
      $stderr.should_receive(:puts).with("[SANDBOX WARNING] 1\n")
      Sicuro.sandbox_error(1)
    end

    context 'fatal sandbox_error' do
      Sicuro.sandbox_error('test', true).should raise_exception(Sicuro::SandboxError, 'test')
    end
  end
end
