describe 'Organizations' do
  let(:user) { create(:user) }

  describe 'GET /organizations' do
    it 'sends visitors to the sign-in page' do
      get organizations_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'lists the organizations the user belongs to, and no others' do
      create_membership(organization: create(:organization, name: 'Acme Inc'), user:)
      create(:organization, name: 'Someone Else Ltd')
      sign_in user

      get organizations_path

      expect(response.body).to include('Acme Inc')
      expect(response.body).not_to include('Someone Else Ltd')
    end

    it 'offers a way out when the user has no organization yet' do
      sign_in user

      get organizations_path

      expect(response.body).to include('not a member of any organization')
    end
  end

  describe 'GET /organizations/new' do
    it 'renders the form' do
      sign_in user

      get new_organization_path

      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /organizations' do
    before { sign_in user }

    it 'creates the organization and makes its creator an admin' do
      post organizations_path, params: { organization: { name: 'Acme Inc' } }

      organization = Organization.find_by!(slug: 'acme-inc')
      membership = ActsAsTenant.with_tenant(organization) { Membership.sole }

      expect(response).to redirect_to(organization_root_path(organization))
      expect(membership.user).to eq(user)
      expect(membership).to be_admin
    end

    it 'renders the form again when the name is unusable' do
      post organizations_path, params: { organization: { name: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Name can&#39;t be blank')
    end
  end
end
