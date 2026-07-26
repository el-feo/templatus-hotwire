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
FactoryBot.define do
  # Membership is tenant-scoped, so it can only be built while its organization
  # is the current tenant - see the `create_membership` helper in
  # spec/support/acts_as_tenant.rb.
  factory :membership do
    user
    organization
    role { 'member' }
  end
end
