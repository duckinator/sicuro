class Sicuro
  # Wrapper function for Sicuro.new.eval(*args).
  # Originally for backwards-compatibility, kept because I (@duckinator) feel it
  # is much nicer than the full Sicuro.new.eval(*args) version.
  def self.eval(*args)
    self.new.eval(*args)
  end

  # Simple testing abilities.
  #
  # >> Sicuro.assert("print 'hi'", "hi")
  # => true
  #
  def assert(code, output, *args)
    eval(code, *args).to_s == output
  end

  def self.assert(*args)
    Sicuro.new.assert(*args)
  end

  # Return true if PID is running, false otherwise.
  def self.process_running?(pid)
    # Process.kill(0, pid) returns true if it can kill the process,
    # and raises an Errno::ESRCH exception when a process does not exist.
    # If you have a saner approach (say, not using exceptions...) please share.
    #
    # Thank you, 'god' (https://github.com/mojombo/god) for reminding me about
    # the `kill -0 PID` trick that translates perfectly to ruby.
    !!(::Process.kill(0, pid) rescue false)
  end

  # Print an error that occurred in the sandbox.
  def self.sandbox_error(x, _fatal = false)
    lines =
      if x.is_a?(String)
        x.split("\n")
      elsif x.is_a?(Array)
        x
      else
        [x.inspect]
      end

    error_type = 'WARNING'
    error_type = 'ERROR  ' if _fatal
    prefix ||= '[SANDBOX ERROR] '
    separator = "\n" + (' ' * prefix.length)

    error = prefix + lines.join(separator)
    warn error

    raise ::Sicuro::SandboxError, lines[0] if _fatal
  end
end
