require 'sicuro/constants' # For access to Sicuro::SandboxIntegrityError.

# :nodoc:
module Sicuro::Utils
  class << self
    # :nodoc:
    # Returns +true+ if a process with +pid+ is running, or +false+.
    def process_running?(pid)
      # Process.kill(0, pid) returns true if it can kill the process,
      # and raises an Errno::ESRCH exception when a process does not exist.
      !!::Process.kill(0, pid) rescue false
    end

    # :nodoc:
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

    # :nodoc:
    # A recursive function to determine if a process has terminated,
    # attempts to terminate it if it has not.
    #
    # Returns +true+ if the process is terminated in the first 3 attempts,
    # or raises a +SandboxIntegrityError+.
    #
    # If it takes more than 1 attempt to terminate the process,
    # it will print a warning.
    def running_check(pid, code, attempt = 1)
      # If it's the second or later attempt, wait in case it was in the
      # process of terminating
      sleep 0.5 if attempt > 1

      # No need to try to kill an already-running process
      return true unless Sicuro::Utils.process_running?(pid)

      begin
        Process.kill('KILL', @pid)
      rescue #Error::ESRCH
        nil
      end

      if attempt > 1
        _fatal = attempt >= 3

        Sicuro::Utils.sandbox_error("Attempt ##{attempt} to terminate process ##{pid}.", _fatal)
      end

      !Sicuro::Utils.process_running?(pid) || running_check(pid, code, attempt + 1)
    end
  end
end
