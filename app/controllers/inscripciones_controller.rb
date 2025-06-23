# REEMPLAZAR en app/controllers/inscripciones_controller.rb

class InscripcionesController < ApplicationController
  before_action :set_program_and_validate, only: [:new, :create]

  def new
    # Verificar disponibilidad para inscripción
    unless @program.puede_inscribirse?
      redirect_to programa_detalle_path(@program), 
                  alert: "Las inscripciones no están disponibles. #{@program.mensaje_disponibilidad}"
      return
    end
    
    # Crear nueva instancia según el tipo
    case @program.tipo
    when 'preincubacion'
      @formulario = FormularioProgramaPreincubacion.new(program: @program, es_plantilla: false)
      render 'formulario_preincubacion'
    when 'incubacion'
      @formulario = FormularioProgramaIncubacion.new(program: @program, es_plantilla: false)
      render 'formulario_incubacion'
    when 'innovacion'
      @formulario = FormularioProgramaInnovacion.new(program: @program, es_plantilla: false)
      render 'formulario_innovacion'
    end
    
    respond_to do |format|
      format.html # Renderiza según el tipo arriba
      format.json do
        if @program.puede_inscribirse?
          render json: {
            program: {
              id: @program.id,
              titulo: @program.titulo,
              descripcion: @program.descripcion,
              tipo: @program.tipo,
              fecha_vencimiento: @program.fecha_vencimiento,
              image_url: @program.image.attached? ? url_for(@program.image) : asset_path('program-placeholder.png')
            },
            puede_inscribirse: true
          }
        else
          render json: {
            error: "Inscripciones no disponibles",
            mensaje: @program.mensaje_disponibilidad,
            puede_inscribirse: false
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def create
    # Verificar disponibilidad antes de crear
    unless @program.puede_inscribirse?
      redirect_to programa_detalle_path(@program), 
                  alert: "Las inscripciones no están disponibles. #{@program.mensaje_disponibilidad}"
      return
    end
    
    # Crear nueva instancia según el tipo
    case @program.tipo
    when 'preincubacion'
      @formulario = FormularioProgramaPreincubacion.new(formulario_preincubacion_params.merge(
        program: @program, 
        es_plantilla: false
      ))
    when 'incubacion'
      @formulario = FormularioProgramaIncubacion.new(formulario_incubacion_params.merge(
        program: @program, 
        es_plantilla: false
      ))
    when 'innovacion'
      @formulario = FormularioProgramaInnovacion.new(formulario_innovacion_params.merge(
        program: @program, 
        es_plantilla: false
      ))
    end
    
    respond_to do |format|
      if @formulario.save
        session[:tipo_programa] = @program.tipo
        session[:last_form_type] = @program.tipo
        
        format.html { redirect_to confirmacion_inscripcion_path }
        format.json { render json: { status: 'success', redirect_url: confirmacion_inscripcion_path } }
      else
        format.html do
          case @program.tipo
          when 'preincubacion'
            render 'formulario_preincubacion', status: :unprocessable_entity
          when 'incubacion'
            render 'formulario_incubacion', status: :unprocessable_entity
          when 'innovacion'
            render 'formulario_innovacion', status: :unprocessable_entity
          end
        end
        format.json { render json: { status: 'error', errors: @formulario.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def confirmacion
    @tipo = session[:tipo_programa]
    
    if @tipo.nil?
      if session[:last_form_type] == 'preincubacion'
        @tipo = 'preincubacion'
      elsif session[:last_form_type] == 'incubacion'
        @tipo = 'incubacion'
      elsif session[:last_form_type] == 'innovacion'
        @tipo = 'innovacion'
      end
    end
    
    session.delete(:tipo_programa)
    session.delete(:last_form_type)
  end

  private
  
  def set_program_and_validate
    @program = Program.find(params[:id])
    
    # Actualizar estado automáticamente
    @program.actualizar_estado_automatico!
    
    # Verificar que el programa sea visible (no inactivo)
    if @program.estado == 'inactivo'
      redirect_to servicios_path, alert: 'Este programa ya no está disponible'
      return
    end
    
  rescue ActiveRecord::RecordNotFound
    redirect_to servicios_path, alert: 'Programa no encontrado'
  end
  
  def formulario_preincubacion_params
    params.require(:formulario_programa_preincubacion).permit(
      :nombre_emprendimiento, :descripcion, :propuesta_valor,
      :numero_integrantes_equipo, :nombre_lider, :apellidos_lider,
      :dni_lider, :correo_lider, :telefono_lider, :ocupacion_lider,
      :enteraste_programa, :expectativas_programa
    )
  end
  
  def formulario_incubacion_params
    params.require(:formulario_programa_incubacion).permit(
      :nombre_lider, :apellido_lider, :dni_lider,
      :telefono_lider, :correo_lider, :nombre_proyecto
    )
  end
  
  def formulario_innovacion_params
    params.require(:formulario_programa_innovacion).permit(
      :nombre_lider, :apellido_lider, :dni_lider,
      :telefono_lider, :correo_lider, :nombre_proyecto
    )
  end
end