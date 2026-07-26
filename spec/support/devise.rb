RSpec.configure do |config|
  # `sign_in`/`sign_out` in request specs, without going through the form.
  config.include Devise::Test::IntegrationHelpers, type: :request

  # Components render inside the application layout, whose header asks Devise
  # who is signed in. There is no real request behind a component spec and so no
  # Warden proxy to ask, which Devise answers with an exception rather than with
  # "nobody" - so hand the rendering context a proxy that has nobody signed in.
  config.before(type: :component) do
    manager = Warden::Manager.new(nil) { |warden_config| warden_config.merge!(Devise.warden_config) }

    vc_test_request.env['warden'] = Warden::Proxy.new(vc_test_request.env, manager)
  end
end
