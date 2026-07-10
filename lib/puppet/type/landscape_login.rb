# frozen_string_literal: true

Puppet::Type.newtype(:landscape_login) do
  @doc = 'Validate Landscape REST login credentials using the login endpoints.'

  ensurable

  newparam(:name, namevar: true) do
    desc 'An arbitrary resource title for the login session check.'
  end

  newparam(:api_url) do
    desc 'Landscape API base URL, for example https://landscape.example.com.'

    isrequired

    validate do |value|
      raise ArgumentError, 'api_url must be an absolute http/https URL' unless value =~ %r{\Ahttps?://}i
    end
  end

  newparam(:api_prefix) do
    desc 'API prefix path. Default is /api/v2.'

    defaultto '/api/v2'
  end

  newparam(:token_file) do
    desc 'Optional absolute path where the JWT token will be written after successful login.'

    validate do |value|
      raise ArgumentError, 'token_file must be an absolute path' unless value.start_with?('/')
    end
  end

  newparam(:password) do
    desc 'Password for email/identity login.'
  end

  newparam(:email) do
    desc 'Email for standard login endpoint.'
  end

  newparam(:identity) do
    desc 'Identity for PAM login endpoint.'
  end

  newparam(:account) do
    desc 'Optional account to login against.'
  end

  newparam(:expiry_minutes) do
    desc 'Optional token expiry in minutes.'

    munge do |value|
      Integer(value)
    end
  end

  newparam(:access_key) do
    desc 'Access key for /login/access-key authentication.'
  end

  newparam(:secret_key) do
    desc 'Secret key for /login/access-key authentication.'
  end

  validate do
    using_access_key = !self[:access_key].nil? || !self[:secret_key].nil?

    if using_access_key
      raise ArgumentError, 'access_key and secret_key must be provided together' if self[:access_key].nil? || self[:secret_key].nil?
      next
    end

    raise ArgumentError, 'password is required for /login email/identity authentication' if self[:password].nil?

    has_email = !self[:email].nil?
    has_identity = !self[:identity].nil?

    unless has_email ^ has_identity
      raise ArgumentError, 'exactly one of email or identity must be provided for /login'
    end
  end
end
