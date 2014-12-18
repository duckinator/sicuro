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
        ::Standalone::Runtime::FileSystem.enable!

        replace(Kernel, :load) do |file, wrap = false|
          eval(open(file).read, TOPLEVEL_BINDING, file)
        end
        
        # TODO: Can this be done without the second argument? It should behave identically to MRI's require().
        replace(Kernel, :require) do |file|
          # If we're 2 levels into require(), add .rb to the filename
          __full_name =
            if caller[0].include?("block (2 levels) ")
              file + '.rb'
            end

          $:.each do |dir|
            f = __full_name || file

            f = File.join(dir, f) unless f.start_with?(dir) || f.start_with?('/')

            return false if $LOADED_FEATURES.include?(f)

            if f && File.file?(f)
              $LOADED_FEATURES << f
              load f
              return true
            elsif __full_name.nil?
              return require(file)#, "#{file}.rb")
            end
          end

          raise ::LoadError, "cannot load such file -- #{file}"
        end
        
        replace(Kernel, :require_relative) do |file|
          raise ::NotImplementedError, NO_SANDBOXED_IMPL % 'require_relative'
        end

        replace(Kernel, :open) do |*args|
          File.open(*args)
        end
      end

    end # Methods
  end
end
