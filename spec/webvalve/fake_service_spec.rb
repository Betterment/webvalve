require 'spec_helper'
require 'addressable/template'

RSpec.describe WebValve::FakeService do
  subject do
    Class.new(described_class) do
      def self.name
        'FakeDummy'
      end

      get '/widgets' do
        json({ result: 'it works!' })
      end
    end
  end

  before do
    stub_const('FakeDummy', subject)
  end

  it 'is a Sinatra::Base' do
    expect(subject).to be < Sinatra::Base
  end

  describe 'integrated behavior' do
    after do
      WebValve.reset!
    end

    context 'when the service is at a root path' do
      it 'raise a useful error when an unmapped route is requested' do
        with_env 'DUMMY_API_URL' => 'http://dummy.dev' do
          WebValve.register subject.name
          WebValve.setup

          expect { Net::HTTP.get(URI('http://dummy.dev/foos')) }.to raise_error(RuntimeError, /route not defined for GET/)
        end
      end

      it 'returns the result from the fake when a mapped route is requested' do
        with_env 'DUMMY_API_URL' => 'http://dummy.dev' do
          WebValve.register subject.name
          WebValve.setup

          expect(Net::HTTP.get(URI('http://dummy.dev/widgets'))).to eq({ result: 'it works!' }.to_json)
        end
      end
    end

    context 'when the service lives at a non-root path' do
      it 'raise a useful error when the route is requested at the root' do
        with_env 'DUMMY_API_URL' => 'http://dummy.dev/gg' do
          WebValve.register subject.name
          WebValve.setup

          expect { Net::HTTP.get(URI('http://dummy.dev/widgets')) }
            .to raise_error(WebMock::NetConnectNotAllowedError, /Real HTTP connections are disabled/)
        end
      end

      it 'returns the result from the fake when a mapped route is requested' do
        with_env 'DUMMY_API_URL' => 'http://dummy.dev/gg' do
          WebValve.register subject.name
          WebValve.setup

          expect(Net::HTTP.get(URI('http://dummy.dev/gg/widgets'))).to eq({ result: 'it works!' }.to_json)
        end
      end
    end

    context 'when the service is registered with a Regexp url' do
      it 'returns the result from the fake when the request URL matches the pattern' do
        WebValve.register subject.name, url: %r{\Ahttp://dummy\.dev/.*\z}
        WebValve.setup

        expect(Net::HTTP.get(URI('http://dummy.dev/widgets'))).to eq({ result: 'it works!' }.to_json)
      end

      it 'does not strip a path prefix by default' do
        nested = Class.new(described_class) do
          def self.name
            'FakeNested'
          end

          get '/api/v2/widgets' do
            json({ result: 'nested!' })
          end
        end
        stub_const('FakeNested', nested)

        WebValve.register nested.name, url: %r{\Ahttp://nested\.dev/api/v2/.*\z}
        WebValve.setup

        expect(Net::HTTP.get(URI('http://nested.dev/api/v2/widgets'))).to eq({ result: 'nested!' }.to_json)
      end

      it 'strips the configured path_prefix when one is given' do
        WebValve.register subject.name, url: %r{\Ahttp://dummy\.dev/api/v2/.*\z}, path_prefix: '/api/v2'
        WebValve.setup

        expect(Net::HTTP.get(URI('http://dummy.dev/api/v2/widgets'))).to eq({ result: 'it works!' }.to_json)
      end
    end

    context 'when the service is registered with an Addressable::Template url' do
      it 'returns the result from the fake when the request URL matches the template' do
        WebValve.register subject.name, url: Addressable::Template.new('http://dummy.dev{/path*}')
        WebValve.setup

        expect(Net::HTTP.get(URI('http://dummy.dev/widgets'))).to eq({ result: 'it works!' }.to_json)
      end

      it 'strips the configured path_prefix when one is given' do
        WebValve.register subject.name, url: Addressable::Template.new('http://dummy.dev/api/v2{/path*}'), path_prefix: '/api/v2'
        WebValve.setup

        expect(Net::HTTP.get(URI('http://dummy.dev/api/v2/widgets'))).to eq({ result: 'it works!' }.to_json)
      end
    end
  end
end
