module Sicuro
  # Same as eval, but get only stdout
  def self.eval_stdout(*args)
    self.eval(*args).stdout
  end
  
  # Same as eval, but get only stderr
  def self.eval_stderr(*args)
    self.eval(*args).stderr
  end
  
  # Same as eval, but get only return value
  def self.eval_return(*args)
    self.eval(*args).return
  end
  
  # Same as eval, but get only exceptions
  def self.eval_exception(*args)
    self.eval(*args).exception
  end
  
  # Same as eval, but run #value on it
  def self.eval_value(*args)
    self.eval(*args).value
  end
  
  # Same as eval, but run #inspect on it
  # Yes, this one has NO use except testing.
  def self.eval_inspect(*args)
    self.eval(*args).inspect
  end
  
  # Same as eval, but run #running? on it
  # Yes, this one has NO use except testing.
  def self.eval_running?(*args)
    self.eval(*args).running?
  end
  
  # Simple testing abilities.
  #
  # >> Sicuro.assert("print 'hi'", "hi")
  # => true
  #
  def self.assert(code, output, *args)
    Sicuro.eval(code, *args).stdout == output
  end
end
