# if the webdrivers gem is included, patch it so that it can make HTTP requests to download
# drivers when necessary.
#
# based on the v3.9.4 release of webdrivers gem
# https://github.com/titusfortner/webdrivers/blob/v3.9.4/lib/webdrivers/network.rb#L47-L54
#
# and the v3.5.1 release of webmock gem
# https://github.com/bblimke/webmock/blob/v3.5.1/lib/webmock/http_lib_adapters/net_http.rb#L12
webdrivers = begin
  require "webdrivers"
  true
rescue LoadError
  false
end

if webdrivers
  class Webdrivers::Network
    class << self
      def http
        client = WebMock::HttpLibAdapters::NetHttpAdapter::OriginalNetHTTP
        if using_proxy
          client.Proxy(Webdrivers.proxy_addr, Webdrivers.proxy_port,
                       Webdrivers.proxy_user, Webdrivers.proxy_pass)
        else
          client
        end
      end
    end
  end
end
