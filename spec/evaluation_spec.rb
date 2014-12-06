describe Sicuro::Evaluation do
  it 'sets all of the accessors' do
    eval_args = %w[code stdout stderr wall_time]

    eval = Sicuro::Evaluation.new(*eval_args)

    eval.code.should      == 'code'
    eval.stdout.should    == 'stdout'
    eval.stderr.should    == 'stderr'
    eval.wall_time.should == 'wall_time'
    eval.inspect.should   == '#<Sicuro::Evaluation code="code" stdout="stdout" stderr="stderr" wall_time="wall_time">'
  end
end
