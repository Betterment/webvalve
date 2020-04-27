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
      return unless enabled?
      load_configs!

      if intercepting?
        fake_service_configs.each do |config|
          if !WebValve.env.test? && config.explicitly_enabled?
            allowlist_service config
          else
            webmock_service config
          end
        end
        WebMock.disable_net_connect! webmock_disable_options
        WebMock.enable!
      end

      if allowing?
        fake_service_configs.each do |config|
          if config.explicitly_disabled?
            webmock_service config
          end
        end
        if fake_service_configs.any?(&:explicitly_disabled?)
          WebMock.allow_net_connect!
          WebMock.enable!
        end
      end
    end

    # @api private
    def enabled?
      in_always_intercepting_env? || explicitly_enabled?
    end

    # @api private
    def intercepting?
      in_always_intercepting_env? || (explicitly_enabled? && !services_enabled_by_default?)
    end

    # @api private
    def allowing?
      !in_always_intercepting_env? && explicitly_enabled? && services_enabled_by_default?
    end

    # @api private
    def reset
      allowlisted_urls.clear
      fake_service_configs.clear
      stubbed_urls.clear
      WebMock.reset!
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

    def explicitly_enabled?
      ENABLED_VALUES.include?(ENV['WEBVALVE_ENABLED'])
    end

    def services_enabled_by_default?
      if WebValve.env.in?(ALWAYS_ENABLED_ENVS)
        if ENV.key? 'WEBVALVE_SERVICE_ENABLED_DEFAULT'
          WebValve.logger.warn(<<~MESSAGE)
            WARNING: Ignoring WEBVALVE_SERVICE_ENABLED_DEFAULT environment variable setting (#{ENV['WEBVALVE_SERVICE_ENABLED_DEFAULT']})
            WebValve is always enabled in intercepting mode in development and test environments.
          MESSAGE
        end
        false
      else
        ENABLED_VALUES.include?(ENV.fetch('WEBVALVE_SERVICE_ENABLED_DEFAULT', '1'))
      end
    end

    def in_always_intercepting_env?
      if WebValve.env.in?(ALWAYS_ENABLED_ENVS)
        if ENV.key? 'WEBVALVE_ENABLED'
          WebValve.logger.warn(<<~MESSAGE)
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
      ensure_non_duplicate_stub(config)

      WebMock.stub_request(
        :any,
        url_to_regexp(config.service_url)
      ).to_rack(FakeServiceWrapper.new(config))
    end

    def allowlist_service(config)
      allowlisted_urls << config.service_url
    end

    def url_to_regexp(url)
      %r(\A#{Regexp.escape url})
    end

    def ensure_non_duplicate_stub(config)
      raise "Invalid config for #{config.service_class_name}. Already stubbed url #{config.full_url}" if stubbed_urls.include?(config.full_url)
      stubbed_urls << config.full_url
    end

    def load_configs!
      WebValve.config_paths.each do |root|
        path = root.join('config', 'webvalve.rb').to_s
        load path if File.exist?(path)
      end
    end

    def stubbed_urls
      @stubbed_urls ||= Set.new
    end
  end
end
