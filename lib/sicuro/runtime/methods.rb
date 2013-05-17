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
        
        replace(Kernel, :require) do |file|

          $:.each do |dir|
            f = file
            f = File.join(dir, f) unless f.start_with?(dir)

            return false if $LOADED_FEATURES.include?(f)

            if f && File.file?(f)
              $LOADED_FEATURES << f
              DummyFS.get_file(f)
              return true
            elsif !file.end_with?('.rb')
              return require("#{f}.rb")
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
