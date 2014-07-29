# HasFilter

**HasFilter** allows you to find a model with a specific set of conditions, eliminating complex sets of filter conditions in filter forms.


## Getting started

Add this line to your Gemfile:

``` ruby
gem has_filter
```

In **Rails 2.3**, you also have to add it to your `envoriment.rb`:

``` ruby
config.gem 'has_filter'
```


### Bundle

``` shell
$ bundle install
```


### Usage

``` ruby
class Post < ActiveRecord::Base
  has_filter
end
```

And now you can use:

``` ruby
Post.filter(:active => true)          #=> All active posts
Post.filter(:active => [true, false]) #=> All posts active or not
Post.filter(:title  => "Something")   #=> All that match with title Something (title like %Something%)
```

You can also specify which attributes should be filtered.

``` ruby
class Post < ActiveRecord::Base
  has_filter :title #=> It will only filter by title conditions
end
```

``` ruby
Post.filter(:active => true)                         #=> No filtering
Post.filter(:title  => "Something", :active => true) #=> All that match with title Something (title like %Something%) ignoring active condition
```
