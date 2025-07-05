class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  # ⚠️ SOLO AGREGAR ESTAS 2 LÍNEAS para solucionar CSRF:
  rescue_from ActionController::InvalidAuthenticityToken, with: :handle_invalid_csrf_token
  before_action :check_user_status, unless: :devise_controller?  # ← CAMBIO: agregar unless: :devise_controller?
  
  # AGREGAR ESTAS LÍNEAS PARA MANEJO DE IDIOMAS
  before_action :set_locale
  # before_action :check_user_status  # ← COMENTAR ESTA LÍNEA Y USAR LA DE ARRIBA
  
  # NUEVO: Configuración de caché para roles
  ROLE_CACHE_DURATION = 15.minutes # Duración del caché de roles
  
  # ⚠️ SOLO AGREGAR ESTE MÉTODO para manejar errores CSRF:
  def handle_invalid_csrf_token
    Rails.logger.error "🚫 CSRF Token inválido - Usuario: #{current_user&.email || 'guest'}"
    reset_session
    redirect_to new_user_session_path, alert: 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.'
  end
  
  # Método para redirección después de login - TU LÓGICA ORIGINAL SIN CAMBIOS
def after_sign_in_path_for(resource)
  return root_path unless resource.is_a?(User)
  
  # NUEVO: Verificar estado del usuario al hacer login
  unless resource.puede_acceder?
    # NO hacer redirect aquí, solo sign_out y retornar la URL de login
    sign_out resource
    
    # Establecer el mensaje flash para mostrar después del redirect
    case resource.estado
    when 'inabilitado'
      flash[:alert] = 'Su cuenta ha sido inhabilitada. Contacte al administrador.'
    when 'suspendido'
      if resource.suspension_activa?
        flash[:alert] = "Su cuenta está suspendida temporalmente. Tiempo restante: #{resource.tiempo_restante_suspension} horas."
      else
        flash[:alert] = 'Su cuenta estaba suspendida pero la suspensión ha expirado. Reintente el login.'
      end
    else
      flash[:alert] = 'Su cuenta no está activa. Contacte al administrador.'
    end
    
    return new_user_session_path  # ← RETORNAR LA URL, NO HACER REDIRECT
  end
  
  # Limpiar caché de roles al hacer login para asegurar datos frescos
  clear_user_roles_cache(resource.id)
  
  case
  when user_has_role?(resource, 'Administrador')
    admin_dashboard_path
  when user_has_role?(resource, 'Participante')
    participante_dashboard_path
  when user_has_role?(resource, 'Mentor')
    mentor_dashboard_path
  else
    root_path
  end
