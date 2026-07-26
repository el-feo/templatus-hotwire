describe FormErrors::Component, type: :component do
  subject(:output) { render_inline(described_class.new(record:)) }

  context 'when the record has errors' do
    let(:record) { Organization.new(name: '').tap(&:valid?) }

    it { is_expected.to have_css('[role="alert"]') }
    it { is_expected.to have_text("Name can't be blank") }
  end

  # So a form can render it unconditionally.
  context 'when the record is fine' do
    let(:record) { Organization.new(name: 'Acme Inc').tap(&:valid?) }

    it 'renders nothing at all' do
      expect(output.to_html).to be_empty
    end
  end
end
