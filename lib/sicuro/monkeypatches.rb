# Various monkeypatches that make sicuro less fugly.

class Sicuro
  def self.process_running?(pid)
    # Process.kill(0, pid) returns true if it can kill the process,
    # and raises an Errno::ESRCH exception when a process does not exist.
    # If you have a saner approach (say, not using exceptions...) please share.
    #
    # Thank you, 'god' (https://github.com/mojombo/god) for reminding me about
    # the `kill -0 PID` trick that translates perfectly to ruby.
    !!(::Process.kill(0, pid) rescue false)
  end
end

# Methods to replace load/require, since they aren't replaced by FakeFS
module Kernel
  # load() hack
  def __replacement_load(file, wrap = false, req = false)
    function = "load"
    function = "require" if req

    raise ::NotImplementedError, "a sandboxed version of \`#{function}\' has not been implemented yet. Could not #{function} #{file.inspect}."
  end

  # require() hack
  def __replacement_require(file)
    return false if $LOADED_FEATURES.include?(file)

    # TODO: Should it be wrapped? It doesn't matter atm since it does nothing.
    Kernel.__replacement_load(file, false, true)
  end
end
