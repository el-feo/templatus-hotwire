module TenantHelpers
  # With `require_tenant` on, even `Membership.new` goes through the default
  # scope - so a membership can only be built while its own organization is the
  # current tenant. That is what a request does anyway; this is the same thing
  # for specs that set up data before the request.
  def create_membership(organization:, **attributes)
    ActsAsTenant.with_tenant(organization) { create(:membership, organization:, **attributes) }
  end
end

RSpec.configure do |config|
  config.include TenantHelpers

  # The current tenant lives in per-request state that no transaction rolls
  # back, so without this an organization set by one example would still be
  # current in the next one. It has to be an `after` hook: a `before` one would
  # run inside an example's `around`, undoing the tenant that just set up.
  config.after { ActsAsTenant.current_tenant = nil }
end
