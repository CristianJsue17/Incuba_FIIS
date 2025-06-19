class FormularioProgramaPreincubacion < ApplicationRecord
  belongs_to :program
  accepts_nested_attributes_for :program
  
  # Validaciones de presencia
  validates :nombre_emprendimiento, presence: true
  validates :descripcion, presence: true
  validates :propuesta_valor, presence: true
  validates :numero_integrantes_equipo, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10 }
  validates :nombre_lider, presence: true
  validates :apellidos_lider, presence: true
  validates :dni_lider, presence: true
  validates :correo_lider, presence: true, format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i }
  validates :telefono_lider, presence: true
  validates :ocupacion_lider, presence: true
  validates :enteraste_programa, presence: true
  validates :expectativas_programa, presence: true
  
  # Opcional: Método para debuggear
  def debug_info
    {
      id: id,
      program_id: program_id,
      nombre_emprendimiento: nombre_emprendimiento,
      # Otros campos relevantes...
      errors: errors.full_messages
    }
  end
end