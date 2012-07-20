# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'sicuro/version'

Gem::Specification.new do |s|
  s.name        = 'sicuro'
  s.version     = Sicuro::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Nick Markwell']
  s.email       = ['nick@duckinator.net']
  s.homepage    = 'http://github.com/duckinator/sicuro'
  s.summary     = %q{Safe ruby code execution.}
  s.description = %q{Safe ruby code execution in a standard ruby environment. Does not use a chroot, jail, etc. No special permissions required.}

  s.add_runtime_dependency 'fakefs'
  #s.add_development_dependency 'rspec', '~>2.5.0'
  s.add_development_dependency 'riot', '>= 0'
  s.add_development_dependency 'bundler', '~> 1.1.3'
  s.add_development_dependency 'simplecov', '~> 0.6.4'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end

