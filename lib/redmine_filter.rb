# Main module for RedmineFilter.  
# Include this in ApplicationController to activate filter
#
module RedmineFilter
  
  def self.included(klass)
    #klass.send :before_filter, :retrieve_query
    klass.send :class_inheritable_accessor, :query
    klass.send :class_inheritable_accessor, :_available_filters
    klass.send :class_inheritable_accessor, :_default_filters
    klass.send :before_filter,:define_query
    klass.send :extend, RedmineFilterClassMethods
    klass.send :helper, RedmineFilterHelper
    klass.send :query=, Query.new
    klass.send :_available_filters=, Array.new
    klass.send :_default_filters=, Array.new

    

  end
  
  module RedmineFilterClassMethods
    def available_filters(field, values={})
      # self.query.available_filters.update({field, values})
      self._available_filters.push([field.to_s, values])
    end
    
    def default_filter(field, operator='*', values=[])
      # self.query.add_filter(field,operator,values) unless self.query.nil?
      self._default_filters.push([field.to_s,operator,values])
    end
  end
  def query_statement
      self.query.statement
  end
  
  def define_query(filters={})
    self.query = Query.new
    context = 'query_' + controller_name.to_s
    
    if params[:set_filter] || session[context].nil? 
      # Give it a name, required to be valid
      #query = Query.new(:name => "_")
      self.query = Query.new
      
      self._available_filters.each do |field, values|
        self.query.available_filters.update({field, values})
      end

      self._default_filters.each do |field,operator,values|
        self.query.add_filter(field,operator,values)
      end
      
      if params[:fields] and params[:fields].is_a? Array
        params[:fields].each do |field|
          self.query.add_filter(field, params[:operators][field], params[:values][field].collect{|v| URI::unescape(v)})
        end
      else
        self.query.available_filters.keys.each do |field|
          self.query.add_short_filter(field, params[field]) if params[field]
        end
      end
      session[context] = {:filters => self.query.filters}
    else
      self.query.filters = session[context][:filters]  if session[context][:filters]
    end
    
  end

  
  module RedmineFilterHelper
    
    def filters
      render :file => "#{File.dirname(__FILE__)}/filter.html.erb", :locals => {:query => controller.query}
    end
    
    def operators_for_select(filter_type)
       Query.operators_by_filter_type[filter_type].collect {|o| [(Query.operators[o].to_s.humanize), o]}
    end
  end
end
