class RenameDownloadRepositoryToDodSource < ActiveRecord::Migration
  def change
    rename_table :download_repositories, :dod_sources
  end
end
