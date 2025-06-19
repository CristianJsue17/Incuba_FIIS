module ApplicationHelper
  def form_field_error(resource, field)
    return unless resource.errors[field].any?
    
    content_tag(:div, class: "invalid-feedback") do
      resource.errors[field].join(", ")
    end
  end
  
  def react_component(name, props = {})
    tag.div(
      data: {
        react_component: name,
        react_props: props.to_json
      }
    )
  end
end
