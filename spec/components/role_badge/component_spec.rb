describe RoleBadge::Component, type: :component do
  it 'names the role' do
    expect(render_inline(described_class.new(role: 'admin'))).to have_css('span.badge', text: 'Admin')
  end

  it 'tells the roles apart by colour' do
    classes = Membership::ROLES.map { |role| render_inline(described_class.new(role:)).css('span').attr('class').value }

    expect(classes.uniq.size).to eq(Membership::ROLES.size)
  end

  it 'accepts a symbol as well' do
    expect(render_inline(described_class.new(role: :viewer))).to have_css('span.badge', text: 'Viewer')
  end
end
