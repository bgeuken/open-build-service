require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Cloud::UploadJobsController, vcr: true do
  let!(:ec2_configuration) { create(:ec2_configuration) }
  let!(:user_with_ec2_configuration) { create(:confirmed_user, login: 'tom', ec2_configuration: ec2_configuration) }
  let(:project) { create(:project, name: 'Apache') }
  let!(:package) { create(:package, name: 'apache2', project: project) }
  let(:upload_job) { create(:upload_job, user: user_with_ec2_configuration) }
  let(:xml_response) do
    <<-HEREDOC
    <clouduploadjob name="6">
      <state>created</state>
      <details>waiting to receive image</details>
      <created>1513604055</created>
      <user>mlschroe</user>
      <target>ec2</target>
      <project>Base:System</project>
      <repository>openSUSE_Factory</repository>
      <package>rpm</package>
      <arch>x86_64</arch>
      <filename>rpm-4.14.0-504.2.x86_64.rpm</filename>
      <size>1690860</size>
    </clouduploadjob>
    HEREDOC
  end

  before do
    login(user_with_ec2_configuration)
  end

  describe '#index' do
    context 'with cloud_upload feature enabled' do
      let(:path) { "#{CONFIG['source_url']}/cloudupload?name=#{upload_job.job_id}" }
      let(:xml_response_list) do
        <<-HEREDOC
        <clouduploadjoblist>
          #{xml_response}
        </clouduploadjoblist>
        HEREDOC
      end

      context 'without an EC2 configuration' do
        let(:user) { create(:confirmed_user) }

        before do
          login(user)
          Feature.run_with_activated(:cloud_upload) do
            get :index, format: 'xml'
          end
        end

        it { expect(response.header['X-Opensuse-Errorcode']).to eq('cloud_upload_job_no_config') }
        it { expect(response).to have_http_status(:bad_request) }
      end

      context 'with an EC2 configuration' do
        before do
          stub_request(:get, path).and_return(body: xml_response_list)
          get :index, format: 'xml'
        end

        it 'returns an xml response with all cloud upload jobs listed' do
          expect(Xmlhash.parse(response.body)).to eq(Xmlhash.parse(xml_response_list))
        end
        it { expect(response).to be_success }
      end
    end

    context 'with cloud_upload feature disabled' do
      before do
        Feature.run_with_deactivated(:cloud_upload) do
          get :index, format: 'xml'
        end
      end

      it { expect(response).to be_not_found }
    end
  end

  describe 'POST #create' do
    let(:params) do
      {
        project:    'Cloud',
        package:    'aws',
        repository: 'standard',
        arch:       'x86_64',
        filename:   'appliance.raw.xz',
        region:     'us-east-1',
        ami_name:   'my-image',
        target:     'ec2'
      }
    end

    context 'requested with invalid data' do
      before do
        post :create, params: { cloud_backend_upload_job: { region: 'nuernberg-southside' }, format: 'xml' }
      end

      it { expect(response.header['X-Opensuse-Errorcode']).to eq('cloud_upload_job_invalid') }
      it { expect(response).to have_http_status(:bad_request) }
    end

    context 'with a backend response' do
      let(:path) { "#{CONFIG['source_url']}/cloudupload?#{backend_params.to_param}" }
      let(:backend_params) do
        params.merge(target: 'ec2', user: user_with_ec2_configuration.login).except(:region, :ami_name)
      end
      let(:additional_data) do
        {
          region:   'us-east-1',
          ami_name: 'my-image'
        }
      end
      let(:post_body) do
        user_with_ec2_configuration.ec2_configuration.attributes.except('id', 'created_at', 'updated_at').merge(additional_data).to_json
      end

      before do
        stub_request(:post, path).with(body: post_body).and_return(body: xml_response)
        post :create, format: 'xml', params: { cloud_backend_upload_job: params }
      end

      it { expect(Cloud::User::UploadJob.last.job_id).to eq(6) }
      it { expect(Cloud::User::UploadJob.last.user).to eq(user_with_ec2_configuration) }
      it { expect(response).to be_success }
      it 'returns an xml response of the created cloud upload job' do
        assert_select "cloud_upload_job[id='6']" do
          assert_select 'target', text: 'ec2'
          assert_select 'filename', text: 'appliance.raw.xz'
          assert_select 'vpc_subnet_id'
          assert_select 'cloud_upload_params' do
            assert_select 'ami_name', text: 'my-image'
            assert_select 'region', text: 'us-east-1'
          end
        end
      end
    end
  end
end
