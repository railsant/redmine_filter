class Query 
  @@operators = { "="   => :equals,
                  "!"   => :not_equals,
                  "!*"  => :none,
                  "*"   => :all,
                  ">="   => '>=',
                  "<="   => '<=',
                  "<t+" => :in_less_than,
                  ">t+" => :in_more_than,
                  "t+"  => :in,
                  "t"   => :today,
                  "w"   => :this_week,
                  ">t-" => :less_than_ago,
                  "<t-" => :more_than_ago,
                  "t-"  => :ago,
                  "~"   => :contains,
                  "!~"  => :not_contains }

  cattr_reader :operators
  @@operators_by_filter_type = { :list => [ "=", "!" ],
                                 :list_status => [ "=", "!", "*" ],
                                 :list_optional => [ "=", "!", "!*", "*" ],
                                 :date => [ "<t+", ">t+", "t+", "t", "w", ">t-", "<t-", "t-" ],
                                 :date_past => [ ">t-", "<t-", "t-", "t", "w" ],
                                 :string => [ "=", "~", "!", "!~" ],
                                 :text => [  "~", "!~" ],
                                 :integer => [ "=", ">=", "<=", "!*", "*" ] }

  cattr_reader :operators_by_filter_type

  attr_writer :available_filters

  def available_filters
	return @available_filters if @available_filters
	@available_filters = { 
                           #"status" => { :type => :list_status, :order => 1 , :values => %w{0 1}},
                           "created_at" => { :type => :date_past, :order => 100 },
                           "updated_at" => { :type => :date_past, :order => 100 },
				}

  end

#  @filters = { 
		#'status' => {:operator => "=", :values => [""]} ,
		#'updated_at' => {:operator => "t", :values => [""]} ,
		#'created_at' => { :operator => "t", :values => [""]},
#		}
  attr_accessor :filters

  def initialize(attributes = nil)
