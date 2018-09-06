require 'spec_helper'

RSpec.describe WebValve::Manager do

  subject { described_class.send :new }

  it 'is a singleton' do
    described_class.is_a? Singleton
  end

  describe '#whitelist_url' do
    it 'raises on duplicates' do
      subject.whitelist_url "foo"
      expect { subject.whitelist_url "foo" }.to raise_error(/already registered/)
      expect(subject.whitelist_url_configs.count).to eq 1
      expect(subject.whitelist_url_configs.first).to be_a WebValve::WhitelistUrlConfig
      subject.whitelist_url_configs.first.tap do |config|
        expect(config.url).to eq "foo"
        expect(config.whitelist_in_spec).to eq false
      end
    end

    it 'accepts whitelist_in_spec argument' do
      subject.whitelist_url "bar", whitelist_in_spec: true
      expect(subject.whitelist_url_configs.count).to eq 1
      expect(subject.whitelist_url_configs.first).to be_a WebValve::WhitelistUrlConfig
      subject.whitelist_url_configs.first.tap do |config|
        expect(config.url).to eq "bar"
        expect(config.whitelist_in_spec).to eq true
      end
    end
  end

  describe '#register(fake_service)' do
    it 'raises on duplicates' do
      fake = class_double(WebValve::FakeService)

      subject.register fake
      expect { subject.register fake }.to raise_error(/already registered/)
      expect(subject.fake_service_configs.count).to eq 1
      expect(subject.fake_service_configs.first.service).to eq fake
    end
  end

  describe '#register(fake_service, url:)' do
    it 'stores the url' do
      fake = class_double(WebValve::FakeService)

      subject.register fake, url: 'http://manual.dev'
      expect(subject.fake_service_configs.first.service_url).to eq 'http://manual.dev'
    end
  end

  describe '#setup' do
    it 'enables webmock' do
      allow(WebMock).to receive(:enable!)

      subject.setup

      expect(WebMock).to have_received(:enable!)
    end

    it 'disables network connections' do
      allow(WebMock).to receive(:disable_net_connect!)

      subject.setup

      expect(WebMock).to have_received(:disable_net_connect!)
    end

    it 'allows localhost connections' do
      allow(WebMock).to receive(:disable_net_connect!)

      subject.setup

      expect(WebMock).to have_received(:disable_net_connect!).with(hash_including(allow_localhost: true))
    end

    context 'in test environment' do
      around do |example|
        with_rails_env 'test' do
          example.run
        end
      end

      it 'does not whitelist configured urls in webmock, unless explicitly specified' do
        allow(WebMock).to receive(:disable_net_connect!)
        allowed_results = [%r{\Ahttp://baz\.dev}]
        disallowed_results = [%r{\Ahttp://foo\.dev}, %r{\Ahttp://bar\.dev}]

        subject.whitelist_url 'http://foo.dev'
        subject.whitelist_url 'http://bar.dev'
        subject.whitelist_url 'http://baz.dev', whitelist_in_spec: true

        subject.setup

        expect(WebMock).to have_received(:disable_net_connect!)
          .with(hash_including(allow: allowed_results))
        expect(WebMock).not_to have_received(:disable_net_connect!)
          .with(hash_including(allow: disallowed_results))
      end
    end

    context 'in non-test environment' do
      around do |example|
        with_rails_env 'development' do
          example.run
        end
      end

      it 'whitelists configured urls in webmock' do
        allow(WebMock).to receive(:disable_net_connect!)
        results = [%r{\Ahttp://foo\.dev}, %r{\Ahttp://bar\.dev}]

        subject.whitelist_url 'http://foo.dev'
        subject.whitelist_url 'http://bar.dev'

        subject.setup

        expect(WebMock).to have_received(:disable_net_connect!)
          .with(hash_including(allow: results))
      end

      it 'mocks registered fakes that are not enabled in ENV' do
        disabled_service = class_double(WebValve::FakeService, name: 'FakeSomething')
        web_mock_stubble = double(to_rack: true)
        allow(WebMock).to receive(:stub_request).and_return(web_mock_stubble)

        with_env 'SOMETHING_API_URL' => 'http://fake.dev' do
          subject.register disabled_service
          subject.setup
        end

        expect(WebMock).to have_received(:stub_request).with(:any, %r{\Ahttp://fake\.dev})
        expect(web_mock_stubble).to have_received(:to_rack)
      end

      it 'whitelists registered fakes that are enabled in ENV' do
        enabled_service = class_double(WebValve::FakeService, name: 'FakeSomething')

        with_env 'SOMETHING_ENABLED' => '1', 'SOMETHING_API_URL' => 'http://real.dev' do
          subject.register enabled_service
          subject.setup
        end

        expect(subject.whitelist_url_configs.map(&:url)).to include 'http://real.dev'
      end
    end
  end
end
