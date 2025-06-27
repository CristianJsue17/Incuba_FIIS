# app/services/event_service.rb - SIMPLIFICADO
class EventService < ApplicationService
  
  # Método principal para el action 'eventos'
  def self.eventos_data
    # Obtener TODOS los eventos (incluyendo inactivos)
    all_events = Event.includes(:user, :created_by, images_attachments: :blob)
                     .order(:fecha_vencimiento)
    
    # Actualizar estados automáticamente
    all_events.each(&:actualizar_estado_automatico!)
    
    # Separar eventos por categorías
    {
      eventos_actuales: all_events.where(estado: ['activo', 'finalizado']),
      eventos_proximos: all_events.where(estado: 'pendiente'),
      eventos_pasados: all_events.where(estado: 'inactivo')
    }
  end

  # Método para evento individual
  def self.evento_detalle(event_id)
    event = Event.includes(:user, :created_by, images_attachments: :blob).find(event_id)
    
    # Actualizar estado automáticamente antes de mostrar
    event.actualizar_estado_automatico!
    
    {
      event: event,
      total_inscripciones: event.total_inscripciones,
      puede_inscribirse: event.puede_inscribirse?,
      mensaje_disponibilidad: event.mensaje_disponibilidad,
      estado_css_class: event.estado_css_class
    }
  end
end