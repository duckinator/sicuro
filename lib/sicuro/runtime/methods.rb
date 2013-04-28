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
        replace(Kernel, :load) do |file, wrap = false|
          raise ::NotImplementedError, Sicuro::NO_SANDBOXED_IMPL % 'require'
        end
        
        replace(Kernel, :require) do |file|
          $:.each do |dir|
            f = DummyFS.find_file(File.join(dir, file))[0]

            return false if $LOADED_FEATURES.include?(f)

            if f && File.file?(f)
              $LOADED_FEATURES << f
              DummyFS.get_file(f)
              return true
            end
          end

          raise ::LoadError, "cannot load such file -- #{file}"
        end
        
        replace(Kernel, :require_relative) do |file|
          raise ::NotImplementedError, Sicuro::NO_SANDBOXED_IMPL % 'require'
        end
      end

    end # Methods
  end
end
