class Sicuro
  class Runtime
    module Constants

      ENV = {
        "LANG"    => "en_US.UTF-8",
        "SHLVL"   => "1",
        "PWD"     => "/home/sicuro",
        "USER"    => "sicuro",
        "LOGNAME" => "sicuro",
        "HOME"    => "/home/sicuro",
        "PATH"    => "/bin",
        "SHELL"   => "/bin/bash",
        "TERM"    => "dumb"
      }

      ARGV = []

      # Stub Monitor implementation.
      class Monitor
        [
          :initialize, :try_enter, :enter, :exit, :mon_try_enter, :try_mon_enter,
          :mon_enter, :mon_exit, :mon_synchronize, :synchronize, :new_cond
        ].each do |name|
          send(:define_instance_method, name) do
            raise NotImplementedError, "Monitor##{name} not implemented."
          end
        end
      end

      RUBYGEMS_ACTIVATION_MONITOR = Monitor.new

      # This removes a constant (to avoid "already initialized constant"), then
      # defines it to the value specified in Sicuro::Runtime::Constants.
      def self.reset!
        ::Sicuro::Runtime::Constants.constants.each do |x|
          Object.instance_eval do
            remove_const x if const_defined?(x)
            const_set(x, ::Sicuro::Runtime::Constants.const_get(x))
          end
        end
      end

    end
  end
end

