module Webui::StagingWorkflowHelper
  def build_progress(staging_project)
    total = 0
    final = 0

    staging_project.building_repositories.each do |r|
      total += r[:tobuild] + r[:final]
      final += r[:final]
    end

    return 100 if total == 0
    # if we have building repositories, make sure we don't exceed 99
    [final * 100 / total, 99].min
  end

  def review_progress(staging_project)
    staged_requests_numbers = staging_project.staged_requests.pluck(:number)
    total = Review.where(bs_request: staging_project.staged_requests).count
    missing = staging_project.missing_reviews.count { |missing_review| staged_requests_numbers.include?(missing_review[:request]) }

    100 - missing * 100 / total
  end

  def testing_progress(staging_project)
    # TODO: Once the following PR is merged, rebase on master and use the status API instead of directly checking openQA
    #       https://github.com/openSUSE/open-build-service/pull/6119
    0
  end

  def progress(staging_project)
    case staging_project.overall_state
    when :building
      link_to project_monitor_url(staging_project.name) do
        "#{build_progress(staging_project)} %"
      end
    when :review
      "#{review_progress(staging_project)} %"
    when :testing
      "#{testing_progress(staging_project)} %"
    end
  end
end
