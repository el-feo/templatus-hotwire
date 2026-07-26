class DashboardsController < ApplicationController
  include TenantScoped

  def show
    # No `where(organization: ...)` anywhere: acts_as_tenant narrows Membership
    # to the organization TenantScoped resolved from the path.
    @members_count = Membership.count
  end
end
