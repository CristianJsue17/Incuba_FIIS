class Ganador < ApplicationRecord
  belongs_to :equipo, class_name: 'Team' #TEAM ES LA TABLA DE EQUIPOS
  belongs_to :project
  belongs_to :program
  belongs_to :event
end

#BIEN 