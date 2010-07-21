module Sicuro
  class Ruby < Base
    def initialize
      super("ruby")
    end

    def eval(cmd)
      output = nil
      error = nil
      result = nil
      command = <<-EOF
        $SAFE=3
        #{cmd}
      EOF

      begin
        result = ::Kernel.eval(command, TOPLEVEL_BINDING)
      rescue Exception, SecurityError => e
        @error = e
      end

      if !error.to_s.empty?
        @error
      elsif !output.to_s.empty?
        output
      else
        result
      end
    end
  end
end

