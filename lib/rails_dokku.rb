require 'rails_dokku/version'

module RailsDokku
  puts Rails
  require 'rails_dokku/railtie' if defined?(Rails)
end
