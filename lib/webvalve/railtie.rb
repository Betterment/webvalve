module WebValve
  class Railtie < ::Rails::Railtie
    initializer 'webvalve.set_autoload_paths', before: :set_autoload_paths do |app|
      if WebValve.enabled?
        WebValve.config_paths << app.root

        WebValve.config_paths.each do |root|
          app.config.eager_load_paths << root.join('webvalve').to_s
        end
      end
    end

    initializer 'webvalve.setup', after: :load_config_initializers do
      if WebValve.enabled?
        WebValve.config_paths.each do |root|
          path = root.join('config', 'webvalve.rb').to_s
          load path if File.exist?(path)
        end

        config.after_initialize do
          WebValve.setup
        end
      end
    end
  end
end
