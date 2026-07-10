# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

Puppet::Type.type(:landscape_apt_source).provide(:rest) do
  desc 'Manage Landscape APT sources over the Landscape repositories REST endpoints.'

  mk_resource_methods

  def exists?
    apt_source = fetch_apt_source

    if apt_source
      @property_hash = {
        ensure: :present,
        name: apt_source['name'],
        id: apt_source['id'],
      }
      true
    else
      @property_hash = { ensure: :absent }
      false
    end
  end

  def create
    raise Puppet::Error,
          'Landscape REST API does not provide POST /repository/apt-source in this endpoint set; creation is unsupported by this provider.'
  end

  def destroy
    apt_source = fetch_apt_source
    return unless apt_source

    query = {}
    query[:disassociate_profiles] = 'true' if resource[:disassociate_profiles].to_s == 'true'

    request_json(:delete, "/repository/apt-source/#{apt_source['id']}", query: query)
    @property_hash.clear
    @property_hash[:ensure] = :absent
  end

  private

  def fetch_apt_source
    response = request_json(:get, '/repository/apt-source', query: { names: resource[:name] })
    results = response.is_a?(Hash) ? response.fetch('results', []) : []
    results.find { |entry| entry['name'] == resource[:name] }
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
    request['Authorization'] = "Bearer #{resource[:api_token]}"
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
end
