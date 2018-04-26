class FakeTwitter < WebValve::FakeService
  URL = 'http://faketwitter.test'.freeze

  get '/' do
    json hello: 'world'
  end
end
