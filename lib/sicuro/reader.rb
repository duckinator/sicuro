class Sicuro
  # :nodoc:
  # Copies data from one IO-like object to another.
  class Reader < Thread
    def initialize(from, to)
      super(from, to) do |from, to|
        ret = ''

        until from.eof?
          s = from.read
          ret += s

          to.write s
          to.flush
        end

        ret
      end
    end
  end

  # :nodoc:
  # Copies data from one IO-like object to another, rewinding it first.
  # Stops copying when $done is true.
  #
  # TODO: Make more generic? (Can this be merged into +reader+?)
  class RewindingReader < Thread
    def initialize(from, to)
      super(from, to) do
        ret = ''
        pos = 0

        from.rewind

        loop do
          s = from.read
          ret += s
          pos += s.length

          to.write s
          to.flush

          from.pos = pos

          break if $done
        end

        s = from.read
        ret += s
        to.write s

        ret
      end
    end
  end
end
