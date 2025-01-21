module Dummy
  class Application < Rails::Application
    config.root = File.expand_path('..', __dir__)
  end
end
