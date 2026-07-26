describe 'Memberships' do
  let(:user) { create(:user) }
  let(:organization) { create(:organization, name: 'Acme Inc') }
  let(:other_organization) { create(:organization) }

  def sign_in_as(role)
    create_membership(organization:, user:, role:)
    sign_in user
  end

  describe 'GET /org/:id/memberships' do
    it 'lists the members of this organization only' do
      colleague = create(:user, email: 'colleague@example.com')
      stranger = create(:user, email: 'stranger@example.com')
      create_membership(organization:, user: colleague)
      create_membership(organization: other_organization, user: stranger)
      sign_in_as(:member)

      get organization_memberships_path(organization)

      expect(response.body).to include('colleague@example.com')
      expect(response.body).not_to include('stranger@example.com')
    end

    it 'is not for viewers' do
      sign_in_as(:viewer)

      get organization_memberships_path(organization)

      expect(response).to redirect_to(organization_root_path(organization))
    end
  end

  describe 'POST /org/:id/memberships' do
    let!(:colleague) { create(:user, email: 'colleague@example.com') }

    it 'adds an existing account to the organization' do
      sign_in_as(:admin)

      post organization_memberships_path(organization),
           params: { membership: { email: 'colleague@example.com', role: 'member' } }

      expect(response).to redirect_to(organization_memberships_path(organization))
      expect(ActsAsTenant.with_tenant(organization) { Membership.find_by(user: colleague) }).to be_member
    end

    it 'accepts an address in a different case, with stray whitespace' do
      sign_in_as(:admin)

      post organization_memberships_path(organization),
           params: { membership: { email: '  COLLEAGUE@example.com ', role: 'viewer' } }

      expect(ActsAsTenant.with_tenant(organization) { Membership.find_by(user: colleague) }).to be_viewer
    end

    it 'says so when nobody has signed up with that address' do
      sign_in_as(:admin)

      post organization_memberships_path(organization),
           params: { membership: { email: 'nobody@example.com', role: 'member' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(flash[:alert]).to eq('Nobody has signed up with that address yet.')
    end

    it 'says so when the account is a member already' do
      sign_in_as(:admin)
      create_membership(organization:, user: colleague)

      post organization_memberships_path(organization),
           params: { membership: { email: colleague.email, role: 'member' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(flash[:alert]).to be_present
    end

    it 'is not for members' do
      sign_in_as(:member)

      post organization_memberships_path(organization),
           params: { membership: { email: colleague.email, role: 'member' } }

      expect(response).to redirect_to(organization_root_path(organization))
      expect(ActsAsTenant.with_tenant(organization) { Membership.count }).to eq(1)
    end
  end

  describe 'PATCH /org/:id/memberships/:id' do
    it 'changes a role' do
      sign_in_as(:admin)
      colleague = create_membership(organization:, role: :viewer)

      patch organization_membership_path(organization, colleague), params: { membership: { role: 'member' } }

      expect(response).to redirect_to(organization_memberships_path(organization))
      expect(colleague.reload).to be_member
    end

    it 'refuses to demote the last admin' do
      sign_in_as(:admin)
      own_membership = ActsAsTenant.with_tenant(organization) { Membership.sole }

      patch organization_membership_path(organization, own_membership), params: { membership: { role: 'member' } }

      expect(flash[:alert]).to be_present
      expect(own_membership.reload).to be_admin
    end

    # acts_as_tenant scopes the lookup, so an id from elsewhere is a 404 rather
    # than somebody else's member.
    it 'cannot reach a membership of another organization' do
      sign_in_as(:admin)
      stranger = create_membership(organization: other_organization)

      patch organization_membership_path(organization, stranger), params: { membership: { role: 'admin' } }

      expect(response).to have_http_status(:not_found)
      expect(stranger.reload).to be_member
    end
  end

  describe 'DELETE /org/:id/memberships/:id' do
    it 'removes a member' do
      sign_in_as(:admin)
      colleague = create_membership(organization:)

      delete organization_membership_path(organization, colleague)

      expect(response).to redirect_to(organization_memberships_path(organization))
      expect(ActsAsTenant.with_tenant(organization) { Membership.exists?(colleague.id) }).to be(false)
    end

    it 'refuses to remove the last admin' do
      sign_in_as(:admin)
      own_membership = ActsAsTenant.with_tenant(organization) { Membership.sole }

      delete organization_membership_path(organization, own_membership)

      expect(flash[:alert]).to be_present
      expect(own_membership.reload).to be_persisted
    end

    # Removing your own membership is how you leave, and the member list you
    # came from is not yours to see anymore.
    it 'sends you back to the picker when you remove yourself' do
      sign_in_as(:admin)
      create_membership(organization:, role: :admin)
      own_membership = ActsAsTenant.with_tenant(organization) { Membership.find_by!(user:) }

      delete organization_membership_path(organization, own_membership)

      expect(response).to redirect_to(organizations_path)
    end
  end
end
