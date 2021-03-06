require 'rails_helper'

describe "Front end builds API", type: :request do
  let(:front_end_app) { FactoryGirl.create :front_end_builds_app, name: "dummy" }

  before(:each) do
    stub_request(
      :get,
      "www.ted.com/builds/1"
    ).to_return(
      body: 'your app!'
    )
  end

  it "creates a new build and then uses it" do
    post "/dummy",
      api_key: front_end_app.api_key,
      branch: "master",
      sha: "a1b2c3",
      job: "jenkins-build-1",
      endpoint: "http://www.ted.com/builds/1"

    expect(response).to be_success

    # Index loads
    get "/dummy"
    expect(response).to be_success
    expect(response.body).to match(/your app!$/)

    # Deep routes load
    get "/dummy/posts/1"
    expect(response).to be_success
    expect(response.body).to match(/your app!$/)
  end

  it "should be able to create a build from a generic endpoint" do
    post "/front_end_builds/builds",
      app_name: 'dummy',
      api_key: front_end_app.api_key,
      branch: "master",
      sha: "a1b2c3",
      job: "jenkins-build-1",
      endpoint: "http://www.ted.com/builds/1"

    expect(response).to be_success
    expect(front_end_app.builds.length).to eq(1)
    expect(front_end_app.builds.first.html).to eq('your app!')
  end
end
