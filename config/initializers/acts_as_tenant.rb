ActsAsTenant.configure do |config|
  # Fail loudly instead of quietly leaking another organization's rows: without
  # this, a query on an `acts_as_tenant` model that runs with no tenant set
  # returns *every* tenant's records. With it, that query raises
  # ActsAsTenant::Errors::NoTenantSet instead.
  #
  # The flip side is that code which legitimately runs outside a single
  # organization - the organization picker, the seeds, a console session - has
  # to say so explicitly with `ActsAsTenant.without_tenant { ... }`.
  config.require_tenant = true
end

# Background jobs would otherwise run with no tenant and hit the raise above.
# ActiveJob is covered automatically: acts_as_tenant prepends
# ActsAsTenant::ActiveJobExtensions, which serializes the current tenant into
# the job and restores it on the worker. Plain `Sidekiq::Job` classes bypass
# ActiveJob and need `require 'acts_as_tenant/sidekiq'` here to get the same
# treatment through Sidekiq's own middleware chain.
