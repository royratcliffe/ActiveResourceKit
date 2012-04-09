class Post < ActiveRecord::Base
  has_many :comments
  belongs_to :person
end