end
    

  
  # Métodos helper para verificación de roles CON CACHÉ
  helper_method :current_admin?, :current_participante?, :current_mentor?, :user_roles_cached
  
  # AGREGAR MÉTODO PARA CAMBIAR IDIOMA
  def change_locale
    if I18n.available_locales.include?(params[:locale].to_sym)
      session[:locale] = params[:locale]
      I18n.locale = params[:locale]
    end
    redirect_back(fallback_location: root_path)
  end
  
  private
  
  # NUEVO: Verificar estado del usuario en cada request - TU LÓGICA ORIGINAL SIN CAMBIOS
  def check_user_status
    return unless user_signed_in?
    
    if current_user.inabilitado?
      sign_out current_user
      redirect_to new_user_session_path, alert: 'Su cuenta ha sido inhabilitada. Contacte al administrador.'
      return
    elsif current_user.suspendido?
      if current_user.suspension_activa?
        sign_out current_user
        tiempo_restante = current_user.tiempo_restante_suspension
        redirect_to new_user_session_path, 
                   alert: "Su cuenta está suspendida temporalmente. Tiempo restante: #{tiempo_restante} horas."
        return
      else
        # La suspensión expiró, reactivar automáticamente
        current_user.update(estado: 'activo', suspension_until: nil)
        # Refrescar caché después del cambio
        refresh_user_roles_cache(current_user.id)
        Rails.logger.info "✅ Usuario #{current_user.email} reactivado automáticamente - suspensión expirada"
      end
    end
  end
  
  # AGREGAR MÉTODO PARA ESTABLECER IDIOMA
  def set_locale
    I18n.locale = extract_locale || I18n.default_locale
    session[:locale] = I18n.locale.to_s
  end
  
  def extract_locale
    # 1. Parámetro en URL
    parsed_locale = params[:locale]
    return parsed_locale if I18n.available_locales.map(&:to_s).include?(parsed_locale)
    
    # 2. Sesión guardada
    parsed_locale = session[:locale]
    return parsed_locale if I18n.available_locales.map(&:to_s).include?(parsed_locale)
    
    # 3. Idioma por defecto (español para Perú)
    'es'
  end
  
  # ===========================================
  # NUEVOS MÉTODOS PARA CACHÉ DE ROLES - TU LÓGICA ORIGINAL SIN CAMBIOS
  # ===========================================
  
  # Método principal para verificar roles con caché
  def user_has_role?(user, role_name)
    return false unless user
    return false unless user.puede_acceder? # ← NUEVA VERIFICACIÓN DE ESTADO
    
    cached_roles = get_user_roles_cached(user.id)
    cached_roles.include?(role_name)
  end
  
  # Obtener roles del usuario desde caché o base de datos
  def get_user_roles_cached(user_id)
    cache_key = "user_roles_#{user_id}"
    
    Rails.cache.fetch(cache_key, expires_in: ROLE_CACHE_DURATION) do
      user = User.find_by(id: user_id)
      if user && user.puede_acceder? # ← NUEVA VERIFICACIÓN DE ESTADO
        # Cargar roles y crear array de nombres
        roles_array = user.roles.pluck(:nombre)
        Rails.logger.info "🔄 Cargando roles desde BD para usuario #{user_id}: #{roles_array}"
        roles_array
      else
        []
      end
    end
  end
  
  # Limpiar caché de roles para un usuario específico
  def clear_user_roles_cache(user_id)
    cache_key = "user_roles_#{user_id}"
    Rails.cache.delete(cache_key)
    Rails.logger.info "🗑️ Caché de roles eliminado para usuario #{user_id}"
  end
  
  # Limpiar caché de roles para el usuario actual
  def clear_current_user_roles_cache
    clear_user_roles_cache(current_user.id) if current_user
  end
  
  # Métodos helper mejorados CON CACHÉ Y VERIFICACIÓN DE ESTADO
  def current_admin?
    return false unless current_user&.puede_acceder?
    user_has_role?(current_user, 'Administrador')
  end
  
  def current_participante?
    return false unless current_user&.puede_acceder?
    user_has_role?(current_user, 'Participante')
  end
  
  def current_mentor?
    return false unless current_user&.puede_acceder?
    user_has_role?(current_user, 'Mentor')
  end
  
  # Método helper para obtener todos los roles cacheados del usuario actual
  def user_roles_cached
    return [] unless current_user&.puede_acceder?
    get_user_roles_cached(current_user.id)
  end
  
  # Método para refrescar caché de roles (útil después de cambios de roles)
  def refresh_user_roles_cache(user_id = nil)
    user_id ||= current_user&.id
    return unless user_id
    
    clear_user_roles_cache(user_id)
    get_user_roles_cached(user_id) # Cargar inmediatamente la nueva data
  end
  
  # ===========================================
  # MÉTODOS PARA ADMINISTRAR CACHÉ DE ROLES
  # ===========================================
  
  # Método para limpiar TODO el caché de roles (útil en development)
  def self.clear_all_roles_cache
    Rails.cache.delete_matched("user_roles_*")
    Rails.logger.info "🧹 Todo el caché de roles ha sido eliminado"
  end
  
  # Método para obtener estadísticas del caché
  def roles_cache_stats
    return unless Rails.env.development? || current_admin?
    
    {
      cache_duration: ROLE_CACHE_DURATION,
      current_user_cached: current_user ? Rails.cache.exist?("user_roles_#{current_user.id}") : false,
      current_user_roles: current_user ? user_roles_cached : [],
      current_user_status: current_user&.estado,
      can_access: current_user&.puede_acceder?
    }
  end
  
  # Personalizar mensajes de Devise
  def set_flash_message(key, kind, options = {})
    case "#{key}.#{kind}"
    when "notice.signed_in"
      flash[:notice] = "¡Bienvenido! Has iniciado sesión correctamente."
    when "notice.signed_out"
      flash[:notice] = "Has cerrado sesión correctamente."
      # Limpiar caché al cerrar sesión
      clear_current_user_roles_cache if current_user
    when "alert.invalid"
      flash[:alert] = "Email o contraseña incorrectos."
    else
      super
    end
  end
  
  # NUEVO: Método para debugging (solo en development)
  def debug_roles_cache
    return unless Rails.env.development? && current_user
    
    Rails.logger.info "🐛 DEBUG - Roles Cache Info:"
    Rails.logger.info "   Usuario: #{current_user.email}"
    Rails.logger.info "   Estado: #{current_user.estado}"
    Rails.logger.info "   Puede acceder: #{current_user.puede_acceder?}"
    Rails.logger.info "   Cache key: user_roles_#{current_user.id}"
    Rails.logger.info "   Cache existe: #{Rails.cache.exist?("user_roles_#{current_user.id}")}"
    Rails.logger.info "   Roles cacheados: #{user_roles_cached}"
    Rails.logger.info "   Es admin: #{current_admin?}"
    Rails.logger.info "   Es participante: #{current_participante?}"
    Rails.logger.info "   Es mentor: #{current_mentor?}"
  end
end