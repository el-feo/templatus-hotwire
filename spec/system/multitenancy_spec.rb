describe 'Multitenancy' do
  let(:colleague) { create(:user, email: 'colleague@example.com') }

  it 'takes a new account from signing up to running an organization' do
    colleague # the person to add later has to exist before they can be added

    visit new_user_registration_path
    fill_in 'Email', with: 'founder@example.com'
    fill_in 'Password', with: 'correct horse battery staple'
    fill_in 'Password confirmation', with: 'correct horse battery staple'
    click_on 'Create account'

    # Signing up lands on the picker, which has nothing to pick yet
    expect(page).to have_css('main h1', text: 'Organizations')
    click_on 'Create an organization'

    fill_in 'Name', with: 'Acme Inc'
    click_on 'Create organization'

    # The URL carries the tenant from here on
    expect(page).to have_current_path('/org/acme-inc')
    expect(page).to have_css('main h1', text: 'Acme Inc')
    expect(page).to have_css('.stat-value', text: '1')

    click_on 'Members'

    # Scoped to the form: every member in the list below has a role select too
    within('#add-member') do
      fill_in 'Add a member by email', with: 'colleague@example.com'
      select 'Viewer', from: 'Role'
      click_on 'Add member'
    end

    expect(page).to have_css('#flash', text: 'colleague@example.com is now a member')
    expect(page).to have_text('colleague@example.com')
  end

  it 'keeps one organization out of the other' do
    user = create(:user, email: 'founder@example.com')
    acme = create(:organization, name: 'Acme Inc')
    other = create(:organization, name: 'Other Ltd')
    create_membership(organization: acme, user:, role: :admin)
    create_membership(organization: other, user: colleague, role: :admin)

    visit new_user_session_path

    # Scoped to the page: the header carries a "Sign in" link of its own
    within('main') do
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      click_on 'Sign in'
    end

    # Wait for the sign-in to land before navigating away from it
    expect(page).to have_css('main h1', text: 'Organizations')

    visit organization_memberships_path(acme)
    expect(page).to have_text('founder@example.com')
    expect(page).to have_no_text('colleague@example.com')

    # The switcher only knows the organizations this account belongs to; asking
    # for the other one by URL is a 404, which the request specs cover.
    within('body > header') do # the page title renders a <header> of its own
      find('summary').click

      expect(page).to have_link(acme.name)
      expect(page).to have_no_link(other.name)
    end
  end
end
