# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

Puppet::Functions.create_function(:'landscape::computer_check') do
  dispatch :computer_check do
    param 'Integer', :computer_id
    param 'String', :api_url
    optional_param 'Optional[String]', :api_token
    optional_param 'Optional[String]', :api_token_file
    optional_param 'String', :api_prefix
    return_type 'Hash'
  end

  def computer_check(computer_id, api_url, api_token = nil, api_token_file = nil, api_prefix = '/api/v2')
    token = resolve_token(api_token, api_token_file)
    base = api_url.sub(%r{/*$}, '')
    prefix = api_prefix.start_with?('/') ? api_prefix : "/#{api_prefix}"
    uri = URI.parse("#{base}#{prefix}/computers/#{computer_id}")

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{token}"
    request['Content-Type'] = 'application/json'

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    status = response.code.to_i

    if status == 404
      return {
        'exists' => false,
        'status_code' => status,
        'computer_id' => computer_id,
        'data' => {},
      }
    end

    unless status.between?(200, 299)
      raise Puppet::Error,
            "Landscape API GET #{uri} failed: #{response.code} #{response.message} #{response.body}"
    end

    data = parse_body(response.body)

    {
      'exists' => true,
      'status_code' => status,
      'computer_id' => computer_id,
      'data' => data,
    }
  end

  private

  def resolve_token(api_token, api_token_file)
    token = api_token.to_s.strip
    return token unless token.empty?

    file_path = api_token_file.to_s.strip
    if file_path.empty?
      raise Puppet::Error, 'One of api_token or api_token_file must be provided'
    end

    unless file_path.start_with?('/')
      raise Puppet::Error, "api_token_file must be an absolute path: #{file_path}"
    end

    unless File.file?(file_path)
      raise Puppet::Error, "api_token_file does not exist: #{file_path}"
    end

    file_token = File.read(file_path).strip
    raise Puppet::Error, "api_token_file is empty: #{file_path}" if file_token.empty?

    file_token
  rescue StandardError => e
    raise Puppet::Error, "Failed to resolve API token: #{e.message}"
  end

  def parse_body(body)
    return {} if body.nil? || body.strip.empty?

    JSON.parse(body)
  rescue JSON::ParserError => e
    raise Puppet::Error, "Landscape API returned invalid JSON: #{e.message}"
  end
end
