require "spec_helper"

describe "logged in user" do
  include Rack::Test::Methods

  def app
    JekyllAuth.site
  end

  before(:each) do
    setup_tmp_dir
    @user = make_user('login' => 'benbaltertest')
    login_as @user

    stub_request(:get, "https://api.github.com/orgs/#{ENV["GITHUB_ORG_ID"]}/members/benbaltertest").
    to_return(:status => 200)
  end

  it "shows the securocat when github returns an oauth error" do
    get "/auth/github/callback?error=redirect_uri_mismatch"
    expect(last_response.body).to match(%r{securocat\.png})
  end

  it "logs the user out" do
    get "/logout"
    expect(last_response.status).to eql(302)
    expect(last_response.headers['Location']).to eql("http://example.org/")

    get "/"
    expect(last_response.status).to eql(302)
    expect(last_response.headers['Location']).to match(%r{^https://github\.com/login/oauth/authorize})
  end

end

describe "logged out user" do

  include Rack::Test::Methods

  def app
    JekyllAuth.site
  end

  it "doesn't let you view indexes" do
    get "/"
    expect(last_response.status).to eql(302)
    expect(last_response.headers['Location']).to match(%r{^https://github\.com/login/oauth/authorize})

    get "/some_dir"
    expect(last_response.status).to eql(302)
    expect(last_response.headers['Location']).to match(%r{^https://github\.com/login/oauth/authorize})
  end

  it "doesn't let you view files" do
    get "/index.html"
    expect(last_response.status).to eql(302)
    expect(last_response.headers['Location']).to match(%r{^https://github\.com/login/oauth/authorize})

    get "/some_dir/index.html"
    expect(last_response.status).to eql(302)
    expect(last_response.headers['Location']).to match(%r{^https://github\.com/login/oauth/authorize})
  end

  it "refuses to serve the site without an authentication strategy" do
    ENV["GITHUB_ORG_ID"] = nil
    ENV["GITHUB_TEAM_ID"] = nil
    ENV["GITHUB_TEAMS_ID"] = nil
    get "/"
    expect(last_response.body).to match(%r{JekyllAuth::ConfigError})
    expect(last_response.status).to eql(500)
  end
end