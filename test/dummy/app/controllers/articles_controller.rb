class ArticlesController < ApplicationController
  def index
    @articles = Article.all rescue []
  end

  def search
    @articles = Article.filter(params)
    render :index
  end

  def show

  end
end
