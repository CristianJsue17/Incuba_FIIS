# app/controllers/admin/base_controller.rb - ACTUALIZADO CON GESTIÓN DE ESTADOS
class Admin::BaseController < ApplicationController
  layout 'admin'
  before_action :authenticate_user!
  before_action :authorize_admin!
  
  # NUEVO: Log de acceso para debugging (opcional)
  after_action :log_admin_access, if: -> { Rails.env.development? }
  
  private
  
  def authorize_admin!
    # Usar el método con caché del ApplicationController
    unless current_admin?
      # Limpiar caché si hay problema de autorización
      clear_current_user_roles_cache if current_user
      
      redirect_to root_path,
        alert: "No tienes permisos para acceder a esta sección"
    end
  end
  
  # NUEVO: Método para refrescar caché después de cambios de roles
  def refresh_roles_after_change(user_id)
    refresh_user_roles_cache(user_id)
    Rails.logger.info "✅ Caché de roles actualizado para usuario #{user_id}"
  end
  
  # NUEVO: Método específico para refrescar caché después de cambios de estado
  def refresh_cache_after_user_status_change(user_id)
    clear_user_roles_cache(user_id)
    Rails.logger.info "🔄 Caché limpiado después de cambio de estado para usuario #{user_id}"
  end
  
  # NUEVO: Log de acceso para debugging
  def log_admin_access
    if current_user
      Rails.logger.info "👤 Admin access: #{current_user.email} → #{controller_name}##{action_name}"
      Rails.logger.info "🔑 Roles cacheados: #{user_roles_cached}" if respond_to?(:user_roles_cached)
    end
  end
  
  # NUEVO: Helper para verificar permisos específicos con caché
  def can_manage_users?
    current_admin? # Ya usa caché y verifica estado
  end
  
  def can_manage_events?
    current_admin? # Ya usa caché y verifica estado
  end
  
  def can_manage_programs?
    current_admin? # Ya usa caché y verifica estado
  end
  
  # NUEVO: Métodos de autorización granular para gestión de usuarios
  def ensure_can_manage_users
    unless can_manage_users?
      redirect_to admin_dashboard_path, alert: 'No tienes permisos para gestionar usuarios.'
    end
  end
  
  def ensure_can_change_user_status
    unless can_manage_users?
      redirect_to admin_dashboard_path, alert: 'No tienes permisos para cambiar estados de usuarios.'
    end
  end
  
  # NUEVO: Método para manejar errores de usuarios no encontrados
  def handle_user_not_found
    redirect_to admin_users_path, alert: 'Usuario no encontrado.'
  end
  
  # NUEVO: Método para validar cambios de estado de usuario
  def validate_user_status_change(user, new_status)
    errors = []
    
    case new_status
    when 'activo'
      # Cualquier usuario puede ser activado
    when 'suspendido'
      if user.es_admin? && User.where("roles.nombre = 'Administrador'").joins(:roles).count <= 1
        errors << "No se puede suspender al único administrador del sistema"
      end
    when 'inabilitado'
      if user.es_admin? && User.where("roles.nombre = 'Administrador'").joins(:roles).count <= 1
        errors << "No se puede inhabilitar al único administrador del sistema"
      end
      if user == current_user
        errors << "No puedes inhabilitarte a ti mismo"
      end
    else
      errors << "Estado no válido"
    end
    
    errors
  end
  
  # NUEVO: Método para validar suspensión temporal
  def validate_suspension(user, hours)
    errors = []
    
    if hours.nil? || hours <= 0
      errors << "Debe especificar un número válido de horas"
    elsif hours > 8760 # 1 año
      errors << "No se puede suspender por más de 8760 horas (1 año)"
    end
    
    if user.es_admin? && User.where("roles.nombre = 'Administrador'").joins(:roles).count <= 1
      errors << "No se puede suspender al único administrador del sistema"
    end
    
    if user == current_user
      errors << "No puedes suspenderte a ti mismo"
    end
    
    errors
  end
  
  # NUEVO: Método para registrar cambios de estado (auditoría)
  def log_user_status_change(user, old_status, new_status, action_type = 'manual')
    Rails.logger.info "📝 AUDITORÍA: Usuario #{user.email} cambió de '#{old_status}' a '#{new_status}'"
    Rails.logger.info "   👤 Realizado por: #{current_user.email}"
    Rails.logger.info "   🕐 Fecha: #{Time.current}"
    Rails.logger.info "   🔧 Tipo: #{action_type}"
    
    # Aquí podrías agregar registro en base de datos si necesitas auditoría persistente
    # UserStatusLog.create(
    #   user: user,
    #   changed_by: current_user,
    #   old_status: old_status,
    #   new_status: new_status,
    #   action_type: action_type
    # )
  end
  
  # NUEVO: Método para estadísticas del caché (útil para debugging)
  def cache_debug_info
    return unless Rails.env.development?
    
    {
      controller: "#{controller_name}##{action_name}",
      user: current_user&.email,
      user_status: current_user&.estado,
      can_access: current_user&.puede_acceder?,
      roles_cached: user_roles_cached,
      cache_stats: roles_cache_stats
    }
  end
  
  # NUEVO: Método helper para generar mensajes de éxito/error consistentes
  def user_action_message(action, user, success = true, additional_info = nil)
    base_message = case action
                   when 'create'
                     success ? "Usuario #{user.nombre_completo} creado exitosamente" : "Error al crear usuario"
                   when 'update'
                     success ? "Usuario #{user.nombre_completo} actualizado exitosamente" : "Error al actualizar usuario"
                   when 'activate'
                     success ? "Usuario #{user.nombre_completo} activado exitosamente" : "Error al activar usuario"
                   when 'suspend'
                     success ? "Usuario #{user.nombre_completo} suspendido exitosamente" : "Error al suspender usuario"
                   when 'disable'
                     success ? "Usuario #{user.nombre_completo} inhabilitado exitosamente" : "Error al inhabilitar usuario"
                   else
                     success ? "Acción realizada exitosamente" : "Error al realizar la acción"
                   end
    
    additional_info ? "#{base_message}. #{additional_info}" : base_message
  end
end