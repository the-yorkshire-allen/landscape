# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:landscape_apt_source).provider(:rest)

describe provider_class do
  let(:resource) do
    Puppet::Type.type(:landscape_apt_source).new(
      name: 'bionic-mirror',
      ensure: :present,
      api_url: 'https://landscape.example.com',
      api_token: 'token',
    )
  end

  let(:provider) { described_class.new(resource) }

  describe '#exists?' do
    it 'returns true when apt source exists' do
      allow(provider).to receive(:request_json).and_return(
        {
          'results' => [
            {
              'id' => 101,
              'name' => 'bionic-mirror',
            },
          ],
        },
      )

      expect(provider.exists?).to eq(true)
    end

    it 'returns false when apt source does not exist' do
      allow(provider).to receive(:request_json).and_return({ 'results' => [] })

      expect(provider.exists?).to eq(false)
    end
  end

  describe '#destroy' do
    it 'sends a DELETE for the discovered apt source id' do
      allow(provider).to receive(:fetch_apt_source).and_return({ 'id' => 101, 'name' => 'bionic-mirror' })

      expect(provider).to receive(:request_json).with(
        :delete,
        '/repository/apt-source/101',
        query: {},
      )

      provider.destroy
    end
  end

  describe '#create' do
    it 'raises because apt source creation is unsupported here' do
      expect { provider.create }.to raise_error(Puppet::Error, /creation is unsupported/i)
    end
  end
end
