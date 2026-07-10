# frozen_string_literal: true

Puppet::Type.newtype(:landscape_computer) do
  @doc = 'Manage Landscape computers through the REST API.'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The Landscape computer ID.'

    validate do |value|
      Integer(value)
    rescue StandardError
      raise ArgumentError, "computer id must be an integer, got #{value.inspect}"
    end

    munge do |value|
      Integer(value)
    end
  end

  newparam(:api_url) do
    desc 'Landscape API base URL, for example https://landscape.example.com.'

    isrequired

    validate do |value|
      raise ArgumentError, 'api_url must be an absolute http/https URL' unless value =~ %r{\Ahttps?://}i
    end
  end

  newparam(:api_token) do
    desc 'Bearer token used to authenticate to the Landscape API.'

    validate do |value|
      raise ArgumentError, 'api_token must not be empty' if value.to_s.strip.empty?
    end
  end

  newparam(:api_token_file) do
    desc 'Absolute path to a file containing a bearer token used to authenticate to the Landscape API.'

    validate do |value|
      raise ArgumentError, 'api_token_file must be an absolute path' unless value.start_with?('/')
    end
  end

  newparam(:api_prefix) do
    desc 'API prefix path. Default is /api/v2.'

    defaultto '/api/v2'
  end

  validate do
    has_inline_token = !self[:api_token].nil? && !self[:api_token].to_s.strip.empty?
    has_token_file = !self[:api_token_file].nil? && !self[:api_token_file].to_s.strip.empty?

    unless has_inline_token || has_token_file
      raise ArgumentError, 'One of api_token or api_token_file must be provided'
    end
  end
end
