require 'rails_dokku'
require 'rails'

module RailsDokku
  class Railtie < Rails::Railtie
    railtie_name :rails_dokku

    rake_tasks do
      load 'lib/tasks/dokku.rake'
    end
  end
end
