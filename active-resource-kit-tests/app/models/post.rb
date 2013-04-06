class Post < ActiveRecord::Base
  has_many :comments
  belongs_to :poster
  attr_accessible :title, :body, :published, :poster_id
  attr_accessible :updated_at, :created_at
end
