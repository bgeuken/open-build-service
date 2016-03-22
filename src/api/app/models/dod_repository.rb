class DODRepository < Repository
  # NOTE that this is a sub class of Repository. Most associations and methods are
  #      defined there. Only add DOD specific things here.

  has_many :dod_sources, :dependent => :delete_all, :class_name => "DODSource", foreign_key: :repository_id

  # DOD repos must have at least one DOD source
#  validates :dod_sources, presence: true
  validates :dod_sources, uniqueness: { scope: :arch } # , presence: true

#  after_destroy delete architectures needed?

  def initialize(attributes = nil, options = {})
    dod_attributes = attributes.delete(:dod_attributes)

    super(attributes, options)

    self.add_dod_source!(dod_attributes)
  end

#  def self.create_dod_repository!(name, arch, dod_attributes)
#    repository = Repository.create!(name: name) # validation?
#    repository.repository_architectures.create!(architecture: Architecture.find_by(name: arch), position: 1)
#    repository.add_dod_repository!(dod_attributes)
#  end

  def add_dod_source!(dod_attributes)
    # transaction
    self.repository_architectures.create!(architecture: Architecture.find_by(name: dod_attributes[:arch]), position: 1)
    self.dod_sources.create!(dod_attributes)
  end
end
