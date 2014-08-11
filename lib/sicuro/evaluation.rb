require 'sicuro/version'
require 'stringio'
require 'contracts'

class Sicuro::Evaluation < Struct.new(:source, :stdin, :stdout, :stderr, :exception, :backtrace)
  include Contracts

  Contract String, StringIO, StringIO, StringIO, Or[Exception, nil], Or[Array, nil] => nil
  def initialize(
      source,
      stdin=StringIO.new,
      stdout=StringIO.new,
      stderr=StringIO.new,
      exception=nil,
      backtrace=nil)
    super(source, stdin, stdout, stderr, exception, backtrace)
  end

end
