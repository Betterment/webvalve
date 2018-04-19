require 'active_support/log_subscriber'

module WebValve
  module Instrumentation
    class LogSubscriber < ActiveSupport::LogSubscriber
      def request(event)
        return unless logger.debug?
        status = event.payload[:status]
        method = event.payload[:method].to_s.upcase
        url = event.payload[:url]
        host = event.payload[:host]
        name = '%s %s (%.1fms)' % ["WebValve", "Request Captured", event.duration]
        details = "#{host} #{method} #{url} [#{status}]"
        debug "  #{color(name, YELLOW, true)}  #{color(details, BOLD, true)}"
      end
    end
  end
end
