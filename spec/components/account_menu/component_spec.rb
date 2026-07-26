describe AccountMenu::Component, type: :component do
  subject(:output) { render_inline(described_class.new(user:, current_organization:)) }

  let(:current_organization) { nil }

  context 'when nobody is signed in' do
    let(:user) { nil }

    it { is_expected.to have_link('Sign in', href: '/users/sign_in') }
    it { is_expected.to have_no_button('Sign out') }
  end

  # The menu is a closed <details>, so everything in it counts as invisible
  # until it is opened - hence `visible: :all` on the items below.
  context 'when a user is signed in outside an organization' do
    let(:user) { create(:user, email: 'me@example.com') }

    before { create_membership(organization: create(:organization, name: 'Acme Inc'), user:) }

    it { is_expected.to have_text('me@example.com') }
    it { is_expected.to have_button('Sign out', visible: :all) }
    it { is_expected.to have_link('Acme Inc', href: '/org/acme-inc', visible: :all) }
  end

  context 'when a user is inside one of their organizations' do
    let(:user) { create(:user, email: 'me@example.com') }
    let(:current_organization) { create(:organization, name: 'Acme Inc') }

    before do
      create_membership(organization: current_organization, user:)
      create_membership(organization: create(:organization, name: 'Other Ltd'), user:)
    end

    # The switcher has to list the organizations the user is *not* in, which is
    # what the component's `without_tenant` is for: the join through the
    # tenant-scoped Membership would otherwise come back with only this one.
    it 'lists the other organizations too' do
      ActsAsTenant.with_tenant(current_organization) do
        expect(output).to have_link('Other Ltd', href: '/org/other-ltd', visible: :all)
      end
    end

    it 'names the current organization on the button' do
      expect(output).to have_css('summary', text: 'Acme Inc')
    end
  end
end
