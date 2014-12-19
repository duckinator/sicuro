describe 'Sicuro' do
  no_sandbox_impl = Sicuro::NO_SANDBOXED_IMPL
  frozen_error = "RuntimeError: can't modify frozen "
  load_error = "LoadError: cannot load such file -- dl"
  timeout_error = "Timeout::Error: Code took longer than %i seconds to terminate."
  name_error = "NameError: undefined local variable or method `%s' "
  no_method_error = "NoMethodError: undefined method `%s' "

  it 'replaces constants' do
    Sicuro.eval('print ENV.inspect').stdout.should == Standalone::ENV.inspect
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
      Sicuro.eval('$* << "Gemfile"; puts $<.read').to_s.should start_with(frozen_error)
    end

    it 'cannot use $stdout to reference IO' do
      code = 'puts Object.new.tap{|o|o.define_singleton_method(:inspect){ $stdout.class.read("/etc/passwd") } }'
      Sicuro.eval(code).to_s.should_not start_with("root:")
    end

    it 'cannot get a reference to (original) File using $* (ARGV) and $< (ARGF)' do
      # If $<.to_io.class.ancestors[0] should return something from within Sicuro
      # (such as Sicuro::Runtime::Constants::File) or error, not return File.

      code = '$* << "/etc/passwd"; puts $<.to_io.class.ancestors[0]'
      Sicuro.eval(code).to_s.should_not == 'File'
    end

    it 'cannot access gem_original_require' do
      Sicuro.eval('gem_original_require').to_s.should start_with(no_method_error % 'gem_original_require')
    end

    context 'file access' do
      it 'cannot write a file to disk by modifying $* (ARGV) and $< (ARGF) to get an IO instance' do
        code = '$* << "/etc/passwd"; io=$<.to_io.class; io.open("file-write-method-1", "w") {|f| f.puts "test" }'
        Sicuro.eval(code)
        File.exist?('file-write-method-1').should == false
      end
    end
  end

  context 'printing text' do
    it 'eval(\'puts "hi"\')' do
      Sicuro.eval('puts "hi"' ).stdout.should == "hi\n"
    end

    it 'eval(\'puts "hi"\')' do
      Sicuro.eval('print "hi"').stdout.should == "hi"
    end

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
    it "should raise a RuntimeError when you call fail()" do
      Sicuro.eval('fail').to_s.should start_with "RuntimeError: "
    end

    it "defaults to STDOUT for eval('puts')" do
      Sicuro.eval('puts').to_s.should == "\n"
    end
  end

  context 'exceptions' do
    it "raises a NameError when referencing an undefined variable" do
      valid_outputs = [
        no_method_error % 'undefined',
        name_error % 'undefined',
      ]
      ret = Sicuro.eval('undefined').stderr
      valid_outputs.any? { |output| ret.start_with?(output) }
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
        ret = Sicuro.eval("#{var.to_s} = nil").stderr
        valid_outputs.any? { |output| ret.start_with?(output) }
      end

      it "cannot append to #{var.to_s}" do
        ret = Sicuro.eval("#{var.to_s} << #{var.to_s}").stderr
        valid_outputs.any? { |output| ret.start_with? output }
      end
    end
  end

  %w[STDIN STDOUT STDERR $stdin $stdout $stderr].each do |x|
    it "changes #{x} to a StringIO" do
      Sicuro.eval("print #{x}.class").stdout.should == 'StringIO'
    end
  end

  it 'enforces timeouts' do
    s = Sicuro.new
    s.timelimit = 0.1
    tmp_timeout_error = timeout_error % 0

    ret = s.eval("sleep 6")
    ret.running?.should == false
    ret.to_s.should == tmp_timeout_error

    # The following crashed many safe eval systems, including many versions of
    # rubino, where sicuro was pulled from.
    ret = s.eval('def Exception.to_s;loop{};end;loop{}')
    ret.running?.should == false
    ret.to_s.should == tmp_timeout_error

    # The following used to create an endlessly-hanging process.
    ret = s.eval('sleep')
    ret.running?.should == false
    ret.to_s.should == tmp_timeout_error
  end

  context 'removes unsafe methods' do
    $TRUSTED_METHODS.each do |const, methods|
      methods_to_check =  ::Kernel.methods - ::Object.methods - methods - $TRUSTED_METHODS_ALL

      methods_to_check.each do |meth|
        it "should remove #{const.to_s}.#{meth}" do
          Sicuro.eval("#{const.to_s}.#{meth}").stderr.should start_with "NoMethodError: undefined method `#{meth}' for "
        end
      end
    end
  end

  it "has a working load()" do
    filename = File.join(Sicuro::Runtime::Constants::ENV['HOME'], 'code.rb')
    expected_output = [filename, filename, ''].join("\n")

    code = <<-EOF
      $i ||= -1
      $i += 1

      exit if $i >= 2

      puts __FILE__
      load __FILE__

    EOF

    Sicuro.eval(code).stdout.should == expected_output
  end

  it "has a working require()" do
    Sicuro.eval("puts(require(__FILE__))").stdout.should == "false\ntrue\n"
  end

  it "assert('print true', 'true')" do
    Sicuro.assert('print true', 'true').should == true
  end
end
