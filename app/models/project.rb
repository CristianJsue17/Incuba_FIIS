class Project < ApplicationRecord
  belongs_to :equipo, class_name: 'Team'  # TEAM ES LA TABLA DE EQUIPOS
  belongs_to :lider, class_name: 'User'  # LIDER ES LA TABLA DE USUARIOS
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
end

# BIEN