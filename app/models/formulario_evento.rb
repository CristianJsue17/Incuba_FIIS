# app/models/formulario_evento.rb - ACTUALIZACIÓN COMPLETA

class FormularioEvento < ApplicationRecord
  belongs_to :event

  # ASEGURAR: Agregar esta migración si no existe:
  # add_column :formulario_eventos, :es_plantilla, :boolean, default: false
  # add_column :formulario_eventos, :estado, :string, default: 'pendiente'

  # Validaciones - Solo aplicar si no es plantilla
  validates :nombre_lider, presence: { message: "no puede estar vacío" }, unless: :es_plantilla?
  validates :apellidos_lider, presence: { message: "no pueden estar vacíos" }, unless: :es_plantilla?
  validates :dni_lider, presence: { message: "no puede estar vacío" }, 
                        format: { with: /\A\d{8}\z/, message: "debe tener 8 dígitos" }, 
                        unless: :es_plantilla?
  validates :correo_lider, presence: { message: "no puede estar vacío" }, 
                          format: { with: URI::MailTo::EMAIL_REGEXP, message: "no tiene un formato válido" }, 
                          unless: :es_plantilla?
  validates :telefono_lider, presence: { message: "no puede estar vacío" }, unless: :es_plantilla?
  validates :nombre_emprendimiento, presence: { message: "no puede estar vacío" }, unless: :es_plantilla?
  validates :descripcion, presence: { message: "no puede estar vacía" }, unless: :es_plantilla?

  # Validación de estado
  validates :estado, inclusion: { in: ['pendiente', 'aprobado', 'rechazado'] }, 
                     allow_blank: false, 
                     unless: :es_plantilla?

  # Scopes
  scope :plantillas, -> { where(es_plantilla: true) }
  scope :inscripciones, -> { where(es_plantilla: [false, nil]) }
  scope :por_estado, ->(estado) { where(estado: estado) }
  scope :pendientes, -> { where(estado: 'pendiente') }
  scope :aprobadas, -> { where(estado: 'aprobado') }
  scope :rechazadas, -> { where(estado: 'rechazado') }
  scope :recientes, -> { where(created_at: 7.days.ago..Time.current) }

  # Callbacks
  before_save :set_default_estado, if: :new_record?

  # Métodos
  def es_plantilla?
    es_plantilla == true
  end

  def es_inscripcion?
    !es_plantilla?
  end

  def nombre_completo
    "#{nombre_lider} #{apellidos_lider}".strip
  end

  def estado_humanizado
    case estado
    when 'pendiente'
      'Pendiente'
    when 'aprobado'
      'Aprobado'
    when 'rechazado'
      'Rechazado'
    else
      estado&.humanize
    end
  end

  def puede_cambiar_estado?
    es_inscripcion? && event.presente?
  end

  def fecha_inscripcion_formateada
    created_at.strftime("%d/%m/%Y a las %H:%M") if created_at.present?
  end

  # Método para exportar datos básicos
  def datos_exportacion
    {
      id: id,
      nombre_completo: nombre_completo,
      dni: dni_lider,
      correo: correo_lider,
      telefono: telefono_lider,
      emprendimiento: nombre_emprendimiento,
      descripcion: descripcion,
      sector: sector_economico,
      categoria: categoria,
      estado: estado_humanizado,
      fecha_inscripcion: fecha_inscripcion_formateada,
      evento: event&.titulo
    }
  end

  # Método para validar unicidad de DNI por evento
  def dni_unico_por_evento
    return if es_plantilla? || dni_lider.blank?
    
    inscripciones_existentes = event.formulario_eventos
                                   .where(es_plantilla: [false, nil])
                                   .where(dni_lider: dni_lider)
    
    inscripciones_existentes = inscripciones_existentes.where.not(id: id) if persisted?
    
    if inscripciones_existentes.exists?
      errors.add(:dni_lider, "ya está registrado para este evento")
    end
  end

  # Método para validar unicidad de correo por evento
  def correo_unico_por_evento
    return if es_plantilla? || correo_lider.blank?
    
    inscripciones_existentes = event.formulario_eventos
                                   .where(es_plantilla: [false, nil])
                                   .where(correo_lider: correo_lider)
    
    inscripciones_existentes = inscripciones_existentes.where.not(id: id) if persisted?
    
    if inscripciones_existentes.exists?
      errors.add(:correo_lider, "ya está registrado para este evento")
    end
  end

  private

  def set_default_estado
    self.estado = 'pendiente' if estado.blank? && es_inscripcion?
  end

  # Agregar validaciones personalizadas si es necesario
  # validate :dni_unico_por_evento, unless: :es_plantilla?
  # validate :correo_unico_por_evento, unless: :es_plantilla?
end