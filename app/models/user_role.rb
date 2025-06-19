class UserRole < ApplicationRecord
  belongs_to :user
  belongs_to :role

  has_one_attached :avatar      # imagen
end
#bien