#BEGIN {
#  Sicuro::Runtime::Methods.replace_all!
#}

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
            # FIXME: This is a hack because we need STDIN (the IO class) to be
            #        left alone for eval() to work.
            next if [:STDIN, :STDOUT, :STDERR].include?(constant)

            m = method_name.to_sym.inspect

            # FIXME: Make this less horrifyingly gross.
              begin
                eval("public #{m}; undef #{m}")
              rescue NameError => e
                # Re-raise the error as long as it is not telling us
                # the method we are trying to remove is undefined.
                unless e.message.start_with?("undefined method `#{method_name.to_s}' ")
                  raise
                end
              end


            #next unless method_defined?('define_method')
            #define_method(meth) {}

            #remove_method(meth) rescue nil
            #eval("public #{m}; undef #{m}")
            #puts "Removing #{constant}.#{meth}"
            #undef_method meth if respond_to?(meth)
          end
        end
      end

      (global_variables - $TRUSTED_GLOBALS).each do |var|
        ::Kernel.eval("#{var.to_s}.freeze")
      end
    end
  end
end
