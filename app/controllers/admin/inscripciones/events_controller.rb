# app/controllers/admin/inscripciones/events_controller.rb

class Admin::Inscripciones::EventsController < Admin::BaseController
  before_action :set_event, only: [:show, :cambiar_estado_inscripcion, :export_pdf, :export_excel]

  def index
    @events = Event.includes(:formulario_eventos)
                   .order(created_at: :desc)

    # Filtros
    @events = @events.where("titulo ILIKE ?", "%#{params[:search]}%") if params[:search].present?

    # Paginación
    @events = @events.page(params[:page]).per(12)

    # Calcular estadísticas generales
    @stats = calculate_general_stats
  end

  def show
    # Obtener todas las inscripciones del evento (excluyendo plantillas)
    @inscripciones = @event.formulario_eventos
                           .where(es_plantilla: [false, nil])
                           .includes(:event)
                           .order(created_at: :asc)

    # Aplicar filtros
    @inscripciones = filter_inscripciones(@inscripciones)
    
    # Estadísticas del evento específico
    @event_stats = calculate_event_stats(@event)

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
      redirect_to admin_inscripciones_event_path(@event), 
                 alert: 'Parámetros inválidos para cambiar estado'
      return
    end
    
    # Validar que el nuevo estado sea válido
    estados_validos = ['pendiente', 'aprobado', 'rechazado']
    unless estados_validos.include?(nuevo_estado)
      redirect_to admin_inscripciones_event_path(@event), 
                 alert: 'Estado inválido'
      return
    end
    
    begin
      inscripcion = find_inscripcion_by_id(@event, inscripcion_id)
      
      if inscripcion.nil?
        redirect_to admin_inscripciones_event_path(@event), 
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
        
        redirect_to admin_inscripciones_event_path(@event), 
                   notice: mensaje_exito
      else
        # Mostrar errores específicos si los hay
        errores = inscripcion.errors.full_messages.join(', ')
        redirect_to admin_inscripciones_event_path(@event), 
                   alert: "Error al actualizar estado: #{errores}"
      end
      
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_inscripciones_event_path(@event), 
                 alert: 'Inscripción no encontrada'
    rescue => e
      # Log del error para debugging
      Rails.logger.error "Error cambiando estado de inscripción: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      redirect_to admin_inscripciones_event_path(@event), 
                 alert: 'Error interno. Contacte al administrador del sistema.'
    end
  end

  def export_excel
    @inscripciones = @event.formulario_eventos
                           .where(es_plantilla: [false, nil])
                           .order(created_at: :asc)
    
    respond_to do |format|
      format.xlsx do
        response.headers['Content-Disposition'] = 
          "attachment; filename=\"inscripciones_evento_#{@event.titulo.parameterize}_#{Date.current}.xlsx\""
      end
    end
  end

def export_pdf
  @inscripciones = @event.formulario_eventos
                         .where(es_plantilla: [false, nil])
                         .order(created_at: :asc)
  
  respond_to do |format|
    format.pdf do
      begin
        # Usar el mismo patrón que programs - SOLO Prawn, SIN fallback
        pdf_service = EventPdfGeneratorService.new
        pdf_content = pdf_service.generate_event_report(@event, @inscripciones)
        
        send_data pdf_content,
                  filename: "inscripciones_evento_#{@event.titulo.parameterize}_#{Date.current}.pdf",
                  type: 'application/pdf',
                  disposition: 'attachment'
      rescue => e
        Rails.logger.error "Error generating PDF: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        
        # Mismo fallback que programs - redirect con mensaje
        redirect_to admin_inscripciones_events_path, 
                   alert: "Error al generar PDF: #{e.message}"
      end
    end
  end
end

  def export_all_excel
    @events = Event.includes(:formulario_eventos)
    
    respond_to do |format|
      format.xlsx do
        response.headers['Content-Disposition'] = 
          "attachment; filename=\"todas_inscripciones_eventos_#{Date.current}.xlsx\""
      end
    end
  end

def export_all_pdf
  @events = Event.includes(:formulario_eventos)
  
  respond_to do |format|
    format.pdf do
      begin
        pdf_service = EventPdfGeneratorService.new
        pdf_content = pdf_service.generate_all_events_report(@events)
        
        send_data pdf_content,
                  filename: "todas_inscripciones_eventos_#{Date.current}.pdf",
                  type: 'application/pdf',
                  disposition: 'attachment'
        
      rescue => e
        Rails.logger.error "Error generating PDF: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        
        # Mismo patrón que export_pdf individual - redirect con alert
        redirect_to admin_inscripciones_events_path, 
                   alert: "Error al generar PDF: #{e.message}"
      end
    end
  end
end

  private

  def set_event
    @event = Event.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_inscripciones_events_path, 
               alert: 'Evento no encontrado'
  end

  def find_inscripcion_by_id(event, inscripcion_id)
    event.formulario_eventos.where(es_plantilla: [false, nil]).find(inscripcion_id)
  end

  def filter_inscripciones(inscripciones)
    # Filtro por estado
    if params[:estado].present?
      inscripciones = inscripciones.where(estado: params[:estado])
    end

    # Filtro por búsqueda (nombre del líder)
    if params[:search_inscripcion].present?
      search_term = "%#{params[:search_inscripcion]}%"
      inscripciones = inscripciones.where(
        "nombre_lider ILIKE ? OR apellidos_lider ILIKE ? OR correo_lider ILIKE ?", 
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
    # Estadísticas generales de eventos (excluyendo plantillas)
    total_inscripciones = FormularioEvento.where(es_plantilla: [false, nil]).count

    {
      total_inscripciones: total_inscripciones,
      por_estado: {
        pendientes: count_by_estado('pendiente'),
        aprobadas: count_by_estado('aprobado'),
        rechazadas: count_by_estado('rechazado')
      },
      recientes: get_recent_inscripciones(5)
    }
  end

  def calculate_event_stats(event)
    inscripciones = event.formulario_eventos.where(es_plantilla: [false, nil])
    
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
    FormularioEvento.where(estado: estado, es_plantilla: [false, nil]).count
  end

  def get_recent_inscripciones(limit)
    recent_inscripciones = FormularioEvento
                          .joins(:event)
                          .includes(:event)
                          .where(es_plantilla: [false, nil])
                          .order(created_at: :desc)
                          .limit(limit)
                          .map { |i| { inscripcion: i, tipo: 'evento' } }

    recent_inscripciones
  end
end