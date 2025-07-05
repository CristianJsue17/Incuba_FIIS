# app/controllers/participante/base_controller.rb - ACTUALIZADO CON CACHÉ Y VERIFICACIÓN DE ESTADOS
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
      
      # Verificar si es problema de estado del usuario o de rol
      if current_user
        unless current_user.puede_acceder?
          case current_user.estado
          when 'inabilitado'
            redirect_to root_path, alert: "Tu cuenta ha sido inhabilitada. Contacta al administrador."
          when 'suspendido'
            if current_user.suspension_activa?
              tiempo_restante = current_user.tiempo_restante_suspension
              redirect_to root_path, alert: "Tu cuenta está suspendida temporalmente. Tiempo restante: #{tiempo_restante} horas."
            else
              # La suspensión expiró, reactivar automáticamente
              current_user.update(estado: 'activo', suspension_until: nil)
              refresh_user_roles_cache(current_user.id)
              # Verificar rol después de reactivar
              unless current_participante?
                redirect_to root_path, alert: "No tienes permisos para acceder a esta sección como participante."
              end
            end
          else
            redirect_to root_path, alert: "Tu cuenta no está activa. Contacta al administrador."
          end
        else
          redirect_to root_path, alert: "No tienes permisos para acceder a esta sección como participante."
        end
      else
        redirect_to new_user_session_path, alert: "Debes iniciar sesión para acceder."
      end
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
      Rails.logger.info "📊 Estado usuario: #{current_user.estado}" if current_user.respond_to?(:estado)
    end
  end
  
  # NUEVO: Helper para verificar permisos específicos con caché y estado
  def can_register_events?
    current_participante? && current_user&.puede_acceder?
  end
  
  def can_access_programs?
    current_participante? && current_user&.puede_acceder?
  end
  
  def can_view_profile?
    current_participante? && current_user&.puede_acceder?
  end
  
  def can_submit_projects?
    current_participante? && current_user&.puede_acceder?
  end
  
  def can_access_resources?
    current_participante? && current_user&.puede_acceder?
  end
  
  # NUEVO: Método para verificar si puede realizar acciones específicas
  def ensure_can_access_feature(feature_name)
    method_name = "can_#{feature_name}?"
    
    if respond_to?(method_name, true) && !send(method_name)
      Rails.logger.warn "🚫 Participante #{current_user&.email} intentó acceder a #{feature_name} sin permisos"
      redirect_to participante_dashboard_path, alert: "No tienes permisos para acceder a esta funcionalidad."
    end
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
      cache_stats: roles_cache_stats,
      permissions: {
        register_events: can_register_events?,
        access_programs: can_access_programs?,
        view_profile: can_view_profile?,
        submit_projects: can_submit_projects?,
        access_resources: can_access_resources?
      }
    }
  end
  
  # NUEVO: Método para manejar errores de acceso
  def handle_access_denied(reason = nil)
    case reason
    when :suspended
      redirect_to root_path, alert: "Tu cuenta está suspendida temporalmente."
    when :disabled
      redirect_to root_path, alert: "Tu cuenta ha sido inhabilitada. Contacta al administrador."
    when :no_role
      redirect_to root_path, alert: "No tienes el rol de participante asignado."
    else
      redirect_to root_path, alert: "No tienes permisos para acceder a esta sección."
    end
  end
  
  # NUEVO: Middleware para logging de acciones importantes
  def log_important_action(action_name, details = {})
    Rails.logger.info "🎯 Participante #{current_user.email} realizó: #{action_name}"
    Rails.logger.info "📋 Detalles: #{details}" if details.any?
  end
end