# The organization picker and the "create an organization" form. Both run
# before there is a current organization, so this controller deliberately does
# not include TenantScoped.
class OrganizationsController < ApplicationController
  before_action :authenticate_user!

  # There is no tenant here by definition: this is where a signed-in user picks
  # one. The two queries that touch the tenant-scoped Membership model say so
  # themselves rather than the whole request running untenanted, where a scoped
  # query added later would quietly return every organization's rows instead of
  # raising. `to_a` inside the block, because a relation would run its query
  # later - from the template, with the tenant back.
  def index
    @organizations = ActsAsTenant.without_tenant { current_user.organizations.order(:name).to_a }
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)

    if save_with_creator_as_admin
      redirect_to organization_root_path(@organization), notice: t('.success'), status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  # Whoever creates an organization is its first admin - without this nobody
  # could manage the organization that was just created. Building the membership
  # needs the tenant suspended as much as saving it does: with `require_tenant`
  # on, even `Membership.new` goes through the default scope.
  def save_with_creator_as_admin
    ActsAsTenant.without_tenant do
      @organization.memberships.build(user: current_user, role: :admin)
      @organization.save
    end
  end

  def organization_params
    params.expect(organization: [:name])
  end
end
