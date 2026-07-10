# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:landscape_apt_source) do
  let(:resource) do
    described_class.new(
      name: 'bionic-mirror',
      ensure: :present,
      api_url: 'https://landscape.example.com',
      api_token: 'token',
    )
  end

  it 'accepts required attributes' do
    expect(resource[:name]).to eq('bionic-mirror')
    expect(resource[:api_prefix]).to eq('/api/v2')
  end

  it 'defaults disassociate_profiles to false' do
    expect(resource[:disassociate_profiles]).to eq(:false)
  end

  it 'requires api_url and api_token' do
    expect do
      described_class.new(name: 'x', ensure: :present, api_token: 'token')
    end.to raise_error(Puppet::Error, /api_url is a required parameter/)

    expect do
      described_class.new(name: 'x', ensure: :present, api_url: 'https://landscape.example.com')
    end.to raise_error(Puppet::Error, /api_token is a required parameter/)
  end
end
