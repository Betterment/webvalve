require 'rails_helper'

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

  it 'delegates .whitelist_url to manager' do
    expect(described_class).to respond_to(:whitelist_url)
  end
end
