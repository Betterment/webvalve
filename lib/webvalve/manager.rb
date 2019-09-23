require 'webmock'
require 'singleton'
require 'set'

module WebValve
  ALWAYS_ENABLED_ENVS = %w(development test).freeze
  ENABLED_VALUES = %w(1 t true).freeze
  DISABLED_VALUES = %w(0 f false).freeze

  # @api private
  class Manager
    include Singleton

    def register(fake_service_class_name, **args)
      raise "register must be called with a string to comply with Rails autoloading" unless fake_service_class_name.is_a?(String)
      raise "#{fake_service_class_name.inspect} already registered" if fake_service_configs.any? { |c| c.service_class_name == fake_service_class_name }
      fake_service_configs << FakeServiceConfig.new(service_class_name: fake_service_class_name, **args)
    end

    def allow_url(url)
      raise "#{url} already registered" if allowlisted_urls.include?(url)
      allowlisted_urls << url
    end

    def setup
      return if disabled?

      if intercepting?
        fake_service_configs.each do |config|
          if WebValve.env.test? || config.explicitly_enabled?
            allowlist_service config
          else
            webmock_service config
          end
        end
        WebMock.disable_net_connect! webmock_disable_options
      end

      if allowing?
        fake_service_configs.each do |config|
          if config.explicitly_disabled?
            webmock_service config
          end
        end
        WebMock.allow_net_connect!
      end

      WebMock.enable!
    end

    # @api private
    def reset
      allowlisted_urls.clear
      fake_service_configs.clear
    end

    # @api private
    def fake_service_configs
      @fake_service_configs ||= []
    end

    # @api private
    def allowlisted_urls
      @allowlisted_urls ||= Set.new
    end

    private

    def disabled?
      !intercepting? && !allowing?
    end

    def intercepting?
      in_always_intercepting_env? || ENABLED_VALUES.include?(ENV['WEBVALVE_ENABLED'])
    end

    def allowing?
      !in_always_intercepting_env? && DISABLED_VALUES.include?(ENV['WEBVALVE_ENABLED'])
    end

    def in_always_intercepting_env?
      if WebValve.env.in?(ALWAYS_ENABLED_ENVS)
        if ENV.key? 'WEBVALVE_ENABLED'
          logger.warn(<<~MESSAGE)
            WARNING: Ignoring WEBVALVE_ENABLED environment variable setting (#{ENV['WEBVALVE_ENABLED']})
            WebValve is always enabled in development and test environments.
          MESSAGE
        end
        true
      else
        false
      end
    end

    def webmock_disable_options
      { allow_localhost: true }.tap do |opts|
        opts[:allow] = allowlisted_url_regexps unless WebValve.env.test?
      end
    end

    def allowlisted_url_regexps
      allowlisted_urls.map { |url| url_to_regexp url }
    end

    def webmock_service(config)
      WebMock.stub_request(
        :any,
        url_to_regexp(config.service_url)
      ).to_rack(FakeServiceWrapper.new(config.service_class_name))
    end

    def allowlist_service(config)
      allowlisted_urls << config.service_url
    end

    def url_to_regexp(url)
      %r(\A#{Regexp.escape url})
    end
  end
end
