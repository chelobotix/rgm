require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.ignore_localhost = true
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true

  config.before_record do |interaction|
    %w[
      Authorization
      X-Api-Key
      X-Access-Token
    ].each do |header|
      interaction.request.headers[header]&.map! { "<#{header.upcase.gsub('-', '_')}>" }
    end
  end

  config.filter_sensitive_data('<GEMINI_API_KEY>') { ENV['gemini_api_key'] }
  config.filter_sensitive_data('<GEMINI_BASE_URL>') { ENV['gemini_base_url'] }

  config.default_cassette_options = {
    match_requests_on: [ :method, :uri ],
    record: :once
  }
end
