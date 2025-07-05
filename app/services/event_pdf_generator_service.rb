# app/services/event_pdf_generator_service.rb
# REEMPLAZA TODO EL ARCHIVO con esta versión:

require 'prawn'
require 'prawn/table'

class EventPdfGeneratorService
  include Prawn::View
  
  def initialize
    @document = Prawn::Document.new(
      page_size: 'A4',
      margin: [50, 50, 50, 50],
      info: {
        Title: "Reporte de Inscripciones - Evento",
        Author: "LINAS - Sistema de Gestión",
        Subject: "Inscripciones de Eventos",
        Creator: "Rails Application",
        Producer: "Prawn PDF Generator",
        CreationDate: Time.current
      }
    )
    font "Helvetica"
  end
  
  def generate_event_report(event, inscripciones)
    begin
      # Header simple
      font_size(20) do
        text "LINAS - Laboratorio de Innovación", align: :center, style: :bold
      end
      
      move_down 10
      
      font_size(16) do
        text "Reporte de Inscripciones - Evento", align: :center, style: :bold
      end
      
      move_down 5
      
      font_size(14) do
        text event.titulo, align: :center
      end
      
      move_down 20
      stroke_horizontal_rule
      move_down 20
      
      # Información del evento
      font_size(14) do
        text "Información del Evento", style: :bold
      end
      
      move_down 10
      
      info_data = [
        ["Título:", event.titulo],
        ["Encargado:", event.encargado],
        ["Estado:", event.estado.humanize],
        ["Total Inscripciones:", inscripciones.count.to_s],
        ["Fecha Creación:", event.created_at.strftime('%d/%m/%Y')]
      ]
      
      table(info_data, cell_style: { borders: [], padding: [4, 8] }) do
        columns(0).font_style = :bold
        columns(0).width = 120
      end
      
      move_down 20
      
      # Estadísticas
      stats = event.inscripciones_por_estado
      
      font_size(14) do
        text "Estadísticas", style: :bold
      end
      
      move_down 10
      
      stats_data = [
        ["Estado", "Cantidad"],
        ["Total", stats[:total].to_s],
        ["Pendientes", stats[:pendiente].to_s],
        ["Aprobadas", stats[:aprobado].to_s],
        ["Rechazadas", stats[:rechazado].to_s]
      ]
      
      table(stats_data, header: true, width: 300) do
        row(0).font_style = :bold
        row(0).background_color = 'E0E7FF'
        cells.padding = [6, 8]
      end
      
      move_down 20
      
      # Lista de inscripciones (si hay)
      if inscripciones.any?
        font_size(14) do
          text "Lista de Inscripciones (#{inscripciones.count})", style: :bold
        end
        
        move_down 10
        
        headers = ["#", "Nombre", "Email", "Estado", "Fecha"]
        table_data = [headers]
        
        inscripciones.each_with_index do |inscripcion, index|
          nombre = "#{inscripcion.nombre_lider} #{inscripcion.apellidos_lider}".strip
          row = [
            (index + 1).to_s,
            nombre,
            inscripcion.correo_lider || "N/A",
            inscripcion.estado&.humanize || "Pendiente",
            inscripcion.created_at.strftime("%d/%m/%Y")
          ]
          table_data << row
        end
        
        table(table_data, header: true, width: bounds.width) do
          row(0).font_style = :bold
          row(0).background_color = 'E0E7FF'
          cells.padding = [4, 6]
          cells.size = 10
        end
      else
        text "No hay inscripciones registradas para este evento.", style: :italic
      end
      
      # Footer
      move_down 30
      font_size(8) do
        text "Generado el #{Time.current.strftime('%d de %B del %Y a las %H:%M')}", 
             align: :center, style: :italic
      end
      
      @document.render
      
    rescue => e
      Rails.logger.error "Error en EventPdfGeneratorService: #{e.message}"
      raise e
    end
  end
  
