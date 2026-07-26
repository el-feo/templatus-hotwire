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
end
