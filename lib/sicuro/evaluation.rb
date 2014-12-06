class Sicuro
  # Sicuro::Evaluation is used to nicely handle stdout/stderr of evaluated code
  class Evaluation
    attr_reader :code, :stdout, :stderr, :wall_time

    def initialize(code, stdout, stderr, wall_time, pid)
      @code   = code
      @stdout = stdout
      @stderr = stderr
      @pid    = pid
      @wall_time = wall_time

      # Check 1 is in sicuro/base.rb.
      running_check_2(code)
      running_check_3(code)
    end

    def running?
      Sicuro::Utils.process_running?(@pid)
    end

    # Get a version suitable for printing.
    def to_s
      return @running_error if @running_error

      if !@stderr.nil? && ((!@stderr.is_a?(String)) ||
         (@stderr.is_a?(String) && !@stderr.empty?))

        # @stderr is not nil and is not a String, or is a non-empty String
        @stderr
      else
        @stdout
      end
    end

    def to_json
      %[{
        "stdout": #{@stdout.inspect},
        "stderr": #{@stderr.inspect},
        "wallTime": #{@wall_time.inspect}
      }]
    end

    def inspect
      "#<#{self.class} code=#{code.inspect} stdout=#{stdout.inspect} stderr=#{stderr.inspect} wall_time=#{wall_time.inspect}>"
    end


    private
    def running_check_2(code)
      if running?
        $stderr.puts "[SICURO] Process ##{@pid} still running in Evaluation#new."
        sleep 1
        Process.kill('KILL', @pid) rescue nil
      end
    end

    def running_check_3(code)
      if running?
        Sicuro::Utils.sandbox_error([
          "Process ##{@pid} could not be terminated. THIS IS A BUG. Code:",
          *code.split("\n")
        ], true)
      end
    end
  end
end
