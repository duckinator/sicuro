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
require 'simplecov'
SimpleCov.start
require 'riot'
require 'sicuro'
