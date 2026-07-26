class RoleBadge::Component < ViewComponent::Base
  BADGE_CLASSES = {
    'admin' => 'badge-primary',
    'member' => 'badge-secondary',
    'viewer' => 'badge-ghost',
  }.freeze
  private_constant :BADGE_CLASSES

  def initialize(role:)
    super()
    @role = role.to_s
  end

  def call
    tag.span(role.capitalize, class: ['badge badge-sm', BADGE_CLASSES[role]])
  end

  private

  attr_reader :role
end
