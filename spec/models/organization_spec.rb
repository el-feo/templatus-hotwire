# == Schema Information
#
# Table name: organizations
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_organizations_on_slug  (slug) UNIQUE
#
describe Organization do
  describe 'the slug' do
    it 'is built from the name' do
      expect(create(:organization, name: 'Acme Inc').slug).to eq('acme-inc')
    end

    it 'gets a suffix when the name is already taken' do
      create(:organization, name: 'Acme Inc')

      expect(create(:organization, name: 'Acme Inc').slug).to eq('acme-inc-2')
    end

    it 'keeps counting up while the suffixed slug is taken as well' do
      create_list(:organization, 3, name: 'Acme Inc')

      expect(create(:organization, name: 'Acme Inc').slug).to eq('acme-inc-4')
    end

    # Renaming must not break the URLs the members have bookmarked.
    it 'survives a rename' do
      organization = create(:organization, name: 'Acme Inc')

      organization.update!(name: 'Acme Limited')

      expect(organization.slug).to eq('acme-inc')
    end

    # Not merely left alone by a rename: the address an organization is reached
    # at is settled on create, whoever asks to change it afterwards.
    it 'cannot be written directly once the organization exists' do
      organization = create(:organization, name: 'Acme Inc')

      expect(organization.update(slug: 'somewhere-else')).to be(false)
      expect(organization.reload.slug).to eq('acme-inc')
    end

    # Blanking it used to regenerate it from the current name, which silently
    # moved a renamed organization to a new address.
    it 'is not regenerated when it is blanked out' do
      organization = create(:organization, name: 'Acme Inc')
      organization.update!(name: 'Acme Limited')

      expect(organization.update(slug: '')).to be(false)
      expect(organization.reload.slug).to eq('acme-inc')
    end

    it 'is what the organization is identified by in URLs' do
      expect(create(:organization, name: 'Acme Inc').to_param).to eq('acme-inc')
    end
  end

  describe 'validations' do
    it 'requires a name' do
      expect(build(:organization, name: '')).not_to be_valid
    end

    it 'rejects a name of more than 100 characters' do
      expect(build(:organization, name: 'a' * 101)).not_to be_valid
    end

    # Nothing to build a slug from, and the error belongs on the field the user
    # actually filled in.
    it 'rejects a name without a single letter or digit' do
      organization = build(:organization, name: '!!!')

      expect(organization).not_to be_valid
      expect(organization.errors[:name]).to include(/at least one letter or digit/)
    end

    it 'rejects a slug that is not URL-safe' do
      expect(build(:organization, slug: 'Not A Slug')).not_to be_valid
    end

    it 'rejects a slug that is already taken' do
      create(:organization, name: 'Acme Inc')

      expect(build(:organization, slug: 'acme-inc')).not_to be_valid
    end
  end

  describe '.from_param!' do
    let!(:organization) { create(:organization, name: 'Acme Inc') }

    it 'finds by slug' do
      expect(described_class.from_param!('acme-inc')).to eq(organization)
    end

    # Links created before the organization had its current slug keep working.
    it 'falls back to the id' do
      expect(described_class.from_param!(organization.id.to_s)).to eq(organization)
    end

    it 'raises when neither matches' do
      expect { described_class.from_param!('nope') }.to raise_error(ActiveRecord::RecordNotFound)
    end

    # This is what turns "you are not a member" into the same 404 as "there is
    # no such organization" in TenantScoped.
    it 'is narrowed by the relation it is called on' do
      user = create(:user)

      expect { ActsAsTenant.without_tenant { user.organizations.from_param!('acme-inc') } }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
