class MembershipsController < ApplicationController
  include TenantScoped

  require_permission :may_see_members?, only: :index
  require_permission :may_manage_members?, except: :index

  before_action :set_membership, only: %i[update destroy]

  def index
    load_memberships
  end

  # Members are added by the email address they signed up with; there is no
  # invitation mail in this template.
  def create
    @membership = build_membership

    if @membership&.save
      redirect_to organization_memberships_path(Current.organization),
                  notice: t('.success', email: @membership.user.email),
                  status: :see_other
    else
      render_index_with_alert
    end
  end

  def update
    if @membership.update(role: membership_params[:role])
      redirect_to organization_memberships_path(Current.organization), notice: t('.success'), status: :see_other
    else
      redirect_to organization_memberships_path(Current.organization),
                  alert: @membership.errors.full_messages.to_sentence,
                  status: :see_other
    end
  end

  def destroy
    if @membership.destroy
      # An admin removing their own membership is how they leave - the member
      # list they came from is not theirs to see anymore. Members and viewers
      # have no way out of an organization in this template: leaving would be
      # its own action, since only `may_manage_members?` gets this far.
      redirect_to after_destroy_path, notice: t('.success'), status: :see_other
    else
      redirect_to organization_memberships_path(Current.organization),
                  alert: @membership.errors.full_messages.to_sentence,
                  status: :see_other
    end
  end

  private

  # Nil when no account uses that address, which is the one failure the
  # membership itself cannot describe.
  #
  # No normalizing here: `normalizes :email` on User applies to `find_by` too,
  # so this lookup and signing in agree on what an address is by construction.
  def build_membership
    user = User.find_by(email: membership_params[:email])

    Membership.new(user:, role: membership_params[:role]) if user
  end

  def render_index_with_alert
    flash.now[:alert] = @membership ? @membership.errors.full_messages.to_sentence : t('.unknown_user')
    load_memberships

    render :index, status: :unprocessable_content
  end

  def load_memberships
    # Most privileged first, by an explicit CASE - ordering by the role column
    # would sort it alphabetically, which is only accidentally the same thing.
    @memberships = Membership.includes(:user).in_order_of(:role, Membership.roles_by_privilege)
  end

  # `find` without a scope is safe here: acts_as_tenant restricts Membership to
  # the current organization, so an id from another organization is a 404
  # rather than somebody else's member.
  def set_membership
    @membership = Membership.find(params.expect(:id))
  end

  def after_destroy_path
    if @membership.user == current_user
      organizations_path
    else
      organization_memberships_path(Current.organization)
    end
  end

  def membership_params
    params.expect(membership: %i[email role])
  end
end
