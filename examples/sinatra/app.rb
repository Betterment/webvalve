require 'sinatra'
require 'net/http'
require './config/webvalve'
WebValve.setup

get '/' do
  Net::HTTP.get('faketwitter.test', '/')
end
