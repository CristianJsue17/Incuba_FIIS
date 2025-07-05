# app/controllers/inscripciones_program_controller.rb
class InscripcionesProgramController < ApplicationController
  before_action :set_program, only: [:new, :create, :consultar_dni]

  def new
    result = InscripcionesProgramService.prepare_new_inscription(@program.id)
        
    unless result[:success]
      redirect_to programa_detalle_path(@program), alert: result[:error]
      return
    end

    @formulario = result[:formulario]
        
    case @program.tipo
    when 'preincubacion'
      render 'formulario_preincubacion'
    when 'incubacion'
      render 'formulario_incubacion'
    when 'innovacion'
      render 'formulario_innovacion'
    end
  end

  def create
    formulario_params = case @program.tipo
                       when 'preincubacion'
                         formulario_preincubacion_params
                       when 'incubacion'
                         formulario_incubacion_params
                       when 'innovacion'
                         formulario_innovacion_params
                       end

    result = InscripcionesProgramService.create_inscription(
      program_id: @program.id,
      formulario_params: formulario_params,
      tipo: @program.tipo
    )

    if result[:success]
      session[:tipo_programa] = result[:session_data][:tipo_programa]
      session[:last_form_type] = result[:session_data][:last_form_type]
      redirect_to confirmacion_inscripcion_path
    else
      @formulario = result[:formulario]
      flash.now[:alert] = result[:errors].join(', ') if result[:errors]
      render result[:template], status: :unprocessable_entity
    end
  end

  # Método para consultar DNI vía AJAX - NUEVO
  def consultar_dni
    dni = params[:dni]

    if dni.blank?
      render json: {
        success: false,
        error: 'DNI es requerido'
      }, status: :bad_request
      return
    end

    # Consultar usando el servicio
    result = DniApiService.consultar_dni(dni)

    if result[:success]
      render json: {
        success: true,
        data: {
          nombres: result[:nombres],
          apellido_paterno: result[:apellido_paterno],
          apellido_materno: result[:apellido_materno],
          apellidos_completos: result[:apellidos_completos],
          nombre_completo: result[:nombre_completo]
        }
      }
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
  end

  def confirmacion
    result = InscripcionesProgramService.confirmacion_data(
      session_tipo: session[:tipo_programa],
      session_last_form_type: session[:last_form_type]
    )
        
    @tipo = result[:tipo]
        
    session.delete(:tipo_programa)
    session.delete(:last_form_type)
  end

  private
    
  def set_program
    @program = Program.find(params[:id])
    @program.actualizar_estado_automatico!
        
    if @program.estado == 'inactivo'
      redirect_to servicios_path, alert: 'Este programa ya no está disponible'
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