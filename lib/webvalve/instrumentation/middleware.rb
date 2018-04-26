require 'active_support/notifications'

module WebValve
  module Instrumentation
    class Middleware
      METHOD = 'REQUEST_METHOD'.freeze
      PATH = 'PATH_INFO'.freeze
      HOST = 'SERVER_NAME'.freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        ActiveSupport::Notifications.instrument('request.webvalve') do |payload|
          payload[:method] = env[METHOD]
          payload[:url] = env[PATH]
          payload[:host] = env[HOST]
          @app.call(env).tap do |status, _header, _body|
            payload[:status] = status
          end
        end
      end
    end
  end
end
