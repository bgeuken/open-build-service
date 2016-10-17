require 'rails_helper'

RSpec.describe SourceController, vcr: true do
  let(:user) { create(:confirmed_user) }

  describe "POST #global_command_orderkiwirepos" do
    it "does not allow anonymous access" do
      post :global_command, params: { cmd: "orderkiwirepos" }
      expect(flash[:error]).to eq("anonymous_user(Anonymous user is not allowed here - please login): ")
      expect(response).to redirect_to(root_path)
    end

    context "without xml configuration" do
      it "replies with the backend error" do
        login(user)
        post :global_command, params: { cmd: "orderkiwirepos" }
        expect(response).to have_http_status(:bad_request)
        expect(Xmlhash.parse(response.body)["summary"]).to eq("read_file: no content attached")
      end
    end
  end
end
