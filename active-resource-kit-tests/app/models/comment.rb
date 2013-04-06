class Comment < ActiveRecord::Base
  belongs_to :post
  attr_accessible :text, :post_id
  attr_accessible :updated_at, :created_at
end
