# == Schema Information
#
# Table name: organizations
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_organizations_on_slug  (slug) UNIQUE
#
class Organization < ApplicationRecord
  # The tenant itself is never tenant-scoped: `acts_as_tenant` belongs on the
  # models that hang off an organization, not on the organization.
  #
  # No `dependent:` for the same reason as in User - see the comment there and
  # the cascading foreign key in the memberships migration.
  has_many :memberships, inverse_of: :organization # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :users, through: :memberships

  validates :name, presence: true, length: { maximum: 100 }

  # A name the slug generator cannot make anything of - "!!!", or one written
  # entirely in a script that does not transliterate - would fail on the slug
  # instead, which is a field the user never filled in.
  validate :name_must_produce_a_slug

  validates :slug,
            presence: true,
            uniqueness: true,
            format: { with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/ }

  before_validation :generate_slug, if: -> { slug.blank? }

  # URLs are built from the slug, but numeric ids stay valid so that links
  # created before an organization had its current slug still resolve.
  #
  # Called on a relation as well as on the class - `current_user.organizations
  # .from_param!(...)` narrows the lookup to the user's own organizations,
  # which turns "not a member" into the same 404 as "does not exist" instead of
  # confirming that the organization is there.
  def self.from_param!(param)
    find_by(slug: param) || find(param)
  end

  def to_param
    slug
  end

  private

  def name_must_produce_a_slug
    return if name.blank? # the presence validation has that covered
    return if name.parameterize.present?

    errors.add(:name, :no_slug)
  end

  # Generated once, on create, and then left alone: renaming an organization
  # must not break the URLs its members have bookmarked.
  def generate_slug
    base = name.to_s.parameterize
    candidate = base
    suffix = 2

    while self.class.exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end

    self.slug = candidate
  end
end
