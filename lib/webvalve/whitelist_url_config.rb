module WebValve
  class WhitelistUrlConfig
    attr_reader :url, :whitelist_in_spec

    def initialize(url:, whitelist_in_spec: false)
      @url = url
      @whitelist_in_spec = whitelist_in_spec
    end
  end
end