def generate_all_events_report(events)
  begin
    # Header principal del reporte general
    font_size(22) do
      text "LINAS - Laboratorio de Innovación", align: :center, style: :bold
    end
    
    move_down 10
    
    font_size(18) do
      text "REPORTE GENERAL DE EVENTOS", align: :center, style: :bold
    end
    
    move_down 5
    
    font_size(12) do
      text "Todos los Eventos del Sistema", align: :center, style: :italic
    end
    
    move_down 20
    stroke_horizontal_rule
    move_down 20
    
    # Resumen general - CALCULADO DE FORMA SEGURA
    total_events = events.count
    total_inscripciones = 0
    eventos_activos = 0
    eventos_finalizados = 0
    
    # Calcular estadísticas de forma segura
    events.each do |event|
      begin
        if event.respond_to?(:inscripciones_por_estado)
          event_stats = event.inscripciones_por_estado
          total_inscripciones += event_stats[:total].to_i if event_stats[:total]
        end
        
        eventos_activos += 1 if event.estado == 'activo'
        eventos_finalizados += 1 if event.estado == 'finalizado'
      rescue => e
        Rails.logger.warn "Error calculando stats para evento #{event.id}: #{e.message}"
      end
    end
    
    font_size(16) do
      text "Resumen General", style: :bold
    end
    
    move_down 10
    
    # Tabla de resumen - ANCHO FIJO Y SEGURO
    resumen_data = [
      ["Métrica", "Valor"],
      ["Total de Eventos", total_events.to_s],
      ["Eventos Activos", eventos_activos.to_s],
      ["Eventos Finalizados", eventos_finalizados.to_s],
      ["Total de Inscripciones", total_inscripciones.to_s],
      ["Promedio por Evento", total_events > 0 ? (total_inscripciones.to_f / total_events).round(1).to_s : "0"],
      ["Fecha del Reporte", Time.current.strftime('%d/%m/%Y %H:%M')]
    ]
    
    # TABLA CON ANCHO ESPECÍFICO Y SEGURO
    table(resumen_data, width: 350, cell_style: { padding: [6, 8] }) do
      row(0).font_style = :bold
      row(0).background_color = 'E0E7FF'
      columns(0).width = 200
      columns(1).width = 150
    end
    
    move_down 25
    
    # Tabla de todos los eventos - SOLO SI HAY EVENTOS
    if events.any?
      font_size(16) do
        text "Lista de Eventos", style: :bold
      end
      
      move_down 10
      
      # TABLA SIMPLE DE EVENTOS
      eventos_headers = ["Evento", "Encargado", "Estado", "Inscripciones"]
      eventos_data = [eventos_headers]
      
      events.each do |event|
        begin
          # Obtener stats de forma segura
          inscripciones_count = 0
          if event.respond_to?(:inscripciones_por_estado)
            stats = event.inscripciones_por_estado
            inscripciones_count = stats[:total].to_i
          end
          
          row = [
            (event.titulo || "Sin título").to_s[0..30],  # Truncar titulo
            (event.encargado || "N/A").to_s[0..20],     # Truncar encargado
            (event.estado || "N/A").humanize,
            inscripciones_count.to_s
          ]
          eventos_data << row
        rescue => e
          Rails.logger.warn "Error procesando evento #{event.id}: #{e.message}"
          # Agregar fila con datos básicos
          row = [
            "Error al cargar",
            "N/A",
            "N/A",
            "0"
          ]
          eventos_data << row
        end
      end
      
      # TABLA CON ANCHO ESPECÍFICO
      table(eventos_data, width: 500, cell_style: { padding: [4, 6], size: 10 }) do
        row(0).font_style = :bold
        row(0).background_color = 'E0E7FF'
        
        # Anchos específicos para evitar errores
        columns(0).width = 200  # Evento
        columns(1).width = 150  # Encargado
        columns(2).width = 100  # Estado
        columns(3).width = 50   # Inscripciones
      end
      
      move_down 30
      
      # ===================================================================
      # NUEVA SECCIÓN: DETALLES INDIVIDUALES DE CADA EVENTO
      # ===================================================================
      
      font_size(18) do
        text "DETALLE POR EVENTO", style: :bold, align: :center
      end
      
      move_down 5
      stroke_horizontal_rule
      move_down 20
      
      events.each_with_index do |event, index|
        begin
          # Título del evento individual
          font_size(14) do
            text "#{index + 1}. #{event.titulo}", style: :bold
          end
          
          move_down 10
          
          # Información básica del evento
          info_data = [
            ["Encargado:", event.encargado || "N/A"],
            ["Estado:", (event.estado || "N/A").humanize],
            ["Fecha Creación:", event.created_at.strftime('%d/%m/%Y')],
            ["Última Actualización:", event.updated_at.strftime('%d/%m/%Y %H:%M')]
          ]
          
          # Agregar fechas de publicación y vencimiento si existen
          if event.fecha_publicacion.present?
            info_data << ["Fecha Publicación:", event.fecha_publicacion.strftime('%d/%m/%Y %H:%M')]
          end
          
          if event.fecha_vencimiento.present?
            info_data << ["Fecha Vencimiento:", event.fecha_vencimiento.strftime('%d/%m/%Y %H:%M')]
          end
          
          table(info_data, width: 400, cell_style: { borders: [], padding: [3, 6], size: 10 }) do
            columns(0).font_style = :bold
            columns(0).width = 150
            columns(1).width = 250
          end
          
          move_down 10
          
          # Estadísticas detalladas del evento
          if event.respond_to?(:inscripciones_por_estado)
            stats = event.inscripciones_por_estado
            
            font_size(12) do
              text "Estadísticas de Inscripciones:", style: :bold
            end
            
            move_down 5
            
            stats_data = [
              ["Estado", "Cantidad", "Porcentaje"],
              ["Total", stats[:total].to_s, "100%"],
              ["Pendientes", stats[:pendiente].to_s, stats[:total] > 0 ? "#{((stats[:pendiente].to_f / stats[:total]) * 100).round(1)}%" : "0%"],
              ["Aprobadas", stats[:aprobado].to_s, stats[:total] > 0 ? "#{((stats[:aprobado].to_f / stats[:total]) * 100).round(1)}%" : "0%"],
              ["Rechazadas", stats[:rechazado].to_s, stats[:total] > 0 ? "#{((stats[:rechazado].to_f / stats[:total]) * 100).round(1)}%" : "0%"]
            ]
            
            table(stats_data, width: 350, cell_style: { padding: [4, 6], size: 9 }) do
              row(0).font_style = :bold
              row(0).background_color = 'E0E7FF'
              
              columns(0).width = 100
              columns(1).width = 80
              columns(2).width = 170
              
              # Colorear filas según el estado
              row(2).background_color = 'FEF3C7' if stats[:pendiente] > 0  # amarillo claro para pendientes
              row(3).background_color = 'D1FAE5' if stats[:aprobado] > 0    # verde claro para aprobadas
              row(4).background_color = 'FEE2E2' if stats[:rechazado] > 0   # rojo claro para rechazadas
            end
            
            # Mostrar lista de inscripciones si hay pocas (máximo 5)
            if stats[:total] > 0 && stats[:total] <= 5
              move_down 10
              
              font_size(11) do
                text "Inscripciones registradas:", style: :bold
              end
              
              move_down 5
              
              inscripciones = event.todas_inscripciones.limit(5)
              
              inscripciones_headers = ["Nombre", "Email", "Estado", "Fecha"]
              inscripciones_data = [inscripciones_headers]
              
              inscripciones.each do |inscripcion|
                nombre = "#{inscripcion.nombre_lider} #{inscripcion.apellidos_lider}".strip
                row = [
                  nombre[0..25],  # Truncar nombre
                  (inscripcion.correo_lider || "N/A")[0..25],  # Truncar email
                  (inscripcion.estado || "Pendiente").humanize,
                  inscripcion.created_at.strftime("%d/%m/%Y")
                ]
                inscripciones_data << row
              end
              
              table(inscripciones_data, width: 500, cell_style: { padding: [3, 5], size: 8 }) do
                row(0).font_style = :bold
                row(0).background_color = 'F3F4F6'
                
                columns(0).width = 150  # Nombre
                columns(1).width = 150  # Email
                columns(2).width = 100  # Estado
                columns(3).width = 100  # Fecha
              end
              
            elsif stats[:total] > 5
              move_down 5
              font_size(9) do
                text "Este evento tiene #{stats[:total]} inscripciones. Ver reporte individual para más detalles.", style: :italic
              end
            end
            
          else
            font_size(10) do
              text "No se pudieron cargar las estadísticas de este evento.", style: :italic
            end
          end
          
          # Separador entre eventos (excepto el último)
          if index < events.count - 1
            move_down 20
            stroke do
              dash(3, space: 2)
              horizontal_rule
              undash
            end
            move_down 15
          end
          
        rescue => e
          Rails.logger.warn "Error procesando detalle del evento #{event.id}: #{e.message}"
          
          font_size(12) do
            text "Error al cargar los detalles de este evento.", style: :italic
          end
          
          move_down 15
        end
      end
      
    else
      font_size(14) do
        text "No hay eventos registrados en el sistema.", style: :italic, align: :center
      end
    end
    
    # Footer
    move_down 30
    font_size(8) do
      text "Reporte generado el #{Time.current.strftime('%d de %B del %Y a las %H:%M')} - Página #{page_number}",
           align: :center, style: :italic
    end
    
    @document.render
    
  rescue => e
    Rails.logger.error "Error en generate_all_events_report: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end
end