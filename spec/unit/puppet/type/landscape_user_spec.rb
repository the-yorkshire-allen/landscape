# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:landscape_user) do
  let(:resource) do
    described_class.new(
      name: 'john',
      ensure: :present,
      computer_ids: [1, 2],
      api_url: 'https://landscape.example.com',
      api_token: 'token',
    )
  end

  it 'accepts required attributes' do
    expect(resource[:name]).to eq('john')
    expect(resource[:computer_ids]).to eq([1, 2])
  end

  it 'defaults api_prefix to /api/v2' do
    expect(resource[:api_prefix]).to eq('/api/v2')
  end

  it 'requires computer_ids' do
    expect do
      described_class.new(
        name: 'john',
        ensure: :present,
        api_url: 'https://landscape.example.com',
        api_token: 'token',
      )
    end.to raise_error(Puppet::Error, /computer_ids is a required parameter/)
  end

  it 'requires api_url and api_token' do
    expect do
      described_class.new(name: 'john', ensure: :present, computer_ids: [1], api_token: 'token')
    end.to raise_error(Puppet::Error, /api_url is a required parameter/)

    expect do
      described_class.new(name: 'john', ensure: :present, computer_ids: [1], api_url: 'https://landscape.example.com')
    end.to raise_error(Puppet::Error, /api_token is a required parameter/)
  end

  it 'validates api_url format' do
    expect do
      described_class.new(
        name: 'john',
        ensure: :present,
        computer_ids: [1],
        api_url: 'landscape.example.com',
        api_token: 'token',
      )
    end.to raise_error(ArgumentError, /api_url must be an absolute http\/https URL/)
  end
end
