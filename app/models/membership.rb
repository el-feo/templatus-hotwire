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

  def at_least?(role)
    ROLES.index(self.role) >= ROLES.index(role.to_s)
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
