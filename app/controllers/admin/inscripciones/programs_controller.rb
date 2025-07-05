module Admin
  module Inscripciones
    class ProgramsController < Admin::BaseController
      before_action :set_program, only: [:show, :cambiar_estado_inscripcion, :export_pdf, :export_excel]

      def index
        @programs = Program.includes(:formulario_programa_preincubacions, 
                                   :formulario_programa_incubacions, 
                                   :formulario_programa_innovacions)
                          .order(created_at: :desc)

        # Filtros
        @programs = @programs.where(tipo: params[:tipo]) if params[:tipo].present?
        @programs = @programs.where("titulo ILIKE ?", "%#{params[:search]}%") if params[:search].present?

        # Paginación
        @programs = @programs.page(params[:page]).per(12)

        # Calcular estadísticas generales
        @stats = calculate_general_stats
      end

def show
  # Obtener todas las inscripciones del programa según su tipo
  @inscripciones = get_inscripciones_by_type(@program)
                    .includes(:program)  # ← CORREGIDO: usar includes normal
                    .order(created_at: :asc)

  # Aplicar filtros
  @inscripciones = filter_inscripciones(@inscripciones)
  
  # Estadísticas del programa específico
  @program_stats = calculate_program_stats(@program)

  # Paginación
  @inscripciones = @inscripciones.page(params[:page]).per(20) if defined?(Kaminari)

  respond_to do |format|
    format.html
    format.json { render json: @inscripciones }
  end
end

def cambiar_estado_inscripcion
  inscripcion_id = params[:inscripcion_id]
  nuevo_estado = params[:nuevo_estado]
  
  # Validar que los parámetros estén presentes
  unless inscripcion_id.present? && nuevo_estado.present?
    redirect_to admin_inscripciones_program_path(@program), 
               alert: 'Parámetros inválidos para cambiar estado'
    return
  end
  
  # Validar que el nuevo estado sea válido
  estados_validos = ['pendiente', 'aprobado', 'rechazado']
  unless estados_validos.include?(nuevo_estado)
    redirect_to admin_inscripciones_program_path(@program), 
               alert: 'Estado inválido'
    return
  end
  
  begin
    inscripcion = find_inscripcion_by_id(@program, inscripcion_id)
    
    if inscripcion.nil?
      redirect_to admin_inscripciones_program_path(@program), 
                 alert: 'Inscripción no encontrada'
      return
    end
    
    # Intentar actualizar el estado
    if inscripcion.update(estado: nuevo_estado)
      # Log del cambio
      Rails.logger.info "Estado de inscripción #{inscripcion_id} cambiado a #{nuevo_estado} por #{current_user.email}"
      
      # Mensaje de éxito personalizado
      mensaje_exito = case nuevo_estado
                     when 'pendiente'
                       'Estado cambiado a Pendiente'
                     when 'aprobado' 
                       '¡Inscripción APROBADA exitosamente!'
                     when 'rechazado'
                       'Inscripción marcada como RECHAZADA'
                     end
      
      redirect_to admin_inscripciones_program_path(@program), 
                 notice: mensaje_exito
    else
      # Mostrar errores específicos si los hay
      errores = inscripcion.errors.full_messages.join(', ')
      redirect_to admin_inscripciones_program_path(@program), 
                 alert: "Error al actualizar estado: #{errores}"
    end
    
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_inscripciones_program_path(@program), 
               alert: 'Inscripción no encontrada'
  rescue => e
    # Log del error para debugging
    Rails.logger.error "Error cambiando estado de inscripción: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    redirect_to admin_inscripciones_program_path(@program), 
               alert: 'Error interno. Contacte al administrador del sistema.'
  end
end

      def export_excel
        @inscripciones = get_inscripciones_by_type(@program).order(created_at: :asc)
        
        respond_to do |format|
          format.xlsx do
            response.headers['Content-Disposition'] = 
              "attachment; filename=\"inscripciones_#{@program.titulo.parameterize}_#{Date.current}.xlsx\""
          end
        end
      end


def export_pdf
  @inscripciones = get_inscripciones_by_type(@program).order(created_at: :asc)
  
  respond_to do |format|
    format.pdf do
      begin
        # CAMBIO: PdfGeneratorService → ProgramPdfGeneratorService
        pdf_service = ProgramPdfGeneratorService.new
        pdf_content = pdf_service.generate_program_report(@program, @inscripciones)
        
        send_data pdf_content,
                  filename: "inscripciones_#{@program.titulo.parameterize}_#{Date.current}.pdf",
                  type: 'application/pdf',
                  disposition: 'attachment'
      rescue => e
        Rails.logger.error "Error generating PDF: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        
        redirect_to admin_inscripciones_programs_path, 
                   alert: "Error al generar PDF: #{e.message}"
      end
    end
  end
end


      def export_all_excel
        @programs = Program.includes(:formulario_programa_preincubacions, 
                                   :formulario_programa_incubacions, 
                                   :formulario_programa_innovacions)
        
        respond_to do |format|
          format.xlsx do
            response.headers['Content-Disposition'] = 
              "attachment; filename=\"todas_inscripciones_#{Date.current}.xlsx\""
          end
        end
      end

