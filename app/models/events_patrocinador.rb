class EventsPatrocinador < ApplicationRecord
  belongs_to :event
  belongs_to :patrocinador
end

#bien