require 'spec_helper'

RSpec.describe WebValve do
  it 'delegates .setup to manager' do
    expect(described_class).to respond_to(:setup)
  end

  it 'delegates .register to manager' do
    expect(described_class).to respond_to(:register)
  end

  it 'delegates .reset to manager' do
    expect(described_class).to respond_to(:reset)
  end

  it 'delegates .allowlist_url to manager' do
    expect(described_class).to respond_to(:allowlist_url)
  end
end
