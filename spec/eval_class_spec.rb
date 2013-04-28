describe Sicuro::Eval do
  it 'sets all of the accessors' do
    eval = Sicuro::Eval.new('code', 'stdout', 'stderr', 'return', 'wall_time', 'pid')

    eval.code.should      == 'code'
    eval.stdout.should    == 'stdout'
    eval.stderr.should    == 'stderr'
    eval.return.should    == 'return'
    eval.wall_time.should == 'wall_time'
    eval.inspect.should   == '#<Sicuro::Eval code="code" stdout="stdout" stderr="stderr" return="return" wall_time="wall_time">'
  end
end
