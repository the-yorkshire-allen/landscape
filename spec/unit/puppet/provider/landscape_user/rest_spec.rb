# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:landscape_user).provider(:rest)

describe provider_class do
  let(:resource) do
    Puppet::Type.type(:landscape_user).new(
      name: 'john',
      ensure: :present,
      computer_ids: [23],
      api_url: 'https://landscape.example.com',
      api_token: 'token',
      full_name: 'John Smith',
    )
  end

  let(:provider) { described_class.new(resource) }

  describe '#exists?' do
    it 'returns true when the user is present and caches properties' do
      allow(provider).to receive(:request_json).and_return(
        {
          'results' => [
            {
              'username' => 'john',
              'name' => 'John Smith',
              'location' => 'NYC',
              'home_phone' => nil,
              'work_phone' => nil,
              'primary_groupname' => 'users',
            },
          ],
        },
      )

      expect(provider.exists?).to eq(true)
    end

    it 'returns false when the user is absent' do
      allow(provider).to receive(:request_json).and_return({ 'results' => [] })

      expect(provider.exists?).to eq(false)
    end
  end

  describe '#create' do
    it 'sends a POST /users request with required fields' do
      expect(provider).to receive(:request_json).with(
        :post,
        '/users',
        payload: hash_including(
          computer_ids: [23],
          username: 'john',
          name: 'John Smith',
          password: 'secret',
        ),
      )

      resource[:password] = 'secret'
      provider.create
    end
  end

  describe '#destroy' do
    it 'sends a DELETE /users request' do
      expect(provider).to receive(:request_json).with(
        :delete,
        '/users',
        query: {
          computer_ids: '23',
          usernames: 'john',
        },
      )

      provider.destroy
    end
  end

  describe '#flush' do
    it 'sends a PUT /users request when managed fields changed' do
      provider.instance_variable_set(
        :@property_hash,
        {
          ensure: :present,
          full_name: 'Old Name',
          location: nil,
          home_phone: nil,
          work_phone: nil,
          primary_groupname: nil,
        },
      )

      expect(provider).to receive(:request_json).with(
        :put,
        '/users',
        payload: hash_including(
          computer_ids: [23],
          username: 'john',
          name: 'John Smith',
        ),
      )

      provider.flush
    end
  end
end
