class Admin::UsersController < Admin::BaseController
  before_action :ensure_can_manage_users
  before_action :set_user, only: [:show, :edit, :update, :destroy, :cambiar_estado, :suspender_temporalmente, :reactivar]

  def index
    # MEJORADO: Incluir información de actividad y ordenar por última actividad
    @users = User.includes(:roles, :occupation)
                 .por_ultima_actividad  # Usar el scope del modelo
                 
    # Aplicar filtros de búsqueda
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @users = @users.where(
        "nombre ILIKE ? OR apellido ILIKE ? OR email ILIKE ? OR dni ILIKE ?", 
        search_term, search_term, search_term, search_term
      )
    end
    
    # Filtrar por estado
    @users = @users.where(estado: params[:estado]) if params[:estado].present?

    # AGREGAR PAGINACIÓN - 10 usuarios por página
    @users = @users.page(params[:page]).per(10)
    
    # Log para debugging
    Rails.logger.info "📊 Mostrando #{@users.count} usuarios en el índice admin"
  end

  def show
    Rails.logger.info "👀 Admin #{current_user.email} visualizando usuario: #{@user.email}"
  end

  def new
    @user = User.new
    @roles = Role.all
    @occupations = Occupation.all.order(:nombre)
  end

  def create
    @user = User.new(user_params)
    @user.password = generate_temporary_password
    @user.estado = 'activo'
    @user.created_by = current_user
    @user.updated_by = current_user

    if @user.save
      # Asignar rol
      if params[:role_id].present?
        @user.user_roles.create(role_id: params[:role_id])
        refresh_cache_after_user_status_change(@user.id)
      end

      log_user_status_change(@user, 'nuevo', 'activo', 'creation')
      redirect_to admin_users_path, notice: user_action_message('create', @user)
    else
      @roles = Role.all
      @occupations = Occupation.all.order(:nombre)
      render :new
    end
  end

  def edit
    @roles = Role.all
    @occupations = Occupation.all.order(:nombre)
    @user_role = @user.user_roles.first
  end

  def update
    old_status = @user.estado
    @user.updated_by = current_user
    
    if @user.update(user_params_for_update)
      # Actualizar rol si se cambió
      if params[:role_id].present?
        @user.user_roles.destroy_all
        @user.user_roles.create(role_id: params[:role_id])
      end

      # Refrescar caché si cambió el estado
      if old_status != @user.estado
        refresh_cache_after_user_status_change(@user.id)
        log_user_status_change(@user, old_status, @user.estado, 'update')
      end

      redirect_to admin_users_path, notice: user_action_message('update', @user)
    else
      @roles = Role.all
      @occupations = Occupation.all.order(:nombre)
      @user_role = @user.user_roles.first
      render :edit
    end
  end

  def destroy
    old_status = @user.estado
    user_name = @user.nombre_completo
    
    # Validar que no se elimine el último administrador
    if @user.es_admin? && User.joins(:roles).where(roles: { nombre: 'Administrador' }).count <= 1
      redirect_to admin_users_path, alert: "No se puede eliminar al único administrador del sistema."
      return
    end
    
    # Validar que no se elimine a sí mismo
    if @user == current_user
      redirect_to admin_users_path, alert: "No puedes eliminarte a ti mismo."
      return
    end
    
    begin
      # Usar transacción para asegurar que todo se elimine correctamente
      ActiveRecord::Base.transaction do
        # Eliminar roles asociados
        @user.user_roles.destroy_all
        
        # Limpiar caché antes de eliminar
        clear_user_roles_cache(@user.id)
        
        # Eliminar avatar si existe
        @user.avatar.purge if @user.avatar.attached?
        
        # Eliminar el usuario
        @user.destroy!
      end
      
      log_user_status_change(@user, old_status, 'eliminado', 'deletion')
      redirect_to admin_users_path, notice: "Usuario #{user_name} eliminado exitosamente."
      
    rescue ActiveRecord::RecordNotDestroyed => e
      redirect_to admin_users_path, alert: "Error al eliminar usuario: #{e.message}"
    rescue => e
      redirect_to admin_users_path, alert: "Error inesperado: #{e.message}"
    end
  end

  def cambiar_estado
    nuevo_estado = params[:estado]
    old_status = @user.estado
    
    if nuevo_estado.blank?
      redirect_to admin_users_path, alert: 'Estado no especificado.'
      return
    end
    
    unless ['activo', 'inabilitado'].include?(nuevo_estado)
      redirect_to admin_users_path, alert: "Estado '#{nuevo_estado}' no válido para esta acción."
      return
    end
    
    validation_errors = validate_user_status_change(@user, nuevo_estado)
    
    if validation_errors.any?
      redirect_to admin_users_path, alert: validation_errors.join(', ')
      return
    end
    
    if @user.update(estado: nuevo_estado, suspension_until: nil, updated_by: current_user)
      refresh_cache_after_user_status_change(@user.id)
      log_user_status_change(@user, old_status, nuevo_estado)
      
      action_type = nuevo_estado == 'activo' ? 'activate' : 'disable'
      message = user_action_message(action_type, @user)
      
      redirect_to admin_users_path, notice: message
    else
      redirect_to admin_users_path, 
                 alert: "Error al cambiar estado del usuario: #{@user.errors.full_messages.join(', ')}"
    end
  end

  def suspender_temporalmente
    horas_suspension = params[:horas_suspension].to_i
    old_status = @user.estado
    
    validation_errors = validate_suspension(@user, horas_suspension)
    
    if validation_errors.any?
      redirect_to admin_users_path, alert: validation_errors.join(', ')
      return
    end
    
    if @user.update(
      estado: 'suspendido',
      suspension_until: horas_suspension.hours.from_now,
      updated_by: current_user
    )
      refresh_cache_after_user_status_change(@user.id)
      log_user_status_change(@user, old_status, 'suspendido', 'suspension')
      redirect_to admin_users_path, 
                 notice: user_action_message('suspend', @user, true, "por #{horas_suspension} horas")
    else
      redirect_to admin_users_path, alert: "Error al suspender usuario."
    end
  end

  def reactivar
    old_status = @user.estado
    
    if @user.update(estado: 'activo', suspension_until: nil, updated_by: current_user)
      refresh_cache_after_user_status_change(@user.id)
      log_user_status_change(@user, old_status, 'activo', 'reactivation')
      redirect_to admin_users_path, notice: user_action_message('activate', @user)
    else
      redirect_to admin_users_path, alert: "Error al reactivar usuario."
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    handle_user_not_found
  end

  def user_params
    params.require(:user).permit(:nombre, :apellido, :email, :descripcion, :telefono, 
                                 :facultad, :dni, :cantidad_miembros_equipo, :nombre_proyectos, 
                                 :proviene, :occupation_id)
  end

  def user_params_for_update
    params.require(:user).permit(:nombre, :apellido, :email, :descripcion, :telefono, 
                                 :facultad, :dni, :cantidad_miembros_equipo, :nombre_proyectos, 
                                 :proviene, :occupation_id, :estado)
  end

  def generate_temporary_password
    "12345678"  # Contraseña fija para testing
    # SecureRandom.alphanumeric(8)  # Usar esta línea en producción
  end

  def validate_user_status_change(user, nuevo_estado)
    errors = []
    
    case nuevo_estado
    when 'activo'
      # Cualquier usuario puede ser activado
    when 'inabilitado'
      admin_count = User.joins(:roles).where(roles: { nombre: 'Administrador' }).count
      
      if user.es_admin? && admin_count <= 1
        errors << "No se puede inhabilitar al único administrador del sistema"
      end
      
      if user == current_user
        errors << "No puedes inhabilitarte a ti mismo"
      end
    when 'suspendido'
      errors << "Use la opción de suspensión temporal para suspender usuarios"
    else
      errors << "Estado '#{nuevo_estado}' no es válido. Estados permitidos: activo, inabilitado"
    end
    
    errors
  end

  def validate_suspension(user, horas_suspension)
    errors = []
    
    if horas_suspension.nil? || horas_suspension <= 0
      errors << "Las horas de suspensión deben ser un número positivo"
    elsif horas_suspension > 8760
      errors << "La suspensión no puede exceder 8760 horas (1 año)"
    end
    
    if user.es_admin? && User.joins(:roles).where(roles: { nombre: 'Administrador' }).count <= 1
      errors << "No se puede suspender al único administrador del sistema"
    end
    
    if user == current_user
      errors << "No puedes suspenderte a ti mismo"
    end
    
    errors
  end

  def refresh_cache_after_user_status_change(user_id)
    Rails.cache.delete("user_roles_#{user_id}")
    Rails.logger.info "🔄 Caché limpiado después de cambio de estado para usuario #{user_id}"
  end

  def log_user_status_change(user, old_status, new_status, action_type = 'status_change')
    Rails.logger.info "📝 #{action_type.upcase}: Usuario #{user.email} - #{old_status} → #{new_status} por #{current_user.email}"
    Rails.logger.info "📅 Última actividad del usuario: #{user.ultimo_acceso&.strftime('%d/%m/%Y %H:%M:%S') || 'Nunca'}"
  end

  def user_action_message(action, user, temporal = false, extra_info = "")
    user_name = user.nombre_completo
    
    case action
    when 'create'
      "Usuario #{user_name} creado exitosamente."
    when 'update'
      "Usuario #{user_name} actualizado exitosamente."
    when 'activate'
      "Usuario #{user_name} activado exitosamente."
    when 'disable'
      "Usuario #{user_name} inhabilitado exitosamente."
    when 'suspend'
      if temporal
        "Usuario #{user_name} suspendido temporalmente #{extra_info}."
      else
        "Usuario #{user_name} suspendido exitosamente."
      end
    else
      "Acción realizada exitosamente para #{user_name}."
    end
  end

  def handle_user_not_found
    redirect_to admin_users_path, alert: 'Usuario no encontrado.'
  end

  def ensure_can_manage_users
    unless current_user&.es_admin?
      redirect_to root_path, alert: 'No tienes permisos para gestionar usuarios.'
    end
  end
end