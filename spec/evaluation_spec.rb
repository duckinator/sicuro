describe Sicuro::Evaluation do
  it 'sets all of the accessors' do
    eval_args = %w[code stdout stderr wall_time]

    eval = Sicuro::Evaluation.new(*eval_args, 'pid')

    eval.code.should      == 'code'
    eval.stdout.should    == 'stdout'
    eval.stderr.should    == 'stderr'
    eval.wall_time.should == 'wall_time'
    eval.inspect.should   == '#<Sicuro::Evaluation code="code" stdout="stdout" stderr="stderr" wall_time="wall_time">'

    io = IO.popen('ruby -e "sleep 5"')
    expect {
      capture(:stderr) {
        Sicuro::Evaluation.new(*eval_args, io.pid)
      }
    }.to raise_exception(Sicuro::SandboxError)
  end
end
