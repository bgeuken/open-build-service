require 'rails_helper'
require 'webmock/rspec'

RSpec.describe StagingProject, vcr: false do
  let(:user) { create(:confirmed_user, login: 'tom') }
  let(:staging_workflow) { create(:staging_workflow_with_staging_projects, project: user.home_project) }
  let(:staging_project) { staging_workflow.staging_projects.first }

  let!(:repository) { create(:repository, architectures: ['x86_64'], project: staging_project, name: 'staging_repository') }
  let!(:package) { create(:package_with_file, project: staging_project) }

  # FIXME: fix tests. We might need to stub all backend requests
  context 'a project with broken build state' do
    describe '#building_repositories' do
      subject { staging_project.building_repositories }

      it do
        is_expected.to contain_exactly({ 'repository' => 'staging_repository',
                                         'arch' => 'x86_64',
                                         'code' => 'broken',
                                         'state' => 'broken',
                                         tobuild: 0,
                                         final: 0 })
      end
    end

    describe '#broken_packages' do
      subject { staging_project.broken_packages }

      it { is_expected.to be_empty } # FIXME: The model code looks like some content would be expected here
    end
  end

  context 'a project with a build state' do
    let(:backend_url) { "/build/#{CGI.escape(staging_project.name)}/_result?view=summary" }
    let(:xml) {
      <<~XML
        <resultlist state="dea55075a09a8497bad40a28c01cfdad">
          <result project="#{staging_project}" repository="#{repository.name}" arch="x86_64" code="published" state="published">
            <summary>
              <statuscount code="succeeded" count="5"/>
              <statuscount code="excluded" count="5"/>
            </summary>
          </result>
        </resultlist>
      XML
    }

    before do
      stub_request(:get, backend_url).and_return(body: xml)
    end

    describe '#broken_packages' do
      subject { staging_project.broken_packages }

      it { is_expected.to be_empty }
    end

    describe '#building_repositories' do
      subject { staging_project.building_repositories }

      it do
        is_expected.to contain_exactly({ 'repository' => 'staging_repository',
                                         'arch' => 'x86_64',
                                         'code' => 'published',
                                         'state' => 'published',
                                         tobuild: 0,
                                         final: 5 })
      end
    end
  end
end
