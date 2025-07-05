# app/models/event.rb - ACTUALIZACIÓN COMPLETA CON MÉTODOS DE FECHA

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
    formulario_eventos.where(es_plantilla: [false, nil]).count
  end

  # NUEVO: Método para obtener o crear plantilla de formulario
  def formulario_asociado
    formulario_plantilla_evento || build_formulario_plantilla_evento(es_plantilla: true)
  end

  # NUEVO: Método para obtener todas las inscripciones de un evento
  def todas_inscripciones
    formulario_eventos.where(es_plantilla: [false, nil]).order(created_at: :asc)
  end

  # NUEVO: Método para contar inscripciones por estado
  def inscripciones_por_estado
    inscripciones = todas_inscripciones
    {
      total: inscripciones.count,
      pendiente: inscripciones.where(estado: 'pendiente').count,
      aprobado: inscripciones.where(estado: 'aprobado').count,
      rechazado: inscripciones.where(estado: 'rechazado').count
    }
  end

  # NUEVO: Método para obtener la inscripción más reciente
  def inscripcion_mas_reciente
    todas_inscripciones.last
  end

  # NUEVO: Método para verificar si tiene inscripciones
  def tiene_inscripciones?
    todas_inscripciones.any?
  end

  # NUEVO: Método para obtener inscripciones recientes (últimos 7 días)
  def inscripciones_recientes
    todas_inscripciones.where(created_at: 7.days.ago..Time.current)
  end

  # NUEVO: Método para exportar datos básicos
  def datos_basicos_inscripciones
    todas_inscripciones.map do |inscripcion|
      {
        id: inscripcion.id,
        nombre_completo: "#{inscripcion.nombre_lider} #{inscripcion.apellidos_lider}",
        correo: inscripcion.correo_lider,
        telefono: inscripcion.telefono_lider,
        estado: inscripcion.estado,
        fecha_inscripcion: inscripcion.created_at,
        tipo_evento: titulo
      }
    end
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

  # =============================================================================
  # MÉTODOS DE FECHA Y TIEMPO (NUEVOS - SIMILARES A PROGRAM)
  # =============================================================================

  # Método principal para mostrar tiempo hasta/desde vencimiento
  def tiempo_hasta_vencimiento
    return "Sin fecha de vencimiento" if fecha_vencimiento.blank?
    
    ahora = Time.current
    
    if fecha_vencimiento > ahora
      diferencia = fecha_vencimiento - ahora
      "Vence #{formato_tiempo_restante(diferencia)} más"
    else
      diferencia = ahora - fecha_vencimiento
      "Venció #{formato_tiempo_transcurrido(diferencia)} atrás"
    end
  end

  # Método para time_ago_in_words personalizado en español
  def tiempo_transcurrido(fecha)
    return "Fecha no válida" if fecha.blank?
    
    ahora = Time.current
    return "En el futuro" if fecha > ahora
    
    diferencia = ahora - fecha
    formato_tiempo_transcurrido(diferencia)
  end

  # Método para calcular tiempo restante hasta una fecha
  def tiempo_restante_hasta(fecha)
    return "Fecha no válida" if fecha.blank?
    
    ahora = Time.current
    return "Ya venció" if fecha <= ahora
    
    diferencia = fecha - ahora
    formato_tiempo_restante(diferencia)
  end

  # Método para obtener estado de disponibilidad
  def estado_disponibilidad
    return "Sin fechas configuradas" if fecha_publicacion.blank? || fecha_vencimiento.blank?
    
    ahora = Time.current
    
    case
    when ahora < fecha_publicacion
      "Próximamente disponible"
    when ahora.between?(fecha_publicacion, fecha_vencimiento)
      "Inscripciones abiertas"
    else
      "Inscripciones cerradas"
    end
  end

  # Método para verificar urgencia
  def es_urgente?
    return false if fecha_vencimiento.blank?
    fecha_vencimiento.between?(Time.current, 24.hours.from_now)
  end

  # Método para obtener clase CSS según estado de tiempo
  def clase_css_tiempo
    return "tiempo-indefinido" if fecha_vencimiento.blank?
    
    ahora = Time.current
    diferencia = fecha_vencimiento - ahora
    
    if diferencia < 0
      "tiempo-vencido"
    elsif diferencia < 2.hours
      "tiempo-critico"
    elsif diferencia < 1.day
      "tiempo-urgente"
    elsif diferencia < 3.days
      "tiempo-proximo"
    else
      "tiempo-normal"
    end
  end

  # =============================================================================
  # MÉTODOS EXISTENTES (MANTENER)
  # =============================================================================

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

  # ACTUALIZADO: Mensaje de disponibilidad mejorado
  def mensaje_disponibilidad
    return "Fechas no configuradas" if fecha_publicacion.blank? || fecha_vencimiento.blank?
    
    ahora = Time.current
    
    case estado
    when 'pendiente'
      if fecha_publicacion > ahora
        "Las inscripciones estarán disponibles a partir del #{fecha_publicacion.strftime('%d de %B del %Y a las %H:%M')}"
      else
        "Las inscripciones estarán disponibles próximamente"
      end
    when 'activo'
      if fecha_vencimiento > ahora
        diferencia = fecha_vencimiento - ahora
        tiempo_restante = formato_tiempo_restante(diferencia)
        
        if diferencia < 1.day
          "¡#{tiempo_restante} para inscribirse! (hasta el #{fecha_vencimiento.strftime('%d/%m/%Y a las %H:%M')})"
        else
          "Quedan #{tiempo_restante} para inscribirse (hasta el #{fecha_vencimiento.strftime('%d/%m/%Y a las %H:%M')})"
        end
      else
        "Inscripciones disponibles"
      end
    when 'finalizado'
      tiempo_transcurrido = formato_tiempo_transcurrido(ahora - fecha_vencimiento)
      "Las inscripciones finalizaron #{tiempo_transcurrido} atrás (el #{fecha_vencimiento.strftime('%d de %B del %Y a las %H:%M')})"
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

  # =============================================================================
  # MÉTODOS PRIVADOS PARA FORMATEAR TIEMPO
  # =============================================================================

  # Formatear tiempo restante de manera legible en español
  def formato_tiempo_restante(diferencia_segundos)
    if diferencia_segundos < 1.hour
      minutos = (diferencia_segundos / 1.minute).round
      "#{minutos} minuto#{'s' if minutos != 1}"
    elsif diferencia_segundos < 1.day
      horas = (diferencia_segundos / 1.hour).round
      "#{horas} hora#{'s' if horas != 1}"
    elsif diferencia_segundos < 1.week
      dias = (diferencia_segundos / 1.day).round
      "#{dias} día#{'s' if dias != 1}"
    elsif diferencia_segundos < 1.month
      semanas = (diferencia_segundos / 1.week).round
      "#{semanas} semana#{'s' if semanas != 1}"
    else
      meses = (diferencia_segundos / 1.month).round
      "#{meses} mes#{'es' if meses != 1}"
    end
  end

  # Formatear tiempo transcurrido de manera legible en español
  def formato_tiempo_transcurrido(diferencia_segundos)
    if diferencia_segundos < 1.minute
      "unos segundos"
    elsif diferencia_segundos < 1.hour
      minutos = (diferencia_segundos / 1.minute).round
      "#{minutos} minuto#{'s' if minutos != 1}"
    elsif diferencia_segundos < 1.day
      horas = (diferencia_segundos / 1.hour).round
      "#{horas} hora#{'s' if horas != 1}"
    elsif diferencia_segundos < 1.week
      dias = (diferencia_segundos / 1.day).round
      "#{dias} día#{'s' if dias != 1}"
    elsif diferencia_segundos < 1.month
      semanas = (diferencia_segundos / 1.week).round
      "#{semanas} semana#{'s' if semanas != 1}"
    elsif diferencia_segundos < 1.year
      meses = (diferencia_segundos / 1.month).round
      "#{meses} mes#{'es' if meses != 1}"
    else
      años = (diferencia_segundos / 1.year).round
      "#{años} año#{'s' if años != 1}"
    end
  end

  # =============================================================================
  # MÉTODOS PRIVADOS EXISTENTES (MANTENER)
  # =============================================================================

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