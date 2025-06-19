# app/jobs/update_program_estados_job.rb
class UpdateProgramEstadosJob < ApplicationJob
  queue_as :default

  def perform
    now = Time.current
    Rails.logger.info "=== Iniciando actualización de estados: #{now} ==="

    begin
      # 1. PENDIENTE -> ACTIVO (cuando llega fecha_publicacion)
      pending_to_active = Program.where(estado: 'pendiente')
                               .where('fecha_publicacion <= ?', now)
      
      pending_count = pending_to_active.count
      if pending_count > 0
        pending_to_active.update_all(estado: 'activo')
        Rails.logger.info "✅ #{pending_count} programas: PENDIENTE -> ACTIVO"
      end

      # 2. ACTIVO -> FINALIZADO (cuando llega fecha_vencimiento)
      active_to_finalized = Program.where(estado: 'activo')
                                  .where('fecha_vencimiento <= ?', now)
      
      active_count = active_to_finalized.count
      if active_count > 0
        active_to_finalized.update_all(estado: 'finalizado')
        Rails.logger.info "✅ #{active_count} programas: ACTIVO -> FINALIZADO"
      end

      # 3. FINALIZADO -> INACTIVO (después de 12 horas)
      twelve_hours_ago = now - 12.hours
      finalized_to_inactive = Program.where(estado: 'finalizado')
                                   .where('fecha_vencimiento <= ?', twelve_hours_ago)
      
      finalized_count = finalized_to_inactive.count
      if finalized_count > 0
        finalized_to_inactive.update_all(estado: 'inactivo')
        Rails.logger.info "✅ #{finalized_count} programas: FINALIZADO -> INACTIVO"
      end

      Rails.logger.info "=== Actualización completada: #{Time.current} ==="
      
    rescue => e
      Rails.logger.error "❌ Error en UpdateProgramEstadosJob: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(5).join('\n')}"
    end
  end
end