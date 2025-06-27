# lib/tasks/sql_injection_test.rake
# Tarea para probar SQL injection en Devise

namespace :security do
  desc "Ejecutar pruebas de SQL injection en el sistema de autenticación"
  task sql_injection_test: :environment do
    puts "🔒 INICIANDO PRUEBAS DE SEGURIDAD SQL INJECTION"
    puts "=" * 60
    
    # Incluir la clase desde el archivo separado
    require_relative '../security/sql_injection_tester'
    
    tester = SqlInjectionTester.new
    tester.run_all_tests
    
    puts "\n✅ Pruebas completadas. Revisa los resultados arriba."
  end
  
  desc "Iniciar monitoreo en tiempo real de SQL injection"
  task monitor_sql: :environment do
    require_relative '../security/sql_injection_tester'
    
    puts "🔍 INICIANDO MONITOREO DE SQL INJECTION..."
    puts "   Presiona Ctrl+C para detener"
    puts "   Ahora haz intentos de login en el navegador"
    puts "=" * 50
    
    SqlInjectionMonitor.start_monitoring
    
    # Mantener el proceso corriendo
    trap("INT") { puts "\n👋 Monitoreo detenido."; exit }
    sleep
  end
end