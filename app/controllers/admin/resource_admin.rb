# Base behavior for admin controller which present a set of model objects in a searchable, sortable table-style view.
# This covers most of the admin interface.

module Admin
  module ResourceAdmin
    include SearchHelper
    
    def current_objects
      @current_objects ||= begin
        if search_pending_moderation?
          @query_title = "#{current_model.name.pluralize} Pending Moderation"
          paginate_pending_moderation(current_model, 30, sort_sql)
        elsif has_textual_search?
          sort, order = sort_params
          sort =~ /^([^\.]+\.)?(.+)/
          sort = $2
          
          search(current_model, params, sort, order) do |results|
            filter_search_results results
          end
        else
          @query_title = current_model.name.pluralize
          current_model.paginate(
            index_query_options.reverse_merge(
              :page => params[:page],
              :per_page => params[:per_page] || 30,
              :order => sort_sql + ', created_at desc'))
        end
      end
    end
  
    def has_textual_search?
      !(params[:search].blank? && params[:similar_to].blank?)
    end
  
    def search_pending_moderation?
      !params[:pending_moderation].blank?
    end
    
    def has_search?
      has_textual_search? || search_pending_moderation?
    end

    def sort_by(name, column, default_order = 'asc')
      render_to_string :partial => 'admin/sort_by', :locals => { :name => name, :column => column, :default_order => default_order }
    end
  
    def sort_params
      # Simple regexp guards against SQL attack. Consider improving this if this code moves beyond admin pages!
      if params[:sort] =~ /^([\w_]+\.)?[\w_]+$/
        [params[:sort], params[:order] == 'desc']
      else
        has_textual_search? ? [nil, true] : default_sort
      end
    end
    
    def self.included(klass)
      klass.class_eval do
        helper_method :has_search?
        helper_method :search_pending_moderation?
        helper_method :sort_by
        helper_method :sort_params
      end
    end
    
  protected
  
    def current_model
      @current_model ||= begin
        self.class.name =~ /Admin::(.*)Controller/
        raise "Can't figure out corresponsding resource for #{self.class.name}" unless $1
        $1.singularize.constantize
      end
    end
    
    def index_query_options
      {}
    end
    
    def sort_sql
      sort, order = sort_params
      sort + (order ? ' DESC' : ' ASC')
    end
  
    def default_sort
      raise "#{self.class} must override default_sort if it wants to call sort_order"
    end
    
    def filter_search_results(results)
      results
    end
    
  end
end
