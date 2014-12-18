class Sicuro
  class FileSystem
    FAKE_GEM_DIR = Standalone::Runtime::FileSystem::FAKE_GEM_DIR

    FAKE_SICURO_DIR = File.join(FAKE_GEM_DIR, 'sicuro')
    REAL_SICURO_DIR = File.expand_path('../../../', File.dirname(__FILE__))

    def self.setup!
      ::Standalone::Runtime::FileSystem.add_real_directory(REAL_SICURO_DIR, '*.rb', true) do |filename|
        filename.gsub(REAL_SICURO_DIR, FAKE_SICURO_DIR)
      end
    end
  end
end
