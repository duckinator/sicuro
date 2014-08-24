require 'sicuro/version'
require 'sicuro/evaluation'
require 'parser/current'
require 'contracts'
require 'default'

module Sicuro
  class << self
    include Contracts

    Contract String, Or[Evaluation, default] => Evaluation
    def eval(source, eval_instance=default)
      default_for(:eval_instance) { Evaluation.new(source) }

      eval_ast(parse(source), eval_instance)
    end

    Contract ::Parser::AST, Evaluation => Evaluation
    def eval_ast(ast, eval_instance)
      # todo
      p ast

      eval_instance
    end

    Contract String => ::Parser::AST
    def parse(code)
      ::Parser::CurrentRuby.parse(code)
    end
  end
end

p Sicuro.eval <<-EOF
  puts "Hello, world!"
EOF
