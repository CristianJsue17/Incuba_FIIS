class Objetivo < ApplicationRecord
    has_many :program_objetivos
    has_many :programs, through: :program_objetivos
end
# #bien