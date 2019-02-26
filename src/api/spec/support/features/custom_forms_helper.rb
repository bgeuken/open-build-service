module CustomFormsHelper
  def make_custom_form_checkbox_clickable(html_id)
    # Workaround: Bootstrap's custom-control causes the checkbox's input field to be at
    # a different location than it visually appears. For browsers this is not an issue, but
    # capybara throws an error because "is not clickable at point (596, 335). Other element
    # would receive the click".
    # Thus we have to remove bootstraps custom-control classes.
    page.execute_script("$('##{html_id}').removeClass('custom-control-input')")
    page.execute_script("$('label[for=#{html_id}]').removeClass('custom-control-label')")
  end
end
