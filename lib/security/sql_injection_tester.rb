# lib/security/sql_injection_tester.rb
# Clase para testing de SQL injection

class SqlInjectionTester
  # Payloads para probar SQL injection
  PAYLOADS_EMAIL = [
    "admin@test.com' OR '1'='1",
    "admin@test.com' OR '1'='1' --",
    "admin@test.com' OR '1'='1' #",
    "admin@test.com' OR 1=1 --",
    "admin@test.com' UNION SELECT 1,2,3,4,5 --",
    "admin@test.com' UNION SELECT * FROM users --",
    "admin@test.com' AND (SELECT COUNT(*) FROM users) > 0 --",
    "admin@test.com'; DROP TABLE users; --",
    "admin@test.com'; INSERT INTO users (email) VALUES ('hacker@evil.com'); --",
    "' OR ''='"
  ].freeze

  PAYLOADS_PASSWORD = [
    "password' OR '1'='1",
    "password' OR '1'='1' --",
    "password' OR 1=1 #",
    "' OR ''='",
    "' OR password IS NULL --",
    "' OR LENGTH(password) > 0 --"
  ].freeze

  def initialize
    @results = []
    @start_time = Time.current
  end

  # Método principal
  def run_all_tests
    puts "🚀 Iniciando pruebas de SQL injection..."
    puts "📅 Fecha: #{@start_time.strftime('%d/%m/%Y %H:%M:%S')}"
    puts "🌐 Entorno: #{Rails.env}"
    puts "=" * 60

    # Verificar que hay usuarios para probar
    setup_test_data
    
    # Ejecutar pruebas
    test_email_injection
    test_password_injection
    test_combined_injection
    test_devise_queries
    
    # Generar reporte
    generate_final_report
  end

  private

  def setup_test_data
    puts "🔧 Configurando datos de prueba..."
    
    # Crear usuario de prueba si no existe
    test_user = User.find_or_create_by(email: "security.test@example.com") do |user|
      user.password = "SecurePassword123!"
      user.password_confirmation = "SecurePassword123!"
    end
    
    puts "✅ Usuario de prueba configurado: #{test_user.email}"
    puts ""
  end

  def test_email_injection
    puts "📧 PROBANDO INJECTION EN CAMPO EMAIL"
    puts "-" * 40
    
    PAYLOADS_EMAIL.each_with_index do |payload, index|
      print "  #{(index + 1).to_s.rjust(2)}. "
      print "#{payload[0..45]}#{'...' if payload.length > 45} "
      
      result = simulate_devise_login(payload, "password123")
      status = result[:success] ? "❌ VULNERABLE" : "✅ BLOQUEADO"
      puts status
      
      @results << {
        type: "email_injection",
        payload: payload,
        success: result[:success],
        sql_queries: result[:sql_queries],
        error: result[:error]
      }
    end
    puts ""
  end

  def test_password_injection
    puts "🔑 PROBANDO INJECTION EN CAMPO PASSWORD"
    puts "-" * 40
    
    PAYLOADS_PASSWORD.each_with_index do |payload, index|
      print "  #{(index + 1).to_s.rjust(2)}. "
      print "#{payload[0..35]}#{'...' if payload.length > 35} "
      
      result = simulate_devise_login("security.test@example.com", payload)
      status = result[:success] ? "❌ VULNERABLE" : "✅ BLOQUEADO"
      puts status
      
      @results << {
        type: "password_injection",
        payload: payload,
        success: result[:success],
        sql_queries: result[:sql_queries],
        error: result[:error]
      }
    end
    puts ""
  end

  def test_combined_injection
    puts "🎯 PROBANDO INJECTION COMBINADA"
    puts "-" * 40
    
    combinations = [
      ["admin@test.com' OR '1'='1' --", "password' OR '1'='1' --"],
      ["' OR 1=1 --", "' OR 1=1 --"],
      ["test@test.com'; DROP TABLE users; --", "password"]
    ]
    
    combinations.each_with_index do |combo, index|
      email_payload, password_payload = combo
      print "  #{index + 1}. COMBO: #{email_payload[0..20]}... + #{password_payload[0..15]}... "
      
      result = simulate_devise_login(email_payload, password_payload)
      status = result[:success] ? "❌ VULNERABLE" : "✅ BLOQUEADO"
      puts status
      
      @results << {
        type: "combined_injection",
        payload: "Email: #{email_payload} | Password: #{password_payload}",
        success: result[:success],
        sql_queries: result[:sql_queries],
        error: result[:error]
      }
    end
    puts ""
  end

  def test_devise_queries
    puts "🔍 ANALIZANDO QUERIES DE DEVISE"
    puts "-" * 40
    
    # Login válido
    puts "  1. Login válido..."
    valid_result = simulate_devise_login("security.test@example.com", "SecurePassword123!")
    
    # Login inválido
    puts "  2. Login inválido..."
    invalid_result = simulate_devise_login("security.test@example.com", "wrongpassword")
    
    # Login con injection
    puts "  3. Login con injection..."
    injection_result = simulate_devise_login("security.test@example.com' OR '1'='1' --", "password")
    
    puts "\n📊 ANÁLISIS DE QUERIES SQL:"
    puts "  - Login válido: #{valid_result[:sql_queries].size} queries"
    puts "  - Login inválido: #{invalid_result[:sql_queries].size} queries"
    puts "  - Login con injection: #{injection_result[:sql_queries].size} queries"
    
    if valid_result[:sql_queries].any?
      puts "\n🔍 EJEMPLO DE QUERY SEGURA DE DEVISE:"
      query = valid_result[:sql_queries].first
      puts "  SQL: #{query[:sql]}"
      puts "  Parámetros: #{query[:bindings]}"
    end
    puts ""
  end

  def simulate_devise_login(email, password)
    sql_queries = []
    
    # Capturar todas las queries SQL
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
      sql_queries << {
        sql: payload[:sql],
        bindings: payload[:bindings]&.map(&:value)
      }
    end
    
    begin
      # Simular el proceso interno de Devise
      user = User.find_for_database_authentication(email: email)
      
      if user
        # Validar password como lo hace Devise
        password_valid = user.valid_password?(password)
        
        {
          success: password_valid,
          user_found: true,
          sql_queries: sql_queries,
          error: nil
        }
      else
        {
          success: false,
          user_found: false,
          sql_queries: sql_queries,
          error: nil
        }
      end
      
    rescue => e
      {
        success: false,
        user_found: false,
        sql_queries: sql_queries,
        error: e.message
      }
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end
  end

  def generate_final_report
    puts "📋 REPORTE FINAL DE SEGURIDAD"
    puts "=" * 60
    
    total_tests = @results.size
    successful_attacks = @results.count { |r| r[:success] }
    blocked_attacks = total_tests - successful_attacks
    
    # Estadísticas generales
    puts "📊 ESTADÍSTICAS:"
    puts "  ✅ Total de pruebas: #{total_tests}"
    puts "  ❌ Ataques exitosos: #{successful_attacks}"
    puts "  🛡️  Ataques bloqueados: #{blocked_attacks}"
    puts "  📈 Porcentaje de bloqueo: #{((blocked_attacks.to_f / total_tests) * 100).round(1)}%"
    
    # Nivel de seguridad
    security_level = case successful_attacks
                    when 0 then "🟢 EXCELENTE"
                    when 1..2 then "🟡 BUENO"
                    when 3..5 then "🟠 REGULAR"
                    else "🔴 CRÍTICO"
                    end
    
    puts "  🔒 Nivel de seguridad: #{security_level}"
    
    # Detalles de vulnerabilidades
    if successful_attacks > 0
      puts "\n⚠️  VULNERABILIDADES ENCONTRADAS:"
      @results.select { |r| r[:success] }.each_with_index do |vuln, index|
        puts "  #{index + 1}. Tipo: #{vuln[:type]}"
        puts "     Payload: #{vuln[:payload]}"
        if vuln[:error]
          puts "     Error: #{vuln[:error]}"
        end
        puts ""
      end
    else
      puts "\n🎉 ¡PERFECTO! Tu aplicación está protegida contra SQL injection."
    end
    
    # Explicación técnica
    puts "\n💡 PROTECCIONES DE RAILS/DEVISE:"
    puts "  ✅ Prepared statements (queries parametrizadas)"
    puts "  ✅ Escape automático de caracteres especiales"
    puts "  ✅ ActiveRecord ORM previene SQL crudo"
    puts "  ✅ Validación de tipos de datos"
    puts "  ✅ No concatenación directa de strings en SQL"
    
    # Tiempo de ejecución
    duration = Time.current - @start_time
    puts "\n⏱️  Pruebas completadas en #{duration.round(2)} segundos"
    puts "=" * 60
  end
end

# Clase para monitoreo en tiempo real
class SqlInjectionMonitor
  def self.start_monitoring
    suspicious_patterns = [
      /OR\s+['"]?1['"]?\s*=\s*['"]?1['"]?/i,
      /UNION\s+SELECT/i,
      /DROP\s+TABLE/i,
      /INSERT\s+INTO/i,
      /DELETE\s+FROM/i,
      /--/,
      /#/,
      /;\s*$/
    ]
    
    ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
      sql = payload[:sql]
      
      suspicious_patterns.each do |pattern|
        if sql.match?(pattern)
          puts "🚨 POSIBLE SQL INJECTION DETECTADA:"
          puts "   📅 #{Time.current.strftime('%H:%M:%S')}"
          puts "   🔍 SQL: #{sql}"
          puts "   📊 Parámetros: #{payload[:bindings]&.map(&:value)}"
          puts "   ⚠️  Patrón: #{pattern}"
          puts "   " + "-" * 50
        end
      end
    end
    
    puts "✅ Monitoreo activo. Presiona Ctrl+C para detener."
  end
end