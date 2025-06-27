# app/controllers/services_controller.rb
class ServicesController < ApplicationController

  # Método para mostrar los servicios y programas de la misma vista
  def servicios
    @datos_servicios = ServiciosService.servicios_data
  end

  # Método para mostrar programas por tipo para su vista programas_tipo.html.erb
  def programas_tipo
    @tipo = params[:tipo]

    # Usar el ServiciosService que ya tiene toda la lógica
    resultado_servicio = ServiciosService.programas_tipo(@tipo)
    
    # Asignar variables para mantener compatibilidad con las vistas
    @programs = resultado_servicio[:programas]
    @tipo_actual = resultado_servicio[:tipo_actual]
  end

  # Método para mostrar los detalles de un programa específico para vista programa_detalle.html.erb
  def programa_detalle
    begin
      resultado = ServiciosService.programa_detalle(params[:id])

      unless resultado[:success]
        redirect_to servicios_path, alert: resultado[:error]
        return
      end

      # Asignar variables para mantener compatibilidad con las vistas
      @program = resultado[:program]
      @tipo_actual = resultado[:tipo_actual]
      @total_inscripciones = resultado[:total_inscripciones]
      @puede_inscribirse = resultado[:puede_inscribirse]
      @mensaje_disponibilidad = resultado[:mensaje_disponibilidad]
      @estado_css_class = resultado[:estado_css_class]

    rescue ActiveRecord::RecordNotFound
      redirect_to servicios_path, alert: 'Programa no encontrado'
    end
  end
end