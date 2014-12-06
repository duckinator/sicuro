require File.join(File.dirname(__FILE__), 'sicuro', 'version')
require File.join(File.dirname(__FILE__), 'sicuro', 'base')

class Sicuro
  attr_accessor :memlimit, :timelimit

  # Set the memory (in MBs) and time (in seconds) limits for Sicuro.
  # Defaults are 200MB and 5 seconds.
  def initialize(memlimit = nil, timelimit = nil)
    @memlimit  = memlimit  || 200
    @timelimit = timelimit || 5

    Sicuro.add_files_to_dummyfs
  end

  # Simple testing abilities.
  #
  # >> Sicuro.assert("print 'hi'", "hi")
  # => true
  #
  def assert(code, output, *args)
    eval(code, *args).to_s == output
  end

  def inspect
    "#<#{self.class} memlimit=#{@memlimit} timelimit=#{@timelimit}>"
  end

  class << self
    # Wrapper function for Sicuro.new.eval(*args).
    def eval(*args)
      self.new.eval(*args)
    end

    def assert(*args)
      self.new.assert(*args)
    end
  end
end
