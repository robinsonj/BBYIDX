module Admin
  class CurrentsController < AdminController

    before_filter :set_body_class

    make_resourceful do
      actions :index, :new, :create, :edit, :update

      before :create do
        @current.inventor = current_user
      end

      response_for :index do |format|
        format.html { render :action => 'index' }
      end

      response_for :create do |format|
        format.html do
          redirect_to edit_admin_current_path(@current)
        end
      end

      response_for :create_fails do |format|
        format.html { render :action => 'new' }
      end

      response_for :update do |format|
        format.html do
          flash[:info] = 'Changes saved.'
          redirect_to edit_admin_current_path(@current)
        end
      end

      response_for :update_fails do |format|
        format.html { render :action => 'edit' }
      end
    end

    def current_ideas
      @current_ideas ||= Idea.paginate_by_current_id(
        current_object.id,
        :page => params[:page],
        :conditions => ['hidden = ?', false],
        :per_page => params[:per_page] || 20)
    end
    helper_method :current_ideas

    include ResourceAdmin

  protected

    def default_sort
      ['currents.created_at', true]
    end

    def index_query_options
      cols = Current.column_names.collect {|c| "currents.#{c}"}.join(",")
      conditions = {}
      # { :select => "#{cols}, count(*) AS idea_count",
      #   :conditions => conditions,
      #   :joins => 'LEFT JOIN ideas ON ideas.current_id = currents.id',
      #   :group => "#{cols}" }

      Current.select("#{cols}, count(*) AS idea_count").where(:conditions => conditions,
                                                              :joins => 'LEFT JOIN ideas ON ideas.current_id = currents.id',
                                                              :group => "#{cols}" )
    end

    def set_body_class
      @body_class = 'currents'
    end

  end
end
