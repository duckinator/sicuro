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



      # This removes a constant (to aovid "already initialized constant" warning), then
      # defines it to the value specified in Sicuro::Runtime::Constants.
      def self.reset
        ::Sicuro::Runtime::Constants.constants.each do |x|
          Object.instance_eval { remove_const x }
          Object.instance_eval { const_set(x, ::Sicuro::Runtime::Constants.const_get(x)) }
        end
      end

    end
  end
end

