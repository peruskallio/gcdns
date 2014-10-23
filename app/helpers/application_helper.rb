# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

module ApplicationHelper
  
  def current_path?(path)
    request.path.starts_with?(path)
  end
  
  def nav_link(link_text, link_path)
    class_name = current_path?(link_path) ? 'active' : ''
    
    content_tag(:li, :class => class_name) do
      link_to link_text, link_path
    end
  end
  
end
