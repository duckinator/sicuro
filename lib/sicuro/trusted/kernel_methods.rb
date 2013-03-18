$TRUSTED_KERNEL_METHODS = [
  :sprintf, :format,

  # Classes/Modules
  :Integer, :Float, :String, :Array, :Rational, :Complex,
  :warn, :raise, :fail,
  :global_variables, :__method__, :__callee__,
  :eval, :local_variables, :iterator?, :block_given?,
  :catch, :throw, :loop, :caller,

  # Tracing
  :trace_var, :untrace_var, :set_trace_func,

  :printf, :print, :putc, :puts,
  :select, :p, :srand, :rand, :exit!, :exit, :sleep, :abort,

  #:load, :require, :require_relative, :autoload, :autoload?,

  :proc, :lambda, :binding,

  # Comparison
  :===, :==, :<=>, :<, :<=, :>, :>=, :nil?, :=~, :!~, :eql?,

  # Conversion
  :to_s, :to_enum,

  :included_modules, :include?, :name, :ancestors,
  :instance_methods, :public_instance_methods, :protected_instance_methods,
  :private_instance_methods, :constants, :const_get, :const_set, :const_defined?,
  :const_missing, :class_variables, :remove_class_variable, :class_variable_get,
  :class_variable_set, :class_variable_defined?, :public_constant,
  :private_constant,

  :module_exec, :class_exec, :module_eval, :class_eval,

  :method_defined?, :public_method_defined?, :private_method_defined?,
  :protected_method_defined?, :public_class_method, :private_class_method,
  :instance_method, :public_instance_method,
  :hash, :class, :singleton_class, :clone, :dup, :initialize_dup, :initialize_clone,
  :tainted?, :untrusted?, :frozen?, :inspect, :methods, :singleton_methods,
  :protected_methods, :private_methods, :public_methods, :instance_variables,
  :instance_variable_get, :instance_variable_set, :instance_variable_defined?,
  :instance_of?, :kind_of?, :is_a?, :tap, :send, :public_send, :respond_to?,
  :respond_to_missing?, :extend, :display, :method, :public_method,
  :define_singleton_method, :object_id, :enum_for, :equal?, :!, :!=,
  :instance_eval, :instance_exec, :__send__, :__id__,

  #:at_exit, :syscall, :open, :gets, :readline, :readlines, :`, :test, :trap, :exec, :fork, :system, :spawn, :freeze, :taint, :untaint, :untrust, :trust,
]
