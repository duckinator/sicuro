begin
  require 'bundler'
rescue LoadError
  require 'rubygems'
  retry
end
=begin
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
=end

# SimpleCov only works with Ruby 1.8, so for now it's just disabled.
# I'll look into finding another code coverage gem for 1.8.
if RUBY_VERSION.to_f > 1.8
  require 'simplecov'
  SimpleCov.start
end
require 'riot'
require 'sicuro'
