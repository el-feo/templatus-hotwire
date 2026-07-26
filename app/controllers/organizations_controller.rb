# The organization picker and the "create an organization" form. Both run
# before there is a current organization, so this controller deliberately does
# not include TenantScoped.
class OrganizationsController < ApplicationController
  before_action :authenticate_user!

  # There is no tenant here by definition: this is where a signed-in user picks
  # one. Every query that touches the tenant-scoped Membership model - the
  # organizations list, the membership built in #create - would otherwise raise
  # NoTenantSet.
  around_action :without_tenant

  def index
    @organizations = current_user.organizations.order(:name)
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)

    # Whoever creates an organization is its first admin - without this nobody
    # could manage the organization that was just created.
    @organization.memberships.build(user: current_user, role: :admin)

    if @organization.save
      redirect_to organization_root_path(@organization), notice: t('.success'), status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def without_tenant(&)
    ActsAsTenant.without_tenant(&)
  end

  def organization_params
    params.expect(organization: [:name])
  end
end
