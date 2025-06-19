# app/models/formulario_programa_incubacion.rb
class FormularioProgramaIncubacion < ApplicationRecord
  belongs_to :program
  accepts_nested_attributes_for :program
end

#BIEN