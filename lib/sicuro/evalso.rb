# For eval.so compatibility

class Sicuro
  def self.run(lang, code)
    raise ArgumentError, "Sicuro.run() can only run ruby code." if lang.to_s != "ruby"

    Sicuro.eval(code)
  end
end
