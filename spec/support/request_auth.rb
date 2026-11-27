# The dev container may export BASIC_AUTH_* (ngrok protection); request specs run without it.
RSpec.configure do |config|
  config.before(:each, type: :request) do
    stub_const("ENV", ENV.to_h.except("BASIC_AUTH_USER", "BASIC_AUTH_PASSWORD"))
  end
end
