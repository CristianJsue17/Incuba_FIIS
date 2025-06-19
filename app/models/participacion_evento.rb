class ParticipacionEvento < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :equipo, class_name: 'Team' # TEAM ES LA TABLA DE EQUIPOS
  belongs_to :project
end

#bien 