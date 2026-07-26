class MemberListPreview < ViewComponent::Preview
  def with_default
    render(MemberList::Component.new(memberships: memberships, organization: organization, viewer: memberships.first))
  end

  # Everybody who is not an admin sees the same list without its controls.
  def as_a_member
    member = memberships.second

    render(MemberList::Component.new(memberships: memberships, organization: organization, viewer: member))
  end

  private

  def organization
    @organization ||= Organization.new(id: 1, name: 'Acme Inc', slug: 'acme-inc')
  end

  # Membership is tenant-scoped, so building one needs a current tenant even
  # here, where nothing is ever saved.
  def memberships
    @memberships ||=
      ActsAsTenant.with_tenant(organization) do
        [
          Membership.new(id: 1, role: 'admin', user: User.new(id: 1, email: 'admin@example.com')),
          Membership.new(id: 2, role: 'member', user: User.new(id: 2, email: 'member@example.com')),
          Membership.new(id: 3, role: 'viewer', user: User.new(id: 3, email: 'viewer@example.com')),
        ]
      end
  end
end
