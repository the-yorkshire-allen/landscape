# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:landscape_computer).provider(:rest)

describe provider_class do
  let(:resource) do
    Puppet::Type.type(:landscape_computer).new(
      name: 23,
      ensure: :present,
      api_url: 'https://landscape.example.com',
      api_token: 'token',
    )
  end

  let(:provider) { described_class.new(resource) }

  describe '#exists?' do
    it 'returns true when computer exists' do
      allow(provider).to receive(:request_json).and_return({ 'id' => 23, 'title' => 'node-23' })

      expect(provider.exists?).to eq(true)
    end

    it 'returns false on 404 response' do
      allow(provider).to receive(:request_json).and_raise(Puppet::Error, 'Landscape API GET x failed: 404 Not Found')

      expect(provider.exists?).to eq(false)
    end
  end

  describe '#destroy' do
    it 'sends POST /computers:delete with id payload' do
      expect(provider).to receive(:request_json).with(
        :post,
        '/computers:delete',
        payload: { computer_ids: [23] },
      )

      provider.destroy
    end
  end

  describe '#create' do
    it 'raises because creation is not supported by this endpoint' do
      expect { provider.create }.to raise_error(Puppet::Error, /does not support computer creation/i)
    end
  end
end
