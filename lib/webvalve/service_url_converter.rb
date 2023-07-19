require 'addressable/uri'
require 'addressable/template'

module WebValve
  # @api private
  class ServiceUrlConverter

    def initialize(url:)
      @url = url
    end

    def template
      if @url.is_a?(String)
        protocol, working_url = split_protocol(double_stars(@url))
        uri = Addressable::URI.parse(working_url)

        if uri.fragment.present?
          raise "Webvalve: URL Fragment will never match: #{@url}"
        end

        suffix = extend_path_and_query!(uri)

        substituted_url = substitute_double_stars(protocol + uri.to_s + suffix)
        Addressable::Template.new(substituted_url)
      else
        @url
      end
    end

    private

    # Doubles asterisks to retain Addressable::URI parseability while making
    # wildcards distinct from the asterisks we'll be adding later. That way
    # we can later gsub double asterisks to Addressable::Template variables
    # in `#substitute_double_stars`
    def double_stars(working_url)
      working_url.gsub('*', '**')
    end

    # Splits protocol off to keep Addressable::URI from rejecting a scheme with
    # asterisks in it. We'll recombine later. Returns [protocol, url]
    def split_protocol(working_url)
      if matchdata = %r{\A([^:]+:)(//.*)\z}.match(working_url)
        [matchdata[1], matchdata[2]]
      else
        ['', working_url]
      end
    end

    # Munges the provided URI object to append extensible path and query
    # variables. If query or path are not present, returned suffix will include
    # path and/or query patterns.
    def extend_path_and_query!(uri)
      suffix = ''

      if uri.query.present?
        uri.query += '{&ext*}'
      else
        if uri.path == '/' || uri.path == ''
          uri.path = ''
          suffix += '{/path*}'
        else
          uri.path += '{/ext*}'
        end

        suffix += '{?query}'
      end

      suffix
    end

    # substitutes double asterisks for `{star}` patterns
    def substitute_double_stars(working_url)
      working_url.gsub('**', '{star}')
    end
  end
end
