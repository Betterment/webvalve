require 'set'

module WebValve
  extend ActiveSupport::Autoload
  autoload :FakeService, 'webvalve/fake_service'
  autoload :FakeServiceWrapper, 'webvalve/fake_service_wrapper'
  autoload :FakeServiceConfig, 'webvalve/fake_service_config'
  autoload :Manager, 'webvalve/manager'

  ENABLED_ENVS = %w(development test).freeze

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
      Rails.env.in?(ENABLED_ENVS)
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
