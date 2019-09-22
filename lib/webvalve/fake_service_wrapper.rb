module WebValve
  class FakeServiceWrapper
    # lazily resolve the app constant to leverage rails class reloading
    def initialize(app_class_name)
      @app_class_name = app_class_name
    end

    def call(env)
      app.call(env)
    end

    private

    def app
      @app_class_name.constantize
    end
  end
end
