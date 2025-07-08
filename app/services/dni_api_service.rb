# app/services/dni_api_service.rb
# REEMPLAZA TODO EL ARCHIVO con esta versión optimizada para AWS:

class DniApiService < ApplicationService
  require 'net/http'
  require 'json'
  require 'uri'
  require 'timeout'

  def self.consultar_dni(dni)
    new(dni).call
  end

  def initialize(dni)
    @dni = dni&.to_s&.strip
  end

  def call
    # Validar formato de DNI
    return error_response('DNI inválido') unless valid_dni_format?

    begin
      # Cache check - verificar si ya consultamos este DNI recientemente
      cached_result = check_cache
      return cached_result if cached_result

      # Hacer la consulta a la API con timeouts más largos
      response = fetch_dni_data
      
      if response[:success]
        # Guardar en cache por 24 horas
        save_to_cache(response[:data])
        success_response(response[:data])
      else
        error_response(response[:message])
      end
    rescue Net::TimeoutError => e
      Rails.logger.error "Timeout en DniApiService: #{e.message}"
      error_response('Tiempo de espera agotado. La consulta tomó demasiado tiempo.')
    rescue Net::OpenTimeout => e
      Rails.logger.error "OpenTimeout en DniApiService: #{e.message}"
      error_response('No se pudo conectar al servidor. Intenta nuevamente.')
    rescue Net::ReadTimeout => e
      Rails.logger.error "ReadTimeout en DniApiService: #{e.message}"
      error_response('Tiempo de lectura agotado. Intenta nuevamente.')
    rescue JSON::ParserError => e
      Rails.logger.error "Error JSON en DniApiService: #{e.message}"
      error_response('Error en la respuesta del servidor.')
    rescue => e
      Rails.logger.error "Error general en DniApiService: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      error_response('Error al consultar el DNI. Intenta nuevamente.')
    end
  end

  private

  def valid_dni_format?
    @dni.present? && @dni.match?(/^\d{8}$/)
  end

  def fetch_dni_data
    # Usar timeout total más largo para AWS
    Timeout::timeout(20) do
      # API específica de apiperu.dev
      url = "https://apiperu.dev/api/dni"
      
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      # TIMEOUTS MÁS LARGOS PARA AWS
      http.read_timeout = 15    # 15 SEGUNDOS para leer la respuesta
      http.open_timeout = 10    # 10 SEGUNDOS para establecer conexión
      http.write_timeout = 10   # 10 SEGUNDOS para enviar datos
      
      # Configuraciones adicionales para AWS
      http.keep_alive_timeout = 30 # 30 SEGUNDOS para mantener la conexión viva
      http.ssl_timeout = 10        # 10 SEGUNDOS para SSL  
      
      request = Net::HTTP::Post.new(uri)
      
      # Headers requeridos por la API
      request['Accept'] = 'application/json'
      request['Content-Type'] = 'application/json'
      request['Authorization'] = "Bearer #{api_token}"
      request['User-Agent'] = 'Rails-DNI-Service/1.0'
      
      # Body con el DNI
      request.body = { dni: @dni }.to_json
      
      Rails.logger.info "Consultando DNI #{@dni} a apiperu.dev..."
      start_time = Time.current
      
      response = http.request(request)
      
      elapsed_time = Time.current - start_time
      Rails.logger.info "Consulta DNI completada en #{elapsed_time.round(2)}s - Status: #{response.code}"
      
      case response.code
      when '200'
        data = JSON.parse(response.body)
        parse_api_response(data)
      when '401'
        { success: false, message: 'Token de API inválido o expirado' }
      when '404'
        { success: false, message: 'DNI no encontrado en los registros de RENIEC' }
      when '422'
        { success: false, message: 'DNI inválido o mal formateado' }
      when '429'
        { success: false, message: 'Límite de consultas excedido. Intenta más tarde.' }
      when '500', '502', '503', '504'
        { success: false, message: 'Servidor temporalmente no disponible. Intenta en unos minutos.' }
      else
        Rails.logger.warn "Código de respuesta inesperado: #{response.code} - #{response.body}"
        { success: false, message: 'Error en el servicio de consulta DNI' }
      end
    end
  end

  def parse_api_response(data)
    # Log para debug
    Rails.logger.info "Respuesta de API: #{data.inspect}"
    
    # Estructura específica de apiperu.dev según tu imagen
    if data['success'] == true
      persona_data = data['data']
      
      {
        success: true,
        data: {
          numero: persona_data['numero'],
          nombres: persona_data['nombres'],
          apellido_paterno: persona_data['apellido_paterno'],
          apellido_materno: persona_data['apellido_materno'],
          nombre_completo: persona_data['nombre_completo'],
          codigo_verificacion: persona_data['codigo_verificacion']
        }
      }
    else
      { success: false, message: data['message'] || 'DNI no encontrado' }
    end
  end

  def success_response(data)
    {
      success: true,
      nombres: data[:nombres],
      apellido_paterno: data[:apellido_paterno],
      apellido_materno: data[:apellido_materno],
      apellidos_completos: "#{data[:apellido_paterno]} #{data[:apellido_materno]}".strip,
      nombre_completo: data[:nombre_completo],
      numero: data[:numero],
      codigo_verificacion: data[:codigo_verificacion]
    }
  end

  def error_response(message)
    {
      success: false,
      error: message,
      nombres: '',
      apellido_paterno: '',
      apellido_materno: '',
      apellidos_completos: '',
      nombre_completo: ''
    }
  end

  # NUEVO: Sistema de caché simple
  def cache_key
    "dni_consulta_#{@dni}"
  end

  def check_cache
    cached_data = Rails.cache.read(cache_key)
    if cached_data
      Rails.logger.info "DNI #{@dni} encontrado en caché"
      return cached_data
    end
    nil
  end

  def save_to_cache(data)
    cache_data = success_response(data)
    Rails.cache.write(cache_key, cache_data, expires_in: 24.hours)
    Rails.logger.info "DNI #{@dni} guardado en caché"
  end

  def api_token
    # MEJORADO: Usar variable de entorno para seguridad
    ENV['APIPERU_TOKEN'] || '57616cfebabbe1007a3095d2fab80347909720d4491610199e5d2dad0d624830'
  end
end