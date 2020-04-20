module WebValve
  class FakeServiceWrapper
    # lazily resolve the app constant to leverage rails class reloading
    def initialize(service_config)
      @service_config = service_config
    end

    def call(env)
      env['PATH_INFO'] = env['PATH_INFO'].gsub(/\A#{path_prefix}/, '')
      app.call(env)
    end

    private

    def app
      @service_config.service_class_name.constantize
    end

    def path_prefix
      @path_prefix ||= URI::parse(@service_config.service_url).path
    end
  end
end
