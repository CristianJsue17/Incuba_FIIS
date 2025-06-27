# config/initializers/roles_cache.rb
# Configuración para el caché de roles - SIN REDIS

Rails.application.configure do
  # Usar memory store que viene por defecto con Rails
  if Rails.env.development?
    # En development usar memory store con tamaño menor
    config.cache_store = :memory_store, { size: 32.megabytes }
  else
    # En production también usar memory store (más seguro sin dependencias)
    config.cache_store = :memory_store, { size: 64.megabytes }
  end
end

# Configuración específica para roles cache
module RolesCacheConfig
  # Duración del caché por ambiente
  CACHE_DURATION = {
    development: 5.minutes,   # Corto en development para testing
    test: 1.minute,          # Muy corto en test
    production: 15.minutes   # Más largo en production
  }.freeze
  
  # Obtener duración según ambiente
  def self.duration
    CACHE_DURATION[Rails.env.to_sym] || 15.minutes
  end
  
  # Método para limpiar todo el caché de roles
  def self.clear_all!
    Rails.cache.delete_matched("user_roles_*")
    Rails.logger.info "🧹 [RolesCache] Todo el caché de roles eliminado"
  end
  
  # Método para obtener estadísticas básicas
  def self.stats
    {
      cache_duration: duration,
      environment: Rails.env,
      cache_store: Rails.cache.class.name,
      message: "Caché de roles configurado con #{Rails.cache.class.name}"
    }
  end
  
  # Método para verificar si el caché está funcionando
  def self.test_cache
    test_key = "roles_cache_test_#{Time.current.to_i}"
    test_value = "working"
    
    # Escribir
    Rails.cache.write(test_key, test_value, expires_in: 1.minute)
    
    # Leer
    result = Rails.cache.read(test_key)
    
    # Limpiar
    Rails.cache.delete(test_key)
    
    {
      cache_working: result == test_value,
      test_key: test_key,
      result: result
    }
  end
end

# Log de inicialización
Rails.logger.info "🚀 [RolesCache] Inicializado con #{Rails.cache.class.name}"
Rails.logger.info "⏱️ [RolesCache] Duración: #{RolesCacheConfig.duration}"
Rails.logger.info "✅ [RolesCache] Test: #{RolesCacheConfig.test_cache[:cache_working] ? 'OK' : 'FALLO'}"