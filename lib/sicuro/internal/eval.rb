class Sicuro
  # Sicuro::Eval is used to nicely handle stdout/stderr of evaluated code
  class Eval
    attr_reader :code, :stdout, :stderr, :return, :wall_time

    def initialize(code, stdout, stderr, _return, wall_time, pid)
      @inspect_for_value = false
      @running_error     = nil

      @code   = code
      @stdout = stdout
      @stderr = stderr
      @pid    = pid
      @return = _return
      @wall_time = wall_time

      # Check 1 is in sicuro/base.rb.
      __running_check_2(pid, code)
      __running_check_3(pid, @code)
    end

    def __running_check_2(pid, code)
      if Sicuro.process_running?(pid)
        $stderr.puts "[SICURO] Process ##{pid} still running in Eval#new."
        sleep 1
        Process.kill('KILL', pid) rescue nil
      end
    end

    def __running_check_3(pid, code)
      if Sicuro.process_running?(pid)
        Sicuro.sandbox_error([
          "Process ##{pid} could not be terminated. THIS IS A BUG. Code:",
          *code.split("\n")
        ], true)
      end
    end


    def running?
      Sicuro.process_running?(@pid)
    end

    # Get a version suitable for printing.
    def to_s
      return @running_error if @running_error

      if !@stderr.nil? && ((!@stderr.is_a?(String)) ||
         (@stderr.is_a?(String) && !@stderr.empty?))

        # @stderr is not nil and is not a String, or is a non-empty String
        @stderr
      elsif !@stdout.nil? && (!@stdout.is_a?(String) || !@stdout.empty?)
        @stdout
      else
        @return
      end
    end

    def to_json
      '{
        "stdout": #{@stdout.inspect},
        "stderr": #{@stderr.inspect},
        "return": #{@return.inspect},
        "wallTime": #{@wall_time.inspect}
      }'
    end

    def inspect
      "#<#{self.class} code=#{code.inspect} stdout=#{stdout.inspect} stderr=#{stderr.inspect} return=#{self.return.inspect} wall_time=#{wall_time.inspect}>"
    end

  end
end
