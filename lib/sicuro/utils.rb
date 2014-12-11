require File.join(File.dirname(__FILE__), 'constants') # For access to Sicuro::SandboxIntegrityError.

module Sicuro::Utils
  class << self
    # Returns +true+ if a process with +pid+ is running, or +false+.
    def process_running?(pid)
      # Process.kill(0, pid) returns true if it can kill the process,
      # and raises an Errno::ESRCH exception when a process does not exist.
      !!::Process.kill(0, pid) rescue false
    end

    # Print an error that occurred in the sandbox.
    # Raises an exeption if +_fatal+ is true.
    def sandbox_error(x, _fatal = false)
      lines =
        case x
        when String
          x.split("\n")
        when Array
          x
        else
          [x.inspect]
        end

      error_type =
        if _fatal
          'ERROR  '
        else
          'WARNING'
        end

      # Format:
      # [SANDBOX WARNING] first line
      #                   second line
      #                   ...
      #                   Nth line

      prefix    = "[SANDBOX #{error_type}] "
      separator = "\n".ljust(prefix.length)

      error = prefix + lines.join(separator)
      $stderr.puts error

      raise ::Sicuro::SandboxIntegrityError, lines[0] if _fatal
    end
  end
end