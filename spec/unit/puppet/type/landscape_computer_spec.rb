# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:landscape_computer) do
  let(:resource) do
    described_class.new(
      name: 23,
      ensure: :present,
      api_url: 'https://landscape.example.com',
      api_token: 'token',
    )
  end

  it 'accepts an integer computer id as namevar' do
    expect(resource[:name]).to eq(23)
  end

  it 'requires api_url and api_token' do
    expect do
      described_class.new(name: 1, ensure: :present, api_token: 'token')
    end.to raise_error(Puppet::Error, /api_url is a required parameter/)

    expect do
      described_class.new(name: 1, ensure: :present, api_url: 'https://landscape.example.com')
    end.to raise_error(Puppet::Error, /api_token is a required parameter/)
  end

  it 'rejects non-integer names' do
    expect do
      described_class.new(
        name: 'host-1',
        ensure: :present,
        api_url: 'https://landscape.example.com',
        api_token: 'token',
      )
    end.to raise_error(ArgumentError, /computer id must be an integer/)
  end
end
