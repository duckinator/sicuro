$TRUSTED_KERNEL_PRIVATE_METHODS = [
  :initialize_copy, :remove_instance_variable, :sprintf, :format, :Integer, :Float, :String, :Array, :warn, :raise, :fail,
  :global_variables, :__method__, :__callee__, :eval, :local_variables, :iterator?, :block_given?, :catch, :throw, :loop, :caller,
  :printf, :print, :putc, :puts, :p, :srand, :rand, :exit!, :sleep, :exit, :abort, :load, :proc, :lambda, :binding,
  :Rational, :Complex, :Pathname, :URI,
  :initialize, :singleton_method_added, :singleton_method_removed, :singleton_method_undefined, :method_missing
]
