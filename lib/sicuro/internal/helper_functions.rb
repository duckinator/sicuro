class Sicuro
  # Wrapper function for Sicuro.new.eval(*args).
  # Originally for backwards-compatibility, kept because I (@duckinator) feel it
  # is much nicer than the full Sicuro.new.eval(*args) version.
  def self.eval(*args)
    self.new.eval(*args)
  end

  # Simple testing abilities.
  #
  # >> Sicuro.assert("print 'hi'", "hi")
  # => true
  #
  def assert(code, output, *args)
    eval(code, *args).to_s == output
  end

  def self.assert(*args)
    Sicuro.new.assert(*args)
  end
end
