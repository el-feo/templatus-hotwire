describe 'Organization settings' do
  let(:user) { create(:user) }
  let(:organization) { create(:organization, name: 'Acme Inc') }

  context 'when the user is an admin' do
    before do
      create_membership(organization:, user:, role: :admin)
      sign_in user
    end

    it 'renders the form' do
      get edit_organization_settings_path(organization)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Acme Inc')
    end

    it 'renames the organization without moving it' do
      patch organization_settings_path(organization), params: { organization: { name: 'Acme Limited' } }

      expect(response).to redirect_to(organization_root_path(organization))
      expect(organization.reload.name).to eq('Acme Limited')
      expect(organization.slug).to eq('acme-inc')
    end

    it 'renders the form again when the name is unusable' do
      patch organization_settings_path(organization), params: { organization: { name: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(organization.reload.name).to eq('Acme Inc')
    end
  end

  context 'when the user is only a member' do
    before do
      create_membership(organization:, user:, role: :member)
      sign_in user
    end

    it 'refuses to show the form' do
      get edit_organization_settings_path(organization)

      expect(response).to redirect_to(organization_root_path(organization))
      expect(flash[:alert]).to be_present
    end

    it 'refuses the update' do
      patch organization_settings_path(organization), params: { organization: { name: 'Not Mine' } }

      expect(response).to redirect_to(organization_root_path(organization))
      expect(organization.reload.name).to eq('Acme Inc')
    end
  end
end
