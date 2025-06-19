# app/models/formulario_programa_innovacion.rb
class FormularioProgramaInnovacion < ApplicationRecord
  belongs_to :program
  accepts_nested_attributes_for :program
end

#BIEN