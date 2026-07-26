# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  # Also available: :confirmable, :lockable, :timeoutable, :trackable and
  # :omniauthable - each one needs its own columns added in a migration.
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable

  # No `dependent:` on purpose: the foreign key cascades in the database
  # instead. Membership is tenant-scoped, and deleting an account happens
  # outside any organization - where an Active Record cascade would query
  # Membership with no tenant set and raise NoTenantSet.
  has_many :memberships, inverse_of: :user # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :organizations, through: :memberships

  # Devise already treats addresses case- and whitespace-insensitively on write.
  # Saying it here says it once and for the read path too: `normalizes` applies
  # to `find_by(email:)`, so looking somebody up cannot drift from signing in.
  normalizes :email, with: ->(email) { email.strip.downcase }

  # The join goes through the tenant-scoped Membership, so listing somebody's
  # organizations is a query that has to suspend tenancy - inside an
  # organization it would otherwise come back holding only that one. Callers get
  # an array rather than a relation: a relation would run its query later, when
  # the tenant is back.
  def all_organizations
    ActsAsTenant.without_tenant { organizations.order(:name).to_a }
  end
end
