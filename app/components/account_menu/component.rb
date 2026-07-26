# The account area of the header: a sign-in link for visitors, and for signed-in
# users a menu that doubles as the organization switcher.
class AccountMenu::Component < ViewComponent::Base
  def initialize(user:, current_organization: nil)
    super()
    @user = user
    @current_organization = current_organization
  end

  private

  attr_reader :user, :current_organization

  # `all_organizations` owns the tenancy question, which matters twice here: on
  # a public page there is no tenant and the join through the tenant-scoped
  # Membership would raise NoTenantSet, and on an organization page the same
  # join would come back narrowed to the organization the user is already
  # looking at - leaving the switcher with the single entry it exists to switch
  # away from.
  def organizations
    @organizations ||= user.all_organizations
  end

  def current?(organization)
    organization == current_organization
  end
end
