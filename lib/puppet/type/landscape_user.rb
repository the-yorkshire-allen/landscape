# frozen_string_literal: true

Puppet::Type.newtype(:landscape_user) do
  @doc = 'Manage users on Ubuntu Landscape managed computers through the REST API.'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The username to manage.'

    validate do |value|
      raise ArgumentError, 'username must not be empty' if value.to_s.strip.empty?
    end
  end

  newparam(:computer_ids, array_matching: :all) do
    desc 'One or more Landscape computer IDs where this user should be managed.'

    isrequired

    validate do |value|
      Integer(value)
    rescue StandardError
      raise ArgumentError, "computer_ids entries must be integers, got #{value.inspect}"
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

    isrequired

    validate do |value|
      raise ArgumentError, 'api_token must not be empty' if value.to_s.strip.empty?
    end
  end

  newparam(:api_prefix) do
    desc 'API prefix path. Default is /api/v2.'

    defaultto '/api/v2'
  end

  newparam(:password) do
    desc 'Password to set when creating or updating this Landscape user.'

    validate do |value|
      next if value.nil?

      raise ArgumentError, 'password must not be empty when provided' if value.to_s.empty?
    end
  end

  newproperty(:full_name) do
    desc 'Display name for the Landscape user (maps to API field name).'
  end

  newproperty(:location) do
    desc 'Location for the Landscape user.'
  end

  newproperty(:home_phone) do
    desc 'Home phone number for the Landscape user.'
  end

  newproperty(:work_phone) do
    desc 'Work phone number for the Landscape user.'
  end

  newproperty(:primary_groupname) do
    desc 'Primary group name for the Landscape user.'
  end
end
