require 'rails_helper'

describe "assignment function" do

  describe "creation page", js: true do

    before(:each) do
      (1..3).each do |i|
        create(:course, name: "Course #{i}")
      end
    end

    #Might as well test small flags for creation here
    it "is able to create a public assignment" do
      login_as("instructor6")
      visit '/assignments/new?private=0'

      fill_in 'assignment_form_assignment_name', with: 'public assignment for test'
      select('Course 2', :from => 'assignment_form_assignment_course_id')
      fill_in 'assignment_form_assignment_directory_path', with: 'testDirectory'
      fill_in 'assignment_form_assignment_spec_location', with: 'testLocation'
      check("assignment_form_assignment_microtask")
      check("assignment_form_assignment_reviews_visible_to_all")
      check("assignment_form_assignment_is_calibrated")
      uncheck("assignment_form_assignment_availability_flag")


      click_button 'Create'
      assignment = Assignment.where(name: 'public assignment for test').first
      expect(assignment).to have_attributes(
          :name => 'public assignment for test',
          :course_id => Course.find_by_name('Course 2')[:id],
          :directory_path => 'testDirectory',
          :spec_location => 'testLocation',
          :microtask => true,
          :is_calibrated => true,
          :availability_flag => false
      )
    end
    it "is able to create a private assignment", js: true do
      login_as("instructor6")
      visit '/assignments/new?private=1'

      fill_in 'assignment_form_assignment_name', with: 'private assignment for test'
      select('Course 2', :from => 'assignment_form_assignment_course_id')
      fill_in 'assignment_form_assignment_directory_path', with: 'testDirectory'
      fill_in 'assignment_form_assignment_spec_location', with: 'testLocation'
      check("assignment_form_assignment_microtask")
      check("assignment_form_assignment_reviews_visible_to_all")
      check("assignment_form_assignment_is_calibrated")
      uncheck("assignment_form_assignment_availability_flag")

      click_button 'Create'
      assignment = Assignment.where(name: 'private assignment for test').first
      expect(assignment).to have_attributes(
          :name => 'private assignment for test',
          :course_id => Course.find_by_name('Course 2')[:id],
          :directory_path => 'testDirectory',
          :spec_location => 'testLocation'
      )
    end

    it "is able to create with teams", js: true do
      login_as("instructor6")
      visit '/assignments/new?private=1'

      fill_in 'assignment_form_assignment_name', with: 'private assignment for test'
      select('Course 2', :from => 'assignment_form_assignment_course_id')
      fill_in 'assignment_form_assignment_directory_path', with: 'testDirectory'
      check("team_assignment")
      check("assignment_form_assignment_show_teammate_reviews")
      fill_in 'assignment_form_assignment_max_team_size', with: 3

      click_button 'Create'

      assignment = Assignment.where(name: 'private assignment for test').first
      expect(assignment).to have_attributes(
          :max_team_size => 3,
          :show_teammate_reviews => true
      )
    end

    it "is able to create with quiz", js: true do
      login_as("instructor6")
      visit '/assignments/new?private=1'

      fill_in 'assignment_form_assignment_name', with: 'private assignment for test'
      select('Course 2', :from => 'assignment_form_assignment_course_id')
      fill_in 'assignment_form_assignment_directory_path', with: 'testDirectory'
      check("assignment_form_assignment_require_quiz")
      click_button 'Create'
      fill_in 'assignment_form_assignment_num_quiz_questions', with: 3
      click_button 'submit_btn'

      assignment = Assignment.where(name: 'private assignment for test').first
      expect(assignment).to have_attributes(
          :num_quiz_questions => 3,
          :require_quiz => true
      )
    end

