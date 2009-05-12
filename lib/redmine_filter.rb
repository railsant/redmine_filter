# Main module for RedmineFilter.  
# Include this in ApplicationController to activate filter
#
module RedmineFilter
  
  def self.included(klass)
    #klass.send :before_filter, :retrieve_query
    klass.send :class_inheritable_accessor, :query
    klass.send :extend, RedmineFilterClassMethods
    klass.send :helper, RedmineFilterHelper
    klass.send :before_filter,:define_query
    klass.send :query=, Query.new
  end
  
  module RedmineFilterClassMethods
    def available_filters(field, values={})
      self.query.available_filters.update({field, values})
    end
    
    def defaut_filter(field, operator, values=[])
      self.query.add_filter(field,operator,values) unless self.query.nil?
    end
  end
  def query_statement
      self.query.statement
  end
  
  def define_query(filters={})
    #options ||= {
    #               "created_at"     => {:type => :date_past},
    #               "updated_at"     => {:type => :date_past}
    #             }
    #self.query = Query.new
    #query.available_filters = filters
    
    context = 'query_' + controller_name.to_s
    
    if params[:set_filter] || session[context].nil? 
      # Give it a name, required to be valid
      #query = Query.new(:name => "_")
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