# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Enough clicks to actually scroll through several pages in development.
DEMO_CLICKS = 250

# Two accounts in one organization, so the member list and the role selector
# have something to show. Same reasoning as the clicks below: development only,
# because seeded rows survive the per-example transaction and would show up in
# the test suite.
if Rails.env.development?
  demo_password = 'templatus'

  founder = User.find_or_create_by!(email: 'founder@templatus.test') { |user| user.password = demo_password }
  colleague = User.find_or_create_by!(email: 'colleague@templatus.test') { |user| user.password = demo_password }

  organization = Organization.find_or_create_by!(name: 'Acme Inc')

  # Membership is tenant-scoped, so both the lookup and the insert need the
  # organization to be the current tenant - `require_tenant` would raise
  # otherwise, seeds included.
  ActsAsTenant.with_tenant(organization) do
    Membership.find_or_create_by!(user: founder) { |membership| membership.role = :admin }
    Membership.find_or_create_by!(user: colleague) { |membership| membership.role = :member }
  end

  Rails.logger.info "Seeded #{organization.name} with #{founder.email} (admin) and #{colleague.email} (member)"
end

# Development only: seeding the test database would leak these records into
# the test suite, because they survive the per-example transaction rollback.
if Rails.env.development? && Click.count < DEMO_CLICKS
  user_agents = [
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 ' \
    'Safari/537.36',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 ' \
    'Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0',
  ]

  missing = DEMO_CLICKS - Click.count
  now = Time.current

  # Bulk insert: the attributes are generated here, so there is nothing to
  # validate, and seeding stays fast
  Click.insert_all!( # rubocop:disable Rails/SkipsModelValidations
    Array.new(missing) do |i|
      {
        ip: "127.0.#{i % 256}.0",
        user_agent: user_agents[i % user_agents.size],
        created_at: now - (i * 7).minutes,
      }
    end,
  )

  Rails.logger.info "Seeded #{missing} demo clicks (#{Click.count} in total)"
end
