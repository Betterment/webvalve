module WebValve
  class ServiceUrlConverter
    WILDCARD_BOUNDARY_CHARS = ('\b' + Regexp.escape('.:/?#@&=')).freeze
    WILDCARD_CHARACTER_CLASS =  ('[^' + WILDCARD_BOUNDARY_CHARS + ']').freeze
    WILDCARD_SUBSTITUTION = (WILDCARD_CHARACTER_CLASS + '*').freeze
    URL_PREFIX_BOUNDARY = ('[' + WILDCARD_BOUNDARY_CHARS + ']').freeze
    URL_SUFFIX_PATTERN = ('(' + URL_PREFIX_BOUNDARY + '.*)?\z').freeze

    attr_reader :url

    def initialize(url:)
      @url = url
    end

    def regexp
      regexp_string = Regexp.escape(url)
      substituted_regexp_string = regexp_string.gsub('\*', WILDCARD_SUBSTITUTION)
      %r(\A#{substituted_regexp_string}#{URL_SUFFIX_PATTERN})
    end
  end
end
