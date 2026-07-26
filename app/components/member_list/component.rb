# The member list of an organization. Admins get the role selector and the
# remove button, everybody else sees the same list read-only.
class MemberList::Component < ViewComponent::Base
  def initialize(memberships:, organization:, viewer:)
    super()
    @memberships = memberships
    @organization = organization
    @viewer = viewer
  end

  private

  attr_reader :memberships, :organization, :viewer

  def manageable?
    viewer.admin?
  end

  def own?(membership)
    membership.user_id == viewer.user_id
  end

  # Most privileged first, so the select reads like the hierarchy it describes.
  def role_options
    Membership::ROLES.reverse_each.map { |role| [role.capitalize, role] }
  end
end
