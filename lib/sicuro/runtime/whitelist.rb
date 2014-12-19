class Sicuro
  class Runtime
    def self.enforce_whitelist!
      unsafe_constants = Object.constants - $TRUSTED_CONSTANTS

      unsafe_constants.each do |x|
        Object.instance_eval { remove_const x }
      end

      Object.constants.each do |constant|
        next unless Object.const_defined?(constant)

        next if [:NIL, :TRUE, :FALSE, :NilClass].include?(constant)

        trusted = $TRUSTED_METHODS[constant] || []

        const = Object.const_get(constant)
        const = const.class unless const.is_a?(Class) || const.is_a?(Module)

        method_name = const.is_a?(Module) ? :module_eval : :instance_eval

        const.module_eval do
          (const.methods + const.private_methods - $TRUSTED_METHODS_ALL - trusted).each do |method_name|
            m = method_name.to_sym.inspect

            next unless method_defined?(method_name) || public_method_defined?(method_name) || private_method_defined?(method_name)

            undef_method method_name
          end
        end
      end

      (global_variables - $TRUSTED_GLOBALS).each do |var|
        ::Kernel.eval("#{var.to_s}.freeze")
      end
    end
  end
end
