require 'test_helper'

class NavigationTest < ActiveSupport::IntegrationCase
  test 'able to filter' do
    visit articles_path
    assert page.has_content?('Count: 0')
  end

  test 'filter options' do
    Article.create(:title => "Foo", :content => "Bar", :active => true, :category_id => 1)
    Article.create(:title => "Foo", :content => "Bar", :active => true, :category_id => 1)
    Article.create(:title => "Foo", :content => "Bar", :active => true, :category_id => 1)

    visit articles_path
    fill_in('title', :with => 'Foo')
    click_button('send')

    assert page.has_content?('Count: 3')
    assert page.has_content?('Foo - Bar')
  end
end
