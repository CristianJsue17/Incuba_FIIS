# app/controllers/participante/base_controller.rb - NUEVO CON CACHÉ
class Participante::BaseController < ApplicationController
  layout 'participante'
  before_action :authenticate_user!
  before_action :authorize_participante!
  
  # NUEVO: Log de acceso para debugging (opcional)
  after_action :log_participante_access, if: -> { Rails.env.development? }
  
  private
  
  def authorize_participante!
    # Usar el método con caché del ApplicationController
    unless current_participante?
      # Limpiar caché si hay problema de autorización
      clear_current_user_roles_cache if current_user
      
      redirect_to root_path,
        alert: "No tienes permisos para acceder a esta sección"
    end
  end
  
  # NUEVO: Método para refrescar caché después de cambios de roles
  def refresh_roles_after_change(user_id)
    refresh_user_roles_cache(user_id)
    Rails.logger.info "✅ Caché de roles actualizado para participante #{user_id}"
  end
  
  # NUEVO: Log de acceso para debugging
  def log_participante_access
    if current_user
      Rails.logger.info "🎓 Participante access: #{current_user.email} → #{controller_name}##{action_name}"
      Rails.logger.info "🔑 Roles cacheados: #{user_roles_cached}" if respond_to?(:user_roles_cached)
    end
  end
  
  # NUEVO: Helper para verificar permisos específicos con caché
  def can_register_events?
    current_participante? # Ya usa caché
  end
  
  def can_access_programs?
    current_participante? # Ya usa caché
  end
  
  def can_view_profile?
    current_participante? # Ya usa caché
  end
  
  # NUEVO: Método para estadísticas del caché (útil para debugging)
  def cache_debug_info
    return unless Rails.env.development?
    
    {
      controller: "#{controller_name}##{action_name}",
      user: current_user&.email,
      roles_cached: user_roles_cached,
      cache_stats: roles_cache_stats
    }
  end
end