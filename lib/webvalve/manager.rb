require 'webmock'
require 'singleton'
require 'set'

module WebValve
  # @api private
  class Manager
    include Singleton

    def register(fake_service, **args)
      raise "#{fake_service.inspect} already registered" if fake_service_configs.any? { |c| c.service == fake_service }
      fake_service_configs << FakeServiceConfig.new(service: fake_service, **args)
    end

    def whitelist_url(url, **args)
      raise "#{url} already registered" if whitelist_url_configs.any? { |c| c.url == url }
      whitelist_url_configs << WhitelistUrlConfig.new(url: url, **args)
    end

    def setup
      fake_service_configs.each do |config|
        if config.should_intercept?
          webmock_service config
        else
          whitelist_service config
        end
      end

      WebMock.enable!
      WebMock.disable_net_connect! webmock_disable_options
    end

    # @api private
    def reset
      whitelist_url_configs.clear
      fake_service_configs.clear
    end

    # @api private
    def fake_service_configs
      @fake_service_configs ||= []
    end

    # @api private
    def whitelist_url_configs
      @whitelist_url_configs ||= Set.new
    end

    private

    def webmock_disable_options
      { allow_localhost: true }.tap do |opts|
        opts[:allow] = whitelisted_url_regexps
      end
    end

    def whitelisted_url_regexps
      whitelist_url_configs.reject do |config|
        WebValve.env.test? && !config.whitelist_in_spec
      end.map do |config|
        url_to_regexp config.url
      end
    end

    def webmock_service(config)
      WebMock.stub_request(
        :any,
        url_to_regexp(config.service_url)
      ).to_rack(FakeServiceWrapper.new(config.service))
    end

    def whitelist_service(config)
      whitelist_url_configs << config.whitelist_url_config
    end

    def url_to_regexp(url)
      %r(\A#{Regexp.escape url})
    end
  end
end
