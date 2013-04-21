class Sicuro
  # Sicuro::Eval is used to nicely handle stdout/stderr of evaluated code
  class Eval
    attr_accessor :code, :stdout, :stderr, :return, :exception

    def initialize(hash, pid)
      @inspect_for_value = false
      running_error     = nil
      @pid    = pid

      hash.keys.each do |key|
        instance_variable_set("@#{key}", hash[key])
      end

      if Sicuro.process_running?(pid)
        warn "[SICURO] Process ##{pid} still running in Eval#new."
        sleep 1
        Process.kill('KILL', pid) rescue nil
        if Sicuro.process_running?(pid)
          Sicuro.sandbox_error([
            "Process ##{pid} could not be terminated. THIS IS A BUG. Code:",
            *@code.split("\n")
          ], true)
        end
      end
    end

    def running?
      Sicuro.process_running?(@pid)
    end

    # Get a version suitable for printing.
    def value
      return @running_error if @running_error

      if !@stderr.nil? && ((!@stderr.is_a?(String)) ||
         (@stderr.is_a?(String) && !@stderr.empty?))

        # @stderr is not nil and is not a String, or is a non-empty String
        @stderr
      elsif (!@exception.nil? && !@exception.is_a?(String)) ||
            (@exception.is_a?(String) && !@exception.empty?)
        # @exception is not nil and is not a String, or is a non-empty String
        @exception
      elsif !@stdout.nil? && (!@stdout.is_a?(String) || !@stdout.empty?)
        @stdout
      else
        @return
      end
    end

    def inspect
      "#<#{self.class} code=#{code.inspect} value=#{value.inspect}>"
    end

  end
end
