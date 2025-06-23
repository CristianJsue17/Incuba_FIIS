# app/models/formulario_programa_preincubacion.rb
class FormularioProgramaPreincubacion < ApplicationRecord
  belongs_to :program
  
  # Validaciones solo para inscripciones reales (no plantillas del admin)
  validates :nombre_emprendimiento, presence: true, unless: :es_plantilla?
  validates :descripcion, presence: true, unless: :es_plantilla?
  validates :propuesta_valor, presence: true, unless: :es_plantilla?
  validates :numero_integrantes_equipo, presence: true, 
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10 }, 
            unless: :es_plantilla?
  validates :nombre_lider, presence: true, unless: :es_plantilla?
  validates :apellidos_lider, presence: true, unless: :es_plantilla?
  validates :dni_lider, presence: true, unless: :es_plantilla?
  validates :correo_lider, presence: true, 
            format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i }, 
            unless: :es_plantilla?
  validates :telefono_lider, presence: true, unless: :es_plantilla?
  validates :ocupacion_lider, presence: true, unless: :es_plantilla?
  validates :enteraste_programa, presence: true, unless: :es_plantilla?
  validates :expectativas_programa, presence: true, unless: :es_plantilla?

  # Scopes
  scope :plantillas, -> { where(es_plantilla: true) }
  scope :inscripciones, -> { where.not(es_plantilla: true) }

  def es_plantilla?
    es_plantilla == true
  end

  def debug_info
    {
      id: id,
      program_id: program_id,
      nombre_emprendimiento: nombre_emprendimiento,
      es_plantilla: es_plantilla,
      errors: errors.full_messages
    }
  end
end

# app/models/formulario_programa_incubacion.rb
class FormularioProgramaIncubacion < ApplicationRecord
  belongs_to :program
  
  # Validaciones solo para inscripciones reales
  validates :nombre_lider, presence: true, unless: :es_plantilla?
  validates :apellido_lider, presence: true, unless: :es_plantilla?
  validates :dni_lider, presence: true, unless: :es_plantilla?
  validates :correo_lider, presence: true, 
            format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i }, 
            unless: :es_plantilla?
  validates :telefono_lider, presence: true, unless: :es_plantilla?
  validates :nombre_proyecto, presence: true, unless: :es_plantilla?

  # Scopes
  scope :plantillas, -> { where(es_plantilla: true) }
  scope :inscripciones, -> { where.not(es_plantilla: true) }

  def es_plantilla?
    es_plantilla == true
  end

  def debug_info
    {
      id: id,
      program_id: program_id,
      nombre_lider: nombre_lider,
      nombre_proyecto: nombre_proyecto,
      es_plantilla: es_plantilla,
      errors: errors.full_messages
    }
  end
end

# app/models/formulario_programa_innovacion.rb
class FormularioProgramaInnovacion < ApplicationRecord
  belongs_to :program
  
  # Validaciones solo para inscripciones reales
  validates :nombre_lider, presence: true, unless: :es_plantilla?
  validates :apellido_lider, presence: true, unless: :es_plantilla?
  validates :dni_lider, presence: true, unless: :es_plantilla?
  validates :correo_lider, presence: true, 
            format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i }, 
            unless: :es_plantilla?
  validates :telefono_lider, presence: true, unless: :es_plantilla?
  validates :nombre_proyecto, presence: true, unless: :es_plantilla?

  # Scopes
  scope :plantillas, -> { where(es_plantilla: true) }
  scope :inscripciones, -> { where.not(es_plantilla: true) }

  def es_plantilla?
    es_plantilla == true
  end

  def debug_info
    {
      id: id,
      program_id: program_id,
      nombre_lider: nombre_lider,
      nombre_proyecto: nombre_proyecto,
      es_plantilla: es_plantilla,
      errors: errors.full_messages
    }
  end
end