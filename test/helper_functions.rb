class Sicuro
  # Same as eval, but get only stdout.
  def eval_stdout(*args)
    eval(*args).stdout
  end

  # Same as eval, but get only stderr.
  def eval_stderr(*args)
    eval(*args).stderr
  end

  # Same as eval, but get only return value.
  def eval_return(*args)
    eval(*args).return
  end

  # Same as eval, but get only exceptions.
  def eval_exception(*args)
    eval(*args).exception
  end

  # Same as eval, but run #value on it.
  def eval_value(*args)
    eval(*args).value
  end

  # Same as eval, but run #inspect on it.
  def eval_inspect(*args)
    eval(*args).inspect
  end

  # Same as eval, but run #running? on it.
  def eval_running?(*args)
    eval(*args).running?
  end
end
