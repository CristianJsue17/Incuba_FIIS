# app/controllers/home_controller.rb
class HomeController < ApplicationController
  

  def index
    @datos_home = HomeService.call
  end

  def servicios
    @datos_servicios = ServiciosService.call
        
    # Para formato JSON, devolvemos información para React
    respond_to do |format|
      format.html # Renderiza la vista servicios.html.erb
      format.json do
        render json: {
          tipos_programas: @datos_servicios[:tipos_programas]
        }
      end
    end
  end
  
  def about
  end
 
  def contact
  end
 
  def mentores
  end

  def programas
    
  end

  def preincubacion; end
  def incubacion; end
  def innovacion; end


 
  def programas_tipo
    @tipo = params[:tipo]
    
    # Usar el ServiciosService que ya tiene toda la lógica
    resultado_servicio = ServiciosService.call(@tipo)
    @programs = resultado_servicio[:programas]
    @tipo_actual = resultado_servicio[:tipo_actual]
    
    # Validar que @tipo_actual no sea nil
    if @tipo_actual.nil?
      # Valor por defecto si no se encuentra el tipo
      @tipo_actual = {
        titulo: 'Programas',
        descripcion: 'Todos nuestros programas disponibles.',
        color: '#607D8B',
        color_claro: 'rgba(96, 125, 139, 0.1)',
        icono: 'fa-th-list'
      }
    end
    
    # Agrega un log para depuración
    Rails.logger.debug "Tipo: #{@tipo}"
    Rails.logger.debug "Tipo actual: #{@tipo_actual}"
    Rails.logger.debug "Programas encontrados: #{@programs.count} para tipo #{@tipo}"
    
    # Para formato JSON, devolvemos la información del servicio
    respond_to do |format|
      format.html # Renderiza la vista programas_tipo.html.erb
      format.json { render json: resultado_servicio }
    end
  end

  def react_test
    @datos_react = ReactTestService.call
  end
end