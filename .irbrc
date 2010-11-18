#Ruby console IRB helpful commands
require 'rubygems'
require 'pp'
require 'wirble'
Wirble.init
Wirble.colorize

alias q exit

# Easily print methods local to an object's class
class Object
  def local_methods
    (methods - Object.instance_methods).sort
  end
end

# Log to STDOUT if in Rails
#Print SQL statements on calls in IRB
if ENV.include?('RAILS_ENV') && !Object.const_defined?('RAILS_DEFAULT_LOGGER')
  require 'logger'
  RAILS_DEFAULT_LOGGER = Logger.new(STDOUT)
end

