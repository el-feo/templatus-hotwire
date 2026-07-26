describe MemberList::Component, type: :component do
  subject(:output) do
    render_inline(described_class.new(memberships: [own, colleague], organization:, viewer: own))
  end

  let(:organization) { create(:organization, name: 'Acme Inc') }
  let(:user) { create(:user, email: 'me@example.com') }
  let(:colleague) { create_membership(organization:, role: :viewer) }

  context 'when the viewer is an admin' do
    let(:own) { create_membership(organization:, user:, role: :admin) }

    it { is_expected.to have_select('membership[role]', count: 2) }
    it { is_expected.to have_button('Save', count: 2) }

    it 'marks the viewer as themselves' do
      expect(output).to have_text('You')
    end

    # Removing your own membership is leaving, and says so.
    it 'offers to leave rather than to remove for the viewer' do
      expect(output).to have_button('Leave')
      expect(output).to have_button("Remove #{colleague.user.email}")
    end
  end

  context 'when the viewer is not an admin' do
    let(:own) { create_membership(organization:, user:, role: :member) }

    it { is_expected.to have_no_select }
    it { is_expected.to have_no_button('Save') }
    it { is_expected.to have_css('span.badge', text: 'Viewer') }
    it { is_expected.to have_text('me@example.com') }
  end
end