def export_all_pdf
  @programs = Program.includes(:formulario_programa_preincubacions, 
                             :formulario_programa_incubacions, 
                             :formulario_programa_innovacions)
  
  respond_to do |format|
    format.pdf do
      # CAMBIO: PdfGeneratorService → ProgramPdfGeneratorService
      pdf_service = ProgramPdfGeneratorService.new
      pdf_content = pdf_service.generate_all_programs_report(@programs)
      
      send_data pdf_content,
                filename: "todas_inscripciones_#{Date.current}.pdf",
                type: 'application/pdf',
                disposition: 'attachment'
    end
  end
end

      private

      def set_program
        @program = Program.find(params[:id])
      end

def get_inscripciones_by_type(program)
  case program.tipo
  when 'preincubacion'
    program.formulario_programa_preincubacions.where(es_plantilla: [false, nil])
  when 'incubacion'
    program.formulario_programa_incubacions.where(es_plantilla: [false, nil])
  when 'innovacion'
    program.formulario_programa_innovacions.where(es_plantilla: [false, nil])
  else
    []
  end
end
      def find_inscripcion_by_id(program, inscripcion_id)
        inscripciones = get_inscripciones_by_type(program)
        inscripciones.find(inscripcion_id)
      end

def filter_inscripciones(inscripciones)
  # Filtro por estado
  if params[:estado].present?
    inscripciones = inscripciones.where(estado: params[:estado])
  end

  # Filtro por búsqueda (nombre del líder)
  if params[:search_inscripcion].present?
    search_term = "%#{params[:search_inscripcion]}%"
    
    # CORREGIDO: Usar apellido correcto según el tipo de programa
    apellido_column = case @program.tipo
                     when 'preincubacion'
                       'apellidos_lider'  # plural
                     when 'incubacion', 'innovacion'
                       'apellido_lider'   # singular
                     else
                       'apellido_lider'   # por defecto singular
                     end
    
    inscripciones = inscripciones.where(
      "nombre_lider ILIKE ? OR #{apellido_column} ILIKE ? OR correo_lider ILIKE ?", 
      search_term, search_term, search_term
    )
  end

  # Filtro por fecha
  if params[:fecha_desde].present?
    inscripciones = inscripciones.where("created_at >= ?", params[:fecha_desde])
  end

  if params[:fecha_hasta].present?
    inscripciones = inscripciones.where("created_at <= ?", params[:fecha_hasta])
  end

  inscripciones
end

def calculate_general_stats
  # Filtrar plantillas en las estadísticas
  total_preincubacion = FormularioProgramaPreincubacion.joins(:program)
                                                      .where(es_plantilla: [false, nil])
                                                      .count
  total_incubacion = FormularioProgramaIncubacion.joins(:program)
                                                .where(es_plantilla: [false, nil])
                                                .count
  total_innovacion = FormularioProgramaInnovacion.joins(:program)
                                                .where(es_plantilla: [false, nil])
                                                .count

  {
    total_inscripciones: total_preincubacion + total_incubacion + total_innovacion,
    por_tipo: {
      preincubacion: total_preincubacion,
      incubacion: total_incubacion,
      innovacion: total_innovacion
    },
    por_estado: {
      pendientes: count_by_estado('pendiente'),
      aprobadas: count_by_estado('aprobado'),
      rechazadas: count_by_estado('rechazado')
    },
    recientes: get_recent_inscripciones(5)
  }
end

      def calculate_program_stats(program)
        inscripciones = get_inscripciones_by_type(program)
        
        {
          total: inscripciones.count,
          pendientes: inscripciones.where(estado: 'pendiente').count,
          aprobadas: inscripciones.where(estado: 'aprobado').count,
          rechazadas: inscripciones.where(estado: 'rechazado').count,
          esta_semana: inscripciones.where(created_at: 1.week.ago..Time.current).count,
          este_mes: inscripciones.where(created_at: 1.month.ago..Time.current).count
        }
      end

def count_by_estado(estado)
  preincubacion = FormularioProgramaPreincubacion.where(estado: estado, es_plantilla: [false, nil]).count
  incubacion = FormularioProgramaIncubacion.where(estado: estado, es_plantilla: [false, nil]).count
  innovacion = FormularioProgramaInnovacion.where(estado: estado, es_plantilla: [false, nil]).count
  
  preincubacion + incubacion + innovacion
end

def get_recent_inscripciones(limit)
  recent = []
  
  # Preincubación - SIN PLANTILLAS
  preincubacion = FormularioProgramaPreincubacion
                   .joins(:program)
                   .includes(:program)
                   .where(es_plantilla: [false, nil])
                   .order(created_at: :desc)
                   .limit(limit)
                   .map { |i| { inscripcion: i, tipo: 'preincubacion' } }
  
  # Incubación - SIN PLANTILLAS
  incubacion = FormularioProgramaIncubacion
                .joins(:program)
                .includes(:program)
                .where(es_plantilla: [false, nil])
                .order(created_at: :desc)
                .limit(limit)
                .map { |i| { inscripcion: i, tipo: 'incubacion' } }
  
  # Innovación - SIN PLANTILLAS
  innovacion = FormularioProgramaInnovacion
                .joins(:program)
                .includes(:program)
                .where(es_plantilla: [false, nil])
                .order(created_at: :desc)
                .limit(limit)
                .map { |i| { inscripcion: i, tipo: 'innovacion' } }
  
  # Combinar y ordenar por fecha
  recent = (preincubacion + incubacion + innovacion)
            .sort_by { |item| item[:inscripcion].created_at }
            .reverse
            .first(limit)
  
  recent
end

      # Scope helpers for associations
      def includes_associations
        # Este método será usado en los modelos para incluir asociaciones necesarias
      end
    end
  end
end