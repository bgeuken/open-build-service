class AddParentIdToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :parent_id, :integer
  end
end
