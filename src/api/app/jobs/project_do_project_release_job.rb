class ProjectDoProjectReleaseJob < ApplicationJob
  def perform(project_id, params)
    Project.find(project_id).do_project_release(params)
  end
end
