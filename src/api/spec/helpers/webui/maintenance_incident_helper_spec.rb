require 'rails_helper'

RSpec.describe Webui::MaintenanceIncidentHelper, type: :helper do
  describe '#release_target_repos' do
    let(:maintenance_incident) { create(:maintenance_incident_project) }
    let!(:target_repo_1) { create(:repository_with_release_target, project: maintenance_incident) }
    let!(:target_repo_2) { create(:repository_with_release_target, project: maintenance_incident) }
    let!(:release_target) { create(:release_target, repository: target_repo_2) }

    subject { release_target_repos(maintenance_incident) }

    context 'returns all target projects with their repositories' do
      it { expect(subject.length).to eq(3) }
      it { expect(subject[0].name).to eq(target_repo_1.name) }
      it { expect(subject[0].prj_name).to eq(target_repo_1.release_targets.first.target_repository.project.name) }
      it { expect(subject[1].name).to eq(target_repo_2.name) }
      it { expect(subject[1].prj_name).to eq(target_repo_2.release_targets.first.target_repository.project.name) }
      it { expect(subject[2].name).to eq(target_repo_2.name) }
      it { expect(subject[2].prj_name).to eq(release_target.target_repository.project.name) }
    end
  end
end
