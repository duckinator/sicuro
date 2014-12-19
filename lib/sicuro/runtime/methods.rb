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

        replace(Kernel, :require) do |file|
          resolve = lambda do |dir, file|
            file =
              if file.start_with?(dir) || file.start_with?('/') || file.start_with?('./')
                file
              else
                File.join(dir, file)
              end

            file += ".rb" if !File.file?(file) && File.file?(file + ".rb")

            return false unless File.file?(file)

            file
          end

          $:.each do |dir|
            resolved = resolve.(dir, file)

            next unless resolved

            return false if $LOADED_FEATURES.include?(resolved)

            $LOADED_FEATURES << resolved
            load resolved
            return true
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
