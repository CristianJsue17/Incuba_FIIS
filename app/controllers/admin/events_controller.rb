# app/controllers/admin/events_controller.rb - CORREGIDO

class Admin::EventsController < Admin::BaseController
  before_action :set_event, only: [:show, :edit, :update, :destroy, :cambiar_estado]

  def index
    @events = Event.includes(:user, :created_by)
                   .order(created_at: :desc)
                   .page(params[:page])
                   .per(10)
    
    # Filtros
    @events = @events.where(estado: params[:estado]) if params[:estado].present?
    @events = @events.where("titulo ILIKE ?", "%#{params[:search]}%") if params[:search].present?
  end

def show
  @total_inscripciones = @event.total_inscripciones
  
  respond_to do |format|
    format.html # Para acceso directo con URL (renderiza show.html.erb)
    format.json { render json: { event: @event } } # Para JSON si se necesita
    
    # Para peticiones AJAX del modal (renderiza solo el partial)
    if request.xhr?
      render partial: 'show_details', locals: { event: @event }, layout: false
    end
  end
end

  def new
    @event = Event.new
    @event.user = current_user
  end

  def create
    @event = Event.new(event_params)
    @event.user = current_user
    @event.created_by = current_user
    
    if @event.save
      # CAMBIO: Redirigir al index en lugar de show
      redirect_to admin_events_path, notice: 'Evento creado exitosamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @event.updated_by = current_user
    
    if @event.update(event_params)
      # CAMBIO: Redirigir al index en lugar de show
      redirect_to admin_events_path, notice: 'Evento actualizado exitosamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @event.formulario_eventos.any?
      redirect_to admin_events_path, alert: 'No se puede eliminar el evento porque tiene inscripciones asociadas.'
    else
      @event.destroy
      redirect_to admin_events_path, notice: 'Evento eliminado exitosamente.'
    end
  end

  def cambiar_estado
    if @event.update(estado: params[:estado])
      render json: { 
        success: true, 
        message: "Estado cambiado a #{params[:estado]}",
        nuevo_estado: @event.estado 
      }
    else
      render json: { 
        success: false, 
        message: 'Error al cambiar el estado' 
      }
    end
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(
      :titulo, :descripcion, :encargado, :fecha_publicacion, 
      :fecha_vencimiento, :estado, :archivo_bases_pitch, :image
    )
  end
end