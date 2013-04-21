class Sicuro
  class Runtime
    module Constants
      module DummyFS
        # Worst excuse of an FS ever.

        FAKE_GEM_DIR = "/home/sicuro/.gem/ruby/#{RUBY_VERSION}/gems"

        def self.activate!
          $:.clear
          $: << File.join(FAKE_GEM_DIR, 'sicuro', 'lib')
        end

        def self.has_file?(file)
          ret = self.find_file(file)
          ret && !ret.empty?
        end

        def self.find_file(file)
          @@files.keys.grep(%r[#{file}(\..*)?$])
        end

        def self.add_file(file, name = nil)
          name ||= file
          @@files ||= {}
          @@files[name] = open(file).read
        end

        def self.get_file(file)
          @@files[name]
        end

        Dir[File.join(File.dirname(__FILE__), '..', '**', '*.rb')].each do |filename|
          fake_filename = filename.gsub(File.dirname(__FILE__), '').gsub(%r[^/..], File.join(FAKE_GEM_DIR, 'sicuro', 'lib', 'sicuro'))
          DummyFS.add_file(filename, fake_filename)
        end
      end

      class File
        def self.exist?(file)
          ::DummyFS::has_file?(file)
        end

        def self.file?(file)
          self.exist?(file)
        end

        def self.dir?(file)
          self.exist?(file)
        end

        def self.dirname(path)
          path.split('/')[0..-2].join('/')
        end

        def self.join(*args)
          args.join('/')
        end
      end
    end
  end
end
