# app/controllers/inscripciones_controller.rb
class InscripcionesController < ApplicationController
  def new
    @program = Program.find(params[:id])
    
    # Determinar qué formulario mostrar según el tipo de programa
    case @program.tipo
    when 'preincubacion'
      @formulario = @program.formulario_programa_preincubacion || @program.build_formulario_programa_preincubacion
      render 'formulario_preincubacion'
    when 'incubacion'
      @formulario = @program.formulario_programa_incubacion || @program.build_formulario_programa_incubacion
      render 'formulario_incubacion'
    when 'innovacion'
      @formulario = @program.formulario_programa_innovacion || @program.build_formulario_programa_innovacion
      render 'formulario_innovacion'
    end
    
    # Para formato JSON, devolvemos información sobre el programa
    respond_to do |format|
      format.html # Renderiza según el tipo arriba
      format.json do
        render json: {
          program: {
            id: @program.id,
            titulo: @program.titulo,
            descripcion: @program.descripcion,
            tipo: @program.tipo,
            fecha_vencimiento: @program.fecha_vencimiento,
            image_url: @program.image.attached? ? url_for(@program.image) : asset_path('program-placeholder.png')
          }
        }
      end
    end
  end

  # El resto del controlador permanece igual
  def create
    @program = Program.find(params[:id])
    
    # Procesar el formulario según el tipo de programa
    case @program.tipo
    when 'preincubacion'
      @formulario = @program.formulario_programa_preincubacion || @program.build_formulario_programa_preincubacion
      @formulario.assign_attributes(formulario_preincubacion_params)
    when 'incubacion'
      @formulario = @program.formulario_programa_incubacion || @program.build_formulario_programa_incubacion
      @formulario.assign_attributes(formulario_incubacion_params)
    when 'innovacion'
      @formulario = @program.formulario_programa_innovacion || @program.build_formulario_programa_innovacion
      @formulario.assign_attributes(formulario_innovacion_params)
    end
    
    respond_to do |format|
      if @formulario.save
        # Guardar tipo en sesión para usarlo en confirmación
        session[:tipo_programa] = @program.tipo
        
        format.html { redirect_to confirmacion_inscripcion_path }
        format.json { render json: { status: 'success', redirect_url: confirmacion_inscripcion_path } }
      else
        # Si hay errores, volver al formulario correspondiente
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
  # Obtener el tipo desde la sesión
  @tipo = session[:tipo_programa]
  
  # Si @tipo es nil, asignar el tipo basado en el modelo del formulario
  if @tipo.nil?
    # Verificar qué tipo de formulario se ha completado recientemente
    if session[:last_form_type] == 'preincubacion'
      @tipo = 'preincubacion'
    elsif session[:last_form_type] == 'incubacion'
      @tipo = 'incubacion'
    elsif session[:last_form_type] == 'innovacion'
      @tipo = 'innovacion'
    end
  end
  
  # Limpiar la sesión después de usarlo
  session.delete(:tipo_programa)
  session.delete(:last_form_type)
end

  private
  
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