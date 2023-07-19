require 'addressable/uri'
require 'addressable/template'

module WebValve
  class ServiceUrlConverter

    attr_reader :url

    def initialize(url:)
      @url = url
    end

    def template
      if url.is_a?(String)
        working_url = url.gsub('*', '**')
        protocol = ""
        if matchdata = %r{\A([^:]+:)(//.*)\z}.match(working_url)
          protocol = matchdata[1]
          working_url = matchdata[2]
        end
        uri = Addressable::URI.parse(working_url)

        if uri.fragment.present?
          raise "Webvalve: URL Fragments are not valid: #{url}"
        end

        suffix = ""

        if uri.query.present?
          uri.query = "#{uri.query}{&ext*}"
        else
          if uri.path == "/" || uri.path == ""
            uri.path = ""
            suffix += "{/path*}"
          else
            uri.path = "#{uri.path}{/ext*}"
          end

          suffix += "{?query}"
        end

        substituted_url = (protocol + uri.to_s).gsub('**', '{star}')
        Addressable::Template.new(substituted_url + suffix)
      else
        @url
      end
    end
  end
end
