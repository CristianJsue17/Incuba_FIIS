# app/controllers/inscripciones_event_controller.rb
class InscripcionesEventController < ApplicationController
  before_action :set_event, only: [:new, :create, :consultar_dni]

  def new
    result = InscripcionesEventService.prepare_new_inscription(@event.id)
    
    unless result[:success]
      redirect_to evento_detalle_path(@event), alert: result[:error]
      return
    end

    @formulario = result[:formulario]
  end

  def create
    result = InscripcionesEventService.create_inscription(
      event_id: @event.id,
      formulario_params: formulario_params
    )

    if result[:success]
      redirect_to confirmacion_inscripcion_evento_path, notice: result[:message]
    else
      @formulario = result[:formulario]
      flash.now[:alert] = result[:errors].join(', ') if result[:errors]
      render :new, status: :unprocessable_entity
    end
  end

  def confirmacion
    # Vista de confirmación después de inscribirse
  end

  # Método para consultar DNI vía AJAX
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

  private

  def set_event
    @event = Event.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to eventos_path, alert: 'Evento no encontrado'
  end

  def formulario_params
    params.require(:formulario_evento).permit(
      :nombre_lider, :apellidos_lider, :dni_lider, :correo_lider, :telefono_lider,
      :numero_integrantes_equipo, :nombre_emprendimiento, :descripcion,
      :cuentanos_proyecto, :atributos_ventaja_diferenciacion, :modelo_negocio,
      :indicadores_metas_6meses, :redes_sociales, :web_startup,
      :sector_economico, :categoria
    )
  end
end