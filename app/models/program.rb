class Program < ApplicationRecord
  # Constantes
  TIPOS = ['preincubacion', 'incubacion', 'innovacion'].freeze
  MAX_OBJETIVOS = 6
  MAX_BENEFICIOS = 6
  MAX_REQUISITOS = 6

  # Asociaciones principales
  belongs_to :user
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  # Asociaciones con objetivos, beneficios y requisitos
  has_many :program_objetivos, dependent: :destroy
  has_many :objetivos, through: :program_objetivos
  
  has_many :program_beneficios, dependent: :destroy
  has_many :beneficios, through: :program_beneficios
  
  has_many :program_requisitos, dependent: :destroy
  has_many :requisitos, through: :program_requisitos

  # Asociaciones con patrocinadores
  has_many :programs_patrocinadors, dependent: :destroy
  has_many :patrocinadors, through: :programs_patrocinadors

  # Asociaciones con formularios específicos
  has_many :formulario_programa_preincubacions, dependent: :destroy, class_name: 'FormularioProgramaPreincubacion'
  has_many :formulario_programa_incubacions, dependent: :destroy, class_name: 'FormularioProgramaIncubacion'
  has_many :formulario_programa_innovacions, dependent: :destroy, class_name: 'FormularioProgramaInnovacion'

  # AGREGAR: Relaciones para plantillas del admin (opcionales)
  has_one :formulario_plantilla_preincubacion, -> { where(es_plantilla: true) }, 
        class_name: 'FormularioProgramaPreincubacion', dependent: :destroy
  has_one :formulario_plantilla_incubacion, -> { where(es_plantilla: true) }, 
        class_name: 'FormularioProgramaIncubacion', dependent: :destroy
  has_one :formulario_plantilla_innovacion, -> { where(es_plantilla: true) }, 
        class_name: 'FormularioProgramaInnovacion', dependent: :destroy

  # AGREGAR MÉTODOS:
  def total_inscripciones
    case tipo
    when 'preincubacion'
      formulario_programa_preincubacions.inscripciones.count
    when 'incubacion'
      formulario_programa_incubacions.inscripciones.count
    when 'innovacion'
      formulario_programa_innovacions.inscripciones.count
    else
      0
    end
  end

  # Active Storage para imagen
  has_one_attached :image

  # Nested Attributes - CORREGIDO: Usar las relaciones de plantilla
  accepts_nested_attributes_for :objetivos, 
    allow_destroy: true

  accepts_nested_attributes_for :beneficios, 
    allow_destroy: true

  accepts_nested_attributes_for :requisitos, 
    allow_destroy: true

  # CAMBIO: Estas tres líneas reemplazadas
  accepts_nested_attributes_for :formulario_plantilla_preincubacion,
    reject_if: :all_blank

  accepts_nested_attributes_for :formulario_plantilla_incubacion,
    reject_if: :all_blank

  accepts_nested_attributes_for :formulario_plantilla_innovacion,
    reject_if: :all_blank

  accepts_nested_attributes_for :programs_patrocinadors,
    allow_destroy: true

  # Validaciones básicas
  validates :titulo, presence: { message: "no puede estar vacío" }, 
                  length: { maximum: 100 },
                  uniqueness: { message: "ya está en uso por otro programa" }
  validates :descripcion, presence: { message: "no puede estar vacía" }, length: { maximum: 1000 }
  validates :tipo, presence: { message: "debe seleccionar un tipo" }, inclusion: { in: TIPOS }
  validates :encargado, presence: { message: "no puede estar vacío" }, length: { maximum: 100 }
  validates :estado, presence: true, inclusion: { in: ['activo', 'inactivo', 'pendiente', 'finalizado'] }
  validates :fecha_publicacion, presence: { message: "debe seleccionar una fecha" }
  validates :fecha_vencimiento, presence: { message: "debe seleccionar una fecha" }
  validate :no_cambiar_tipo_con_inscripciones, on: :update
 
  
  # Validaciones personalizadas
  validate :validate_image_presence_and_type
  validate :fecha_vencimiento_mayor_publicacion

  # Scopes útiles
  scope :preincubacion, -> { where(tipo: 'preincubacion') }
  scope :incubacion, -> { where(tipo: 'incubacion') }
  scope :innovacion, -> { where(tipo: 'innovacion') }
  scope :activos, -> { where(estado: 'activo') }

  def formulario_asociado
  # Para admin - obtener o crear plantilla
    case tipo
    when 'preincubacion'
      formulario_plantilla_preincubacion || build_formulario_plantilla_preincubacion(es_plantilla: true)
    when 'incubacion'
      formulario_plantilla_incubacion || build_formulario_plantilla_incubacion(es_plantilla: true)
    when 'innovacion'
      formulario_plantilla_innovacion || build_formulario_plantilla_innovacion(es_plantilla: true)
    end
  end

  def tipo_humanizado
    case tipo
    when 'preincubacion'
      'Preincubación'
    when 'incubacion'
      'Incubación'
    when 'innovacion'
      'Innovación'
    else
      tipo.humanize
    end
  end

  # Método para actualizar estado automáticamente (llamado desde servicios)
  def actualizar_estado_automatico!
    nuevo_estado = determine_estado(false) # No respetar cambios manuales
    
    if estado != nuevo_estado
      update_column(:estado, nuevo_estado)
      Rails.logger.info "Programa ##{id} cambió de estado: #{estado} → #{nuevo_estado}"
    end
  end

  # Método para verificar disponibilidad de inscripción
  def puede_inscribirse?
    estado == 'activo' && fecha_vencimiento.present? && fecha_vencimiento > Time.current
  end

  # NUEVO: Método para obtener mensaje de disponibilidad según el estado
  def mensaje_disponibilidad
    case estado
    when 'pendiente'
      if fecha_publicacion.present?
        "Las inscripciones estarán disponibles a partir del #{fecha_publicacion.strftime('%d de %B del %Y a las %H:%M')}"
      else
        "Las inscripciones estarán disponibles próximamente"
      end
    when 'activo'
      if fecha_vencimiento.present?
        dias_restantes = ((fecha_vencimiento - Time.current) / 1.day).ceil
        if dias_restantes > 1
          "Quedan #{dias_restantes} días para inscribirse (hasta el #{fecha_vencimiento.strftime('%d/%m/%Y a las %H:%M')})"
        elsif dias_restantes == 1
          "¡Último día para inscribirse! (hasta el #{fecha_vencimiento.strftime('%d/%m/%Y a las %H:%M')})"
        else
          horas_restantes = ((fecha_vencimiento - Time.current) / 1.hour).ceil
          if horas_restantes > 0
            "¡Quedan #{horas_restantes} horas para inscribirse!"
          else
            "Las inscripciones finalizan muy pronto"
          end
        end
      else
        "Inscripciones disponibles"
      end
    when 'finalizado'
      if fecha_vencimiento.present?
        "Las inscripciones finalizaron el #{fecha_vencimiento.strftime('%d de %B del %Y a las %H:%M')}"
      else
        "Las inscripciones han finalizado"
      end
    when 'inactivo'
      "Este programa ya no está disponible"
    else
      "Estado desconocido"
    end
  end

  # NUEVO: Método para determinar si el programa debe ser visible en las listas
  def visible_en_lista?
    estado != 'inactivo'
  end

  # NUEVO: Método para obtener color del estado
  def color_estado
    case estado
    when 'pendiente'
      '#fbbf24' # amarillo
    when 'activo'
      '#10b981' # verde
    when 'finalizado'
      '#6b7280' # gris
    when 'inactivo'
      '#dc2626' # rojo
    else
      '#6b7280' # gris
    end
  end

  # Método para obtener clase CSS del estado
  def estado_css_class
    case estado
    when 'pendiente'
      'estado-pendiente'
    when 'activo'
      'estado-activo'
    when 'finalizado'
      'estado-finalizado'
    when 'inactivo'
      'estado-inactivo'
    else
      'estado-unknown'
    end
  end

  def puede_agregar_objetivo?
    objetivos.size < MAX_OBJETIVOS
  end

  def puede_agregar_beneficio?
    beneficios.size < MAX_BENEFICIOS
  end

  def puede_agregar_requisito?
    requisitos.size < MAX_REQUISITOS
  end

  def image_preview_url
    image.attached? ? image : 'placeholder_program.png'
  end

  # Métodos de clase
  def self.tipos_para_select
    TIPOS.map { |t| [t.humanize, t] }
  end

  # Método para determinar el estado automáticamente según fechas
  # Pero respeta el estado actual si se configuró manualmente
  def determine_estado(respect_manual_changes = true)
    now = Time.current
    
    # Si no hay fechas definidas, mantener el estado actual
    if fecha_publicacion.nil? || fecha_vencimiento.nil?
      return estado || 'pendiente'  # Mantener el estado actual o usar 'pendiente' por defecto
    end
    
    # Determinar el estado correcto según fechas
    correct_state = if now < fecha_publicacion
                      # Antes de la fecha de publicación
                      'pendiente'
                    elsif now >= fecha_publicacion && now < fecha_vencimiento
                      # Entre fecha de publicación y vencimiento
                      'activo'
                    elsif now >= fecha_vencimiento && now < (fecha_vencimiento + 12.hours)
                      # Después de fecha de vencimiento pero aún no pasan 12 horas
                      'finalizado'
                    else
                      # Después de fecha de vencimiento + 12 horas
                      'inactivo'
                    end
    
    # Si respect_manual_changes está activado y se actualizó manualmente recientemente,
    # respetar el estado actual
    if respect_manual_changes && 
       updated_at.present? && 
       updated_at > (now - 30.minutes) && 
       estado.present?
      return estado
    end
    
    # De lo contrario, devolver el estado correcto según las fechas
    correct_state
  end

  # Callback para actualizar estado automáticamente
  #before_save :update_estado_automatico

  private

  def fecha_vencimiento_mayor_publicacion
    return if fecha_vencimiento.blank? || fecha_publicacion.blank?
    
    if fecha_vencimiento <= fecha_publicacion
      errors.add(:fecha_vencimiento, "debe ser posterior a la fecha de publicación")
    end
  end

  def update_estado_automatico
    # Solo actualizar automáticamente si no se especificó un estado manual
    if estado.blank? || estado_changed?
      self.estado = determine_estado
    end
  end
    
  # Elimina la validación de presencia pero mantén tipo y tamaño
  def validate_image_presence_and_type
    return unless image.attached? # Solo validar si hay imagen adjunta

    unless image.content_type.in?(%w[image/jpeg image/png image/gif])
      errors.add(:image, "debe ser un archivo JPEG, PNG o GIF")
    end
    
    if image.blob.byte_size > 5.megabytes
      errors.add(:image, "no debe superar los 5MB")
    end
  end

  def no_cambiar_tipo_con_inscripciones
    return unless tipo_changed? && persisted?
    
    if total_inscripciones > 0
      errors.add(:tipo, "no se puede cambiar porque ya hay #{total_inscripciones} inscripción(es) registrada(s)")
    end
  end

end