module WebValve
  class FakeServiceConfig
    attr_reader :service

    def initialize(service:, url: nil)
      @service = service
      @custom_service_url = url
    end

    def should_intercept?
      Rails.env.test? ||
        (WebValve.enabled? && !service_enabled_in_env?)
    end

    def service_url
      @service_url ||= begin
        url = custom_service_url || default_service_url
        raise missing_url_message if url.blank?
        strip_basic_auth url
      end
    end

    private

    attr_reader :custom_service_url

    def missing_url_message
      <<~MESSAGE
        There is no URL defined for #{service.name}.
        Configure one by setting the ENV variable "#{service_name.to_s.upcase}_API_URL"
        or by using WebValve.register #{service.name}, url: "http://something.dev"
      MESSAGE
    end

    def strip_basic_auth(url)
      url.to_s.sub(%r(\Ahttp(s)?://[^@/]+@), 'http\1://')
    end

    def service_enabled_in_env?
      WebValve::ENABLED_VALUES.include?(ENV["#{service_name.to_s.upcase}_ENABLED"])
    end

    def default_service_url
      ENV["#{service_name.to_s.upcase}_API_URL"]
    end

    def service_name
      @service_name ||= service.name.demodulize.underscore.sub 'fake_', ''
    end
  end
end
