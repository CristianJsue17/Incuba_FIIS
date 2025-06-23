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

  
# # Método para mostrar los detalles de un programa específico
def programa_detalle
  @program = Program.includes(
    :objetivos, 
    :beneficios, 
    :requisitos,
    :user,
    :created_by
  ).find(params[:id])
  
  # Actualizar estado automáticamente antes de mostrar
  @program.actualizar_estado_automatico!
  
  # Verificar si el programa debe ser visible (no inactivo)
  if @program.estado == 'inactivo'
    redirect_to servicios_path, alert: 'Este programa ya no está disponible'
    return
  end
  
  # Obtener información del tipo para estilos
  @tipo_actual = ServiciosService.call(@program.tipo)[:tipo_actual]
  
  # Contar inscripciones actuales
  @total_inscripciones = @program.total_inscripciones
  
  # Verificar disponibilidad para inscripciones según estado
  @puede_inscribirse = @program.puede_inscribirse?
  @mensaje_disponibilidad = @program.mensaje_disponibilidad
  @estado_css_class = @program.estado_css_class
  
  respond_to do |format|
    format.html # Renderiza programa_detalle.html.erb
    format.json do
      render json: {
        program: {
          id: @program.id,
          titulo: @program.titulo,
          descripcion: @program.descripcion,
          tipo: @program.tipo,
          tipo_humanizado: @program.tipo_humanizado,
          encargado: @program.encargado,
          estado: @program.estado,
          fecha_publicacion: @program.fecha_publicacion,
          fecha_vencimiento: @program.fecha_vencimiento,
          objetivos: @program.objetivos.map(&:descripcion),
          beneficios: @program.beneficios.map(&:descripcion),
          requisitos: @program.requisitos.map(&:descripcion),
          total_inscripciones: @total_inscripciones,
          puede_inscribirse: @puede_inscribirse,
          mensaje_disponibilidad: @mensaje_disponibilidad,
          image_url: @program.image.attached? ? url_for(@program.image) : asset_path('program-placeholder.png')
        },
        tipo_actual: @tipo_actual
      }
    end
  end
rescue ActiveRecord::RecordNotFound
  redirect_to servicios_path, alert: 'Programa no encontrado'
end

 
end