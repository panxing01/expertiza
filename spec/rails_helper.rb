# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rspec'
require 'capybara/rails'
# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end
   config.before(:each) do |example|
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end



  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  def login_as(user_name)
    user = User.find_by_name(user_name)
    msg = user.to_yaml
    File.open('log/diagnostic.txt', 'a') { |f| f.write msg }

    visit root_path
    fill_in 'login_name', with: user_name
    fill_in 'login_password', with: 'password'
    click_button 'SIGN IN'
    stub_current_user(user, user.role.name, user.role)
  end

  def stub_current_user(current_user, current_role_name='Student', current_role)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(current_user)
    allow_any_instance_of(ApplicationController).to receive(:current_role_name).and_return(current_role_name)
    allow_any_instance_of(ApplicationController).to receive(:current_role).and_return(current_role)
  end
 def questionnaire_options(assignment, type, round=0)
    questionnaires = Questionnaire.where( ['private = 0 or instructor_id = ?', assignment.instructor_id]).order('name')
    options = Array.new
    questionnaires.select { |x| x.type == type }.each do |questionnaire|
      options << [questionnaire.name, questionnaire.id]
    end
    options
  end

  def get_questionnaire(finder_var = nil)
    if finder_var.nil?
      AssignmentQuestionnaire.find_by_assignment_id(@assignment[:id])
    else
      AssignmentQuestionnaire.where(:assignment_id=>@assignment[:id]).where(:questionnaire_id=>get_selected_id(finder_var))
    end
  end

  def get_selected_id(finder_var)
    if finder_var == "ReviewQuestionnaire2"
      ReviewQuestionnaire.find_by_name(finder_var)[:id]
    elsif finder_var == "AuthorFeedbackQuestionnaire2"
      AuthorFeedbackQuestionnaire.find_by_name(finder_var)[:id]
    elsif finder_var == "TeammateReviewQuestionnaire2"
      TeammateReviewQuestionnaire.find_by_name(finder_var)[:id]
    end
  end
end

