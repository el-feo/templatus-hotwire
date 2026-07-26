class OrganizationListPreview < ViewComponent::Preview
  def with_default
    render(OrganizationList::Component.new(organizations: [acme, other]))
  end

  def without_any_organization
    render(OrganizationList::Component.new(organizations: []))
  end

  private

  def acme
    Organization.new(id: 1, name: 'Acme Inc', slug: 'acme-inc')
  end

  def other
    Organization.new(id: 2, name: 'Other Ltd', slug: 'other-ltd')
  end
end
