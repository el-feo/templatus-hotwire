# The errors of a record that failed to save, above the form that submitted it.
# Renders nothing when there are none, so forms can include it unconditionally.
class FormErrors::Component < ViewComponent::Base
  def initialize(record:)
    super()
    @record = record
  end

  def render?
    record.errors.any?
  end

  private

  attr_reader :record
end