=begin
    it "is able to create with staggered deadline", js: true do
      pending(%-not sure what's broken here but the error is: #ActionController::RoutingError: No route matches [GET] "/assets/staggered_deadline_assignment_graph/graph_1.jpg"-)
      login_as("instructor6")
      visit '/assignments/new?private=1'

      fill_in 'assignment_form_assignment_name', with: 'private assignment for test'
      select('Course 2', :from => 'assignment_form_assignment_course_id')
      fill_in 'assignment_form_assignment_directory_path', with: 'testDirectory'
      begin
        check("assignment_form_assignment_staggered_deadline")
      rescue
        return
      end
      page.driver.browser.switch_to.alert.accept
      click_button 'Create'
      fill_in 'assignment_form_assignment_days_between_submissions', with: 7
      click_button 'submit_btn'

      assignment = Assignment.where(name: 'private assignment for test').first
      expect(assignment).to have_attributes(
          :staggered_deadline => true,
          :days_between_submissions => 7
      )
    end
=end
  end

  describe "topics tab" do

    before(:each) do
      (1..3).each do |i|
        create(:course, name: "Course #{i}")
      end
      @assignment = create(:assignment, name: 'public assignment for test')
    end

    it "can edit topics properties" , js: true do
      login_as("instructor6")
      visit "/assignments/#{@assignment[:id]}/edit"
      find_link('Topics').click

      check("assignment_form_assignment_allow_suggestions")
      check("assignment_form_assignment_is_intelligent")
      check("assignment_form_assignment_can_review_same_topic")
      check("assignment_form_assignment_can_choose_topic_to_review")
      check("assignment_form_assignment_use_bookmark")
      click_button 'submit_btn'
      assignment = Assignment.where(name: 'public assignment for test').first
      expect(assignment).to have_attributes(
          :allow_suggestions => true,
          :is_intelligent => true,
          :can_review_same_topic => true,
          :can_choose_topic_to_review => true,
          :use_bookmark => true
      )
    end
    it "can edit topics properties" , js: true do
      login_as("instructor6")
      visit "/assignments/#{@assignment[:id]}/edit"
      find_link('Topics').click

      uncheck("assignment_form_assignment_allow_suggestions")
      uncheck("assignment_form_assignment_is_intelligent")
      uncheck("assignment_form_assignment_can_review_same_topic")
      uncheck("assignment_form_assignment_can_choose_topic_to_review")
      uncheck("assignment_form_assignment_use_bookmark")
      click_button 'submit_btn'
      assignment = Assignment.where(name: 'public assignment for test').first
      expect(assignment).to have_attributes(
          :allow_suggestions => false,
          :is_intelligent => false,
          :can_review_same_topic => false,
          :can_choose_topic_to_review => false,
          :use_bookmark => false
      )
    end
  end

#Begin rubric tab
  describe "rubrics tab", js:true do
    before(:each) do
      @assignment = create(:assignment)
      create_list(:participant, 3)
      create(:assignment_node)
      create(:question)
      create(:questionnaire)
      create(:assignment_questionnaire)
      (1..3).each do |i|
        create(:questionnaire, name: "ReviewQuestionnaire#{i}")
        create(:author_feedback_questionnaire, name: "AuthorFeedbackQuestionnaire#{i}")
        create(:teammate_review_questionnaire, name: "TeammateReviewQuestionnaire#{i}")
      end
    end

    describe "Load rubric questionnaire" do
      it "is able to edit assignment" do
        login_as("instructor6")
        visit '/assignments/1/edit'
        find_link('Rubrics').click
        #might find a better acceptance criteria here
        expect(page).to have_content("Review rubric varies by round")
      end
    end

#First row of rubric
    describe "Edit review rubric" do
      #
      it "updates review questionnaire", js: true do
        login_as("instructor6")
        visit '/assignments/1/edit'
        find_link('Rubrics').click
        within("tr#questionnaire_table_ReviewQuestionnaire") do
          select "ReviewQuestionnaire2", :from => 'assignment_form[assignment_questionnaire][][questionnaire_id]'
          uncheck('dropdown')
          select "Scale", :from => 'assignment_form[assignment_questionnaire][][dropdown]'
          fill_in 'assignment_form[assignment_questionnaire][][questionnaire_weight]', :with => '50'
          fill_in 'assignment_form[assignment_questionnaire][][notification_limit]', :with => '50'
        end
        click_button 'Save'
        sleep 1
        questionnaire = get_questionnaire("ReviewQuestionnaire2").first
        expect(questionnaire).to have_attributes(
                                     :questionnaire_weight => 50,
                                     :notification_limit => 50,
                                 )
      end
      #Pending tests, haven't tracked down values
      it "should update use dropdown", js: true do
        login_as("instructor6")
        visit '/assignments/1/edit'
        find_link('Rubrics').click
        within("tr#questionnaire_table_ReviewQuestionnaire") do
          select "ReviewQuestionnaire2", :from => 'assignment_form[assignment_questionnaire][][questionnaire_id]'
          uncheck('dropdown')
        end
        click_button 'Save'
        pending("can't find where this value is used")
        expect(get_questionnaire("ReviewQuestionnaire2").first).to have_attributes(:dropdown => false)
      end
      it "should update scored question dropdown", js: true do
        login_as("instructor6")
        visit '/assignments/1/edit'
        find_link('Rubrics').click
        within("tr#questionnaire_table_ReviewQuestionnaire") do
          select "ReviewQuestionnaire2", :from => 'assignment_form[assignment_questionnaire][][questionnaire_id]'
          select "Scale", :from => 'assignment_form[assignment_questionnaire][][dropdown]'
        end
        click_button 'Save'
        pending("can't find where this value is used")
        expect(get_questionnaire("ReviewQuestionnaire2").first).to have_attributes(:scored_question_display_type => false)
      end
    end

#Second row of rubric
    it "updates author feedback questionnaire", js: true do
      login_as("instructor6")
      visit '/assignments/1/edit'
      find_link('Rubrics').click
      within("tr#questionnaire_table_AuthorFeedbackQuestionnaire") do
        select "AuthorFeedbackQuestionnaire2", :from => 'assignment_form[assignment_questionnaire][][questionnaire_id]'
        uncheck('dropdown')
        select "Scale", :from => 'assignment_form[assignment_questionnaire][][dropdown]'
        fill_in 'assignment_form[assignment_questionnaire][][questionnaire_weight]', :with => '50'
        fill_in 'assignment_form[assignment_questionnaire][][notification_limit]', :with => '50'
      end
      click_button 'Save'
      questionnaire = get_questionnaire( "AuthorFeedbackQuestionnaire2").first
      expect(questionnaire).to have_attributes(
                                   :questionnaire_weight => 50,
                                   :notification_limit => 50,
                               )
    end
#Pending tests, haven't tracked down values
    it "should update use dropdown", js: true do
      login_as("instructor6")
      visit '/assignments/1/edit'
      find_link('Rubrics').click
      within("tr#questionnaire_table_AuthorFeedbackQuestionnaire") do
        select "AuthorFeedbackQuestionnaire2", :from => 'assignment_form[assignment_questionnaire][][questionnaire_id]'
        uncheck('dropdown')
      end
      click_button 'Save'
      pending("can't find where this value is used")
      expect(get_questionnaire("AuthorFeedbackQuestionnaire2").first).to have_attributes(:dropdown => false)
    end
    it "should update scored question dropdown", js: true do
      login_as("instructor6")
      visit '/assignments/1/edit'
      find_link('Rubrics').click
      within("tr#questionnaire_table_AuthorFeedbackQuestionnaire") do
        select "AuthorFeedbackQuestionnaire2", :from => 'assignment_form[assignment_questionnaire][][questionnaire_id]'
        select "Scale", :from => 'assignment_form[assignment_questionnaire][][dropdown]'
      end
      click_button 'Save'
      pending("can't find where this value is used")
      expect(get_questionnaire("AuthorFeedbackQuestionnaire2").first).to have_attributes(:scored_question_display_type => false)
    end

#Third row of rubric
    it "updates teammate review questionnaire", js: true do
      login_as("instructor6")
      visit '/assignments/1/edit'
      find_link('Rubrics').click
      within("tr#questionnaire_table_TeammateReviewQuestionnaire") do
        select "TeammateReviewQuestionnaire2", :from => 'assignment_form[assignment_questionnaire][][questionnaire_id]'
        uncheck('dropdown')
        select "Scale", :from => 'assignment_form[assignment_questionnaire][][dropdown]'
        fill_in 'assignment_form[assignment_questionnaire][][questionnaire_weight]', :with => '50'
        fill_in 'assignment_form[assignment_questionnaire][][notification_limit]', :with => '50'
      end
      click_button 'Save'
      questionnaire = get_questionnaire("TeammateReviewQuestionnaire2").first
      expect(questionnaire).to have_attributes(
                                   :questionnaire_weight => 50,
                                   :notification_limit => 50,
                               )
    end
#Pending tests, haven't tracked down values
    it "should update use dropdown", js: true do
      login_as("instructor6")
      visit '/assignments/1/edit'
      find_link('Rubrics').click
      within("tr#questionnaire_table_TeammateReviewQuestionnaire") do
        select "TeammateReviewQuestionnaire2", :from => 'assignment_form[assignment_questionnaire][][questionnaire_id]'
        uncheck('dropdown')
      end
      click_button 'Save'
      pending("can't find where this value is used")
      expect(get_questionnaire("TeammateReviewQuestionnaire2").first).to have_attributes(:dropdown => false)
    end
    it "should update scored question dropdown", js: true do
      login_as("instructor6")
      visit '/assignments/1/edit'
      find_link('Rubrics').click
      within("tr#questionnaire_table_TeammateReviewQuestionnaire") do
        select "TeammateReviewQuestionnaire2", :from => 'assignment_form[assignment_questionnaire][][questionnaire_id]'
        select "Scale", :from => 'assignment_form[assignment_questionnaire][][dropdown]'
      end
      click_button 'Save'
      pending("can't find where this value is used")
      expect(get_questionnaire("TeammateReviewQuestionnaire2").first).to have_attributes(:scored_question_display_type => false)
    end
  end

#Begin review strategy tab
  describe "review strategy tab", js:true do

    before(:each) do
      @assignment = create(:assignment, name: 'public assignment for test')
      create_list(:participant, 3)
      create(:assignment_node)
      create(:question)
      create(:questionnaire)
      create(:assignment_questionnaire)
      (1..3).each do |i|
        create(:questionnaire, name: "ReviewQuestionnaire#{i}")
        create(:author_feedback_questionnaire, name: "AuthorFeedbackQuestionnaire#{i}")
        create(:teammate_review_questionnaire, name: "TeammateReviewQuestionnaire#{i}")
      end
    end

    it "auto selects", js: true do
      login_as("instructor6")
      visit '/assignments/1/edit'
      find_link('ReviewStrategy').click
      select "Auto-Selected", :from => 'assignment_form_assignment_review_assignment_strategy'
      fill_in 'assignment_form_assignment_review_topic_threshold', :with => 3
      fill_in 'assignment_form_assignment_max_reviews_per_submission', :with => 10
      click_button 'Save'
      assignment = Assignment.where(name: 'public assignment for test').first
      expect(assignment).to have_attributes(
                                   :review_assignment_strategy => 'Auto-Selected',
                                   :review_topic_threshold => 3,
                                   :max_reviews_per_submission => 10,
                            )
    end

    it "sets number of reviews by each student", js: true do
      pending('review section not yet completed')
      login_as("instructor6")
      visit '/assignments/1/edit'
      find_link('ReviewStrategy').click
      select "Instructor-Selected", :from => 'assignment_form_assignment_review_assignment_strategy'
      check 'num_reviews_student'
      fill_in 'num_reviews_per_student', with: 5

    end
  end
end

