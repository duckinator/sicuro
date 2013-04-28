require 'coveralls'
Coveralls.wear!

require 'simplecov'

SimpleCov.configure do
  add_filter 'spec/'

  add_group 'Sandbox' do |src|
    !src.filename.start_with?('sicuro/runtime')
  end

  add_group 'Runtime', 'runtime/'
end
SimpleCov.start unless ENV['TRAVIS']

require 'bundler/setup'

require 'rspec'

require 'sicuro'
