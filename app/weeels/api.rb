module Weeels
  class API
    require 'net/http'
    require 'json'
    
    class APIError < StandardError; end

    def initialize(email, password = '')
      sign_in(email, password)
    end

    def request(path, params = {})
      if port
        uri = URI("http://#{base_url}:#{port}#{path}")
      else
        uri = URI("http://#{base_url}#{path}")
      end
      uri.query = URI.encode_www_form(params.merge(credential_params))
      res = Net::HTTP.get_response(uri)

      raise APIError.new(res.error) unless res.is_a?(Net::HTTPSuccess)
      JSON.parse(res.body)
    end

    def post(path, data = {})
      req = Net::HTTP::Post.new(path, {'Content-Type' =>'application/json'})
      req.body = data.merge(credential_params).to_json
      response = Net::HTTP.new(base_url, port).start {|http| http.request(req) }
      raise APIError.new(response.error) unless response.is_a?(Net::HTTPSuccess)
      puts "Response #{response.code} #{response.message}"
      JSON.parse(response.body)
    end

    def credential_params
      if @auth_token
        { auth_token: @auth_token }
      else
        {}
      end
    end

    private

    def sign_in(email, password)
      sign_in_response = post('/users/sessions.json', user: {email: email, password: password})
      @auth_token = sign_in_response['user']['auth_token']
    end

    def base_url
      'admin.bandwagon.io'
    end

    def port
      nil
    end
  end

  def self.api_client
    @api_client ||= get_api_client
  end

  def self.get_api_client
    API.new('dev_accounts@bandwagon.io', 'starlab2015')
  end
end