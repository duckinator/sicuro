class Sicuro
  FAKE_GEM_DIR = "/home/sicuro/.gem/ruby/#{RUBY_VERSION}/gems"

  def self.add_files_to_dummyfs
    Dir[File.join(File.dirname(__FILE__), '..', '..', '**', '*.rb')].each do |filename|
      fake_filename = filename.gsub(File.dirname(__FILE__), '').gsub(%r[^/../..], File.join(FAKE_GEM_DIR, 'sicuro', 'lib'))
      ::Standalone::DummyFS.add_real_file(filename, fake_filename)
    end
#require 'pp' rescue nil
#pp ::Standalone::DummyFS.find_file(File.join(FAKE_GEM_DIR, 'sicuro', 'lib', 'sicuro', 'runtime', 'constants'))
  end
end
