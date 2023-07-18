require 'spec_helper'

RSpec.describe WebValve::Manager do

  subject { described_class.send :new }

  it 'is a singleton' do
    described_class.is_a? Singleton
  end

  describe '#allow_url' do
    it 'raises on duplicates' do
      subject.allow_url "foo"
      expect { subject.allow_url "foo" }.to raise_error(/already registered/)
      expect(subject.allowlisted_urls.count).to eq 1
      expect(subject.allowlisted_urls).to contain_exactly(/foo/)
    end
  end

  describe '#register(fake_service_class_name)' do
    it 'raises on duplicates' do
      fake = class_double(WebValve::FakeService, name: "FooService")

      subject.register fake.name
      expect { subject.register fake.name }.to raise_error(/already registered/)
      expect(subject.fake_service_configs.count).to eq 1
      expect(subject.fake_service_configs.first.service_class_name).to eq fake.name
    end
  end

  describe '#register(fake_service_class_name, url:)' do
    it 'stores the url' do
      fake = class_double(WebValve::FakeService, name: "FooService")

      subject.register fake.name, url: 'http://foo.dev'
      expect(subject.fake_service_configs.first.service_url).to eq 'http://foo.dev'
    end
  end

  describe '#setup' do
    context 'when WebValve is disabled' do
      around do |ex|
        with_rails_env 'production' do
          # unset
          with_env 'WEBVALVE_ENABLED' => nil do
            ex.run
          end
        end
      end

      it 'does not setup webmock' do
        allow(WebMock).to receive(:allow_net_connect!)
        allow(WebMock).to receive(:enable!)

        subject.setup

        expect(WebMock).not_to have_received(:allow_net_connect!)
        expect(WebMock).not_to have_received(:enable!)
      end
    end

    context 'when WebValve is on and intercepting traffic' do
      around do |ex|
        with_rails_env 'production' do
          with_env 'WEBVALVE_ENABLED' => '1', 'WEBVALVE_SERVICE_ENABLED_DEFAULT' => '0' do
            ex.run
          end
        end
      end

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

      it 'allowlists configured urls in webmock' do
        allow(WebMock).to receive(:disable_net_connect!)
        results = [
          Addressable::Template.new('http://foo.dev{/path*}{?query*}'),
          Addressable::Template.new('http://bar.dev{/path*}{?query*}'),
          Addressable::Template.new('http://bar.{star}.dev{/path*}{?query*}'),
          Addressable::Template.new('http://bar.dev/?foo=bar{&ext*}')
        ]

        subject.allow_url 'http://foo.dev'
        subject.allow_url 'http://bar.dev'
        subject.allow_url 'http://bar.*.dev'
        subject.allow_url 'http://bar.dev/?foo=bar'

        subject.setup

        expect(WebMock).to have_received(:disable_net_connect!)
          .with(hash_including(allow: results))
      end

      it 'mocks registered fakes that are not enabled in ENV' do
        disabled_service = class_double(WebValve::FakeService, name: 'FakeSomething')
        web_mock_stubble = double(to_rack: true)
        allow(WebMock).to receive(:stub_request).and_return(web_mock_stubble)

        with_env 'SOMETHING_API_URL' => 'http://something.dev' do
          subject.register disabled_service.name
          subject.setup
        end

        expect(WebMock).to have_received(:stub_request).with(:any, Addressable::Template.new('http://something.dev{/path*}{?query*}'))
        expect(web_mock_stubble).to have_received(:to_rack)
      end

      it 'allowlists registered fakes that are enabled in ENV' do
        enabled_service = class_double(WebValve::FakeService, name: 'FakeSomething')

        with_env 'SOMETHING_ENABLED' => '1', 'SOMETHING_API_URL' => 'http://something.dev' do
          subject.register enabled_service.name
          subject.setup
        end

        expect(subject.allowlisted_urls).to include 'http://something.dev'
      end

      it 'raises with duplicate stubbed urls' do
        disabled_service = class_double(WebValve::FakeService, name: 'FakeSomething')
        other_disabled_service = class_double(WebValve::FakeService, name: 'FakeOtherThing')

        with_env 'SOMETHING_API_URL' => 'http://something.dev', 'OTHER_THING_API_URL' => 'http://something.dev' do
          subject.register disabled_service.name
          subject.register other_disabled_service.name

          expect { subject.setup }.to raise_error('Invalid config for FakeOtherThing. Already stubbed url http://something.dev')
        end
      end

      it 'does not raise with different HTTP auth patterns' do
        disabled_service = class_double(WebValve::FakeService, name: 'FakeSomething')
        other_disabled_service = class_double(WebValve::FakeService, name: 'FakeOtherThing')
        web_mock_stubble = double(to_rack: true)
        allow(WebMock).to receive(:stub_request).and_return(web_mock_stubble)

        with_env 'SOMETHING_API_URL' => 'http://user1@something.dev', 'OTHER_THING_API_URL' => 'http://user2@something.dev' do
          subject.register disabled_service.name
          subject.register other_disabled_service.name

          expect { subject.setup }.to_not raise_error
          expect(WebMock).to have_received(:stub_request).with(:any, Addressable::Template.new('http://something.dev{/path*}{?query*}')).twice
        end
      end
    end

    context 'when WebValve is on and allowing traffic' do
      around do |ex|
        with_rails_env 'production' do
          with_env 'WEBVALVE_ENABLED' => '1', 'WEBVALVE_SERVICE_ENABLED_DEFAULT' => '1' do
            ex.run
          end
        end
      end

      context 'when there are no services disabled' do
        it 'does not setup webmock' do
          allow(WebMock).to receive(:allow_net_connect!)
          allow(WebMock).to receive(:enable!)

          subject.setup

          expect(WebMock).not_to have_received(:allow_net_connect!)
          expect(WebMock).not_to have_received(:enable!)
        end
      end

      context 'when there are explicitly disabled fake services to stub' do
        it 'allows network connections and enables webmock' do
          allow(WebMock).to receive(:allow_net_connect!)
          allow(WebMock).to receive(:enable!)

          enabled_service = class_double(WebValve::FakeService, name: 'FakeSomething')

          with_env 'SOMETHING_ENABLED' => '0', 'SOMETHING_API_URL' => 'http://something.dev' do
            subject.register enabled_service.name
            subject.setup
          end

          expect(WebMock).to have_received(:allow_net_connect!)
          expect(WebMock).to have_received(:enable!)
        end

        it 'mocks registered fakes that are explicitly disabled in ENV' do
          disabled_service = class_double(WebValve::FakeService, name: 'FakeSomething')
          other_service = class_double(WebValve::FakeService, name: 'FakeOther')

          web_mock_stubble = double(to_rack: true)
          allow(WebMock).to receive(:stub_request).and_return(web_mock_stubble)

          with_env 'SOMETHING_API_URL' => 'http://something.dev', 'SOMETHING_ENABLED' => '0', 'OTHER_API_URL' => 'http://other.dev' do
            subject.register disabled_service.name
            subject.register other_service.name
            subject.setup
          end

          expect(WebMock).to have_received(:stub_request).with(:any, Addressable::Template.new('http://something.dev{/path*}{?query*}'))
          expect(WebMock).not_to have_received(:stub_request).with(:any, Addressable::Template.new('http://other.dev{/path*}{?query*}'))
          expect(web_mock_stubble).to have_received(:to_rack).once
        end

        it 'does not allowlist registered fakes because the network is enabled' do
          some_service = class_double(WebValve::FakeService, name: 'FakeSomething')

          with_env 'SOMETHING_API_URL' => 'http://something.dev' do
            subject.register some_service.name
            subject.setup
          end

          expect(subject.allowlisted_urls).not_to include 'http://something.dev'
        end
      end
    end

    context 'in test environment' do
      around do |example|
        with_rails_env 'test' do
          example.run
        end
      end

      it 'does not allowlist configured urls in webmock' do
        allow(WebMock).to receive(:disable_net_connect!)
        results = [%r{\Ahttp://foo\.dev}, %r{\Ahttp://bar\.dev}]

        subject.allow_url 'http://foo.dev'
        subject.allow_url 'http://bar.dev'

        subject.setup

        expect(WebMock).not_to have_received(:disable_net_connect!)
          .with(hash_including(allow: results))
      end

      it 'fakes all services regardless of ENV settings' do
        enabled_service = class_double(WebValve::FakeService, name: 'FakeSomething')
        disabled_service = class_double(WebValve::FakeService, name: 'FakeSomethingElse')
        other_service = class_double(WebValve::FakeService, name: 'FakeOther')

        web_mock_stubble = double(to_rack: true)
        allow(WebMock).to receive(:stub_request).and_return(web_mock_stubble)

        with_env 'SOMETHING_ENABLED' => '1', 'SOMETHING_ELSE_ENABLED' => '0', 'OTHER_ENABLED' => nil do
          subject.register disabled_service.name, url: 'http://something.dev'
          subject.register enabled_service.name, url: 'http://something-else.dev'
          subject.register other_service.name, url: 'http://other.dev'
          subject.setup
        end

        expect(WebMock).to have_received(:stub_request).with(:any, Addressable::Template.new('http://something.dev{/path*}{?query*}'))
        expect(WebMock).to have_received(:stub_request).with(:any, Addressable::Template.new('http://something-else.dev{/path*}{?query*}'))
        expect(WebMock).to have_received(:stub_request).with(:any, Addressable::Template.new('http://other.dev{/path*}{?query*}'))
        expect(web_mock_stubble).to have_received(:to_rack).exactly(3).times
      end
    end
  end

  describe '.intercepting?' do
    context 'in test env' do
      around do |ex|
        with_rails_env 'test' do
          ex.run
        end
      end

      it 'returns true when WEBVALVE_ENABLED is unset' do
        expect(subject.intercepting?).to eq true
      end

      it 'returns true regardless of WEBVALVE_ENABLED value' do
        allow(WebValve.logger).to receive(:warn)

        with_env 'WEBVALVE_ENABLED' => '1' do
          expect(subject.intercepting?).to eq true
          expect(WebValve.logger).to have_received(:warn).at_least(1)
        end

        with_env 'WEBVALVE_ENABLED' => '0' do
          expect(subject.intercepting?).to eq true
          expect(WebValve.logger).to have_received(:warn).at_least(1)
        end
      end
    end

    context 'in development env' do
      around do |ex|
        with_rails_env 'development' do
          ex.run
        end
      end

      it 'returns true when WEBVALVE_ENABLED is unset' do
        expect(subject.intercepting?).to eq true
      end

      it 'returns true regardless of WEBVALVE_ENABLED value' do
        allow(WebValve.logger).to receive(:warn)

        with_env 'WEBVALVE_ENABLED' => '1' do
          expect(subject.intercepting?).to eq true
          expect(WebValve.logger).to have_received(:warn).at_least(1)
        end

        with_env 'WEBVALVE_ENABLED' => '0' do
          expect(subject.intercepting?).to eq true
          expect(WebValve.logger).to have_received(:warn).at_least(1)
        end
      end

      it 'returns true when WEBVALVE_ENABLED is unset' do
        with_env 'WEBVALVE_ENABLED' => nil do
          expect(subject.intercepting?).to eq true
        end
      end
    end

    context 'in production enviroment' do
      around do |ex|
        with_rails_env 'production' do
          ex.run
        end
      end

      it 'return false when WEBVALVE_ENABLED is unset' do
        with_env 'WEBVALVE_ENABLED' => nil do
          expect(subject.intercepting?).to eq false
        end
      end

      it 'returns true when WEBVALVE_ENABLED is truthy and WEBVALVE_SERVICE_ENABLED_DEFAULT is set and falsey' do
        with_env 'WEBVALVE_ENABLED' => '1', 'WEBVALVE_SERVICE_ENABLED_DEFAULT' => '0' do
          expect(subject.intercepting?).to eq true
        end

        with_env 'WEBVALVE_ENABLED' => 't', 'WEBVALVE_SERVICE_ENABLED_DEFAULT' => 'f' do
          expect(subject.intercepting?).to eq true
        end

        with_env 'WEBVALVE_ENABLED' => 'true', 'WEBVALVE_SERVICE_ENABLED_DEFAULT' => 'false' do
          expect(subject.intercepting?).to eq true
        end
      end

      it 'returns false when WEBVALVE_ENABLED is truthy and WEBVALVE_SERVICE_ENABLED_DEFAULT is set and truthy' do
        with_env 'WEBVALVE_ENABLED' => '1', 'WEBVALVE_SERVICE_ENABLED_DEFAULT' => '1' do
          expect(subject.intercepting?).to eq false
        end

        with_env 'WEBVALVE_ENABLED' => 't', 'WEBVALVE_SERVICE_ENABLED_DEFAULT' => 't' do
          expect(subject.intercepting?).to eq false
        end

        with_env 'WEBVALVE_ENABLED' => 'true', 'WEBVALVE_SERVICE_ENABLED_DEFAULT' => 'true' do
          expect(subject.intercepting?).to eq false
        end
      end

      it 'returns false when WEBVALVE_ENABLED is truthy but WEBVALVE_SERVICE_ENABLED_DEFAULT is unset' do
        with_env 'WEBVALVE_ENABLED' => '1' do
          expect(subject.intercepting?).to eq false
        end

        with_env 'WEBVALVE_ENABLED' => 't' do
          expect(subject.intercepting?).to eq false
        end

        with_env 'WEBVALVE_ENABLED' => 'true' do
          expect(subject.intercepting?).to eq false
        end
      end

      it 'returns false when WEBVALVE_ENABLED is not truthy' do
        with_env 'WEBVALVE_ENABLED' => '0' do
          expect(subject.intercepting?).to eq false
        end

        with_env 'WEBVALVE_ENABLED' => 'f' do
          expect(subject.intercepting?).to eq false
        end

        with_env 'WEBVALVE_ENABLED' => 'false' do
          expect(subject.intercepting?).to eq false
        end

        with_env 'WEBVALVE_ENABLED' => 'not true or false' do
          expect(subject.intercepting?).to eq false
        end
      end
    end
  end

  describe '.allowing?' do
    context 'in test env' do
      around do |ex|
        with_rails_env 'test' do
          ex.run
        end
      end

      it 'returns false when WEBVALVE_ENABLED is unset' do
        expect(subject.allowing?).to eq false
      end

      it 'returns false regardless of WEBVALVE_ENABLED value' do
        allow(WebValve.logger).to receive(:warn)

        with_env 'WEBVALVE_ENABLED' => '1' do
          expect(subject.allowing?).to eq false
          expect(WebValve.logger).to have_received(:warn).at_least(1)
        end

        with_env 'WEBVALVE_ENABLED' => '0' do
          expect(subject.allowing?).to eq false
          expect(WebValve.logger).to have_received(:warn).at_least(1)
        end
      end
    end

    context 'in development env' do
      around do |ex|
        with_rails_env 'development' do
          ex.run
        end
      end

      it 'returns false when WEBVALVE_ENABLED is unset' do
        expect(subject.allowing?).to eq false
      end

      it 'returns false regardless of WEBVALVE_ENABLED value' do
        allow(WebValve.logger).to receive(:warn)

        with_env 'WEBVALVE_ENABLED' => '1' do
          expect(subject.allowing?).to eq false
          expect(WebValve.logger).to have_received(:warn).at_least(1)
        end

        with_env 'WEBVALVE_ENABLED' => '0' do
          expect(subject.allowing?).to eq false
          expect(WebValve.logger).to have_received(:warn).at_least(1)
        end
      end

      it 'returns false when WEBVALVE_ENABLED is unset' do
        with_env 'WEBVALVE_ENABLED' => nil do
          expect(subject.allowing?).to eq false
        end
      end
    end

    context 'in production enviroment' do
      around do |ex|
        with_rails_env 'production' do
          ex.run
        end
      end

      it 'returns false when WEBVALVE_ENABLED is unset' do
        with_env 'WEBVALVE_ENABLED' => nil do
          expect(subject.allowing?).to eq false
        end
      end


      it 'returns true when WEBVALVE_ENABLED is truthy and WEBVALVE_SERVICE_ENABLED_DEFAULT is unset' do
        with_env 'WEBVALVE_ENABLED' => '1' do
          expect(subject.allowing?).to eq true
        end

        with_env 'WEBVALVE_ENABLED' => 't' do
          expect(subject.allowing?).to eq true
        end

        with_env 'WEBVALVE_ENABLED' => 'true' do
          expect(subject.allowing?).to eq true
        end
      end

      it 'returns true when WEBVALVE_ENABLED is truthy and WEBVALVE_SERVICE_ENABLED_DEFAULT is truthy' do
        with_env 'WEBVALVE_ENABLED' => '1', 'WEBVALVE_SERVICE_ENABLED_DEFAULT' => '1' do
          expect(subject.allowing?).to eq true
        end

        with_env 'WEBVALVE_ENABLED' => 't', 'WEBVALVE_SERVICE_ENABLED_DEFAULT' => 't' do
          expect(subject.allowing?).to eq true
        end

        with_env 'WEBVALVE_ENABLED' => 'true', 'WEBVALVE_SERVICE_ENABLED_DEFAULT' => 'true' do
          expect(subject.allowing?).to eq true
        end
      end

      it 'returns false when WEBVALVE_ENABLED is truthy and WEBVALVE_SERVICE_ENABLED_DEFAULT is set and falsey' do
        with_env 'WEBVALVE_ENABLED' => '1', 'WEBVALVE_SERVICE_ENABLED_DEFAULT' => '0' do
          expect(subject.allowing?).to eq false
        end

        with_env 'WEBVALVE_ENABLED' => 't', 'WEBVALVE_SERVICE_ENABLED_DEFAULT' => 'f' do
          expect(subject.allowing?).to eq false
        end

        with_env 'WEBVALVE_ENABLED' => 'true', 'WEBVALVE_SERVICE_ENABLED_DEFAULT' => 'false' do
          expect(subject.allowing?).to eq false
        end
      end

      it 'returns false when WEBVALVE_ENABLED is falsey' do
        with_env 'WEBVALVE_ENABLED' => '0' do
          expect(subject.allowing?).to eq false
        end

        with_env 'WEBVALVE_ENABLED' => 'f' do
          expect(subject.allowing?).to eq false
        end

        with_env 'WEBVALVE_ENABLED' => 'false' do
          expect(subject.allowing?).to eq false
        end

        with_env 'WEBVALVE_ENABLED' => 'not true or false' do
          expect(subject.allowing?).to eq false
        end
      end
    end
  end

  describe '.enabled?' do
    context 'in test env' do
      around do |ex|
        with_rails_env 'test' do
          ex.run
        end
      end

      it 'returns true when WEBVALVE_ENABLED is unset' do
        with_env 'WEBVALVE_ENABLED' => nil do
          expect(subject.enabled?).to eq true
        end
      end

      it 'returns true regardless of WEBVALVE_ENABLED value' do
        allow(WebValve.logger).to receive(:warn)

        with_env 'WEBVALVE_ENABLED' => '1' do
          expect(subject.enabled?).to eq true
          expect(WebValve.logger).to have_received(:warn).at_least(1)
        end

        with_env 'WEBVALVE_ENABLED' => '0' do
          expect(subject.enabled?).to eq true
          expect(WebValve.logger).to have_received(:warn).at_least(1)
        end
      end
    end

    context 'in development env' do
      around do |ex|
        with_rails_env 'development' do
          ex.run
        end
      end

      it 'returns true when WEBVALVE_ENABLED is unset' do
        with_env 'WEBVALVE_ENABLED' => nil do
          expect(subject.enabled?).to eq true
        end
      end

      it 'returns true regardless of WEBVALVE_ENABLED value' do
        allow(WebValve.logger).to receive(:warn)

        with_env 'WEBVALVE_ENABLED' => '1' do
          expect(subject.enabled?).to eq true
          expect(WebValve.logger).to have_received(:warn).at_least(1)
        end

        with_env 'WEBVALVE_ENABLED' => '0' do
          expect(subject.enabled?).to eq true
          expect(WebValve.logger).to have_received(:warn).at_least(1)
        end
      end
    end

    context 'in production enviroment' do
      around do |ex|
        with_rails_env 'production' do
          ex.run
        end
      end

      it 'returns false when WEBVALVE_ENABLED is unset' do
        with_env 'WEBVALVE_ENABLED' => nil do
          expect(subject.enabled?).to eq false
        end
      end


      it 'returns false when WEBVALVE_ENABLED is falsey' do
        with_env 'WEBVALVE_ENABLED' => '0' do
          expect(subject.enabled?).to eq false
        end

        with_env 'WEBVALVE_ENABLED' => 'f' do
          expect(subject.enabled?).to eq false
        end

        with_env 'WEBVALVE_ENABLED' => 'false' do
          expect(subject.enabled?).to eq false
        end
      end

      it 'returns true when WEBVALVE_ENABLED is truthy' do
        with_env 'WEBVALVE_ENABLED' => '1' do
          expect(subject.enabled?).to eq true
        end

        with_env 'WEBVALVE_ENABLED' => 't' do
          expect(subject.enabled?).to eq true
        end

        with_env 'WEBVALVE_ENABLED' => 'true' do
          expect(subject.enabled?).to eq true
        end
      end

      it 'returns false when WEBVALVE_ENABLED is an invalid value' do
        with_env 'WEBVALVE_ENABLED' => 'not true or false' do
          expect(subject.enabled?).to eq false
        end
      end
    end
  end
end
