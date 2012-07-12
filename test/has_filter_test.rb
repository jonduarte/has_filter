require 'test_helper'

class Article < ActiveRecord::Base
  establish_connection :adapter => 'sqlite3', :database => ':memory:'
  connection.create_table table_name do |t|
    t.string  :title
    t.text    :content
    t.boolean :active, :default => false
    t.integer :category_id
  end

  has_filter
end

class Post < ActiveRecord::Base
  establish_connection :adapter => 'sqlite3', :database => ':memory:'
  connection.create_table table_name do |t|
    t.string  :title
    t.text    :content
    t.boolean :active, :default => false
    t.integer :category_id
  end

  has_filter :title
end

class Activity < ActiveRecord::Base
  establish_connection :adapter => 'sqlite3', :database => ':memory:'
  connection.create_table table_name do |t|
    t.integer :category_id
    t.integer :school_grade_id
    t.integer :discipline_id
    t.integer :custom_theme_id
    t.integer :custom_subject_id
    t.string  :objective
    t.string  :pcn
    t.string  :name
    t.string  :status
  end

  has_filter
end

class HasFilterTest < ActiveSupport::TestCase
  test "create an article instance" do
    article = Article.create(:title => "Foo", :content => "Bar", :active => true, :category_id => 1)
    assert_kind_of Article, article
    assert_equal "Foo", article.title
    assert_equal "Bar", article.content
    assert_equal true, article.active
    assert_equal 1, article.category_id
  end

  test "filter basic object" do
    article = Article.create(:title => "Foo", :content => "Bar", :active => true, :category_id => 1)
    founds  = Article.filter(:active => true)
    assert_equal article, founds.last
  end

  test "filter with two conditions" do
    article = Article.create(:title => "Foo", :content => "Baz", :active => true, :category_id => 1)
    founds  = Article.filter(:active => true, :content => "Baz")
    assert_equal article, founds.last
    assert_equal "Baz", founds.last.content
  end

  test "with multiple type" do
    Article.create(:title => "Active", :active => true)
    Article.create(:title => "Active")

    articles = Article.filter(:title => "Active", :active => true)
    assert_equal 1, articles.size
    assert_equal "Active", articles.first.title
  end

  test "with nil filters" do
    Article.delete_all
    Article.create(:title => "Active", :active => true)
    Article.create(:title => "Active")

    articles = Article.filter(:title => nil, :active => nil)
    assert_equal 2, articles.size
    assert_equal "Active", articles.first.title
  end

  test "filter allowed fields" do
    Post.create(:active => false, :title => "Post 1")
    Post.create(:active => true, :title => "Post 2")

    posts = Post.filter(:active => true)
    assert_equal 0, posts.size

    posts = Post.filter(:title => "Post", :active => true)
    assert_equal 2, posts.size
    assert_equal "Post 1", posts.first.title
  end

  test "when string filter with like" do
    Post.create(:title => "filter")
    Post.create(:title => "filter option")
    Post.create(:title => "Filber")

    posts = Post.filter(:title => "Filter")
    assert_equal 2, posts.size
    assert_equal ["filter", "filter option"], posts.map(&:title)
  end

  test "with array option" do
    Article.delete_all
    Article.create(:title => "filter", :active => true)
    Article.create(:title => "Test", :active => true)
    Article.create(:title => "Coding", :active => false)

    articles = Article.filter(:title => "ing", :active => [true, false])
    assert_equal 1, articles.size

    articles = Article.filter(:active => [true, false])
    assert_equal 3, articles.size
  end

  test "multiple array conditions" do
    activities = []
    2.times do
      activities << Activity.create(:school_grade_id   => 1,
                      :discipline_id     => 1,
                      :custom_theme_id   => 1,
                      :custom_subject_id => 1,
                      :objective         => "some objetive",
                      :pcn               => "some pcn",
                      :name              => nil,
                      :status            => "inactive")
    end

    Activity.create(:school_grade_id   => 3,
                    :discipline_id     => 1,
                    :custom_theme_id   => 1,
                    :custom_subject_id => 1,
                    :objective         => "some objetive",
                    :pcn               => "some pcn",
                    :name              => nil,
                    :status            => "inactive")

    multiple_conditions = {:custom_theme_id   => 1,
                           :pcn               => "some pcn",
                           :school_grade_id   => 1,
                           :objective         => "some objetive",
                           :custom_subject_id => 1,
                           :status            => "inactive",
                           :discipline_id     => 1 }

    results = Activity.filter(multiple_conditions)
    assert_equal 2, results.size
    assert_equal results, activities
  end

  test "ignore unrecognized attributes" do
    article = Article.create(:title => "Foo", :content => "Bar", :active => true, :category_id => 1)
    founds  = Article.filter(:active => true, :el_kabong => true)
    assert_equal article, founds.last
  end

  test "no conditions no results" do
    article = Article.create(:title => "Foo", :content => "Bar", :active => true, :category_id => 1)
    founds = Article.filter
    assert_equal 0, founds.size
  end

  test "empty array values" do
    Article.delete_all
    article = Article.create(:title => "Foo", :content => "Bar", :active => true, :category_id => 1)
    founds = Article.filter(:content => ["Bar", ""])
    assert_equal 1, founds.size
  end
end