#	@filters, @available_filters = attributes[:0
    #self.filters ||= { 'status_id' => {:operator => "o", :values => [""]} }
    #set_language_if_valid(User.current.language)
  end
  def has_filter?(field)
	filters and filters[field]
  end

  def operator_for(field)
    has_filter?(field) ? filters[field][:operator] : nil rescue nil
  end

  def values_for(field)
    has_filter?(field) ? filters[field][:values].collect{|v|CGI::unescape(v)} : nil rescue nil
  end

  def label_for(field)
    label = available_filters[field][:name] if available_filters.has_key?(field)
    label ||= field.gsub(/\_id$/, "").humanize
  end rescue nil

  def add_short_filter(field, expression)
    return unless expression
    parms = expression.scan(/^(o|c|\!|\*)?(.*)$/).first
    add_filter field, (parms[0] || "="), [parms[1] || ""]
  end

  def add_filter(field, operator, values=[])
    # values must be an array
    return unless values and values.is_a? Array # and !values.first.empty?
    # check if field is defined as an available filter
    if self.available_filters.has_key? field
      filter_options = self.available_filters[field]
      # check if operator is allowed for that filter
      #if @@operators_by_filter_type[filter_options[:type]].include? operator
      #  allowed_values = values & ([""] + (filter_options[:values] || []).collect {|val| val[1]})
      #  filters[field] = {:operator => operator, :values => allowed_values } if (allowed_values.first and !allowed_values.first.empty?) or ["o", "c", "!*", "*", "t"].include? operator
      #end
      self.filters = Hash.new if self.filters.nil?
      self.filters[field] = {:operator => operator, :values => values }
    end
  end

  def statement
   
    # filters clauses
    filters_clauses = []
    sql = ' 1 '
    condition_values = []


    self.filters.each_key do |field|
      v = values_for(field).clone
      next unless v and !v.empty?
            
      #is_custom_filter = false

      #if field =~ /^cf_(\d+)$/
      #  # custom field
      #  db_table = CustomValue.table_name
      #  db_field = 'value'
      #  is_custom_filter = true
      #  sql << "#{Issue.table_name}.id IN (SELECT #{Issue.table_name}.id FROM #{Issue.table_name} LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='Issue' AND #{db_table}.customized_id=#{Issue.table_name}.id AND #{db_table}.custom_field_id=#{$1} WHERE "
      #else
      #  # regular field
        db_table = ''#Issue.table_name
        db_field = field
        #sql << '('
      #end
      
      sql << ' AND '

      case operator_for field
      when "="
	      sql << "#{db_field} IN (?)" 
	      #condition_values << v.collect{|val| "#{val}"}
	      condition_values << v.collect{|val| CGI::unescape(val)}
	
        #sql = sql + "#{db_field} IN (" + v.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + ")"
      when "!"
	      sql << "#{db_field} IS NULL OR #{db_field} NOT IN (?)"
	      #condition_values << v.collect{|val| "#{val}"}
	      #condition_values << v.collect{|val| "#{val}"}
	      condition_values << v.collect{|val| CGI::unescape(val)}

        #sql = sql + "(#{db_field} IS NULL OR #{db_field} NOT IN (" + v.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + "))"
      when "!*"
        sql << "#{db_field} IS NULL OR #{db_field} = ''"
      #  sql = sql + "#{db_field} IS NULL"
      #  sql << " OR #{db_field} = ''" if is_custom_filter
      when "*"
        sql << "#{db_field} IS NOT NULL"
        #sql = sql + "#{db_field} IS NOT NULL"
        #sql << " AND #{db_field} <> ''" if is_custom_filter
      when ">="
          sql << "#{db_field} >= ?"
          condition_values << v.first.to_i
      #  sql = sql + "#{db_field} >= #{v.first.to_i}"
      when "<="
            sql << "#{db_field} <= ?"
            condition_values << v.first.to_i
      #  sql = sql + "#{db_field} <= #{v.first.to_i}"
      #when "o"
      #  sql = sql + "#{IssueStatus.table_name}.is_closed=#{connection.quoted_false}" if field == "status_id"
      #when "c"
      #  sql = sql + "#{IssueStatus.table_name}.is_closed=#{connection.quoted_true}" if field == "status_id"
      when ">t-"
        sql << "#{db_field} BETWEEN ? AND ?" 
        condition_values <<  (Date.today - v.first.to_i).to_time
        condition_values <<  (Date.today + 1).to_time
      #  sql = sql + "#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date((Date.today - v.first.to_i).to_time), connection.quoted_date((Date.today + 1).to_time)]
      when "<t-"
        sql << "#{db_field} <= ?" 
        condition_values <<  (Date.today - v.first.to_i).to_time
      #  sql = sql + "#{db_field} <= '%s'" % connection.quoted_date((Date.today - v.first.to_i).to_time)
      when "t-"
          sql << "#{db_field} BETWEEN ? AND ?" 
          condition_values <<  (Date.today - v.first.to_i).to_time
          condition_values <<  (Date.today - v.first.to_i + 1).to_time
      #  sql = sql + "#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date((Date.today - v.first.to_i).to_time), connection.quoted_date((Date.today - v.first.to_i + 1).to_time)]
      when ">t+"
          sql << "#{db_field} >= ?"
          condition_values <<  (Date.today + v.first.to_i).to_time
      #  sql = sql + "#{db_field} >= '%s'" % connection.quoted_date((Date.today + v.first.to_i).to_time)
      when "<t+"
          sql << "#{db_field} BETWEEN ? AND ?"
          condition_values <<  Date.today.to_time
          condition_values <<  (Date.today + v.first.to_i + 1).to_time
      #  sql = sql + "#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date(Date.today.to_time), connection.quoted_date((Date.today + v.first.to_i + 1).to_time)]
      when "t+"
            sql << "#{db_field} BETWEEN ? AND ?"
            condition_values <<  (Date.today + v.first.to_i).to_time
            condition_values <<  (Date.today + v.first.to_i + 1).to_time
      #  sql = sql + "#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date((Date.today + v.first.to_i).to_time), connection.quoted_date((Date.today + v.first.to_i + 1).to_time)]
      when "t"
            sql << "#{db_field} BETWEEN ? AND ?"
            condition_values <<  Date.today.to_time
            condition_values <<  (Date.today+1).to_time
      #  sql = sql + "#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date(Date.today.to_time), connection.quoted_date((Date.today+1).to_time)]
      when "w"
        #from = l(:general_first_day_of_week) == '7' ?
      # week starts on sunday
          #((Date.today.cwday == 7) ? Time.now.at_beginning_of_day : Time.now.at_beginning_of_week - 1.day) :
      # week starts on monday (Rails default)
          from = Time.now.at_beginning_of_week
      #  sql = sql + "#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date(from), connection.quoted_date(from + 7.days)]
      	 sql << "#{db_field} BETWEEN ? AND ?" 
	condition_values << from 
	condition_values << from  + 7.days
      when "~"
         sql << "#{db_field} LIKE ?" 
  	      condition_values << '%' + v.first + '%'
        #sql = sql + "#{db_table}.#{db_field} LIKE '%#{connection.quote_string(v.first)}%'"
      when "!~"
         sql << "#{db_field} NOT LIKE ?" 
  	      condition_values << '%' + v.first + '%'
        #sql = sql + "#{db_field} NOT LIKE '%#{connection.quote_string(v.first)}%'"
      else 
    	  sql << ' 1 '
      end
      #sql << ')'
      #filters_clauses << ' AND ' + condition unless condition.blank?
    end if filters 
   filters_clauses << sql
   filters_clauses += condition_values
  end
 
  
end
