class RoleBadgePreview < ViewComponent::Preview
  def with_default
    render(RoleBadge::Component.new(role: 'admin'))
  end

  def with_member
    render(RoleBadge::Component.new(role: 'member'))
  end

  def with_viewer
    render(RoleBadge::Component.new(role: 'viewer'))
  end
end
