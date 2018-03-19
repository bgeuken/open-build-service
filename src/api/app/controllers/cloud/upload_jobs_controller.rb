module Cloud
  class UploadJobsController < ApplicationController
    before_action :require_login
    before_action -> { feature_active?(:cloud_upload) }
    before_action :validate_configuration_presence, only: [:index, :create]

    def index
      render xml: ::Cloud::Backend::UploadJob.all(::User.current, format: :xml)
    end

    def create
      upload_job = ::Cloud::UploadJob.create(permitted_params.merge(user: ::User.current))
      if upload_job.valid?
        render xml: upload_job
      else
        response.headers['X-Opensuse-Errorcode'] = 'cloud_upload_job_invalid'
        render_error status: 400,
                     errorcode: 'cloud_upload_job_invalid',
                     summary: "Failed to create upload job: #{upload_job.errors.full_messages.to_sentence}."
      end
    end

    private

    def validate_configuration_presence
      return if ::User.current.cloud_configurations?
      render_error status: 400,
                   errorcode: 'cloud_upload_job_no_config',
                   summary: "Couldn't find a cloud configuration for user"
    end

    def permitted_params
      params.require(:cloud_backend_upload_job).permit(
        :project, :package, :repository, :arch, :filename, :region, :ami_name, :target, :vpc_subnet_id
      )
    end
  end
end
