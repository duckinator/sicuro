describe 'Sicuro' do
  no_sandbox_impl = Sicuro::NO_SANDBOXED_IMPL
  frozen_array_error = "RuntimeError: can't modify frozen Array"
  load_error = "LoadError: cannot load such file -- dl"
  timeout_error = 'Timeout::Error: Code took longer than 5 seconds to terminate.'

  it 'replaces constants' do
    Sicuro.eval('ENV').return.should == Sicuro::Runtime::Constants::ENV.inspect
  end

  context 'sandbox integrity' do
    # http://duckinator.net/blog/sicuro-untrusted-code-execution/

    it 'cannot load DL' do
      Sicuro.eval("require 'dl'").to_s.should start_with(load_error % 'dl')
    end

    it 'cannot use DL to kill entire process group' do
      code = "require 'dl'; require 'dl/import'; module KillDashNine; extend DL::Importer; dlload '/lib/libc.so.6'; extern 'int kill(int, int)'; end; KillDashNine.kill(0, 9)"
      Sicuro.eval(code).to_s.should start_with(load_error % 'dl')
    end

    it 'cannot append a filename to $* (ARGV) and read the contents from $< (ARGF)' do
      Sicuro.eval('$* << "Gemfile"; puts $<.read').to_s.should start_with(frozen_array_error)
    end
  end

  context 'printing text' do
    Sicuro.eval('puts "hi"' ).stdout.should == "hi\n"
    Sicuro.eval('print "hi"').stdout.should == "hi"

    context 'puts' do
      it "does not print to stderr" do
        Sicuro.eval('puts "hi"').stderr.should == ''
      end

      it "prints to stdout" do
        Sicuro.eval('puts "hi"').stdout.should == "hi\n"
      end
    end

    context 'warn' do
      it "does not print to stdout" do
        Sicuro.eval('warn "hi"').stdout.should == ''
      end

      it "prints to stderr" do
        Sicuro.eval('warn "hi"').stderr.should == "hi\n"
      end
    end
  end

  context 'stringification' do
    Sicuro.eval('"hi"').to_s.should == '"hi"'
    Sicuro.eval("'hi'").to_s.should == '"hi"'
    Sicuro.eval('1'   ).to_s.should == '1'

    it "should raise a RuntimeError when you call fail()" do
      Sicuro.eval('fail').to_s.should start_with "RuntimeError: "
    end

    Sicuro.eval('nil'  ).to_s.should == 'nil'
    Sicuro.eval('exit!').to_s.should == 'nil'
    Sicuro.eval('puts' ).to_s.should == "\n"
  end

  context 'return values' do
    Sicuro.eval('nil'   ).return.should == 'nil'
    Sicuro.eval('exit!' ).return.should == 'nil'
    Sicuro.eval('puts'  ).return.should == 'nil'
    Sicuro.eval('puts 1').return.should == 'nil'
    Sicuro.eval('1'     ).return.should == '1'
  end

=begin
  context 'wrapper functions' do
    asserts("Sicuro.eval('puts \"hi\"')") do
      topic.Sicuro.eval('puts "hi"').to_s
    end.equals("hi\n")

    asserts(:eval_stdout, 'puts 1').equals("1\n")
    asserts(:eval_stderr, 'warn 1').equals("1\n")
    asserts(:eval_return, '1').equals('1')

    asserts("raise prints to stderr") do
      topic.Sicuro.eval('raise').stderr.start_with? "RuntimeError: "
    end

    asserts("Sicuro.eval('1').inspect") do
      topic.Sicuro.eval('1').inspect =~ /#<Sicuro::Eval code="1" stdout="" stderr="" return="1" wall_time=\d+>/
    end
  end
=end

  context 'exceptions' do
    it "raises a NameError when referencing an undefined variable" do
      Sicuro.eval('undefined').stderr.should start_with "NameError: undefined local variable or method `undefined' for main:Object"
    end

    # Verify if there is a syntax error. Don't check more than the first word,
    # given that it varies with ruby version and possibly interpreter.
    it "raises a SyntaxError when the entire program is a colon" do
      Sicuro.eval(':').stderr.should start_with "SyntaxError: "
    end

    it "runs out of memory when running a=[];loop{a<<a}" do
      Sicuro.eval('a=[];loop{a<<a}').stderr.should start_with "NoMemoryError: failed to allocate memory"
    end
  end

  context 'unsafe constants are removed' do
    (Object.constants - $TRUSTED_CONSTANTS).each do |constant|
      it "removes #{constant}" do
        Sicuro.eval(constant.to_s).stderr.should start_with "NameError: uninitialized constant "
      end
    end
  end

  context 'unsafe globals are removed' do
    (global_variables - $TRUSTED_GLOBALS).each do |var|
      valid_outputs = [
        "NameError: #{var.to_s} is a read-only variable",
        "SyntaxError: <main>: Can't set variable #{var.to_s}"
      ]

      it "cannot assign to #{var.to_s}" do
        ret = Sicuro.eval("#{var.to_s} = nil").stderr.split("\n")[0]
        valid_outputs.each do |x|
          valid_outputs.any? { |output| ret.start_with? output }
        end
      end

      it "cannot append to #{var.to_s}" do
        ret = Sicuro.eval("#{var.to_s} << #{var.to_s}").stderr.split("\n")[0]
        valid_outputs.each do |x|
          valid_outputs.any? { |output| ret.start_with? output }
        end
      end
    end
  end

  %w[STDIN STDOUT STDERR $stdin $stdout $stderr].each do |x|
    it "changes #{x} to a StringIO" do
      Sicuro.eval("#{x}.class").to_s.should == 'StringIO'
    end
  end

  context 'returns the correct string when timing out' do
    Sicuro.eval("sleep 6").to_s.should == timeout_error

    # The following crashed many safe eval systems, including many versions of
    # rubino, where sicuro was pulled from.
    Sicuro.eval('def Exception.to_s;loop{};end;loop{}').to_s.should == timeout_error

    # The following used to create an endlessly-hanging process.
    Sicuro.eval('sleep').to_s.should == timeout_error
  end

  context 'terminated code after the timeout' do
    Sicuro.eval('sleep 6').running?.should == false

    # The following crashed many safe eval systems, including many versions of
    # rubino, where sicuro was pulled from.
    Sicuro.eval('def Exception.to_s;loop{};end;loop{}').running?.should == false

    # The following used to create an endlessly-hanging process. Not sure how to
    # check for that automatically, but giving 'Timeout::Error: Code took longer than 5 seconds to terminate.' is a bit closer
    # than hanging endlessly.
    Sicuro.eval('sleep').running?.should == false
  end

  context 'removes unsafe methods' do
    $TRUSTED_METHODS.each do |const, methods|
      methods_to_check =  ::Kernel.methods - ::Object.methods - methods

      methods_to_check.each do |meth|
        it "should remove #{const.to_s}.#{meth}" do
          Sicuro.eval("#{const.to_s}.#{meth}").stderr.should start_with "NoMethodError: undefined method `#{meth}' for #{const.to_s}:"
        end
      end
    end
  end

end
