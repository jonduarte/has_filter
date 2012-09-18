class Article < ActiveRecord::Base
  scope :limitation, limit(1)
  scope :by_limitation, lambda{ |l| limit(l) }
  has_filter
end
