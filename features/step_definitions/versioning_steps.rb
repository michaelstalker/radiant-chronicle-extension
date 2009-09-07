require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

Given /^I am logged in as (.*)(?: user)?$/ do |username|
  visit login_path
  fill_in "Username", :with => username
  fill_in "Password",  :with => "password"
  click_button "Login"
end

Given /^I have a (.*) page$/ do |status|
  case status
  when /published/
    @page = pages(:first)
    @page.status.should == Status[:published]
  when /draft/
    @page = pages(:draft)
    @page.status.should == Status[:draft]
  end
  @page.save
  @page.reload
end

Given /^I have a (.*) page with a draft$/ do |status|
  Given "I have a #{status} page"
  @page.title = "#{@page.title} Draft"
  @page.status = Status[:draft]
  lambda { @page.save }.should change{ @page.versions.length }.by(1)
  @page.reload
end

Given /^I have a page with more than one version$/ do
  Given "I have a published page with a draft"
  @page.status = Status[:published]
  @page.title = @page.title += " Version 2"
  @page.save
end

When /^I edit the page$/ do
  visit admin_pages_path
  click_link @page.title
  fill_in "Page Title", :with => "Edited"
end

When /^I save it as (?:a )?(draft|published)$/ do |status|
  select status.titleize, :from => "Status"
  click_button "Save"
end

When /^I click the revert button$/ do
  click_button "Revert to Version 1"
end

When /^I edit a previous version$/ do
  visit edit_admin_page_path(:id => @page.id, :version => 1)
end

Then /^I should be taken to the edit page$/ do
  request.params.should == {"format"=>"html", "action"=>"edit", "id"=>"520095529", "version"=>"1", "controller"=>"admin/pages"}
  response.should have_selector('h1', :content => "Edit Page")
end

Then /^the older content should be loaded$/ do
  field_labeled("Page Title").value.should_not == @page.current.title
end

Then /^the content I am editing should be the draft$/ do
  field_labeled("Page Title").value.should =~ /.+ Draft/
end

Then /^the page should be saved$/ do
  @page.current.title.should == "Edited"
end

Then /^not change the live version$/ do
  @page.reload.title.should_not == "Edited"
end

Then /^change the live version$/ do
  @page.reload.title.should == "Edited"
end

When /^I view a previous version$/ do
  visit admin_versions_path
  click_link "Version 1"
  @current_version = 1
end

When /^I view a version$/ do
  visit admin_versions_path
  click_link "Version 2"
  @current_version = 2
end

When /^I click on a different version$/ do
  @current_version.should == 2
  click_link "version-1"
  @current_version = 1
end

Then /^I should see a timeline$/ do
  response.should have_selector("#timeline")
end

Then /^the timeline should have a chevron to indicate where I am$/ do
  case request.path
  when /pages/
    response.should have_selector("#working-version #this-marker")
  when /versions/
    response.should contain("Version #{@current_version}")
    response.should have_selector("#version-#{@current_version} #this-marker")
  end
end

Then /^I should see that version's diff$/ do
  response.should contain("Version #{@current_version}")
end

Given /^I have two layouts$/ do
  Layout.count.should >= 2
end

When /^I change the draft page's layout$/ do
  select "UTF8", :from => "Layout"
end

Then /^the live version should have the different layout$/ do
  @page.reload.layout.name.should == "UTF8"
end


