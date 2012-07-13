# HasFilter

Active Record filter conditions

It's allows you to find a model with a specific set of conditions, eliminating complex set of filter conditions in filter forms.


## Getting started

Install - Gemfile

`gem has_filter`


### Rails 2.3

In rails 2.3 also needs add to `envoriment.rb`

```ruby
config.gem 'has_filter'
```

### Bundle

`$ bundle install`


### Usage

```ruby
class Post < ActiveRecord::Base
  has_filter
end
```

And now you can use:

```ruby
Post.filter(:active => true)          #=> All active posts
Post.filter(:active => [true, false]) #=> All posts active or not
Post.filter(:title  => "Something")   #=> All that match with title Something (title like %Something%)
```
You can also specify what attributes should be filtered

```ruby
class Post < ActiveRecord::Base
  has_filter :title #=> It will only filter by title conditions
end
```

```ruby
Post.filter(:active => true)                         #=> No filtering
Post.filter(:title  => "Something", :active => true) #=> All that match with title Something (title like %Something%) ignoring active condition
```

### Limit

By default the max of records is 100, by you can specify other amount:

```ruby
Article.filter({:status => "open"}, 1)   #=> Retrieve just one element
```

Note which when we specify a limit, we need to wrap our options in a hash
