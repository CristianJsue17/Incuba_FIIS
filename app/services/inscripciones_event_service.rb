# app/services/inscripciones_event_service.rb
class InscripcionesEventService < ApplicationService
  
  # Método para preparar nueva inscripción (action new)
  def self.prepare_new_inscription(event_id)
    event = Event.find(event_id)
    
    # Verificar que el evento puede recibir inscripciones
    unless event.puede_inscribirse?
      return {
        success: false,
        error: 'Las inscripciones no están disponibles para este evento'
      }
    end

    formulario = FormularioEvento.new
    formulario.event = event

    {
      success: true,
      formulario: formulario
    }
  end

  # Método para crear inscripción (action create)
  def self.create_inscription(event_id:, formulario_params:)
    event = Event.find(event_id)
    
    # Verificar nuevamente que puede inscribirse
    unless event.puede_inscribirse?
      return {
        success: false,
        error: 'Las inscripciones no están disponibles para este evento'
      }
    end

    formulario = FormularioEvento.new(formulario_params)
    formulario.event = event
    formulario.es_plantilla = false

    if formulario.save
      {
        success: true,
        message: 'Tu inscripción ha sido enviada exitosamente.'
      }
    else
      {
        success: false,
        formulario: formulario,
        errors: formulario.errors.full_messages
      }
    end
  end
end