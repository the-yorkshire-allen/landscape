# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

Puppet::Functions.create_function(:'landscape::login_jwt') do
  # Returns JWT as an in-memory String only. This function never writes tokens to disk.
  dispatch :login_jwt do
    param 'String', :api_url
    optional_param 'Optional[String]', :email
    optional_param 'Optional[String]', :password
    optional_param 'Optional[String]', :identity
    optional_param 'Optional[String]', :account
    optional_param 'Optional[Integer]', :expiry_minutes
    optional_param 'Optional[String]', :access_key
    optional_param 'Optional[String]', :secret_key
    optional_param 'String', :api_prefix
    return_type 'String'
  end

  def login_jwt(api_url,
                email = nil,
                password = nil,
                identity = nil,
                account = nil,
                expiry_minutes = nil,
                access_key = nil,
                secret_key = nil,
                api_prefix = '/api/v2')
    auth_mode = validate_auth_mode(email, password, identity, access_key, secret_key)

    base = api_url.sub(%r{/*$}, '')
    prefix = api_prefix.start_with?('/') ? api_prefix : "/#{api_prefix}"

    if auth_mode == :access_key
      uri = URI.parse("#{base}#{prefix}/login/access-key")
      payload = {
        access_key: access_key,
        secret_key: secret_key,
      }
    else
      uri = URI.parse("#{base}#{prefix}/login")
      payload = { password: password }
      payload[:email] = email if present?(email)
      payload[:identity] = identity if present?(identity)
      payload[:account] = account if present?(account)
    end

    payload[:expiry_minutes] = expiry_minutes unless expiry_minutes.nil?

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate(payload)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    unless response.code.to_i.between?(200, 299)
      raise Puppet::Error,
            "Landscape API POST #{uri} failed: #{response.code} #{response.message} #{response.body}"
    end

    parsed = parse_body(response.body)
    token = parsed['token']

    if token.nil? || token.to_s.strip.empty?
      raise Puppet::Error, "Landscape login response did not include a token for #{uri}"
    end

    token
  end

  private

  def validate_auth_mode(email, password, identity, access_key, secret_key)
    using_access_key = present?(access_key) || present?(secret_key)

    if using_access_key
      unless present?(access_key) && present?(secret_key)
        raise Puppet::Error, 'access_key and secret_key must be provided together'
      end

      if present?(email) || present?(identity) || present?(password)
        raise Puppet::Error, 'Do not mix access_key/secret_key with email/identity/password login arguments'
      end

      return :access_key
    end

    unless present?(password)
      raise Puppet::Error, 'password is required for email/identity login'
    end

    has_email = present?(email)
    has_identity = present?(identity)

    unless has_email ^ has_identity
      raise Puppet::Error, 'exactly one of email or identity must be provided for /login'
    end

    :password
  end

  def parse_body(body)
    return {} if body.nil? || body.strip.empty?

    JSON.parse(body)
  rescue JSON::ParserError => e
    raise Puppet::Error, "Landscape API returned invalid JSON: #{e.message}"
  end

  def present?(value)
    !value.nil? && !value.to_s.strip.empty?
  end
end
