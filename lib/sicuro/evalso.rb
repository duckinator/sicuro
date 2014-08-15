require 'sicuro'
require 'contracts'

module Sicuro
  class Evaluation
    alias_method :code, :source
    alias_method :wall_time, :execution_time
  end

  class << self
    Contract Hash => Evaluation
    def run(hash)
      raise ArgumentError, "No language specified." if hash[:language].to_s.empty?
      raise ArgumentError, "No code specified." unless hash[:code].is_a?(String)
      raise ArgumentError, "Sicuro.run() can only run ruby code." if hash[:language].to_s != "ruby"
      Sicuro.eval(hash[:code])
    end
  end
end
