require 'browser_helper'

RSpec.feature "User's admin edit page", type: :feature, js: true do
  let(:user) { create(:confirmed_user, realname: 'John Doe', email: 'john@suse.de') }
  let(:admin) { create(:admin_user) }
  let(:admin_role_html_id) { "user_role_ids_#{Role.find_by(title: 'Admin').id}" }

  scenario 'view user' do
    login(admin)
    visit user_edit_path(user: user.login)

    expect(page).to have_field('Name:', with: 'John Doe')
    expect(page).to have_field('e-Mail:', with: 'john@suse.de')

    make_custom_form_checkbox_clickable(admin_role_html_id)
    expect(find_field('Admin')).not_to be_checked
    expect(find_field('confirmed')).to be_checked
    expect(find_field('unconfirmed')).not_to be_checked
    expect(find_field('deleted')).not_to be_checked
    expect(find_field('locked')).not_to be_checked
  end

  scenario 'make user admin' do
    login(admin)
    visit user_edit_path(user: user.login)

    make_custom_form_checkbox_clickable(admin_role_html_id)
    check('Admin')
    click_button('Update')
    expect(user.is_admin?).to be(true)
  end

  scenario 'remove admin rights from user' do
    login(admin)
    visit user_edit_path(user: admin.login)
    make_custom_form_checkbox_clickable(admin_role_html_id)
    uncheck('Admin')
    click_button('Update')
    expect(admin.is_admin?).to be(false)
  end
end
