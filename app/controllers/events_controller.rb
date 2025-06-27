# app/controllers/events_controller.rb - SIMPLIFICADO
class EventsController < ApplicationController
  
  def eventos
    @eventos_data = EventService.eventos_data
    
    @eventos_actuales = @eventos_data[:eventos_actuales]
    @eventos_proximos = @eventos_data[:eventos_proximos] 
    @eventos_pasados = @eventos_data[:eventos_pasados]
  end

  def evento_detalle
    begin
      @evento_data = EventService.evento_detalle(params[:id])
      
      @event = @evento_data[:event]
      @total_inscripciones = @evento_data[:total_inscripciones]
      @puede_inscribirse = @evento_data[:puede_inscribirse]
      @mensaje_disponibilidad = @evento_data[:mensaje_disponibilidad]
      @estado_css_class = @evento_data[:estado_css_class]
      
    rescue ActiveRecord::RecordNotFound
      redirect_to eventos_path, alert: 'Evento no encontrado'
    end
  end
end