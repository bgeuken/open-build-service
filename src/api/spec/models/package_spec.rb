require 'rails_helper'

RSpec.describe Package, vcr: true do
  let(:user) { create(:confirmed_user, login: 'tom') }
  let(:home_project) { Project.find_by(name: user.home_project_name) }
  let(:package) { create(:package, name: 'test_package', project: home_project) }
  let(:services) { package.services }

  context '#save_file' do
    before do
      User.current = user
    end

    it 'calls #addKiwiImport if filename ends with kiwi.txz' do
      Service.any_instance.expects(:addKiwiImport).once
      package.save_file({ filename: 'foo.kiwi.txz' })
    end

    it 'does not call #addKiwiImport if filename ends not with kiwi.txz' do
      Service.any_instance.expects(:addKiwiImport).never
      package.save_file({ filename: 'foo.spec' })
    end
  end

  describe '#backend_build_command' do
    let(:params) { ActionController::Parameters.new(arch: 'x86') }
    let(:backend_url) { "#{CONFIG['source_url']}/build/#{package.project.name}?cmd=rebuild&arch=x86" }

    subject { package.backend_build_command(:rebuild, package.project.name, params) }

    context 'backend response is successful' do
      before { stub_request(:post, backend_url) }

      it { is_expected.to be_truthy }
    end

    context 'backend response fails' do
      before { stub_request(:post, backend_url).and_raise(ActiveXML::Transport::Error) }

      it { is_expected.to be_falsey }
    end

    context 'user has no access rights for the project' do
      let(:other_project) { create(:project) }

      before do
        # check_write_access! depends on the Rails env. We have to workaround this here.
        allow(Rails.env).to receive(:test?).and_return false
        # also check_write_access! relies on User.current
        login(user)

        allow(Suse::Backend).to receive(:post).never
      end

      subject { package.backend_build_command(:rebuild, other_project.name, params) }

      it { is_expected.to be_falsey }
    end
  end
end
