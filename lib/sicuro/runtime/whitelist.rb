BEGIN {
  eigenclass = class << Kernel; self end
=begin
  unsafe_methods = ::Kernel.methods - ::Object.methods -
                   $TRUSTED_KERNEL_METHODS.inspect
  unsafe_methods.each do |x|
    ::Kernel.send(:remove_method, x.to_sym)
    eigenclass.send(:remove_method, x.to_sym)
  end

  unsafe_private_methods = ::Object.private_methods -
                           $TRUSTED_OBJECT_PRIVATE_METHODS.inspect -
                           $TRUSTED_KERNEL_METHODS.inspect -
                           $TRUSTED_CONSTANTS.inspect
p unsafe_private_methods
  unsafe_private_methods.each do |x|
    ::Kernel.send(:remove_method, x.to_sym)
    eigenclass.send(:remove_method, x.to_sym)
  end

  (global_variables - $TRUSTED_GLOBALS).each do |x|
    eval(x.to_s).freeze
  end

  ::Kernel.module_eval do
    alias load             __replacement_load
    alias require          __replacement_require
    alias require_relative __replacement_require_relative
  end
=end

  Sicuro::Runtime::Methods.replace_all

}

