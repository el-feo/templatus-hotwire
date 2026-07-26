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
describe User do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  it 'reaches its organizations through its memberships' do
    create_membership(user:, organization:, role: :admin)

    # `to_a` inside the block, not outside it: a relation would only run its
    # query once the matcher touches it, by which time the tenant is back.
    expect(ActsAsTenant.without_tenant { user.organizations.to_a }).to eq([organization])
  end

  # The cascade is a foreign key, not `dependent: :destroy`, precisely so that
  # this works: deleting an account happens outside of any organization, where
  # an Active Record cascade would query the tenant-scoped Membership and raise.
  it 'takes its memberships along when the account is deleted' do
    create_membership(user:, organization:)

    expect { user.destroy! }.to change { ActsAsTenant.without_tenant { Membership.count } }.from(1).to(0)
  end
end
