module AdminFormHelper

  ##
  # All helpers related to form.
  #

  def build_form(fields = @item_fields)
    returning(String.new) do |html|
      html << "#{error_messages_for :item, :header_tag => "h3"}"
      html << "<ul>"
      fields.each do |field|
        case field.last
        when "string":          html << typus_string_field(field.first, field.last)
        when "boolean":         html << typus_boolean_field(field.first, field.last)
        when "datetime":        html << typus_datetime_field(field.first, field.last)
        when "text":            html << typus_text_field(field.first, field.last)
        when "file":            html << typus_file_field(field.first, field.last)
        when "password":        html << typus_password_field(field.first, field.last)
        when "selector":        html << typus_selector_field(field.first, field.last)
        when "collection":      html << typus_collection_field(field.first, field.last)
        when "tree":            html << typus_tree_field(field.first, field.last)
        else
          html << typus_string_field(field.first, field.last)
        end
      end
      html << "</ul>"
    end
  end

  def typus_tree_field(attribute, value)
    returning(String.new) do |html|
      html << <<-HTML
<li><label for=\"item_#{attribute}\">#{attribute.titleize.capitalize}</label>
    <select id="item_#{attribute}" name="item[#{attribute}]">
      <option value=""></option>
      #{expand_tree_into_select_field(@item.class.top)}
    </select></li>
      HTML
    end
  end

  def typus_datetime_field(attribute, value)
    returning(String.new) do |html|
      html << "<li><label for=\"item_#{attribute}\">#{attribute.titleize.capitalize}</label>"
      html << "#{datetime_select :item, attribute, { :minute_step => Typus::Configuration.options[:minute_step] }}</li>"
    end
  end

  def typus_text_field(attribute, value)
    returning(String.new) do |html|
      html << "<li><label for=\"item_#{attribute}\">#{attribute.titleize.capitalize}</label>"
      html << "#{text_area :item, attribute, :class => 'text', :rows => Typus::Configuration.options[:form_rows]}</li>"
    end
  end

  def typus_selector_field(attribute, value)
    returning(String.new) do |html|
      options = ""
      @item.class.send(attribute).each do |option|
        options << "<option #{'selected' if @item.send(attribute).to_s == option.to_s} value=\"#{option}\">#{option}</option>"
      end
      html << <<-HTML
<li><label for=\"item_#{attribute}\">#{attribute.titleize.capitalize}</label>
<select id="item_#{attribute}" name="item[#{attribute}]">
  <option value="">Select an option</option>
  #{options}
</select></li>
      HTML
    end
  end

  def typus_collection_field(attribute, value)
    returning(String.new) do |html|
      related = attribute.split("_id").first.capitalize.camelize.constantize
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute.titleize.capitalize} <small>#{link_to "Add new", "/admin/#{attribute.titleize.tableize}/new?back_to=#{request.env['REQUEST_URI']}" }</small></label>
#{select :item, attribute, related.find(:all).collect { |p| [p.typus_name, p.id] }.sort_by { |e| e.first }, :prompt => "Select a #{related.name.downcase}"}</li>
      HTML
    end
  end

  def typus_string_field(attribute, value)

    # Read only fields.
    if @model.typus_field_options_for(:read_only).include?(attribute)
      value = 'read_only' if %w( edit ).include?(params[:action])
    end

    # Auto generated fields.
    if @model.typus_field_options_for(:auto_generated).include?(attribute)
      value = 'auto_generated' if %w( new edit ).include?(params[:action])
    end

    comment = %w( read_only auto_generated ).include?(value) ? (value + " field").titleize : ""

    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute.titleize.capitalize} <small>#{comment}</small></label>
#{text_field :item, attribute, :class => 'text'}</li>
      HTML
    end

  end

  def typus_password_field(attribute, value)
    returning(String.new) do |html|
      html << "<li><label for=\"item_#{attribute}\">#{attribute.titleize.capitalize}</label>"
      html << "#{password_field :item, attribute, :class => 'text'}"
    end
  end

  def typus_boolean_field(attribute, value)
    question = true if @model.typus_field_options_for(:questions).include?(attribute)
    returning(String.new) do |html|
      html << "<li><label for=\"item_#{attribute}\">#{attribute.titleize.capitalize}#{"?" if question}</label>"
      html << "#{check_box :item, attribute} Checked if active</li>"
    end
  end

  def typus_file_field(attribute, value)

    attribute_display = attribute.split("_file_name").first
    content_type = @item.send("#{attribute_display}_content_type")

    returning(String.new) do |html|

      html << "<li><label for=\"item_#{attribute}\">#{attribute_display.titleize.capitalize}</label>"

      case content_type
      when /image/
        html << "#{link_to image_tag(@item.send(attribute_display).url(:thumb)), @item.send(attribute_display).url, :style => "border: 1px solid #D3D3D3;"}<br /><br />"
      when /pdf|flv|quicktime/
        html << "<p>No preview available. (#{content_type.split('/').last})</p>"
      end

      html << "#{file_field :item, attribute.split("_file_name").first}</li>"

    end

  end

  def typus_form_has_many
    html = ""
    if @item_has_many
      @item_has_many.each do |field|
        model_to_relate = field.singularize.camelize.constantize
        html << "<h2 style=\"margin: 20px 0px 10px 0px;\"><a href=\"/admin/#{field}\">#{field.titleize}</a> <small>#{link_to "Add new", "/admin/#{field}/new?back_to=#{request.env['REQUEST_URI']}&model=#{@model}&model_id=#{@item.id}"}</small></h2>"
        current_model = @model
        @items = @model.find(params[:id]).send(field)
        if @items.size > 0
          html << typus_table(@items[0].class, 'relationship', @items)
        else
          html << "<div id=\"flash\" class=\"notice\"><p>There are no #{field.titleize.downcase}.</p></div>"
        end
      end
    end
    return html
  end

  def typus_form_has_and_belongs_to_many
    html = ""
    if @item_has_and_belongs_to_many
      @item_has_and_belongs_to_many.each do |field|
        model_to_relate = field.singularize.camelize.constantize
        html << "<h2 style=\"margin: 20px 0px 10px 0px;\"><a href=\"/admin/#{field}\">#{field.titleize}</a> <small>#{link_to "Add new", "/admin/#{field}/new?back_to=#{request.env['REQUEST_URI']}&model=#{@model}&model_id=#{@item.id}"}</small></h2>"
        items_to_relate = (model_to_relate.find(:all) - @item.send(field))
        if items_to_relate.size > 0
          html << <<-HTML
            #{form_tag :action => 'relate'}
            #{hidden_field :related, :model, :value => field.modelize}
            <p>#{ select :related, :id, items_to_relate.collect { |f| [f.typus_name, f.id] }.sort_by { |e| e.first } }
          &nbsp; #{submit_tag "Add", :class => 'button'}
            </form></p>
          HTML
        end
        current_model = @model.name.singularize.camelize.constantize
        @items = current_model.find(params[:id]).send(field)
        html << typus_table(field.modelize, 'relationship') if @items.size > 0
      end
    end
    return html
  end

  ##
  # Tree when +acts_as_tree+
  #
  def expand_tree_into_select_field(categories)
    returning(String.new) do |html|
      categories.each do |category|
        html << %{<option #{"selected" if @item.parent_id == category.id} value="#{category.id}">#{"-" * category.ancestors.size} #{category.name}</option>}
        html << expand_tree_into_select_field(category.children) if category.has_children?
      end
    end
  end

end