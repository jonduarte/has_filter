# HasFilter

Active Record filter conditions

It's allows you to find a model with a specific set of conditions, eliminating complex set of filter conditions in filter forms.


## Getting started

Install - Gemfile

`gem has_filter`


`$ bundle install`


```ruby
class Post < ActiveRecord::Base
  has_filter
end
```

And now you can use:

```ruby
Post.filtering(:active => true)          #=> All active posts
Post.filtering(:active => [true, false]) #=> All posts active or not
Post.filtering(:title  => "Something")   #=> All that match with title Something (title like %Something%)
```
You can also specify what attributes should be filtered

```ruby
class Post < ActiveRecord::Base
  has_filter :title #=> It will only filter by title conditions
end
```

```ruby
Post.filtering(:active => true)                         #=> No filtering
Post.filtering(:title  => "Something", :active => true) #=> All that match with title Something (title like %Something%) ignoring active condition
```


