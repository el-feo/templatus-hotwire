class Current < ActiveSupport::CurrentAttributes
  # The signed-in user's membership in the current organization. It carries the
  # role, so views and controllers can ask what this user is allowed to do
  # without querying for it again. Set by the TenantScoped concern, and reset
  # between requests by Rails.
  attribute :membership

  # acts_as_tenant already keeps the current tenant per request, so this reads
  # it back instead of storing a second copy that could drift out of sync.
  def organization
    ActsAsTenant.current_tenant
  end
end
