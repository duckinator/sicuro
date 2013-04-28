$TRUSTED_METHODS = {}

$TRUSTED_METHODS[:Kernel] = [
  :sprintf, :format,
  
  # Classes/Modules
  :Integer, :Float, :String, :Array, :Rational, :Complex,
  :warn, :raise, :fail,
  :global_variables, :__method__, :__callee__,
  :eval, :local_variables, :iterator?, :block_given?,
  :catch, :throw, :loop, :caller,

  # Printing    
  :printf, :print, :putc, :puts, :p,

  # Random numbers.
  :srand, :rand,

  # Exiting
  :exit!, :exit, :sleep, :abort,
  
  :proc, :lambda, :binding,
  
  # Comparison
  :===, :==, :<=>, :<, :<=, :>, :>=, :nil?, :=~, :!~, :eql?,
  
  # Conversion
  :to_s, :to_enum,
  
  :included_modules, :include?, :name, :ancestors,
  :instance_methods, :public_instance_methods, :protected_instance_methods,
  :private_instance_methods, :constants, :const_get, :const_set,
  :const_defined?, :const_missing, :class_variables, :remove_class_variable,
  :class_variable_get, :class_variable_set, :class_variable_defined?,
  :public_constant, :private_constant,
  
  :module_exec, :class_exec, :module_eval, :class_eval,
  
  :method_defined?, :public_method_defined?, :private_method_defined?,
  :protected_method_defined?, :public_class_method, :private_class_method,
  :instance_method, :public_instance_method,
  :hash, :class, :singleton_class, :clone, :dup, :initialize_dup,
  :initialize_clone, :tainted?, :untrusted?, :frozen?, :inspect, :methods,
  :singleton_methods, :protected_methods, :private_methods, :public_methods,
  :instance_variables, :instance_variable_get, :instance_variable_set,
  :instance_variable_defined?, :instance_of?, :kind_of?, :is_a?,
  :tap, :send, :public_send, :respond_to?,
  :respond_to_missing?, :extend, :display, :method, :public_method,
  :define_singleton_method, :object_id, :enum_for, :equal?, :!, :!=,
  :instance_eval, :instance_exec, :__send__, :__id__,

  # Pretty-printing
  :pretty_print, :pretty_print_cycle,
  :pretty_print_inspect, :pretty_print_instance_variables,

  # Require/load functions. Redefined in sicuro/runtime/methods.
  :require, :require_relative, :load,
]

$TRUSTED_METHODS[:Object] = $TRUSTED_METHODS[:Kernel] + [
  :inherited, :initialize, :initialize_copy, :included, :extended,
  
  :method_added, :method_removed, :method_undefined,
  
  :inherited, :initialize, :initialize_copy, :included, :extended,
  
  :method_added, :method_removed, :method_undefined,
  :attr, :attr_reader, :attr_writer, :attr_accessor,
  
  
  :remove_const, :include, :remove_method, :undef_method, :alias_method,
  
  :public, :protected, :private,
  
  :define_method,
  
  :remove_instance_variable,
  
  :__method__, :__callee__,

  :allocate, :new, :superclass, :freeze, :frozen?,
  :autoload, :autoload?,
]

