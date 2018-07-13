class AssignParentProjects < ActiveRecord::Migration[5.2]
  def up
    Project.where(parent: nil).find_each do |project|
      project.set_parent
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
