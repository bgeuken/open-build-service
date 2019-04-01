class StagingProjectAcceptJob < ApplicationJob
  queue_as :staging

  def perform(project_id, user_login)
    current_user_before = User.current
    User.current = User.find_by(login: user_login)
    Project.find(project_id).accept_staged_requests
    User.current = current_user_before
  end
end
