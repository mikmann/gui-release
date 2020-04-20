# frozen_string_literal: true

require 'httparty'
# TODO: http://localhost:4567 check if the url is valid
#
# Send a POST or GET request to particular endpoints
#
class HTTPRestAdapter
  #
  # The default timeout for the external Rest API requests.
  #
  DEFAULT_TIMEOUT = 60

  attr_reader :base_url

  def initialize(base_url)
    @base_url = check_base_url!(base_url)
  end

  def http_get(url, body = nil)
    params = {
      headers: headers_hash,
      timeout: DEFAULT_TIMEOUT
    }
    params[:body] = body.to_json unless body.nil?
    response = HTTParty.get("#{base_url}/#{url}", params)
    check_response!(response)
    response
  end

  def http_post(url, body = nil)
    params = {
      headers: headers_hash,
      timeout: DEFAULT_TIMEOUT
    }
    params[:body] = body.to_json unless body.nil?

    response = HTTParty.post("#{base_url}/#{url}", params)
    check_response!(response)
    response
  end

  def http_delete(url, body = nil)
    params = {
      headers: headers_hash,
      timeout: DEFAULT_TIMEOUT
    }
    params[:body] = body.to_json unless body.nil?
    puts params.inspect
    response = HTTParty.delete("#{base_url}/#{url}", params)
    check_response!(response)
    response
  end

  private

  def headers_hash
    { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  end

  def check_base_url!(base_url)
    raise 'Not base url set' if base_url.nil?

    base_url
  end

  def check_response!(result)
    # only successful operation codes allowed
    return if (200..299).include?(result.code)

    # logger.error "Invalid result from API endpoint HTTP Return Code=#{result.code}"
    # logger.error "Received error message: #{result['error']}" unless result['error'].nil?
    raise "Status code was #{result.code}"
  end
end
