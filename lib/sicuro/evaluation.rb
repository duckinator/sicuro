require 'sicuro/version'
require 'stringio'
require 'contracts'

class Sicuro::Evaluation < Struct.new(:source, :stdin, :stdout, :stderr, :exception, :backtrace, :execution_time)
  include Contracts

  Contract String => String
  def source=(other)
    super(other)
  end

  Contract StringIO => StringIO
  def stdin=(other)
    super(other)
  end

  Contract StringIO => StringIO
  def stdout=(other)
    super(other)
  end

  Contract StringIO => StringIO
  def stderr=(other)
    super(other)
  end

  Contract String, StringIO, StringIO, StringIO, Or[Exception, nil],
    Or[Array, nil], Or[Num, nil] => nil
  def initialize(
      source,
      stdin=StringIO.new,
      stdout=StringIO.new,
      stderr=StringIO.new,
      exception=nil,
      backtrace=nil,
      execution_time=nil)
    super(source, stdin, stdout, stderr, exception, backtrace, execution_time)
  end

end
