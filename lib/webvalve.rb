require 'set'
require 'active_support'
require 'active_support/core_ext'

module WebValve
  class << self
    # @!method setup
    #   @see WebValve::Manager#setup
    # @!method register
    #   @see WebValve::Manager#register
    # @!method allow_url
    #   @see WebValve::Manager#allow_url
    # @!method reset
    #   @see WebValve::Manager#reset
    # @!method disabled?
    #   @see WebValve::Manager#disabled?
    delegate :setup, :register, :allow_url, :reset, :disabled?, to: :manager
    attr_writer :logger

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
require 'webvalve/monkey_patches'
