require 'set'
require 'active_support'
require 'active_support/core_ext'

module WebValve
  ALWAYS_ENABLED_ENVS = %w(development test).freeze
  ENABLED_VALUES = %w(1 t true).freeze

  class << self
    # @!method setup
    #   @see WebValve::Manager#setup
    # @!method register
    #   @see WebValve::Manager#register
    # @!method whitelist_url
    #   @see WebValve::Manager#whitelist_url
    # @!method reset
    #   @see WebValve::Manager#reset
    delegate :setup, :register, :whitelist_url, :reset, to: :manager
    attr_writer :logger

    def enabled?
      if env.in?(ALWAYS_ENABLED_ENVS)
        if ENV.key? 'WEBVALVE_ENABLED'
          logger.warn(<<~MESSAGE)
            WARNING: Ignoring WEBVALVE_ENABLED environment variable setting (#{ENV['WEBVALVE_ENABLED']})
            WebValve is always enabled in development and test environments.
          MESSAGE
        end
        true
      else
        ENABLED_VALUES.include?(ENV['WEBVALVE_ENABLED'])
      end
    end

    def config_paths
      @config_paths ||= Set.new
    end

    def logger
      @logger ||=
        if defined?(::Rails)
          # Rails.logger can be nil
          ::Rails.logger || default_logger
        else
          default_logger
        end
    end

    def default_logger
      ActiveSupport::Logger.new(STDOUT).tap do |l|
        l.formatter = ::Logger::Formatter.new
      end
    end

    if defined?(::Rails)
      delegate :env, :env=, to: ::Rails
    else
      def env
        @env ||= (ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development').inquiry
      end

      def env=(env)
        @env = env&.inquiry
      end
    end

    def manager
      WebValve::Manager.instance
    end
  end
end

require 'webvalve/railtie' if defined?(::Rails)
require 'webvalve/instrumentation'
require 'webvalve/fake_service'
require 'webvalve/fake_service_wrapper'
require 'webvalve/fake_service_config'
require 'webvalve/manager'
