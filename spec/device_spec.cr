require "./spec_helper"

module Motion
  describe Motion::Configuration do
    client = AC::SpecHelper.client

    it "should list devices available" do
      result = client.get("/api/edge/ai/devices/video")
      puts JSON.parse(result.body).to_pretty_json
      result.success?.should be_true
    end
  end
end
