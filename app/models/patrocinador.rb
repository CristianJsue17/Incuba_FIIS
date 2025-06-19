class Patrocinador < ApplicationRecord
    has_many :programs_patrocinadors
    has_many :programs, through: :programs_patrocinadors
    
    belongs_to :created_by, class_name: 'User', optional: true
    belongs_to :updated_by, class_name: 'User', optional: true

    has_one_attached :logo
end

#bien