class Sicuro
  FAKE_GEM_DIR = "/home/standalone/.gem/ruby/#{RUBY_VERSION}/gems"

  def self.add_files_to_dummyfs
    ::Standalone::DummyFS.add_real_directory(File.join(File.dirname(__FILE__), '..', '..'), '*.rb', true) do |filename|
      filename.gsub(File.dirname(__FILE__), '').gsub(%r[^/../..], File.join(FAKE_GEM_DIR, 'sicuro', 'lib'))
    end
  end
end
