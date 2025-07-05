module Admin
  class ProgramsController < BaseController
    before_action :set_program, only: [:edit, :update, :cambiar_estado]

def index
  @programs = Program.all
  
  # Filtros
  @programs = @programs.where(estado: params[:estado]) if params[:estado].present?
  @programs = @programs.where("titulo ILIKE ?", "%#{params[:search]}%") if params[:search].present?
  
  # Ordenamiento y paginación
  @programs = @programs.order(created_at: :desc)
                      .page(params[:page])
                      .per(10)
end
    
    def new
      @program = Program.new
      # Inicializa 1 campo vacío para cada tipo
      @program.objetivos.build
      @program.beneficios.build
      @program.requisitos.build
    end

    def show
      @program = Program.find(params[:id])
      
      respond_to do |format|
        format.html do
          if request.xhr?
            render partial: 'show_details', locals: { program: @program }, layout: false
          else
            # Vista completa si se accede directamente a la URL
            render 'show'
          end
        end
      end
    end


def create
  # Asegúrate de que el usuario está asignado
  @program = Program.new(program_params.except(:image, :objetivos_attributes, :beneficios_attributes, :requisitos_attributes))
  @program.user = current_user
  @program.created_by = current_user
  @program.updated_by = current_user
  
  # Aplicar validación manual de fechas
  fecha_pub = safe_parse_datetime(program_params[:fecha_publicacion])
  fecha_ven = safe_parse_datetime(program_params[:fecha_vencimiento])
  
  if fecha_pub.present? && fecha_ven.present? && fecha_ven <= fecha_pub
    @program.errors.add(:fecha_vencimiento, "debe ser posterior a la fecha de publicación")
  end
  
  # Validar el programa
  if @program.valid?
    # Usar el servicio actualizado para crear el programa
    result = CreateProgramService.call(program_params, current_user)
    
    if result.persisted?
      # Preparar datos para el modal de éxito
      flash[:program_data] = {
        titulo: result.titulo,
        encargado: result.encargado,
        descripcion: result.descripcion,
        tipo: result.tipo,
        estado: result.estado,
        fecha_publicacion: result.fecha_publicacion.strftime("%Y-%m-%d %H:%M"),
        fecha_vencimiento: result.fecha_vencimiento.strftime("%Y-%m-%d %H:%M")
      }
      
      # Redirigir con parámetro de éxito, y un mensaje más específico
      redirect_to admin_programs_path(success: true), notice: "¡Programa '#{result.titulo}' creado correctamente!"
      return
    else
      @program = result
    end
  end
  
  # Si llegamos aquí, hubo un error
  # Reconstruir asociaciones para el formulario
  rebuild_form_associations
  render :new, status: :unprocessable_entity
end


    def edit
      # Asegurar que hay al menos un campo de cada tipo para edición
      @program.objetivos.build if @program.objetivos.empty?
      @program.beneficios.build if @program.beneficios.empty?
      @program.requisitos.build if @program.requisitos.empty?
    end


  

def update
  adjusted_params = prepare_program_params(program_params)
  old_tipo = @program.tipo
  new_tipo = adjusted_params[:tipo]
  
  # VALIDACIÓN PREVIA: Verificar si se puede cambiar el tipo
  if old_tipo != new_tipo && @program.total_inscripciones > 0
    @program.errors.add(:tipo, "no se puede cambiar porque ya hay #{@program.total_inscripciones} inscripción(es) registrada(s)")
    
    # Asegurar que hay al menos un campo de cada tipo para renderizar la vista
    @program.objetivos.build if @program.objetivos.empty?
    @program.beneficios.build if @program.beneficios.empty?
    @program.requisitos.build if @program.requisitos.empty?
    
    render :edit, status: :unprocessable_entity
    return
  end
  
  # Si llegamos aquí, el cambio es válido
  if @program.update(adjusted_params.merge(updated_by: current_user))
    # Si el tipo ha cambiado, eliminar la plantilla anterior y crear nueva
    if old_tipo != @program.tipo
      case old_tipo
      when 'preincubacion'
        @program.formulario_plantilla_preincubacion&.destroy
      when 'incubacion'
        @program.formulario_plantilla_incubacion&.destroy
      when 'innovacion'
        @program.formulario_plantilla_innovacion&.destroy
      end
      
      # Crear nueva plantilla según el nuevo tipo
      case @program.tipo
      when 'preincubacion'
        @program.create_formulario_plantilla_preincubacion!(es_plantilla: true)
      when 'incubacion'
        @program.create_formulario_plantilla_incubacion!(es_plantilla: true)
      when 'innovacion'
        @program.create_formulario_plantilla_innovacion!(es_plantilla: true)
      end
    end
    
    update_associations(@program)
    redirect_to admin_programs_path, notice: 'Programa actualizado correctamente.'
  else
    render :edit, status: :unprocessable_entity
  end
