module ApplicationHelper

  def title(page_title)
    content_for(:title) { page_title }
  end

  def link_to_add_fields(name, f, association, button_class=nil, container_id=nil)
    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    fields = f.fields_for(association, new_object, child_index: id) do |builder|
      render(association.to_s.singularize + "_fields", f: builder)
    end
    if container_id == nil
      container_id = association
    end
    container_id_css_spec = '#' + container_id
    opts = { class: 'add_fields', data: { id: id, container: container_id_css_spec, fields: fields.gsub("\n",'') } }
    if button_class != nil
      opts['class'] = "add_fields #{button_class}" 
    end
    link_to(name, '#', opts)
  end

end
