# frozen_string_literal: true

require 'httparty'

class HTTPRestAdapter
  #
  # The default timeout for the external Rest API requests.
  #
  DEFAULT_TIMEOUT = 60

  attr_reader :base_url

  def initialize(base_url)
    @base_url = base_url
  end

  def http_get(url, body = nil)
    params = {
      headers: headers_hash,
      timeout: DEFAULT_TIMEOUT
    }
    params[:body] = body.to_json unless body.nil?

    HTTParty.get("#{base_url}/#{url}", params)
  end

  def http_post(url, body = nil)
    params = {
      headers: headers_hash,
      timeout: DEFAULT_TIMEOUT
    }
    params[:body] = body.to_json unless body.nil?

    response = HTTParty.post("#{base_url}/#{url}", params)

    response
  end

  private

  def headers_hash
    { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  end
end

puts HTTPRestAdapter.new('http://localhost:4567').http_post('parser', 'tokenshallo')
puts HTTPRestAdapter.new('http://localhost:4567').http_get('parser', 'tokens': %w[LPAR DIGIT])
