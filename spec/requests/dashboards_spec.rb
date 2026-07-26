describe 'Organization dashboard' do
  let(:user) { create(:user) }
  let(:organization) { create(:organization, name: 'Acme Inc') }

  describe 'GET /org/:id' do
    it 'sends visitors to the sign-in page' do
      get organization_root_path(organization)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'shows the organization to its members' do
      create_membership(organization:, user:, role: :member)
      create_membership(organization:)
      sign_in user

      get organization_root_path(organization)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Acme Inc')
      expect(response.body).to include('2') # both members counted
    end

    # A slug somebody else's organization uses has to look exactly like a slug
    # nobody uses, or the URL space becomes a directory of customers.
    it 'is a 404 for a non-member' do
      sign_in user

      get organization_root_path(organization)

      expect(response).to have_http_status(:not_found)
    end

    it 'answers the same way for an organization that does not exist' do
      sign_in user

      get '/org/no-such-organization'

      expect(response).to have_http_status(:not_found)
    end

    it 'still resolves an organization addressed by its id' do
      create_membership(organization:, user:)
      sign_in user

      get "/org/#{organization.id}"

      expect(response).to have_http_status(:success)
    end
  end

  describe 'signing in on the way there' do
    before { create_membership(organization:, user:) }

    it 'returns to the page that asked for a sign-in' do
      get organization_root_path(organization)

      post user_session_path, params: { user: { email: user.email, password: user.password } }

      expect(response).to redirect_to(organization_root_path(organization))
    end

    it 'lands on the organization picker when there was no such page' do
      post user_session_path, params: { user: { email: user.email, password: user.password } }

      expect(response).to redirect_to(organizations_path)
    end
  end
end
