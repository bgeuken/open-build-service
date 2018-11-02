FactoryBot.define do
  factory :staging_project, class: 'StagingProject', parent:  do
    sequence(:name, [*'A'..'Z'].cycle) { |letter| "#{staging_workflow.project.name}:Staging:#{letter}" }
  end
end

