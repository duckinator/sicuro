require File.join(File.dirname(__FILE__), 'sicuro', 'version')
require File.join(File.dirname(__FILE__), 'sicuro', 'base')

class Sicuro
  attr_accessor :memlimit, :timelimit

  # Initialize a new sandbox, with the defined constraints.
  #
  # +res_memlimit+::  Maximum resident memory usage (in megabytes). Default: +20+.
  # +timelimit+::     Maximum execution time (in seconds). Default: +5+.
  # +virt_memlimit+:: Maximum virtual memory usage (in megabytes). Default: +res_memlimit * 20+.
  def initialize(res_memlimit = nil, timelimit = nil, virt_memlimit = nil)
    # Resident memory: how much RAM can be actively used (I think?), in
    #   megabytes.
    @res_memlimit = res_memlimit  || 20

    # Virtual memory: how much is allocated (I think?), in megabytes.
    @virt_memlimit = virt_memlimit || (@res_memlimit * 20)

    # Execution time, in seconds.
    @timelimit = timelimit || 5

    Sicuro.add_files_to_dummyfs
  end

  # Assert that the result of executing +code+ in the sandbox is equal
  # to +output+. Passes +args+ through to +eval()+.
  #
  #   >> Sicuro.assert("print 'hi'", "hi")
  #   => true
  #
  # Returns +true+ if the result of executing +code+ is equal to +output+,
  # or +false+.
  def assert(code, output, *args)
    eval(code, *args).to_s == output
  end

  def inspect
    "#<#{self.class} res_memlimit=#{@res_memlimit} virt_memlimit=#{@virt_memlimit} timelimit=#{@timelimit}>"
  end

  class << self
    # Alias for +Sicuro.new.eval+.
    def eval(*args)
      self.new.eval(*args)
    end

    # Alias for +Sicuro.new.assert+.
    def assert(*args)
      self.new.assert(*args)
    end
  end
end
