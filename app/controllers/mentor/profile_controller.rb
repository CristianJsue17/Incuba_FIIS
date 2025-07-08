# app/controllers/mentor/profile_controller.rb
class Mentor::ProfileController < Mentor::BaseController
  before_action :set_current_user_as_profile

  def show
    # El usuario ya está establecido en @user por el before_action
  end

  def update
    # Verificar si es un cambio de contraseña
    if params[:change_password] == 'true'
      handle_password_change
    else
      handle_profile_update
    end
  end

  def update_avatar
    if params[:user] && params[:user][:avatar]
      @user.updated_by = current_user
      
      if @user.update(avatar: params[:user][:avatar])
        redirect_to mentor_profile_path, 
                    notice: "Tu foto de perfil ha sido actualizada exitosamente."
      else
        redirect_to mentor_profile_path, 
                    alert: "Error al actualizar la foto de perfil: #{@user.errors.full_messages.join(', ')}"
      end
    else
      redirect_to mentor_profile_path, 
                  alert: "No se seleccionó ninguna imagen."
    end
  end

  # Eliminar avatar con soporte para AJAX
  def remove_avatar
    respond_to do |format|
      if @user.avatar.attached?
        @user.updated_by = current_user
        @user.avatar.purge
        
        # Respuesta HTML tradicional (fallback)
        format.html { 
          redirect_to mentor_profile_path, 
                      notice: "Tu foto de perfil ha sido eliminada exitosamente." 
        }
        
        # Respuesta JSON para AJAX
        format.json { 
          render json: { 
            status: 'success', 
            message: 'Tu foto de perfil ha sido eliminada exitosamente.',
            avatar_removed: true
          }, status: :ok
        }
      else
        # No hay avatar para eliminar
        format.html { 
          redirect_to mentor_profile_path, 
                      alert: "No hay foto de perfil para eliminar." 
        }
        
        format.json { 
          render json: { 
            status: 'error', 
            message: 'No hay foto de perfil para eliminar.' 
          }, status: :unprocessable_entity
        }
      end
    end
  end

  private

  def set_current_user_as_profile
    # Solo permitir que los mentores vean/editen SU PROPIO perfil
    @user = current_user
    
    # Verificación adicional de seguridad
    unless @user&.es_mentor?
      redirect_to root_path, 
                  alert: 'No tienes permisos para acceder a esta sección.'
    end
  end

  def handle_profile_update
    # Actualizar información del perfil (sin contraseña)
    @user.updated_by = current_user
    
    if @user.update(profile_params)
      # Refrescar caché de roles después de actualización
      refresh_cache_after_user_status_change(@user.id) if @user.saved_changes.key?('estado')
      
      redirect_to mentor_profile_path, 
                  notice: "Tu perfil ha sido actualizado exitosamente."
    else
      # Si hay errores, volver a mostrar la vista con los errores
      render :show, status: :unprocessable_entity
    end
  end

  def handle_password_change
    Rails.logger.info "🔍 DEBUG: handle_password_change iniciado para mentor"
    Rails.logger.info "🔍 DEBUG: Request format: #{request.format}"
    Rails.logger.info "🔍 DEBUG: Accept header: #{request.headers['Accept']}"
    
    # FORZAR formato JSON si el Accept header lo solicita
    request.format = :json if request.headers['Accept']&.include?('application/json')
    
    Rails.logger.info "🔍 DEBUG: Formato después de ajuste: #{request.format}"
    
    current_password = params[:current_password]
    new_password = params[:user][:password]
    password_confirmation = params[:user][:password_confirmation]
    
    # Validar contraseña actual
    unless @user.valid_password?(current_password)
      Rails.logger.info "❌ DEBUG: Contraseña actual incorrecta"
      
      if request.format.json?
        Rails.logger.info "🔍 DEBUG: Respondiendo con JSON (contraseña incorrecta)"
        render json: {
          status: 'error',
          errors: {
            current_password: ['La contraseña actual no es correcta']
          }
        }, status: :unprocessable_entity
      else
        Rails.logger.info "🔍 DEBUG: Respondiendo con HTML (contraseña incorrecta)"
        @user.errors.add(:current_password, 'La contraseña actual no es correcta')
        render :show, status: :unprocessable_entity
      end
      return
    end

    # Validaciones de seguridad
    errors = {}

    # Validar que la nueva contraseña no esté vacía
    if new_password.blank?
      errors[:password] = ['La nueva contraseña no puede estar vacía']
    else
      # Validar longitud mínima
      if new_password.length < 8
        errors[:password] = ['La nueva contraseña debe tener al menos 8 caracteres']
      end
      
      # Validar que la nueva contraseña sea diferente a la actual
      if @user.valid_password?(new_password)
        errors[:password] = ['La nueva contraseña debe ser diferente a la contraseña actual']
      end
      
      # Validar que no sea igual al email (seguridad básica)
      if new_password.downcase == @user.email.downcase
        errors[:password] = ['La contraseña no puede ser igual a tu email']
      end
      
      # Validar que no sea muy simple
      simple_passwords = ['password', 'qwerty123', 'abc12345']
      if simple_passwords.include?(new_password.downcase)
        errors[:password] = ['La contraseña es demasiado simple. Usa una contraseña más segura']
      end
    end

    # Validar confirmación de contraseña
    if password_confirmation.blank?
      errors[:password_confirmation] = ['La confirmación de contraseña es requerida']
    elsif new_password != password_confirmation
      errors[:password_confirmation] = ['La confirmación de contraseña no coincide']
    end

    if errors.any?
      Rails.logger.info "❌ DEBUG: Errores de validación: #{errors}"
      
      if request.format.json?
        Rails.logger.info "🔍 DEBUG: Respondiendo con JSON (errores validación)"
        render json: {
          status: 'error',
          errors: errors
        }, status: :unprocessable_entity
      else
        Rails.logger.info "🔍 DEBUG: Respondiendo con HTML (errores validación)"
        errors.each do |field, messages|
          messages.each { |message| @user.errors.add(field, message) }
        end
        render :show, status: :unprocessable_entity
      end
      return
    end

    # Actualizar contraseña
    @user.updated_by = current_user
    
    if @user.update(password: new_password, password_confirmation: password_confirmation)
      Rails.logger.info "✅ DEBUG: Contraseña actualizada exitosamente para mentor"
      
      bypass_sign_in(@user)
      log_password_change
      
      if request.format.json?
        Rails.logger.info "🔍 DEBUG: Respondiendo con JSON (éxito)"
        render json: {
          status: 'success',
          message: 'Tu contraseña ha sido actualizada exitosamente. Tu sesión se mantiene activa.'
        }, status: :ok
      else
        Rails.logger.info "🔍 DEBUG: Respondiendo con HTML (éxito)"
        redirect_to mentor_profile_path, 
                    notice: "Tu contraseña ha sido actualizada exitosamente."
      end
    else
      Rails.logger.error "❌ DEBUG: Error al actualizar contraseña: #{@user.errors.full_messages}"
      
      if request.format.json?
        Rails.logger.info "🔍 DEBUG: Respondiendo con JSON (error actualización)"
        render json: {
          status: 'error',
          errors: @user.errors.messages
        }, status: :unprocessable_entity
      else
        Rails.logger.info "🔍 DEBUG: Respondiendo con HTML (error actualización)"
        render :show, status: :unprocessable_entity
      end
    end
  rescue => e
    Rails.logger.error "🚨 DEBUG: Excepción capturada: #{e.class} - #{e.message}"
    Rails.logger.error "🚨 DEBUG: Backtrace: #{e.backtrace.first(3).join("\n")}"
    
    if request.format.json?
      render json: { 
        status: 'error', 
        errors: { general: ['Error interno del servidor'] }
      }, status: :internal_server_error
    else
      redirect_to mentor_profile_path, alert: "Error interno del servidor"
    end
  end

  def profile_params
    # IMPORTANTE: Excluir email para que no pueda ser modificado
    # Excluir también campos críticos como estado, roles, etc.
    # Excluir password para actualizaciones normales del perfil
    params.require(:user).permit(
      :nombre, 
      :apellido, 
      :descripcion, 
      :telefono, 
      :facultad, 
      :dni, 
      :cantidad_miembros_equipo, 
      :nombre_proyectos, 
      :proviene, 
      :occupation_id,
      :avatar
    )
  end

  # Método para auditoría de cambios de contraseña
  def log_password_change
    Rails.logger.info "🔐 CONTRASEÑA CAMBIADA (Mentor) - Usuario: #{@user.email}"
    Rails.logger.info "   Fecha: #{Time.current}"
    Rails.logger.info "   IP: #{request.remote_ip}" if request
    Rails.logger.info "   User Agent: #{request.user_agent}" if request
    Rails.logger.info "   Sesión mantenida: SÍ (bypass_sign_in usado)"
    
    # Aquí podrías agregar notificación por email sobre el cambio de contraseña
    # UserMailer.password_changed(@user).deliver_later
  end

  # Método para refrescar caché después de cambios
  def refresh_cache_after_user_status_change(user_id)
    clear_user_roles_cache(user_id)
    Rails.logger.info "🔄 Caché limpiado después de cambio de estado para mentor #{user_id}"
  end
end