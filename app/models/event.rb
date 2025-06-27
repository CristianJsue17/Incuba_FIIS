# app/models/event.rb - ACTUALIZACIÓN CON MÚLTIPLES IMÁGENES

class Event < ApplicationRecord
  # Asociaciones
  belongs_to :user
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  has_many :formulario_eventos, dependent: :destroy
  
  # NUEVO: Relación con plantilla de formulario automática
  has_one :formulario_plantilla_evento, -> { where(es_plantilla: true) }, 
          class_name: 'FormularioEvento', dependent: :destroy
  
  # ACTUALIZADO: Active Storage para múltiples imágenes
  has_many_attached :images

  # NUEVO: Nested attributes para plantilla de formulario
  accepts_nested_attributes_for :formulario_plantilla_evento,
    reject_if: :all_blank

  # Validaciones (mantener las existentes)
  validates :titulo, presence: { message: "no puede estar vacío" }, 
                     length: { maximum: 100 },
                     uniqueness: { message: "ya está en uso por otro evento" }
  validates :descripcion, presence: { message: "no puede estar vacía" }, 
                          length: { maximum: 1000 }
  validates :encargado, presence: { message: "no puede estar vacío" }, 
                        length: { maximum: 100 }
  validates :estado, presence: true, 
                     inclusion: { in: ['activo', 'inactivo', 'pendiente', 'finalizado'] }
  validates :fecha_publicacion, presence: { message: "debe seleccionar una fecha" }
  validates :fecha_vencimiento, presence: { message: "debe seleccionar una fecha" }
  
  # Validaciones personalizadas
  validate :validate_images_type_and_size
  validate :validate_images_count
  validate :fecha_vencimiento_mayor_publicacion

  # Scopes
  scope :activos, -> { where(estado: 'activo') }
  scope :pendientes, -> { where(estado: 'pendiente') }
  scope :finalizados, -> { where(estado: 'finalizado') }

  # NUEVO: Método para obtener total de inscripciones (formularios completados)
  def total_inscripciones
    formulario_eventos.where(es_plantilla: false).count
  end

  # NUEVO: Método para obtener o crear plantilla de formulario
  def formulario_asociado
    formulario_plantilla_evento || build_formulario_plantilla_evento(es_plantilla: true)
  end

  # NUEVO: Método para obtener la imagen principal (primera imagen)
  def imagen_principal
    images.attached? ? images.first : nil
  end

  # NUEVO: Método para obtener todas las imágenes como array
  def todas_las_imagenes
    images.attached? ? images : []
  end

  # NUEVO: Método de compatibilidad para mantener funcionalidad existente
  def image
    imagen_principal
  end

  # Métodos existentes (mantener todos)
  def puede_inscribirse?
    estado == 'activo' && fecha_vencimiento.present? && fecha_vencimiento > Time.current
  end

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

  def color_estado
    case estado
    when 'pendiente'
      '#fbbf24' # amarillo
    when 'activo'
      '#10b981' # verde
    when 'finalizado'
      '#6b7280' # gris plomo
    when 'inactivo'
      '#dc2626' # rojo
    else
      '#6b7280' # gris
    end
  end

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
      "Este evento ya no está disponible"
    else
      "Estado desconocido"
    end
  end

  # NUEVO: Método para determinar si el evento debe ser visible en las listas
  def visible_en_lista?
    estado != 'inactivo'
  end

  # Método para actualizar estado automáticamente
  def actualizar_estado_automatico!
    nuevo_estado = determine_estado(false) # No respetar cambios manuales
    
    if estado != nuevo_estado
      update_column(:estado, nuevo_estado)
      Rails.logger.info "Evento ##{id} cambió de estado: #{estado} → #{nuevo_estado}"
    end
  end

  def determine_estado(respect_manual_changes = true)
    now = Time.current
    
    # Si no hay fechas definidas, mantener el estado actual
    if fecha_publicacion.nil? || fecha_vencimiento.nil?
      return estado || 'pendiente'
    end
    
    # Determinar el estado correcto según fechas
    correct_state = if now < fecha_publicacion
                      'pendiente'
                    elsif now >= fecha_publicacion && now < fecha_vencimiento
                      'activo'
                    elsif now >= fecha_vencimiento && now < (fecha_vencimiento + 12.hours)
                      'finalizado'
                    else
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
    
    correct_state
  end

  private

  # NUEVO: Validación para múltiples imágenes
  def validate_images_type_and_size
    return unless images.attached?

    images.each_with_index do |image, index|
      unless image.content_type.in?(%w[image/jpeg image/png image/gif])
        errors.add(:images, "La imagen #{index + 1} debe ser un archivo JPEG, PNG o GIF")
      end
      
      if image.blob.byte_size > 5.megabytes
        errors.add(:images, "La imagen #{index + 1} no debe superar los 5MB")
      end
    end
  end

  # NUEVO: Validación para cantidad de imágenes
  def validate_images_count
    return unless images.attached?

    if images.count > 3
      errors.add(:images, "No puedes subir más de 3 imágenes por evento")
    elsif images.count < 1
      errors.add(:images, "Debes subir al menos 1 imagen para el evento")
    end
  end

  # Validación existente
  def fecha_vencimiento_mayor_publicacion
    return if fecha_vencimiento.blank? || fecha_publicacion.blank?
    
    if fecha_vencimiento <= fecha_publicacion
      errors.add(:fecha_vencimiento, "debe ser posterior a la fecha de publicación")
    end
  end
end