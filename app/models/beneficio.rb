class Beneficio < ApplicationRecord
    has_many :program_beneficios
    has_many :programs, through: :program_beneficios
end

#bien