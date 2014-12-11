describe 'Sicuro' do
  # Tests regarding the behavior of evaluations are in sicuro_evaluation_results_spec.rb.

  context '#eval' do
    it 'returns an Evaluation' do
      Sicuro.new.eval('').should be_a Sicuro::Evaluation
    end
  end

  it 'defines res_memlimit, virt_memlimit, and timelimit correctly' do
    sandbox = Sicuro.new(1, 2, 3)

    sandbox.res_memlimit.should  == 1
    sandbox.virt_memlimit.should == 2
    sandbox.timelimit.should     == 3
  end

  it '#inspect' do
    Sicuro.new(1, 2, 3).inspect.should == "#<Sicuro res_memlimit=1 virt_memlimit=2 timelimit=3>"
    Sicuro.new(1, 2).inspect.should    == "#<Sicuro res_memlimit=1 virt_memlimit=2 timelimit=5>"
  end
end
