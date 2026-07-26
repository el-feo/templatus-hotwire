class OrganizationSettingsController < ApplicationController
  include TenantScoped

  before_action :require_admin

  def edit
    @organization = Current.organization
  end

  # Renaming leaves the slug alone, so the URLs members have bookmarked keep
  # working.
  def update
    @organization = Current.organization

    if @organization.update(organization_params)
      redirect_to organization_root_path(@organization), notice: t('.success'), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def organization_params
    params.expect(organization: [:name])
  end
end
