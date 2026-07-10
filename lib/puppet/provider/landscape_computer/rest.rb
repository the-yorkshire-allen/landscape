# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

Puppet::Type.type(:landscape_computer).provide(:rest) do
  desc 'Manage Landscape computers over the Computers REST endpoints.'

  mk_resource_methods

  def exists?
    computer = fetch_computer

    if computer
      @property_hash = {
        ensure: :present,
        name: computer['id'],
      }
      true
    else
      @property_hash = { ensure: :absent }
      false
    end
  end

  def create
    raise Puppet::Error,
          'Landscape REST API does not support computer creation through /computers; registration is handled by Landscape client enrollment.'
  end

  def destroy
    request_json(:post, '/computers:delete', payload: { computer_ids: [computer_id] })

    @property_hash.clear
    @property_hash[:ensure] = :absent
  end

  private

  def fetch_computer
    request_json(:get, "/computers/#{computer_id}")
  rescue Puppet::Error => e
    return nil if e.message.include?(' 404 ')

    raise
  end

  def computer_id
    Integer(resource[:name])
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
