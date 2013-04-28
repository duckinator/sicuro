describe Sicuro do
  context 'helpers' do
    Sicuro.assert('true', 'true').should == true

    Sicuro.sandbox_error('test').should   == "[SANDBOX ERROR] test\n"
    Sicuro.sandbox_error(['test']).should == "[SANDBOX ERROR] test\n"
    Sicuro.sandbox_error(1).should        == "[SANDBOX ERROR] 1\n"
    Sicuro.sandbox_error('test', true).should raise_exception(Sicuro::SandboxError, 'test')
  end
end
