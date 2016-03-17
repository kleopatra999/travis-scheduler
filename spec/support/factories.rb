require 'factory_girl'

FactoryGirl.define do
  factory :build do
    owner { User.first || FactoryGirl.create(:user) }
    repository { Repository.first || FactoryGirl.create(:repository) }
    association :request
    association :commit
    started_at { Time.now.utc }
    finished_at { Time.now.utc }
    number 1
    state :passed
  end

  factory :commit do
    commit '62aae5f70ceee39123ef'
    branch 'master'
    message 'the commit message'
    committed_at '2011-11-11T11:11:11Z'
    committer_name 'Sven Fuchs'
    committer_email 'svenfuchs@artweb-design.de'
    author_name 'Sven Fuchs'
    author_email 'svenfuchs@artweb-design.de'
    compare_url 'https://github.com/svenfuchs/minimal/compare/master...develop'
  end

  factory :job do
    owner      { User.first || FactoryGirl.create(:user) }
    repository { Repository.first || FactoryGirl.create(:repository) }
    commit     { FactoryGirl.create(:commit) }
    source     { FactoryGirl.create(:build) }
    config     { { 'rvm' => '1.8.7', 'gemfile' => 'test/Gemfile.rails-2.3.x' } }
    type       'test' # legacy
    number     '2.1'
  end

  factory :log do
    content '$ bundle install --pa'
  end

  factory :request do
    repository { Repository.first || FactoryGirl.create(:repository) }
    association :commit
    token 'the-token'
    event_type 'push'
  end

  REPO_KEY = OpenSSL::PKey::RSA.generate(4096)

  factory :repository do
    owner { User.find_by_login('svenfuchs') || FactoryGirl.create(:user) }
    name 'minimal'
    owner_name 'svenfuchs'
    owner_email 'svenfuchs@artweb-design.de'
    active true
    url { |r| "http://github.com/#{r.owner_name}/#{r.name}" }
    created_at { |r| Time.utc(2011, 01, 30, 5, 25) }
    updated_at { |r| r.created_at + 5.minutes }
    last_build_state :passed
    last_build_number '2'
    last_build_id 2
    last_build_started_at { Time.now.utc }
    last_build_finished_at { Time.now.utc }
    sequence(:github_id) {|n| n }
    key { SslKey.create(public_key: REPO_KEY.public_key, private_key: REPO_KEY.to_pem) }
  end

  factory :minimal, :parent => :repository do
  end

  factory :enginex, :parent => :repository do
    name 'enginex'
    owner_name 'josevalim'
    owner_email 'josevalim@email.com'
    owner { User.find_by_login('josevalim') || FactoryGirl.create(:user, :login => 'josevalim') }
  end

  factory :event do
    repository { Repository.first || FactoryGirl.create(:repository) }
    source { Build.first || FactoryGirl.create(:build) }
    event 'build:started'
  end

  factory :user do
    name  'Sven Fuchs'
    login 'svenfuchs'
    email 'sven@fuchs.com'
    github_oauth_token 'github_oauth_token'
  end

  factory :org, :class => 'Organization' do
    name 'travis-ci'
  end

  factory :running_build, :parent => :build do
    repository { FactoryGirl(:repository, :name => 'running_build') }
    state :started
  end

  factory :successful_build, :parent => :build do
    repository { |b| FactoryGirl(:repository, :name => 'successful_build') }
    state :passed
    started_at { Time.now.utc }
    finished_at { Time.now.utc }
  end

  factory :broken_build, :parent => :build do
    repository { FactoryGirl(:repository, :name => 'broken_build', :last_build_state => :failed) }
    state :failed
    started_at { Time.now.utc }
    finished_at { Time.now.utc }
  end

  factory :broken_build_with_tags, :parent => :build do
    repository  { FactoryGirl(:repository, :name => 'broken_build_with_tags', :last_build_state => :errored) }
    matrix      {[FactoryGirl(:test, :tags => "database_missing,rake_not_bundled",   :number => "1.1"),
                  FactoryGirl(:test, :tags => "database_missing,log_limit_exceeded", :number => "1.2")]}
    state       :failed
    started_at  { Time.now.utc }
    finished_at { Time.now.utc }
  end

  factory :annotation do
    url "https://travis-ci.org/travis-ci/travis-ci/jobs/12345"
    description "Job passed"
    job { FactoryGirl.create(:test) }
    annotation_provider { FactoryGirl.create(:annotation_provider) }
  end

  factory :annotation_provider do
    name "Travis CI"
    api_username "travis-ci"
    api_key "0123456789abcdef"
  end
end

