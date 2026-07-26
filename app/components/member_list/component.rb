# The member list of an organization. Admins get the role selector and the
# remove button, everybody else sees the same list read-only.
class MemberList::Component < ViewComponent::Base
  # `dom_id`, so each row's role select gets an id of its own - one id per page
  # is what the sr-only label needs to point at the right control.
  include ActionView::RecordIdentifier

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

  def role_field_id(membership)
    dom_id(membership, :role)
  end

  # Removing your own membership is how you leave, so the button says so - and
  # either way it asks first, because neither is undoable.
  def confirm_text(membership)
    if own?(membership)
      "Leave #{organization.name}?"
    else
      "Remove #{membership.user.email} from #{organization.name}?"
    end
  end

  def remove_label(membership)
    own?(membership) ? 'Leave' : "Remove #{membership.user.email}"
  end

  def remove_icon(membership)
    own?(membership) ? 'icon-[lucide--log-out]' : 'icon-[lucide--user-minus]'
  end
end