end


    def cambiar_estado
      nuevo_estado = case @program.estado
                     when 'activo' then 'inactivo'
                     when 'inactivo' then 'pendiente'
                     when 'pendiente' then 'finalizado'
                     when 'finalizado' then 'activo'
                     end
      
      if @program.update(estado: nuevo_estado, updated_by: current_user)
        redirect_to admin_programs_path, notice: "Estado cambiado a #{nuevo_estado.humanize}"
      else
        redirect_to admin_programs_path, alert: 'Error al cambiar estado'
      end
    end

    def tipo_formulario
      tipo = params[:tipo]
      render partial: "admin/programs/formulario_#{tipo}", layout: false
    end

    private

    def set_program
      @program = Program.includes(
        :objetivos, 
        :beneficios, 
        :requisitos,
        :formulario_plantilla_preincubacion,
        :formulario_plantilla_incubacion,
        :formulario_plantilla_innovacion
      ).find(params[:id])
    end
    
    def prepare_program_params(params)
      adjusted_params = params.dup
      
      # Parseo seguro de fechas
      adjusted_params[:fecha_publicacion] = safe_parse_datetime(params[:fecha_publicacion])
      adjusted_params[:fecha_vencimiento] = safe_parse_datetime(params[:fecha_vencimiento])
      adjusted_params
    end
    
def program_params
  params.require(:program).permit(
    :titulo, :descripcion, :encargado, :tipo, 
    :fecha_publicacion, :fecha_vencimiento, :estado, :image,
    objetivos_attributes: [:id, :descripcion, :_destroy],
    beneficios_attributes: [:id, :descripcion, :_destroy],
    requisitos_attributes: [:id, :descripcion, :_destroy],
    # CAMBIO: Usar las relaciones de plantilla
    formulario_plantilla_preincubacion_attributes: [
      :id, :_destroy, :nombre_emprendimiento, :descripcion, :propuesta_valor,
      :numero_integrantes_equipo, :nombre_lider, :apellidos_lider,
      :dni_lider, :correo_lider, :telefono_lider, :ocupacion_lider,
      :enteraste_programa, :expectativas_programa, :es_plantilla
    ],
    formulario_plantilla_incubacion_attributes: [
      :id, :_destroy, :nombre_lider, :apellido_lider, :dni_lider,
      :telefono_lider, :correo_lider, :nombre_proyecto, :es_plantilla
    ],
    formulario_plantilla_innovacion_attributes: [
      :id, :_destroy, :nombre_lider, :apellido_lider, :dni_lider,
      :telefono_lider, :correo_lider, :nombre_proyecto, :es_plantilla
    ],
    programs_patrocinadors_attributes: [
      :id, :_destroy, :patrocinador_id
    ]
  )
end
    
    def safe_parse_datetime(datetime_string)
      return if datetime_string.blank?
      
      if datetime_string.is_a?(String)
        DateTime.strptime(datetime_string, '%Y-%m-%dT%H:%M') rescue datetime_string
      else
        datetime_string
      end
    end
    
    def update_associations(program)
      # Usamos nested attributes para manejar las asociaciones
      if program_params[:objetivos_fields]
        program.objetivos.destroy_all
        program_params[:objetivos_fields].each do |obj|
          program.objetivos.build(descripcion: obj[:descripcion]) if obj[:descripcion].present?
        end
      end
    
      if program_params[:beneficios_fields]
        program.beneficios.destroy_all
        program_params[:beneficios_fields].each do |ben|
          program.beneficios.build(descripcion: ben[:descripcion]) if ben[:descripcion].present?
        end
      end
    
      if program_params[:requisitos_fields]
        program.requisitos.destroy_all
        program_params[:requisitos_fields].each do |req|
          program.requisitos.build(descripcion: req[:descripcion]) if req[:descripcion].present?
        end
      end
    end
    
    def fecha_vencimiento_mayor_publicacion
      return if @program.fecha_vencimiento.blank? || @program.fecha_publicacion.blank?
      
      if @program.fecha_vencimiento <= @program.fecha_publicacion
        @program.errors.add(:fecha_vencimiento, "debe ser posterior a la fecha de publicación")
        throw :abort
      end
    end
    
    def rebuild_form_associations
      # Asegurarse de que hay al menos un campo de cada tipo
      @program.objetivos.build if @program.objetivos.empty?
      @program.beneficios.build if @program.beneficios.empty?
      @program.requisitos.build if @program.requisitos.empty?
      
      # Reconstruir objetivos desde los parámetros
      if params[:program] && params[:program][:objetivos_attributes]
        params[:program][:objetivos_attributes].each do |index, attrs|
          next if attrs[:_destroy] == "1" || attrs[:descripcion].blank?
          @program.objetivos.build(descripcion: attrs[:descripcion])
        end
      end
    
      # Reconstruir beneficios desde los parámetros
      if params[:program] && params[:program][:beneficios_attributes]
        params[:program][:beneficios_attributes].each do |index, attrs|
          next if attrs[:_destroy] == "1" || attrs[:descripcion].blank?
          @program.beneficios.build(descripcion: attrs[:descripcion])
        end
      end
    
      # Reconstruir requisitos desde los parámetros
      if params[:program] && params[:program][:requisitos_attributes]
        params[:program][:requisitos_attributes].each do |index, attrs|
          next if attrs[:_destroy] == "1" || attrs[:descripcion].blank?
          @program.requisitos.build(descripcion: attrs[:descripcion])
        end
      end
    end


  end
end