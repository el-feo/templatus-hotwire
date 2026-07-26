# == Schema Information
#
# Table name: memberships
#
#  id              :bigint           not null, primary key
#  role            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_memberships_on_organization_id              (organization_id)
#  index_memberships_on_user_id_and_organization_id  (user_id,organization_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class Membership < ApplicationRecord
  # Scopes every Membership query to ActsAsTenant.current_tenant, which
  # TenantScoped sets from the /org/:organization_id/ segment of the URL. A
  # controller that forgets to scope a query still only sees the current
  # organization's rows, and a query with no tenant at all raises NoTenantSet
  # instead of quietly returning everybody's.
  acts_as_tenant :organization

  belongs_to :user

  # Ordered from least to most privileged: `at_least?` compares by index.
  ROLES = %w[viewer member admin].freeze
  public_constant :ROLES

  enum :role, ROLES.index_by(&:to_sym), validate: true

  # Backed by the unique index on [user_id, organization_id].
  validates :user_id, uniqueness: { scope: :organization_id }

  # An organization with no admin left cannot be managed by anyone, so the last
  # one can neither be demoted nor removed.
  validate :keep_one_admin, on: :update
  before_destroy :abort_when_last_admin

  # Most privileged first: the role selectors read like the hierarchy they
  # describe, and ordering by the role column would only accidentally agree.
  def self.roles_by_privilege
    ROLES.reverse
  end

  def self.role_options
    roles_by_privilege.map { |role| [role.capitalize, role] }
  end

  # What each role may do, named once here instead of at every call site. The
  # app asks for the permission; that a role happens to imply it is this
  # object's business.
  def may_see_members?
    at_least?(:member)
  end

  def may_manage_members?
    at_least?(:admin)
  end

  def may_edit_settings?
    at_least?(:admin)
  end

  def at_least?(role)
    ROLES.index(self.role) >= ROLES.index(role.to_s)
  end

  # Three-valued by construction: a role added to ROLES without a description
  # raises here instead of being silently described as something it is not.
  def role_description
    I18n.t("roles.#{role}.description")
  end

  private

  def keep_one_admin
    return unless role_changed?(from: 'admin')
    return unless last_admin?

    errors.add(:role, :last_admin)
  end

  def abort_when_last_admin
    return unless admin? && last_admin?

    errors.add(:base, :last_admin)
    throw :abort
  end

  def last_admin?
    organization.memberships.admin.where.not(id: id).none?
  end
end
