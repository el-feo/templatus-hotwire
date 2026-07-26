describe 'Organization dashboard' do
  let(:user) { create(:user) }
  let(:organization) { create(:organization, name: 'Acme Inc') }

  describe 'GET /org/:id' do
    it 'sends visitors to the sign-in page' do
      get organization_root_path(organization)

      expect(response).to redirect_to(new_user_session_path)
    end

    # The member count is the one place on this page where the tenant scoping is
    # visible, so it is asserted on the node rather than on the body: a bare
    # `include('2')` also matches `gap-2` and passes with the scoping broken.
    it 'shows the organization to its members' do
      create_membership(organization:, user:, role: :member)
      create_membership(organization:)
      create_membership(organization: create(:organization)) # noise from elsewhere

      sign_in user

      get organization_root_path(organization)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Acme Inc')
      expect(response.parsed_body.css('.stat-value').first.text.strip).to eq('2')
    end

    it 'describes the role the member actually has' do
      create_membership(organization:, user:, role: :viewer)
      sign_in user

      get organization_root_path(organization)

      expect(response.body).to include('Read-only')
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

  # The classic multitenancy failure is state left over from the request before:
  # a current tenant or a Current.membership that outlives its request shows one
  # organization's data under the other one's URL.
  describe 'moving between organizations in one session' do
    let(:other_organization) { create(:organization, name: 'Other Ltd') }

    before do
      create_membership(organization:, user:, role: :admin)
      create_membership(organization:)
      create_membership(organization: other_organization, user:, role: :viewer)
      sign_in user
    end

    it 'counts the members of whichever organization the URL names' do
      get organization_root_path(organization)
      expect(response.parsed_body.css('.stat-value').first.text.strip).to eq('2')

      get organization_root_path(other_organization)
      expect(response.parsed_body.css('.stat-value').first.text.strip).to eq('1')

      get organization_root_path(organization)
      expect(response.parsed_body.css('.stat-value').first.text.strip).to eq('2')
    end

    it 'carries the membership of the organization in the URL, not of the last one' do
      get organization_root_path(organization)
      expect(response.body).to include('Can manage members and settings')

      get organization_root_path(other_organization)
      expect(response.body).to include('Read-only')
    end

    # Leaving the organization behind again: the picker runs with no tenant at
    # all, and a leftover one would narrow it to a single entry.
    it 'goes back to the picker afterwards' do
      get organization_root_path(organization)
      get organizations_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Acme Inc')
      expect(response.body).to include('Other Ltd')
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
