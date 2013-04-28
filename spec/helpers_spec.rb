describe Sicuro do
  context 'helpers' do
    Sicuro.assert('true', 'true').should == true

    context 'sandbox_error passed a string' do
      capture(:stderr) { Sicuro.sandbox_error('test') }.should == "[SANDBOX WARNING] test\n"
    end

    context 'sandbox_error passed an array' do
      capture(:stderr) { Sicuro.sandbox_error(['test']) }.should == "[SANDBOX WARNING] test\n"
    end

    context 'sandbox_error passed a number' do
      capture(:stder) { Sicuro.sandbox_error(1) }.should == "[SANDBOX WARNING] 1\n"
    end

    context 'fatal sandbox_error' do
      Sicuro.sandbox_error('test', true).should raise_exception(Sicuro::SandboxError, 'test')
    end
  end
end
