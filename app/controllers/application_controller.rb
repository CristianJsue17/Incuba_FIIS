class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  # AGREGAR ESTAS LÍNEAS PARA MANEJO DE IDIOMAS
  before_action :set_locale
  
  # Método para redirección después de login
  def after_sign_in_path_for(resource)
    return root_path unless resource.is_a?(User)
         
    case
    when resource.roles.exists?(nombre: 'Administrador')
      admin_dashboard_path
    when resource.roles.exists?(nombre: 'Participante')
      participante_dashboard_path
    when resource.roles.exists?(nombre: 'Mentor')
      mentor_dashboard_path
    else
      root_path
    end
  end

  # Métodos helper para verificación de roles
  helper_method :current_admin?, :current_participante?, :current_mentor?

  # AGREGAR MÉTODO PARA CAMBIAR IDIOMA
  def change_locale
    if I18n.available_locales.include?(params[:locale].to_sym)
      session[:locale] = params[:locale]
      I18n.locale = params[:locale]
    end
    redirect_back(fallback_location: root_path)
  end

  private

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

  def current_admin?
    current_user&.roles&.exists?(nombre: 'Administrador')
  end

  def current_participante?
    current_user&.roles&.exists?(nombre: 'Participante')
  end

  def current_mentor?
    current_user&.roles&.exists?(nombre: 'Mentor')
  end


  private
  
  # Personalizar mensajes de Devise
  def set_flash_message(key, kind, options = {})
    case "#{key}.#{kind}"
    when "notice.signed_in"
      flash[:notice] = "¡Bienvenido! Has iniciado sesión correctamente."
    when "notice.signed_out"
      flash[:notice] = "Has cerrado sesión correctamente."
    when "alert.invalid"
      flash[:alert] = "Email o contraseña incorrectos."
    else
      super
    end
  end
  
end

