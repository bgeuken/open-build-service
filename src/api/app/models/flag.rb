class Flag < ApplicationRecord
  belongs_to :project, inverse_of: :flags
  belongs_to :package, inverse_of: :flags

  belongs_to :architecture

  scope :of_type, ->(type) { where(flag: type) }

  validates :flag, presence: true
  validates :position, presence: true
  validates_numericality_of :position, only_integer: true

  after_save :discard_forbidden_project_cache
  after_destroy :discard_forbidden_project_cache

  before_validation(on: :create) do
    self.position = main_object.flags.maximum(:position).to_i + 1
  end

  validate :validate_custom_save
  def validate_custom_save
    errors.add(:name, 'Please set either project or package.') if project.nil? && package.nil?
    errors.add(:name, 'Please set either project or package.') unless project.nil? || package.nil?
    errors.add(:flag, 'There needs to be a valid flag.') unless FlagHelper::TYPES.has_key?(flag.to_s)
    errors.add(:status, 'Status needs to be enable or disable') unless (status && (status.to_sym == :enable || status.to_sym == :disable))
  end

  validate :validate_duplicates, on: :create
  def validate_duplicates
    # rubocop:disable Metrics/LineLength
    if Flag.where("status = ? AND repo = ? AND project_id = ? AND package_id = ? AND architecture_id = ? AND flag = ?", status, repo, project_id, package_id, architecture_id, flag).exists?
      errors.add(:flag, "Flag already exists")
    end
    # rubocop:enable Metrics/LineLength
  end

  def self.default_status(flag_name)
    case flag_name
    when 'lock', 'debuginfo'
      'disable'
    when 'build', 'publish', 'useforbuild', 'binarydownload', 'access'
      'enable'
    else
      'disable'
    end
  end

  def discard_forbidden_project_cache
    Relationship.discard_cache if flag == 'access'
  end

  def compute_status(variant)
    if variant == "effective"
      status = (repo_and_arch_status || repo_status || arch_status || all_status)
    elsif variant == "default"
      status = if main_object.kind_of?(Package)
        all_status
      elsif repo && architecture_id
        repo_status || arch_status
      end
    end

    status || Flag.default_status(flag)
  end
  private :compute_status

  def default_status
    return compute_status('default')
  end

  def effective_status
    return compute_status('effective')
  end

  def has_children
    repo.blank? || architecture.blank?
  end

  def to_xml(builder)
    raise RuntimeError.new( "FlagError: No flag-status set. \n #{inspect}" ) if status.nil?
    options = Hash.new
    options['arch'] = architecture.name unless architecture.nil?
    options['repository'] = repo unless repo.nil?
    builder.send(status.to_s, options)
  end

  def is_explicit_for?(in_repo, in_arch)
    return false unless is_relevant_for?(in_repo, in_arch)

    arch = architecture ? architecture.name : nil

    return false if arch.nil? && in_arch
    return false if arch && in_arch.nil?

    return false if repo.nil? && in_repo
    return false if repo && in_repo.nil?

    return true
  end

  # returns true when flag is relevant for the given repo/arch combination
  def is_relevant_for?(in_repo, in_arch)
    arch = architecture ? architecture.name : nil

    if arch.nil? && repo.nil?
      return true
    elsif arch.nil? && !repo.nil?
      return true if in_repo == repo
    elsif arch && repo.nil?
      return true if in_arch == arch
    else
      return true if in_arch == arch && in_repo == repo
    end

    return false
  end

  def specifics
    count = 0
    count += 1 if status == 'disable'
    count += 2 if architecture
    count += 4 if repo
    count
  end

  def to_s
    ret = status
    ret += " arch=#{architecture.name}" unless architecture.nil?
    ret += " repo=#{repo}" unless repo.nil?
    ret
  end

  def fullname
    ret = flag
    ret += "_#{repo}" unless repo.blank?
    ret += "_#{architecture.name}" unless architecture_id.blank?
    ret
  end

  def arch
    architecture.try(:name).to_s
  end

  def main_object
    package || project
  end

  private

  def flags_status(repo = nil, architecture_id = nil)
    # rubocop:disable Rails/FindBy
    query = (main_object.kind_of?(Package) ? main_object.project : main_object)
    query.flags.
      where(flag: flag).
      where(sql_select("repo", repo)).
      where(sql_select("architecture_id", architecture_id)).
      first.try(:status)
    # rubocop:enable Rails/FindBy
  end

  def sql_select(attr_name, value)
    if value
      ["#{attr_name} = ?", value]
    else
      "#{attr_name} IS NULL"
    end
  end

  # Flags are presented in a ui in a table.
  # The model implementation matches that.
  # So repos are on x axis, arch on y axis,
  # 'All' at the intersection.
  #
  # Both repo and arch got selected
  # FIXME: This doesn't seem to be necessary.
  #        One of them has priority anyway.
  def repo_and_arch_status
    flags_status(repo, architecture_id)
  end

  # Specific repo got selected
  def repo_status
    flags_status(repo)
  end

  # Specific arch got selected
  def arch_status
    flags_status(nil, architecture_id)
  end

  # All got selected (repo and arch are nil)
  def all_status
    flags_status
  end
end
