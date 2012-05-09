# Various monkeypatches that make sicuro less fugly.

module Sicuro
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
