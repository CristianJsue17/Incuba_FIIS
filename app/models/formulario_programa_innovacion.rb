# app/models/formulario_programa_innovacion.rb
class FormularioProgramaInnovacion < ApplicationRecord
  belongs_to :program
  
  # Validaciones solo para inscripciones reales (no plantillas del admin)
  validates :nombre_lider, presence: { message: "no puede estar vacío" }, 
            length: { maximum: 100 }, 
            unless: :es_plantilla?
            
  validates :apellido_lider, presence: { message: "no puede estar vacío" }, 
            length: { maximum: 100 }, 
            unless: :es_plantilla?
            
  validates :dni_lider, presence: { message: "no puede estar vacío" }, 
            length: { is: 8, message: "debe tener exactamente 8 dígitos" },
            format: { with: /\A\d{8}\z/, message: "debe contener solo números" },
            unless: :es_plantilla?
            
  validates :correo_lider, presence: { message: "no puede estar vacío" }, 
            format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i, 
                     message: "debe tener un formato válido" }, 
            unless: :es_plantilla?
            
  validates :telefono_lider, presence: { message: "no puede estar vacío" },
            length: { in: 7..15, message: "debe tener entre 7 y 15 dígitos" },
            format: { with: /\A\d+\z/, message: "debe contener solo números" },
            unless: :es_plantilla?
            
  validates :nombre_proyecto, presence: { message: "no puede estar vacío" }, 
            length: { maximum: 200 }, 
            unless: :es_plantilla?

  # Scopes
  scope :plantillas, -> { where(es_plantilla: true) }
  scope :inscripciones, -> { where.not(es_plantilla: true) }

  # Métodos
  def es_plantilla?
    es_plantilla == true
  end

  def es_inscripcion?
    !es_plantilla?
  end

  def nombre_completo_lider
    "#{nombre_lider} #{apellido_lider}".strip
  end

  def debug_info
    {
      id: id,
      program_id: program_id,
      nombre_lider: nombre_lider,
      apellido_lider: apellido_lider,
      nombre_proyecto: nombre_proyecto,
      es_plantilla: es_plantilla,
      errors: errors.full_messages
    }
  end
end