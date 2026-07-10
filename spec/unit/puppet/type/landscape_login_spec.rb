# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:landscape_login) do
  it 'accepts email/password login' do
    resource = described_class.new(
      name: 'session-check',
      ensure: :present,
      api_url: 'https://landscape.example.com',
      email: 'john@example.com',
      password: 'pwd',
    )

    expect(resource[:email]).to eq('john@example.com')
  end

  it 'accepts access-key login' do
    resource = described_class.new(
      name: 'session-check',
      ensure: :present,
      api_url: 'https://landscape.example.com',
      access_key: 'AK',
      secret_key: 'SK',
    )

    expect(resource[:access_key]).to eq('AK')
  end

  it 'requires exactly one of email or identity for password auth' do
    expect do
      described_class.new(
        name: 'bad',
        ensure: :present,
        api_url: 'https://landscape.example.com',
        password: 'pwd',
        email: 'john@example.com',
        identity: 'john',
      )
    end.to raise_error(ArgumentError, /exactly one of email or identity/)
  end
end
