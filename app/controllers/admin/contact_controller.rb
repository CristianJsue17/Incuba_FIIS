# app/controllers/admin/contact_controller.rb
class Admin::ContactController < Admin::BaseController
  before_action :set_formulario_contacto, only: [:show, :destroy]
  
  def index
    @formularios_contacto = FormularioContacto.search(params[:search])
                                              .filter_by_priority(params[:prioridad])
                                              .filter_by_date_range(params[:fecha_inicio], params[:fecha_fin])
                                              .order(created_at: :desc)
                                              .page(params[:page])
                                              .per(15)
    
    respond_to do |format|
      format.html
      format.json { render json: { formularios: @formularios_contacto } }
      format.csv do
        @formularios = FormularioContacto.search(params[:search])
                                        .filter_by_priority(params[:prioridad])
                                        .filter_by_date_range(params[:fecha_inicio], params[:fecha_fin])
                                        .order(created_at: :desc)
        send_data generate_csv(@formularios), 
                  filename: "mensajes_contacto_#{Date.current.strftime('%Y%m%d')}.csv",
                  type: 'text/csv'
      end
      format.xlsx do
        @formularios = FormularioContacto.search(params[:search])
                                        .filter_by_priority(params[:prioridad])
                                        .filter_by_date_range(params[:fecha_inicio], params[:fecha_fin])
                                        .order(created_at: :desc)
        send_data generate_excel(@formularios), 
                  filename: "mensajes_contacto_#{Date.current.strftime('%Y%m%d')}.xlsx",
                  type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render partial: 'show_modal', locals: { formulario: @formulario_contacto } }
      format.json { render json: @formulario_contacto }
    end
  end

  def destroy
    begin
      @formulario_contacto.destroy
      
      respond_to do |format|
        format.html do
          redirect_to admin_contact_index_path, 
                      notice: "Mensaje eliminado exitosamente."
        end
        format.json { render json: { success: true, message: "Mensaje eliminado" } }
      end
    rescue => e
      Rails.logger.error "Error al eliminar mensaje de contacto: #{e.message}"
      
      respond_to do |format|
        format.html do
          redirect_to admin_contact_index_path, 
                      alert: "Error al eliminar el mensaje."
        end
        format.json { render json: { success: false, error: e.message } }
      end
    end
  end

  # Estadísticas para el dashboard
  def stats
    stats_data = {
      total: FormularioContacto.count,
      esta_semana: FormularioContacto.where(created_at: 1.week.ago..Time.current).count,
      este_mes: FormularioContacto.where(created_at: 1.month.ago..Time.current).count,
      prioridad_alta: FormularioContacto.where(
        FormularioContacto.arel_table[:asunto].lower.matches('%urgente%')
        .or(FormularioContacto.arel_table[:asunto].lower.matches('%inmediato%'))
        .or(FormularioContacto.arel_table[:asunto].lower.matches('%problema%'))
        .or(FormularioContacto.arel_table[:asunto].lower.matches('%error%'))
        .or(FormularioContacto.arel_table[:asunto].lower.matches('%ayuda%'))
        .or(FormularioContacto.arel_table[:mensaje].lower.matches('%urgente%'))
        .or(FormularioContacto.arel_table[:mensaje].lower.matches('%inmediato%'))
        .or(FormularioContacto.arel_table[:mensaje].lower.matches('%problema%'))
        .or(FormularioContacto.arel_table[:mensaje].lower.matches('%error%'))
        .or(FormularioContacto.arel_table[:mensaje].lower.matches('%ayuda%'))
      ).count,
      mensajes_por_mes: FormularioContacto.group_by_month(:created_at, last: 6).count
    }

    render json: stats_data
  end

  private

  def set_formulario_contacto
    @formulario_contacto = FormularioContacto.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html do
        redirect_to admin_contact_index_path, 
                    alert: "Mensaje no encontrado."
      end
      format.json { render json: { error: "Mensaje no encontrado" }, status: :not_found }
    end
  end

  def generate_csv(formularios)
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      csv << [
        'ID', 'Nombre', 'Correo', 'Asunto', 'Mensaje', 'Prioridad', 'Fecha de Envío'
      ]
      
      formularios.each do |formulario|
        csv << [
          formulario.id,
          formulario.nombre,
          formulario.correo,
          formulario.asunto,
          formulario.mensaje,
          formulario.prioridad,
          formulario.created_at.strftime('%d/%m/%Y %H:%M')
        ]
      end
    end
  end

  def generate_excel(formularios)
    require 'caxlsx'
    
    package = Axlsx::Package.new
    workbook = package.workbook
    
    workbook.add_worksheet(name: "Mensajes de Contacto") do |sheet|
      # Estilos
      header_style = sheet.styles.add_style(
        bg_color: "3366CC",
        fg_color: "FFFFFF",
        b: true,
        alignment: { horizontal: :center }
      )
      
      priority_high_style = sheet.styles.add_style(
        bg_color: "FEE2E2",
        fg_color: "DC2626",
        alignment: { horizontal: :center }
      )
      
      priority_normal_style = sheet.styles.add_style(
        bg_color: "F3F4F6",
        fg_color: "6B7280",
        alignment: { horizontal: :center }
      )
      
      # Encabezados
      sheet.add_row [
        'ID', 'Nombre', 'Correo', 'Asunto', 'Mensaje', 'Prioridad', 'Fecha de Envío'
      ], style: header_style
      
      # Datos
      formularios.each do |formulario|
        priority_style = formulario.prioridad == 'alta' ? priority_high_style : priority_normal_style
        
        sheet.add_row [
          formulario.id,
          formulario.nombre,
          formulario.correo,
          formulario.asunto,
          formulario.mensaje,
          formulario.prioridad.capitalize,
          formulario.created_at.strftime('%d/%m/%Y %H:%M')
        ], style: [nil, nil, nil, nil, nil, priority_style, nil]
      end
      
      # Ajustar ancho de columnas
      sheet.column_widths 8, 20, 25, 25, 40, 12, 18
    end
    
    package.to_stream.read
  end
end