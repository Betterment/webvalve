require 'spec_helper'

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
  end
end
