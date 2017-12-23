require 'set'

module WebValve
  extend ActiveSupport::Autoload
  autoload :FakeService, 'webvalve/fake_service'
  autoload :FakeServiceWrapper, 'webvalve/fake_service_wrapper'
  autoload :FakeServiceConfig, 'webvalve/fake_service_config'
  autoload :Manager, 'webvalve/manager'

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
      Rails.env.in?(ALWAYS_ENABLED_ENVS) ||
        ENABLED_VALUES.include?(ENV['WEBVALVE_ENABLED'])
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
