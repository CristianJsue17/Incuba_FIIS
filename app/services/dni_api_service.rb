# app/services/dni_api_service.rb
class DniApiService < ApplicationService
  require 'net/http'
  require 'json'
  require 'uri'

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
      # Hacer la consulta a la API
      response = fetch_dni_data
      
      if response[:success]
        success_response(response[:data])
      else
        error_response(response[:message])
      end
    rescue => e
      Rails.logger.error "Error en DniApiService: #{e.message}"
      error_response('Error al consultar el DNI. Intenta nuevamente.')
    end
  end

  private

  def valid_dni_format?
    @dni.present? && @dni.match?(/^\d{8}$/)
  end

  def fetch_dni_data
    # API específica de apiperu.dev
    url = "https://apiperu.dev/api/dni"
    
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 10
    http.open_timeout = 5

    request = Net::HTTP::Post.new(uri)
    
    # Headers requeridos por la API
    request['Accept'] = 'application/json'
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{api_token}"

    # Body con el DNI
    request.body = { dni: @dni }.to_json

    response = http.request(request)

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
    else
      { success: false, message: 'Error en el servicio de consulta DNI' }
    end
  end

  def parse_api_response(data)
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

  def api_token
    # TODO: Reemplazar con tu token real de apiperu.dev
    '57616cfebabbe1007a3095d2fab80347909720d4491610199e5d2dad0d624830'
  end
end