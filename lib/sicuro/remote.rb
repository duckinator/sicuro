require 'httparty'
require 'json'
require 'cgi'

class Sicuro
  include HTTParty
  base_uri 'http://sicuro.duckinator.net'

  class Eval < Struct.new(:hash, :pid)
    def method_missing(name); hash[name.to_s]; end
  end

  # Unnecessary, but exists for compatibility reasons.
  def self.setup(*args); nil; end

  # Send code off to the server to be evaluated.
  def self.eval(code, *args)
    raise "Only the first argument of Sicuro.eval(...) is effective when using sicuro/network." unless args.empty?

    opts = { :body => { :code => code } }
    json = JSON.parse(post('/new.json', opts).body)

    Eval.new(json)
  end
end
