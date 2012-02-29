require 'timeout'
require 'open3'

module Sicuro
  # Set the time and memory limits, define @@code_start for Sicuro.eval.
  def self.setup(timelimit=5, memlimit=10, precode='')
    @@timelimit = timelimit
    @@memlimit = memlimit
    @@memlimit = 50 # FIXME
    @@precode = precode # safe code to evaluate in the child proc
    
    @@code_start =
      precode + "\n" +
      "require #{__FILE__.inspect};" +
      "Sicuro.setup(#{@@timelimit.inspect}, #{@@memlimit.inspect});" +
      "print Sicuro._safe_eval "
  end
  
  # Runs the specified code, returns STDOUT and STDERR as a single string.
  # Automatically runs Sicuro.setup if needed.
  def self.eval(code)
    begin
      Timeout.timeout(5) do
        Open3.capture2e('ruby', :stdin_data => @@code_start + code.inspect).first
      end
    rescue Timeout::Error
      '<timeout hit>'
    rescue NameError
      Sicuro.setup
      retry
    end
  end
  
  # Use Sicuro.eval instead. This does not provide a strict time limit or call Sicuro.setup.
  # Used internally by Sicuro.eval
  def self._safe_eval(code)
    # RAM limit
    Process.setrlimit(Process::RLIMIT_AS, @@memlimit*1024*1024)
    
    # CPU time limit. 5s means 5s of CPU time.
    Process.setrlimit(Process::RLIMIT_CPU, @@timelimit)
    
    # Things we want, or need to have, available in eval
    require 'stringio'
    require 'pp'
    
    # fakefs goes last, because I don't think `require` will work after it
    require 'fakefs'
    
    # Undefine FakeFS
    [:FakeFS, :RealFile, :RealFileTest, :RealFileUtils, :RealDir].each do |x|
      Object.instance_eval{ remove_const x }
    end
    
    output_io, result, error = nil
    
    begin
      output_io = $stdout = $stderr = StringIO.new
      code = '$SAFE = 3; BEGIN { $SAFE=3 };' + code
      
      result = ::Kernel.eval(code, TOPLEVEL_BINDING)
    rescue Exception => e
      error = "#{e.class}: #{e.message}"
    ensure
      $stdout = STDOUT
      $stderr = STDERR
    end
    
    output = output_io.string
    
    if output.empty?
      if error
        error
      else
        result.inspect
      end
    else
      output
    end
  end
end
