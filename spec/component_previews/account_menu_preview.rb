class AccountMenuPreview < ViewComponent::Preview
  # Nobody signed in: the header only offers the way in.
  def with_default
    render(AccountMenu::Component.new(user: nil))
  end

  # An unsaved user, so the preview does not depend on what is in the database.
  # Its organization list comes back empty for the same reason - open the menu
  # in the running app to see the switcher with entries in it.
  def with_a_signed_in_user
    render(AccountMenu::Component.new(user: User.new(email: 'me@example.com')))
  end
end
