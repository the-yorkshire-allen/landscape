# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

Puppet::Type.type(:landscape_user).provide(:rest) do
  desc 'Manage Landscape users over the Landscape REST API.'

  mk_resource_methods

  def exists?
    user = fetch_user
    if user
      @property_hash = {
        ensure: :present,
        name: user['username'],
        full_name: user['name'],
        location: user['location'],
        home_phone: user['home_phone'],
        work_phone: user['work_phone'],
        primary_groupname: user['primary_groupname'],
      }
      true
    else
      @property_hash = { ensure: :absent }
      false
    end
  end

  def create
    payload = {
      computer_ids: computer_ids,
      username: resource[:name],
      name: resource[:full_name] || resource[:name],
      password: resource[:password],
    }

    %i[location home_phone work_phone primary_groupname].each do |field|
      value = resource[field]
      payload[field] = value unless value.nil?
    end

    if payload[:password].nil?
      raise Puppet::Error, 'password is required by Landscape when creating a user'
    end

    request_json(:post, '/users', payload: payload)
    @property_hash[:ensure] = :present
  end

  def destroy
    request_json(
      :delete,
      '/users',
      query: {
        computer_ids: computer_ids.join(','),
        usernames: resource[:name],
      },
    )

    @property_hash.clear
    @property_hash[:ensure] = :absent
  end

  def flush
    return unless @property_hash[:ensure] == :present

    payload = {
      computer_ids: computer_ids,
      username: resource[:name],
    }

    update_field(payload, :name, :full_name)
    update_field(payload, :location, :location)
    update_field(payload, :home_phone, :home_phone)
    update_field(payload, :work_phone, :work_phone)
    update_field(payload, :primary_groupname, :primary_groupname)

    if resource[:password] && !resource[:password].to_s.empty?
      payload[:password] = resource[:password]
    end

    return if payload.keys.sort == %i[computer_ids username]

    request_json(:put, '/users', payload: payload)
    @property_hash = @property_hash.merge(
      full_name: resource[:full_name],
      location: resource[:location],
      home_phone: resource[:home_phone],
      work_phone: resource[:work_phone],
      primary_groupname: resource[:primary_groupname],
    )
  end

  private

  def update_field(payload, api_field, prop)
    current = @property_hash[prop]
    desired = resource[prop]
    return if desired == current

    payload[api_field] = desired
  end

  def fetch_user
    response = request_json(:get, '/users', query: { computer_id: computer_ids.first })
    results = response.is_a?(Hash) ? response.fetch('results', []) : []
    results.find { |user| user['username'] == resource[:name] }
  end

  def computer_ids
    Array(resource[:computer_ids]).map(&:to_i)
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
    request['Authorization'] = "Bearer #{auth_token}"
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

    JSON.parse(response.body)
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

  def auth_token
    token = resource[:api_token]
    return token unless token.nil? || token.to_s.strip.empty?

    token_file = resource[:api_token_file]
    raise Puppet::Error, 'No api_token or api_token_file was provided' if token_file.nil? || token_file.to_s.empty?

    unless File.file?(token_file)
      raise Puppet::Error, "api_token_file does not exist: #{token_file}"
    end

    file_token = File.read(token_file).strip
    raise Puppet::Error, "api_token_file is empty: #{token_file}" if file_token.empty?

    file_token
  end
end
