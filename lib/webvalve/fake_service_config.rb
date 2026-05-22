module WebValve
  class FakeServiceConfig
    attr_reader :service_class_name

    def initialize(service_class_name:, url: nil, path_prefix: nil)
      @service_class_name = service_class_name
      @custom_service_url = url
      @custom_path_prefix = path_prefix
    end

    def explicitly_enabled?
      value_from_env.present? && WebValve::ENABLED_VALUES.include?(value_from_env.to_s)
    end

    def explicitly_disabled?
      value_from_env.present? && WebValve::DISABLED_VALUES.include?(value_from_env.to_s)
    end

    def full_url
      @full_url ||= custom_service_url || default_service_url
    end

    def service_url
      @service_url ||= begin
        raise missing_url_message if full_url.blank?
        full_url.is_a?(String) ? strip_basic_auth(full_url) : full_url
      end
    end

    def path_prefix
      @path_prefix ||= begin
        raise missing_url_message if full_url.blank?
        custom_path_prefix || (full_url.is_a?(String) ? URI.parse(service_url).path : "")
      end
    end

    private

    attr_reader :custom_service_url, :custom_path_prefix

    def value_from_env
      ENV["#{service_name.to_s.upcase}_ENABLED"]
    end

    def missing_url_message
      <<~MESSAGE
        There is no URL defined for #{service_class_name}.
        Configure one by setting the ENV variable "#{service_name.to_s.upcase}_API_URL"
        or by using WebValve.register "#{service_class_name}", url: "http://something.dev"
      MESSAGE
    end

    def strip_basic_auth(url)
      url.to_s.sub(%r(\Ahttp(s)?://[^@/]+@), 'http\1://')
    end

    def default_service_url
      ENV["#{service_name.to_s.upcase}_API_URL"]
    end

    def service_name
      @service_name ||= service_class_name.demodulize.underscore.sub 'fake_', ''
    end
  end
end
