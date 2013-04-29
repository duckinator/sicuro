class Sicuro
  class Runtime
    module Constants
      class File < StringIO
        def initialize(filename, mode = 'r', opt = nil)
          @filename = filename
          @mode = mode
          @opt  = opt
          f = nil
          start = :end
          mode  = :r
          truncate = false

          case mode
          when "r"
            # Read-only, starts at beginning of file  (default mode).
            start = :beginning
            mode =  :r
            truncate = false
          when "r+"
            # Read-write, starts at beginning of file.
            start = :beginning
            mode  = :rw
            truncate = false
          when "w"
            # Write-only, truncates existing file
            # to zero length or creates a new file for writing.
            start = :beginning
            mode  = :w
            truncate = true
          when "w+"
            # Read-write, truncates existing file to zero length
            # or creates a new file for reading and writing.
            start = :beginning
            mode  = :rw
            truncate = true
          when "a"
            # Write-only, starts at end of file if file exists,
            # otherwise creates a new file for writing.
            start = :end
            mode  = :w
            truncate = false
          when "a+"
            # Read-write, starts at end of file if file exists,
            # otherwise creates a new file for reading and writing.
            start = :end
            mode  = :rw
            truncate = false
          end

          f ||= super(::DummyFS.get_file(filename))
        end

        class << self
          def exist?(file)
            ::DummyFS.has_file?(file)
          end
          alias :'exists?' :'exist?'

          def open(filename, mode = 'r', opt = nil)
            raise ::NotImplementedError, "Sandboxed File.open() only supports reading files."
            ::DummyFS.get_file(file)
          end

          def file?(file)
            exist?(file)
          end

          def directory?(file)
            exist?(file)
          end

          def dirname(path)
            path.split('/')[0..-2].join('/')
          end

          def join(*args)
            args.join('/')
          end
        end

      end # FileIO
    end
  end
end
