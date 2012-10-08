require 'test_helper'

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
    assert_equal 0, articles.size
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

  test "ignore unrecognized attributes" do
    article = Article.create(:title => "Foo", :content => "Bar", :active => true, :category_id => 1)
    founds  = Article.filter(:active => true, :el_kabong => true)
    assert_equal article, founds.last
  end

  test "empty values" do
    Article.delete_all
    article = Article.create(:title => "Foo", :content => "Bar", :active => true, :category_id => 1)
    founds = Article.filter(:content => ["Bar", ""])
    assert_equal 1, founds.size

    founds = Article.filter("title" => "", "content" => "", "active" => ["true", "false"], :category_id => "")
    assert_equal 1, founds.size

    founds = Article.filter("title" => "", "content" => "", "active" => "false", :category_id => "")
    assert_equal 0, founds.size

    founds = Article.filter("title" => "", "content" => "", "active" => "true", :category_id => "")
    assert_equal 1, founds.size
  end

  test "keep it chainable" do
    Article.delete_all
    Article.create(:title => "Foo", :content => "Bar", :active => true, :category_id => 1)
    Article.create(:title => "Foo", :content => "Bar", :active => true, :category_id => 1)
    barz = Article.create(:title => "Foo", :content => "Barz", :active => true, :category_id => 1)

    founds = Article.filter("title" => "Foo").limit(1).all
    assert_equal 1, founds.size

    found = Article.filter("title" => "Foo").where(:content => "Barz").first
    assert_equal barz, found
  end

  test "using named scope" do
    Article.delete_all
    Article.create(:title => "Foo", :content => "Bar", :active => true, :category_id => 1)
    Article.create(:title => "Foo", :content => "Bar", :active => true, :category_id => 1)
    barz = Article.create(:title => "Foo", :content => "Barz", :active => true, :category_id => 1)

    founds = Article.filter("title" => "Foo").limitation.all
    assert_equal 1, founds.size

    found = Article.filter("title" => "Foo").where(:content => "Barz").limitation(1).first
    assert_equal barz, found
  end
end
