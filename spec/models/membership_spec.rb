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
describe Membership do
  let(:organization) { create(:organization) }

  describe 'tenant scoping' do
    let(:other_organization) { create(:organization) }

    before do
      create_membership(organization:)
      create_membership(organization: other_organization)
    end

    it 'only sees the current organization' do
      ActsAsTenant.with_tenant(organization) do
        expect(described_class.count).to eq(1)
      end
    end

    # The point of `require_tenant`: a forgotten scope is an exception, not a
    # list of everybody's members.
    it 'refuses to answer without a tenant' do
      expect { described_class.count }.to raise_error(ActsAsTenant::Errors::NoTenantSet)
    end

    it 'takes the organization from the current tenant when created' do
      membership =
        ActsAsTenant.with_tenant(organization) { described_class.create!(user: create(:user), role: :member) }

      expect(membership.organization).to eq(organization)
    end
  end

  describe 'roles' do
    around { |example| ActsAsTenant.with_tenant(organization) { example.run } }

    it 'rejects a role outside the list' do
      expect(build(:membership, organization:, role: 'owner')).not_to be_valid
    end

    it 'answers at_least? along the hierarchy' do
      admin = build(:membership, organization:, role: :admin)
      member = build(:membership, organization:, role: :member)
      viewer = build(:membership, organization:, role: :viewer)

      expect(admin.at_least?(:member)).to be(true)
      expect(member.at_least?(:member)).to be(true)
      expect(member.at_least?(:admin)).to be(false)
      expect(viewer.at_least?(:member)).to be(false)
      expect(viewer.at_least?(:viewer)).to be(true)
    end
  end

  it 'allows a user only one membership per organization' do
    user = create(:user)
    create_membership(organization:, user:)

    expect(ActsAsTenant.with_tenant(organization) { build(:membership, organization:, user:) }).not_to be_valid
  end

  # The other half of the same rule: uniqueness is scoped to the organization,
  # so belonging to two of them is the ordinary case rather than a duplicate.
  it 'allows a user a membership in every organization' do
    user = create(:user)
    other_organization = create(:organization)
    create_membership(organization:, user:)

    membership =
      ActsAsTenant.with_tenant(other_organization) do
        build(:membership, organization: other_organization, user:)
      end

    expect(membership).to be_valid
  end

  # A two-branch description of a three-valued concept told viewers they could
  # write; the description belongs to the role now.
  describe 'the role description' do
    around { |example| ActsAsTenant.with_tenant(organization) { example.run } }

    it 'covers every role in ROLES' do
      described_class::ROLES.each do |role|
        expect(build(:membership, organization:, role:).role_description).to be_present
      end
    end
  end

  # An organization whose last admin is gone cannot be managed by anybody.
  describe 'the last admin' do
    let!(:admin) { create_membership(organization:, role: :admin) }

    around { |example| ActsAsTenant.with_tenant(organization) { example.run } }

    it 'cannot be removed' do
      expect(admin.destroy).to be(false)
      expect(admin.errors[:base]).to include('An organization needs at least one admin, and this is the last one.')
      expect(admin.reload).to be_persisted
    end

    it 'cannot be demoted' do
      expect(admin.update(role: :member)).to be(false)
      expect(admin.errors[:role]).to be_present
    end

    it 'can be removed once somebody else is an admin' do
      create(:membership, organization:, role: :admin)

      expect(admin.destroy).to be_truthy
    end

    it 'can be demoted once somebody else is an admin' do
      create(:membership, organization:, role: :admin)

      expect(admin.update(role: :member)).to be(true)
    end

    it 'does not get in the way of removing anybody else' do
      member = create(:membership, organization:, role: :member)

      expect(member.destroy).to be_truthy
    end

    it 'does not get in the way of promoting anybody else' do
      member = create(:membership, organization:, role: :member)

      expect(member.update(role: :admin)).to be(true)
    end
  end
end
