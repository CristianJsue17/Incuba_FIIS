class Team < ApplicationRecord
  belongs_to :mentor, class_name: 'User' # MENTOR ES LA TABLA DE USUARIOS
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
end
#bien