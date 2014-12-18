class Sicuro
  # :nodoc:
  # Copies data from one IO-like object to another until `from` is closed.
  class Reader < Thread
    def initialize(from, to)
      super(from, to) do |from, to|
        IO.copy_stream(from, to) until from.eof?
      end
    end
  end

  # :nodoc:
  # Copies data from one IO-like object to another until `#close` is called.
  #
  # I have no idea why calling `#close` on `from` doesn't work with this one.
  #
  # This works in a really gross fashion, because we can't use IO from inside of
  # the sandbox.
  class HorribleReader < Thread
    def initialize(from, to)
      @done = false

      super(from, to) do
        pos = from.pos

        until @done
          s = from.read
          pos += s.length

          to.write s
          to.flush

          from.pos = pos 
        end

        s = from.read
        to.write s
      end
    end

    def close
      @done = true
    end
  end
end
