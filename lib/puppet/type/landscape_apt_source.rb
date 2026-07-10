# frozen_string_literal: true

Puppet::Type.newtype(:landscape_apt_source) do
  @doc = 'Manage Landscape repository APT sources through the REST API.'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The Landscape APT source name.'

    validate do |value|
      raise ArgumentError, 'name must not be empty' if value.to_s.strip.empty?
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

  newparam(:disassociate_profiles) do
    desc 'When deleting an APT source, remove profile associations as well.'

    newvalues(:true, :false)
    defaultto :false
  end
end
