require 'webvalve/instrumentation/middleware'
require 'webvalve/instrumentation/log_subscriber'

WebValve::Instrumentation::LogSubscriber.attach_to :webvalve
