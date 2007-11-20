class ActiveRecord::Base

  def self.list_fields
    @config = YAML.load_file("#{RAILS_ROOT}/config/typus.yml")
    @config = @config["#{self}"]["list"].split(" ")
    @fields = Array.new
    @config.each { |i| @fields << i.split("::") }
    @fields << [["name", "string"]] if @fields.size == 0
    return @fields
  end

  def self.form_fields
    @config = YAML.load_file("#{RAILS_ROOT}/config/typus.yml")
    @config = @config["#{self}"]["form"].split(" ")
    @fields = Array.new
    @config.each { |i| @fields << i.split("::") }
    @fields << [["name", "string"]] if @fields.size == 0
    return @fields
  end

  def self.form_fields_externals
    @config = YAML.load_file("#{RAILS_ROOT}/config/typus.yml")
    @fields = Array.new
    if @config["#{self}"]["form_externals"]
      @config["#{self}"]["form_externals"].split(" ").each { |i| @fields << i.split("::") }
    end
    return @fields
  end

  def self.default_order
    @config = YAML.load_file("#{RAILS_ROOT}/config/typus.yml")
    @order = Array.new
    if @config["#{self}"]["order"]
      @config["#{self}"]["order"].split(" ").each { |i| @order << i.split("::") }
    else
      @order << ['id', 'asc']
    end
    return @order
  end

  def self.search_fields
    @config = YAML.load_file("#{RAILS_ROOT}/config/typus.yml")
    @search = Array.new
    if @config["#{self}"]["search"]
      @config = @config["#{self}"]["search"].split(" ")
      @config.each { |i| @search << i }
    end
    return @search
  end

  def self.filters
    @config = YAML.load_file("#{RAILS_ROOT}/config/typus.yml")
    @filters = Array.new
    if @config["#{self}"]["filters"]
      @config = @config["#{self}"]["filters"].split(" ")
      @config.each { |i| @filters << i.split("::") }
    end
    return @filters
  end

  def self.actions
    @config = YAML.load_file("#{RAILS_ROOT}/config/typus.yml")
    @actions = Array.new
    if @config["#{self}"]["actions"]
      @config = @config["#{self}"]["actions"].split(" ")
      @config.each { |i| @actions << i.split("::") }
    end
    return @actions
  end

end