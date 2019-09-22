class FakeTwitter < WebValve::FakeService
  get '/' do
    json hello: 'world'
  end
end
