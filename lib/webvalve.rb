require 'set'

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

    def enabled?
      if Rails.env.in?(ALWAYS_ENABLED_ENVS)
        if ENV.key? 'WEBVALVE_ENABLED'
          Rails.logger.warn(<<~MESSAGE)
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

    private

    def manager
      WebValve::Manager.instance
    end
  end
end

require 'webvalve/instrumentation'
require 'webvalve/engine'
require 'webvalve/fake_service'
require 'webvalve/fake_service_wrapper'
require 'webvalve/fake_service_config'
require 'webvalve/manager'
