import Config

# When authenticating, you should see your rate limit bumped to 5,000 requests an hour, as indicated in the X-RateLimit-Limit header.
# See https://docs.github.com/en/rest/guides/getting-started-with-the-rest-api#authentication
config :nerves_system_compatibility,
  github_api_token: System.get_env("GITHUB_API_TOKEN")

if Mix.env() == :test do
  # https://github.com/parroty/exvcr
  config :exvcr,
    vcr_cassette_library_dir: "test/vcr_cassettes",
    custom_cassette_library_dir: "test/custom_cassettes",
    filter_sensitive_data: [
      [pattern: "<PASSWORD>.+</PASSWORD>", placeholder: "PASSWORD_PLACEHOLDER"]
    ],
    filter_url_params: false,
    filter_request_headers: ["Authorization"],
    response_headers_blacklist: []
end
