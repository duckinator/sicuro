class Sicuro
  class Runtime
    class Methods
      def self.replace(klass, method, &block)
        method = method.to_sym

        eigenclass = class << klass; self end
        klass.instance_eval do
          klass.send(:remove_method, method)
          eigenclass.send(:remove_method, method)
          
          define_method(method, &block)
        end
      end
      
      def self.replace_all!
        $:.clear
        $: << File.join(FAKE_GEM_DIR, 'sicuro', 'lib')

        replace(Kernel, :load) do |file, wrap = false|
          raise ::NotImplementedError, Sicuro::NO_SANDBOXED_IMPL % 'load'
        end
        
        # TODO: Can this be done without the second argument? It should behave identically to MRI's require().
        replace(Kernel, :require) do |file, __full_name = nil|
          $:.each do |dir|
            f = __full_name || file

            f = File.join(dir, f) unless f.start_with?(dir)

            return false if $LOADED_FEATURES.include?(f)

            if f && File.file?(f)
              $LOADED_FEATURES << f
              File.open(f).read # TODO: Actually execute the code in it.
              return true
            elsif __full_name.nil?
              return require(file, "#{file}.rb")
            end
          end

          raise ::LoadError, "cannot load such file -- #{file}"
        end
        
        replace(Kernel, :require_relative) do |file|
          raise ::NotImplementedError, Sicuro::NO_SANDBOXED_IMPL % 'require_relative'
        end
      end

    end # Methods
  end
end
