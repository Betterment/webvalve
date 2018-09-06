require 'spec_helper'

RSpec.describe WebValve::WhitelistUrlConfig do
  subject { described_class.new url: 'http://bar.dev' }

  describe 'constructor' do
    it 'defaults whitelist_in_spec to false' do
      expect(subject.whitelist_in_spec).to eq false
    end
  end
end
