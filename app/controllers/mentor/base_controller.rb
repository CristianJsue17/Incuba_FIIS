# app/controllers/mentor/base_controller.rb - ACTUALIZADO CON CACHÉ Y VERIFICACIÓN DE ESTADOS
class Mentor::BaseController < ApplicationController
  layout 'mentor'
  before_action :authenticate_user!
  before_action :authorize_mentor!
  
  # NUEVO: Log de acceso para debugging (opcional)
  after_action :log_mentor_access, if: -> { Rails.env.development? }
  
  private
  
  def authorize_mentor!
    # Usar el método con caché del ApplicationController
    unless current_mentor?
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
              unless current_mentor?
                redirect_to root_path, alert: "No tienes permisos para acceder a esta sección como mentor."
              end
            end
          else
            redirect_to root_path, alert: "Tu cuenta no está activa. Contacta al administrador."
          end
        else
          redirect_to root_path, alert: "No tienes permisos para acceder a esta sección como mentor."
        end
      else
        redirect_to new_user_session_path, alert: "Debes iniciar sesión para acceder."
      end
    end
  end
  
  # NUEVO: Método para refrescar caché después de cambios de roles
  def refresh_roles_after_change(user_id)
    refresh_user_roles_cache(user_id)
    Rails.logger.info "✅ Caché de roles actualizado para mentor #{user_id}"
  end
  
  # NUEVO: Log de acceso para debugging
  def log_mentor_access
    if current_user
      Rails.logger.info "👨‍🏫 Mentor access: #{current_user.email} → #{controller_name}##{action_name}"
      Rails.logger.info "🔑 Roles cacheados: #{user_roles_cached}" if respond_to?(:user_roles_cached)
      Rails.logger.info "📊 Estado usuario: #{current_user.estado}" if current_user.respond_to?(:estado)
    end
  end
  
  # NUEVO: Helper para verificar permisos específicos con caché y estado
  def can_manage_mentoring?
    current_mentor? && current_user&.puede_acceder?
  end
  
  def can_view_participants?
    current_mentor? && current_user&.puede_acceder?
  end
  
  def can_review_projects?
    current_mentor? && current_user&.puede_acceder?
  end
  
  def can_create_content?
    current_mentor? && current_user&.puede_acceder?
  end
  
  def can_access_mentor_tools?
    current_mentor? && current_user&.puede_acceder?
  end
  
  def can_manage_sessions?
    current_mentor? && current_user&.puede_acceder?
  end
  
  # NUEVO: Método para verificar si puede realizar acciones específicas
  def ensure_can_access_feature(feature_name)
    method_name = "can_#{feature_name}?"
    
    if respond_to?(method_name, true) && !send(method_name)
      Rails.logger.warn "🚫 Mentor #{current_user&.email} intentó acceder a #{feature_name} sin permisos"
      redirect_to mentor_dashboard_path, alert: "No tienes permisos para acceder a esta funcionalidad."
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
        manage_mentoring: can_manage_mentoring?,
        view_participants: can_view_participants?,
        review_projects: can_review_projects?,
        create_content: can_create_content?,
        access_mentor_tools: can_access_mentor_tools?,
        manage_sessions: can_manage_sessions?
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
      redirect_to root_path, alert: "No tienes el rol de mentor asignado."
    else
      redirect_to root_path, alert: "No tienes permisos para acceder a esta sección."
    end
  end
  
  # NUEVO: Middleware para logging de acciones importantes
  def log_important_action(action_name, details = {})
    Rails.logger.info "🎯 Mentor #{current_user.email} realizó: #{action_name}"
    Rails.logger.info "📋 Detalles: #{details}" if details.any?
  end
  
  # NUEVO: Helper específico para mentores - verificar capacidad de mentoría
  def can_mentor_user?(participant_user)
    return false unless can_manage_mentoring?
    return false unless participant_user&.es_participante?
    return false unless participant_user&.puede_acceder?
    true
  end
  
  # NUEVO: Helper para verificar límites de mentoría (si aplica)
  def within_mentoring_limits?
    # Aquí puedes agregar lógica para limitar cuántos participantes puede mentorear
    # Por ejemplo: current_user.mentoring_assignments.active.count < MAX_MENTEES
    true
  end
  
  # NUEVO: Helper para obtener participantes asignados
  def assigned_participants
    # Retorna los participantes asignados a este mentor
    # Implementar según tu modelo de relación mentor-participante
    User.joins(:roles)
        .where(roles: { nombre: 'Participante' })
        .where(estado: 'activo')
    # .where(mentor_id: current_user.id) # Si tienes esta relación
  end
end