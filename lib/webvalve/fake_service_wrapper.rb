module WebValve
  class FakeServiceWrapper
    # lazily resolve the app constant to leverage rails class reloading
    def initialize(app)
      @app_klass_name = app.name
    end

    def call(env)
      app.call(env)
    end

    private

    def app
      @app_klass_name.constantize
    end
  end
end
