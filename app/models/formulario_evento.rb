# app/models/formulario_evento.rb - ACTUALIZACIÓN

class FormularioEvento < ApplicationRecord
  belongs_to :event

  # NUEVO: Agregar campo es_plantilla para diferenciar plantillas de inscripciones reales
  # Asegúrate de agregar esta migración:
  # add_column :formulario_eventos, :es_plantilla, :boolean, default: false

  # Validaciones
  validates :nombre_lider, presence: true, unless: :es_plantilla?
  validates :apellidos_lider, presence: true, unless: :es_plantilla?
  validates :dni_lider, presence: true, unless: :es_plantilla?
  validates :correo_lider, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, unless: :es_plantilla?
  validates :telefono_lider, presence: true, unless: :es_plantilla?
  validates :nombre_emprendimiento, presence: true, unless: :es_plantilla?
  validates :descripcion, presence: true, unless: :es_plantilla?

  # Scopes
  scope :plantillas, -> { where(es_plantilla: true) }
  scope :inscripciones, -> { where(es_plantilla: false) }

  # Métodos
  def es_plantilla?
    es_plantilla == true
  end

  def es_inscripcion?
    !es_plantilla?
  end
end