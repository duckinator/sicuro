class Sicuro
  # Sicuro::Eval is used to nicely handle stdout/stderr of evaluated code
  class Eval
    attr_accessor :stdin, :stdout, :stderr, :return, :exception

    def initialize(hash, pid)
      @inspect_for_value = false
      @running_error     = nil
      @pid    = pid
      @stdin  = hash['stdin']
      @stdout = hash['stdout']
      @stderr = hash['stderr']
      @return = hash['return']
      @exception = hash['exception']

      if Sicuro.process_running?(pid)
        sleep 1
        Process.kill('KILL', pid) rescue nil
        if Sicuro.process_running?(pid)
          @running_error = "Process ##{pid} could not be terminated."
          # Should we `exit 1` if we get here?
        else
          # Un-comment the following line if/when we figure out why
          # Travis CI loves it so much.
          #@running_error = "Process ##{pid} could not be terminated in Sicuro#eval, but was killed in Sicuro::Eval#new."
        end
      end

      if @running_error
        @running_error = "[SICURO ERROR] #{@running_error} THIS IS A BUG. Code:"

        lines = @stdin.split("\n").map do |x|
          x.rjust(error_prefix.length + x.length)
        end
        @running_error += "\n" + lines.join("\n")
      end

      warn @running_error if @running_error

      @running = Sicuro.process_running?(pid)
    end

    def running?
      @running
    end

    # Get a version suitable for printing.
    # Main difference between #value and #_get_return_value: with #value,
    # if you get @return, it called .inspect in base.rb.
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
      "#<#{self.class} stdin=#{stdin.inspect} value=#{value.inspect}>"
    end

  end
end
