class OrganizationList::Component < ViewComponent::Base
  def initialize(organizations:)
    super()
    @organizations = organizations
  end

  private

  attr_reader :organizations
end
