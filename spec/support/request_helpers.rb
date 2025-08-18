module RequestHelpers
  def json_headers
    {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
  end

  def auth_headers(token)
    json_headers.merge('Authorization' => "Bearer #{token}")
  end

  def parsed_response
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end