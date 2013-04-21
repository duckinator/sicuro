class Sicuro
  class Runtime
    class Methods
      NO_SANDBOXED_IMPL = "a sandboxed version of \`%s' has not been implemented yet."

      def self.replace(klass, method, &block)
        method = method.to_sym

        eigenclass = class << klass; self end
        klass.instance_eval do
          klass.send(:remove_method, method)
          eigenclass.send(:remove_method, method)
          
          define_method(method, &block)
        end
      end
      
      def self.replace_all
        replace(Kernel, :load) do |file, wrap = false|
          raise ::NotImplementedError, NO_SANDBOXED_IMPL % 'require'
        end
        
        replace(Kernel, :require) do |file|
          raise ::NotImplementedError, NO_SANDBOXED_IMPL % 'require'
        end
        
        replace(Kernel, :require_relative) do |file|
          raise ::NotImplementedError, NO_SANDBOXED_IMPL % 'require'
        end
      end

=begin
      # Methods to replace load/require, since they aren't replaced by FakeFS
      module Kernel
        # load() hack
        def __replacement_load(file, wrap = false, function = 'load')
          raise ::NotImplementedError, "a sandboxed version of \`#{function}\' has not been implemented yet. Could not #{function} #{file.inspect}."
        end
        
        # require() hack
        def __replacement_require(file)
          return false if $LOADED_FEATURES.include?(file)
          
          # TODO: Should it be wrapped? It doesn't matter atm since it does nothing.
          Kernel.__replacement_load(file, false, 'require')
        end
        
        # require_relative() hack
        def __replacement_require_relative(file)
          return false if $LOADED_FEATURES.include?(file)
      
          # TODO: Should it be wrapped? It doesn't matter atm since it does nothing.
          Kernel.__replacement_load(file, false, 'require_relative')
        end
      end # Kernel
=end
    end
  end
end
