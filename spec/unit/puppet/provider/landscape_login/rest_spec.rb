# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:landscape_login).provider(:rest)

describe provider_class do
  describe '#exists?' do
    it 'validates credentials with /login for email/password' do
      resource = Puppet::Type.type(:landscape_login).new(
        name: 'session-check',
        ensure: :present,
        api_url: 'https://landscape.example.com',
        email: 'john@example.com',
        password: 'pwd',
      )

      provider = described_class.new(resource)

      expect(provider).to receive(:request_json).with(
        :post,
        '/login',
        payload: hash_including(email: 'john@example.com', password: 'pwd'),
      ).and_return({ 'token' => 'jwt' })

      expect(provider.exists?).to eq(true)
    end

    it 'validates credentials with /login/access-key for key auth' do
      resource = Puppet::Type.type(:landscape_login).new(
        name: 'session-check',
        ensure: :present,
        api_url: 'https://landscape.example.com',
        access_key: 'AK',
        secret_key: 'SK',
      )

      provider = described_class.new(resource)

      expect(provider).to receive(:request_json).with(
        :post,
        '/login/access-key',
        payload: hash_including(access_key: 'AK', secret_key: 'SK'),
      ).and_return({ 'token' => 'jwt' })

      expect(provider.exists?).to eq(true)
    end
  end
end
