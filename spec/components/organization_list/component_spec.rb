describe OrganizationList::Component, type: :component do
  subject(:output) { render_inline(described_class.new(organizations:)) }

  context 'with organizations' do
    let(:organizations) { [create(:organization, name: 'Acme Inc')] }

    it { is_expected.to have_link('Acme Inc', href: '/org/acme-inc') }
    it { is_expected.to have_text('/org/acme-inc') }
  end

  context 'without a single one' do
    let(:organizations) { [] }

    it { is_expected.to have_text('not a member of any organization') }
    it { is_expected.to have_link('Create an organization', href: '/organizations/new') }
  end
end
