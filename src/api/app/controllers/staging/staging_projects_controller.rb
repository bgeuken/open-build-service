class Staging::StagingProjectsController < ApplicationController
  before_action :require_login, except: [:index, :show]

  before_action :set_main_project

  def index
    if @main_project.staging
      @staging_workflow = @main_project.staging
      @staging_projects = @staging_workflow.staging_projects
    else
      render_error status: 400, errcode: 'project_has_no_staging_workflow'
    end
  end

  def show
    @staging_project = @main_project.staging.staging_projects.find_by!(name: params[:name])
  end

  def copy
    authorize @main_project.staging

    StagingProjectCopyJob.perform_later(params[:staging_workflow_project], params[:staging_project_name], params[:staging_project_copy_name], User.current.id)

    render_ok
  end

  def accept
    staging_project = Project.find_by!(name: params[:staging_project_name])
    authorize staging_project, :update?

    if staging_project.overall_state != :acceptable
      render_error(
        status: 400,
        errorcode: 'invalid_request',
        message: 'Staging project is not in state acceptable.'
      )
      return
    end

    StagingProjectAcceptJob.perform_later(staging_project.id, User.current.login)
    render_ok
  end

  private

  def set_main_project
    @main_project = Project.find_by!(name: params[:staging_workflow_project])
  end
end
