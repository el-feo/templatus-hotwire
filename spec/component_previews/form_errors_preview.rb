class FormErrorsPreview < ViewComponent::Preview
  def with_default
    render(FormErrors::Component.new(record: Organization.new(name: '').tap(&:valid?)))
  end

  # Renders nothing, which is what lets a form include it unconditionally.
  def without_errors
    render(FormErrors::Component.new(record: Organization.new(name: 'Acme Inc')))
  end
end
