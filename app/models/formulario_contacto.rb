# app/models/formulario_contacto.rb
class FormularioContacto < ApplicationRecord
  # Validaciones
  validates :nombre, presence: { message: "El nombre es obligatorio" },
                     length: { minimum: 2, maximum: 100, message: "El nombre debe tener entre 2 y 100 caracteres" }
     
  validates :correo, presence: { message: "El correo electrónico es obligatorio" },
                     format: { with: URI::MailTo::EMAIL_REGEXP, message: "El formato del correo electrónico no es válido" },
                     length: { maximum: 255, message: "El correo electrónico es demasiado largo" }
     
  validates :asunto, presence: { message: "El asunto es obligatorio" },
                     length: { minimum: 3, maximum: 200, message: "El asunto debe tener entre 3 y 200 caracteres" }
     
  validates :mensaje, presence: { message: "El mensaje es obligatorio" },
                      length: { minimum: 10, maximum: 2000, message: "El mensaje debe tener entre 10 y 2000 caracteres" }

  # Scopes para búsqueda y filtrado
  scope :recientes, -> { order(created_at: :desc) }
  scope :del_mes, -> { where(created_at: 1.month.ago..Time.current) }
  
  scope :search, ->(query) {
    return all if query.blank?
        
    where(
      "nombre ILIKE ? OR correo ILIKE ? OR asunto ILIKE ? OR mensaje ILIKE ?",
      "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
    )
  }
     
  scope :filter_by_priority, ->(prioridad) {
    return all if prioridad.blank?
        
    if prioridad == 'alta'
      palabras_urgentes = ['urgente', 'inmediato', 'problema', 'error', 'ayuda']
      where(
        palabras_urgentes.map { |palabra| 
          "(LOWER(asunto) LIKE ? OR LOWER(mensaje) LIKE ?)"
        }.join(' OR '),
        *palabras_urgentes.flat_map { |palabra| ["%#{palabra}%", "%#{palabra}%"] }
      )
    else
      all
    end
  }
     
  scope :filter_by_date_range, ->(fecha_inicio, fecha_fin) {
    return all if fecha_inicio.blank? && fecha_fin.blank?
        
    inicio = fecha_inicio.present? ? Date.parse(fecha_inicio).beginning_of_day : 1.year.ago
    fin = fecha_fin.present? ? Date.parse(fecha_fin).end_of_day : Time.current
        
    where(created_at: inicio..fin)
  }

  # Callbacks
  before_save :normalize_data
  after_create :send_notification_to_admin

  # Métodos de instancia
  def nombre_formateado
    nombre.titleize
  end

  def resumen_mensaje(caracteres = 100)
    mensaje.length > caracteres ? "#{mensaje[0...caracteres]}..." : mensaje
  end
     
  def prioridad
    # Lógica para determinar prioridad basada en palabras clave
    palabras_urgentes = ['urgente', 'inmediato', 'problema', 'error', 'ayuda']
        
    if palabras_urgentes.any? { |palabra| asunto.downcase.include?(palabra) || mensaje.downcase.include?(palabra) }
      'alta'
    else
      'normal'
    end
  end

  # Métodos de clase
  def self.estadisticas
    {
      total: count,
      esta_semana: where(created_at: 1.week.ago..Time.current).count,
      este_mes: where(created_at: 1.month.ago..Time.current).count,
      promedio_diario: count.to_f / [where(created_at: 30.days.ago..Time.current).count, 1].max
    }
  end
     
  def self.buscar_por_email(email)
    where(correo: email).order(created_at: :desc)
  end

  # Método para compatibilidad con groupdate si lo tienes instalado
  def self.group_by_month(field, options = {})
    if defined?(Groupdate)
      group_by_month(field, **options)
    else
      # Fallback manual si no tienes groupdate
      group("DATE_TRUNC('month', #{field})")
    end
  end

  private

  def normalize_data
    self.nombre = nombre.strip.titleize if nombre.present?
    self.correo = correo.strip.downcase if correo.present?
    self.asunto = asunto.strip if asunto.present?
    self.mensaje = mensaje.strip if mensaje.present?
  end

  def send_notification_to_admin
    # Aquí puedes agregar lógica para enviar notificaciones
    # Por ejemplo, enviar email a administradores
    # AdminNotificationMailer.new_contact_message(self).deliver_later
        
    Rails.logger.info "📧 Nuevo mensaje de contacto recibido de #{correo} - Asunto: #{asunto}"
  end
end