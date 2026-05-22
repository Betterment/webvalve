require 'spec_helper'
require 'addressable/template'

RSpec.describe WebValve::FakeServiceConfig do
  let(:fake_service) do
    Class.new(described_class) do
      def self.service_name
        'dummy'
      end

      def self.name
        'FakeDummy'
      end
    end
  end

  before do
    stub_const('FakeDummy', fake_service)
  end

  subject { described_class.new service_class_name: fake_service.name }

  describe '.explicitly_enabled?' do
    it 'returns false when DUMMY_ENABLED is unset' do
      expect(subject.explicitly_enabled?).to eq false
    end

    it 'returns true when DUMMY_ENABLED is truthy' do
      with_env 'DUMMY_ENABLED' => '1' do
        expect(subject.explicitly_enabled?).to eq true
      end

      with_env 'DUMMY_ENABLED' => 't' do
        expect(subject.explicitly_enabled?).to eq true
      end

      with_env 'DUMMY_ENABLED' => 'true' do
        expect(subject.explicitly_enabled?).to eq true
      end

      with_env 'DUMMY_ENABLED' => 'not true or false' do
        expect(subject.explicitly_enabled?).to eq false
      end
    end
  end

  describe '.explicitly_disabled?' do
    it 'returns false when DUMMY_ENABLED is unset' do
      expect(subject.explicitly_disabled?).to eq false
    end

    it 'returns true when DUMMY_ENABLED is falsey' do
      with_env 'DUMMY_ENABLED' => '0' do
        expect(subject.explicitly_disabled?).to eq true
      end

      with_env 'DUMMY_ENABLED' => 'f' do
        expect(subject.explicitly_disabled?).to eq true
      end

      with_env 'DUMMY_ENABLED' => 'false' do
        expect(subject.explicitly_disabled?).to eq true
      end

      with_env 'DUMMY_ENABLED' => 'not true or false' do
        expect(subject.explicitly_disabled?).to eq false
      end
    end
  end

  describe '.service_url' do
    it 'raises if the url is not present' do
      expect { subject.service_url }.to raise_error <<~MESSAGE
        There is no URL defined for FakeDummy.
        Configure one by setting the ENV variable "DUMMY_API_URL"
        or by using WebValve.register "FakeDummy", url: "http://something.dev"
      MESSAGE
    end

    it 'discovers url via ENV based on fake service name' do
      with_env 'DUMMY_API_URL' => 'http://thingy.dev' do
        expect(subject.service_url).to eq 'http://thingy.dev'
      end
    end

    it 'removes embedded basic auth credentials' do
      with_env 'DUMMY_API_URL' => 'http://foo:bar@thingy.dev' do
        expect(subject.service_url).to eq 'http://thingy.dev'
      end
    end

    context 'when registered with a Regexp url' do
      let(:url) { %r{\Ahttp://thingy\.dev(/.*)?\z} }

      subject { described_class.new(service_class_name: fake_service.name, url: url) }

      it 'returns the Regexp unchanged' do
        expect(subject.service_url).to equal(url)
      end
    end

    context 'when registered with an Addressable::Template url' do
      let(:url) { Addressable::Template.new('http://thingy.dev{/path*}') }

      subject { described_class.new(service_class_name: fake_service.name, url: url) }

      it 'returns the Addressable::Template unchanged' do
        expect(subject.service_url).to equal(url)
      end
    end
  end

  describe '.path_prefix' do
    it 'raises if the url is not present' do
      expect { subject.path_prefix }.to raise_error(/There is no URL defined for FakeDummy/)
    end

    it 'returns root when there is no path in the service URL' do
      with_env 'DUMMY_API_URL' => 'http://bananas.test/' do
        expect(subject.path_prefix).to eq '/'
      end
      with_env 'DUMMY_API_URL' => 'https://some:auth@bananas.test//' do
        expect(subject.path_prefix).to eq '/' # Parses funkier URL
      end
    end

    it 'returns the path when there is one in the service URL' do
      with_env 'DUMMY_API_URL' => 'http://zombo.com/welcome' do
        expect(subject.path_prefix).to eq '/welcome'
      end
      with_env 'DUMMY_API_URL' => 'http://zombo.com/welcome/' do
        expect(subject.path_prefix).to eq '/welcome' # Ignores trailing '/'
      end
    end

    context 'when registered with a Regexp url' do
      subject { described_class.new(service_class_name: fake_service.name, url: %r{\Ahttp://thingy\.dev/api(/.*)?\z}) }

      it 'defaults to an empty string so FakeServiceWrapper does not strip from PATH_INFO' do
        expect(subject.path_prefix).to eq ''
      end
    end

    context 'when registered with an Addressable::Template url' do
      subject { described_class.new(service_class_name: fake_service.name, url: Addressable::Template.new('http://thingy.dev/api{/path*}')) }

      it 'defaults to an empty string so FakeServiceWrapper does not strip from PATH_INFO' do
        expect(subject.path_prefix).to eq ''
      end
    end

    context 'when an explicit path_prefix is provided' do
      it 'uses the override with a String url' do
        with_env 'DUMMY_API_URL' => 'http://zombo.com' do
          config = described_class.new(service_class_name: fake_service.name, path_prefix: '/api/v2')
          expect(config.path_prefix).to eq '/api/v2'
        end
      end

      it 'uses the override with a Regexp url' do
        config = described_class.new(
          service_class_name: fake_service.name,
          url: %r{\Ahttp://thingy\.dev/api/v2(/.*)?\z},
          path_prefix: '/api/v2',
        )
        expect(config.path_prefix).to eq '/api/v2'
      end

      it 'uses the override with an Addressable::Template url' do
        config = described_class.new(
          service_class_name: fake_service.name,
          url: Addressable::Template.new('http://thingy.dev/api/v2{/path*}'),
          path_prefix: '/api/v2',
        )
        expect(config.path_prefix).to eq '/api/v2'
      end
    end
  end
end
