begin
  require 'sicuro/base'
rescue LoadError
  require 'rubygems'
  retry
end
