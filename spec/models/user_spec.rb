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

  # The call sites - the picker and the switcher in the header - do not have to
  # know that the join is tenant-scoped.
  describe '#all_organizations' do
    it 'lists them by name, without a tenant of its own' do
      zulu = create(:organization, name: 'Zulu Ltd')
      acme = create(:organization, name: 'Acme Inc')
      create_membership(user:, organization: zulu)
      create_membership(user:, organization: acme)

      expect(user.all_organizations).to eq([acme, zulu])
    end

    # Inside an organization the same join would otherwise come back narrowed to
    # that one, leaving the switcher with nowhere to switch to.
    it 'lists them all from inside one of them' do
      other = create(:organization)
      create_membership(user:, organization:)
      create_membership(user:, organization: other)

      expect(ActsAsTenant.with_tenant(organization) { user.all_organizations })
        .to contain_exactly(organization, other)
    end
  end

  # Devise normalizes on the way in; this is what makes the same rule apply when
  # somebody is looked up by address - adding a member, say.
  describe 'the email address' do
    it 'is stored stripped and downcased' do
      expect(create(:user, email: '  Me@Example.COM ').email).to eq('me@example.com')
    end

    it 'is found by an address written in a different case' do
      user = create(:user, email: 'me@example.com')

      expect(described_class.find_by(email: '  ME@example.com ')).to eq(user)
    end
  end

  # The cascade is a foreign key, not `dependent: :destroy`, precisely so that
  # this works: deleting an account happens outside of any organization, where
  # an Active Record cascade would query the tenant-scoped Membership and raise.
  it 'takes its memberships along when the account is deleted' do
    create_membership(user:, organization:)

    expect { user.destroy! }.to change { ActsAsTenant.without_tenant { Membership.count } }.from(1).to(0)
  end
end
