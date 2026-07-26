# Everything under /org/:organization_id/ includes this: it resolves the
# organization from the path, refuses requests from non-members, and hands
# acts_as_tenant the tenant that scopes every tenant-scoped query for the rest
# of the request.
module TenantScoped
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    before_action :set_current_organization
  end

  private

  # The lookup goes through the user's own memberships on purpose: a slug the
  # signed-in user is not a member of raises RecordNotFound, exactly like a slug
  # that does not exist. Answering both the same way keeps the URL space from
  # confirming which organizations are real.
  #
  # `without_tenant` is needed because Membership - which the join goes through
  # - is tenant-scoped, and the tenant is precisely what this method is about to
  # work out.
  def set_current_organization
    organization =
      ActsAsTenant.without_tenant do
        current_user.organizations.from_param!(params[:organization_id])
      end

    ActsAsTenant.current_tenant = organization
    Current.membership = current_user.memberships.find_by!(organization_id: organization.id)
  end

  def require_admin
    require_role(:admin)
  end

  def require_member
    require_role(:member)
  end

  def require_role(role)
    return if Current.membership.at_least?(role)

    # 303, because this also answers non-GET requests, and Turbo only follows a
    # redirect away from a form submission when it sees See Other.
    redirect_to organization_root_path(Current.organization),
                alert: t('tenant.role_required'),
                status: :see_other
  end
end
