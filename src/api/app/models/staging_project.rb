class StagingProject < Project
  # TODO: Make sure that we aren't fetching those requests over and over again when using this association
  has_many :staged_requests, class_name: 'BsRequest', foreign_key: :project_id

  def untracked_requests
    open_requests - staged_requests
  end

  def open_requests
    @open_requests ||= BsRequest.with_open_reviews_for(by_project: name)
  end

  def build_state
    set_buildinfo

    return :building if building_repositories.present?
    return :failed if broken_packages.present?

    :acceptable
  end

  def building_repositories
    @building_repositories
  end

  def broken_packages
    @broken_packages
  end

  # TODO: Move to lib
  def set_buildinfo
    buildresult = Xmlhash.parse(Backend::Api::BuildResults::Status.failed_results(name))

    @broken_packages = []
    @building_repositories = []

    buildresult.elements('result') do |result|
      building = false
      if !['published', 'unpublished'].include?(result['state']) || result['dirty'] == 'true'
        building = true
      end

      result.elements('status') do |status|
        code = status.get('code')

        if ['broken', 'failed'].include?(code) || (code == 'unresolvable' && !building)
          @broken_packages << { 'package'    => status['package'],
                                'project'    => name,
                                'state'      => code,
                                'details'    => status['details'],
                                'repository' => result['repository'],
                                'arch'       => result['arch'] }
        end
      end

      if building
        # determine build summary
        current_repo = result.slice('repository', 'arch', 'code', 'state', 'dirty')
        current_repo[:tobuild] = 0
        current_repo[:final] = 0

        buildresult = Buildresult.find_hashed(project: name, view: 'summary', repository: current_repo['repository'], arch: current_repo['arch']).get('result').get('summary')
        buildresult.elements('statuscount') do |sc|
          if ['excluded', 'broken', 'failed', 'unresolvable', 'succeeded', 'excluded', 'disabled'].include?(sc['code'])
            current_repo[:final] += sc['count'].to_i
          else
            current_repo[:tobuild] += sc['count'].to_i
          end
        end

        @building_repositories << current_repo
      end
    end

    if @building_repositories.present?
      @broken_packages = @broken_packages.reject { |p| p['state'] == 'unresolvable' }
    end
  end

  # TODO: This should be an association to the review model
  def missing_reviews
    # TODO: Is this if needed?
    if @missing_reviews.nil?
      @missing_reviews = []
      attribs = [:by_group, :by_user, :by_project, :by_package]

      (open_requests + staged_requests).uniq.each do |req|
        req.reviews.each do |rev|
          next if rev.state.to_s == 'accepted' || rev.by_project == name
          # FIXME: this loop (and the inner if) would not be needed
          # if every review only has one valid by_xxx.
          # I'm keeping it to mimic the python implementation.
          # Instead, we could have something like
          # who = rev.by_group || rev.by_user || rev.by_project || rev.by_package
          attribs.each do |att|
            if who = rev.send(att)
              @missing_reviews << { id: rev.id, request: req.number, state: rev.state.to_s, package: req.first_target_package, by: who }
            end
          end
        end
      end
    end

    @missing_reviews
  end

  def overall_state
    return @state unless @state.nil?
    @state = :empty

    return @state if staged_requests.empty?

    if untracked_requests.present? || staged_requests.obsolete.present?
      return @state = :unacceptable
    end

    @state = build_state

    if @state == :acceptable
      # TODO: Replace with the Status API
      # @state = openqa_state
    end

    if @state == :acceptable && missing_reviews.present?
      @state = :review
    end

    @state
  end
end
