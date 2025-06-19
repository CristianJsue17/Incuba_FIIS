class Requisito < ApplicationRecord
    has_many :program_requisitos
    has_many :programs, through: :program_requisitos
end

#BIEN