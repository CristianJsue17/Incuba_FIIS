require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
  
  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true
  
  # Do not eager load code on boot.
  config.eager_load = false
  
  # Enable server timing
  config.server_timing = true
  
  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    
    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
    
    config.cache_store = :null_store
  end
  
  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local
  
  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  
  config.action_mailer.perform_caching = false
  
  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log
  
  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise
  
  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []
  
  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load
  
  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true
  
  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true
  
  # Suppress logger output for asset requests.
  config.assets.quiet = true
  
  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true
  
  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true
  
  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true
  
  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true
  
  # ========================================================================
  # 🔧 INTERRUPTOR PARA PÁGINAS DE ERROR - CAMBIA AQUÍ FÁCILMENTE
  # ========================================================================
  
  # 🟢 MODO DESARROLLO NORMAL (errores detallados con archivos y líneas)
  # Descomenta estas 2 líneas para desarrollo normal:
   config.consider_all_requests_local = true
   puts "📋 MODO: Errores detallados para desarrollo"
  
  # 🟡 MODO PRUEBA DE PÁGINAS DE ERROR PERSONALIZADAS
  # Descomenta estas 3 líneas para probar páginas de error:
  #config.consider_all_requests_local = false
  #config.action_dispatch.show_exceptions = true
  #puts "🎨 MODO: Páginas de error personalizadas activas"
  
  # ========================================================================
  # INSTRUCCIONES:
  # 1. Para desarrollo normal: comenta las líneas del "MODO PRUEBA" y 
  #    descomenta las del "MODO DESARROLLO NORMAL"
  # 2. Para probar errores: comenta las líneas del "MODO DESARROLLO NORMAL" y
  #    descomenta las del "MODO PRUEBA"
  # 3. Reinicia el servidor después de cada cambio: docker-compose restart web
  # ========================================================================
end