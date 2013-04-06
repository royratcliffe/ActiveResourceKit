class Person < ActiveRecord::Base
  has_many :posts
  attr_accessible :name
  attr_accessible :updated_at, :created_at
end
