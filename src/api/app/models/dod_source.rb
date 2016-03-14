class DODSource < ActiveRecord::Base
  REPOTYPES = ["rpmmd", "susetags", "deb", "arch", "mdk"]

  belongs_to :dod_repository

  validates :repository_id, presence: true
  validates :arch, inclusion: { in: Architecture.all.pluck(:name) }, presence: true
  validates :url, presence: true
  validates :repotype, presence: true
  validates :repotype, inclusion: { in: REPOTYPES }

  delegate :to_s, to: :id
end
