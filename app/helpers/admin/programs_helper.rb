module Admin::ProgramsHelper
    def estado_badge_class(estado)
      case estado
      when 'activo' then 'bg-success'
      when 'inactivo' then 'bg-secondary'
      when 'pendiente' then 'bg-warning text-dark'
      when 'finalizado' then 'bg-danger'
      else 'bg-light text-dark'
      end
    end
  end 