class StagingProjectCopyJob < ApplicationJob
  queue_as :default

  rescue_from(::ActiveRecord::ActiveRecordError) do |exception|
    @original_staging_project.reports.create!(failure_message: exception.message)
  end

  def perform(staging_workflow_project_name, original_staging_project_name, staging_project_copy_name)
    staging_workflow_project = Project.find_by!(name: staging_workflow_project_name)
    @original_staging_project = staging_workflow_project.staging.staging_projects.find_by!(name: original_staging_project_name)
    @original_staging_project.copy(staging_project_copy_name)
  end
end
