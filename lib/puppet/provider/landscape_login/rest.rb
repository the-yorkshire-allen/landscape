# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require 'fileutils'

Puppet::Type.type(:landscape_login).provide(:rest) do
  desc 'Validate authentication against Landscape login endpoints.'

  mk_resource_methods

  def exists?
    response = authenticate!
    persist_token(response['token'])
    @property_hash = { ensure: :present }
    true
  end

  def create
    response = authenticate!
    persist_token(response['token'])
    @property_hash = { ensure: :present }
  end

  def destroy
    raise Puppet::Error, 'landscape_login does not support ensure => absent'
  end

  private

  def persist_token(token)
    path = resource[:token_file]
    return if path.nil? || path.to_s.empty?

    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w', 0o600) do |file|
      file.write("#{token}\n")
    end
  rescue StandardError => e
    raise Puppet::Error, "Failed to write Landscape JWT to #{path}: #{e.message}"
  end

  def authenticate!
    if resource[:access_key]
      request_json(:post, '/login/access-key', payload: access_key_payload)
    else
      request_json(:post, '/login', payload: password_payload)
    end
  end

  def password_payload
    payload = { password: resource[:password] }
    payload[:email] = resource[:email] if resource[:email]
    payload[:identity] = resource[:identity] if resource[:identity]
    payload[:account] = resource[:account] if resource[:account]
    payload[:expiry_minutes] = resource[:expiry_minutes] if resource[:expiry_minutes]
    payload
  end

  def access_key_payload
    payload = {
      access_key: resource[:access_key],
      secret_key: resource[:secret_key],
    }
    payload[:expiry_minutes] = resource[:expiry_minutes] if resource[:expiry_minutes]
    payload
  end

  def request_json(method, path, query: nil, payload: nil)
    uri = api_uri(path, query)

    request_class = case method
                    when :get then Net::HTTP::Get
                    when :post then Net::HTTP::Post
                    when :put then Net::HTTP::Put
                    when :delete then Net::HTTP::Delete
                    else
                      raise Puppet::Error, "Unsupported HTTP method: #{method}"
                    end

    request = request_class.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate(payload) if payload

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    unless response.code.to_i.between?(200, 299)
      raise Puppet::Error,
            "Landscape API #{method.to_s.upcase} #{uri} failed: #{response.code} #{response.message} #{response.body}"
    end

    return {} if response.body.nil? || response.body.empty?

    parsed = JSON.parse(response.body)
    raise Puppet::Error, "Landscape login response did not include token for #{uri}" unless parsed['token']

    parsed
  rescue JSON::ParserError => e
    raise Puppet::Error, "Landscape API returned invalid JSON for #{method.to_s.upcase} #{uri}: #{e.message}"
  end

  def api_uri(path, query = nil)
    base = resource[:api_url].to_s.sub(%r{/*$}, '')
    prefix = resource[:api_prefix].to_s
    prefix = "/#{prefix}" unless prefix.start_with?('/')
    uri = URI.parse("#{base}#{prefix}#{path}")
    uri.query = URI.encode_www_form(query) if query && !query.empty?
    uri
  end
end
