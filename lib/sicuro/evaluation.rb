class Sicuro
  # Sicuro::Evaluation is used to nicely handle stdout/stderr of evaluated code
  class Evaluation
    attr_reader :code, :stdout, :stderr, :wall_time

    def initialize(code, stdout, stderr, wall_time)
      @code   = code
      @stdout = stdout
      @stderr = stderr
      @wall_time = wall_time
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
  end
end
