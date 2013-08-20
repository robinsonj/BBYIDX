module Admin
  class IdeasController < AdminController
    before_filter :set_body_class
    after_filter :expire_cloud_cache, :only => [:update, :create, :destroy]
    
    make_resourceful do
      actions :index, :edit, :update
      
      before :index do
        Idea.populate_comment_counts current_objects
        Tag.load_tags current_objects
        AdminTag.load_tags current_objects
      end
    
      before :edit do
        unless @idea.viewed
          @idea.viewed = true
          @idea.save
        end
        @life_cycle_handler = LifeCycleHandler.new(@idea)
      end
      
      before :update do
        @idea.duplicate_of.remove_duplicate!(@idea) if params[:clear_duplicate]
        if !params[:admin_comment].blank? && !params[:admin_comment][:text].blank?
          @admin_comment = @idea.admin_comments.build(params[:admin_comment])
          @admin_comment.author = current_user
        end
      end
    
      response_for :index do |format|
        format.html do
          if ajax_request?
            render :partial => 'index' 
          else
            render :action => 'index' 
          end
        end
      end
    
      response_for :update do |format|
        format.html do
          if ajax_request?
            render :text => 'OK'
          else
            flash[:info] = 'Changes saved.'
            redirect_to edit_admin_idea_path(@idea)
          end
        end
      end
    end
    
    def has_search?
      super || search_life_cycle_step
    end
    
    def search_life_cycle_step
      @search_life_cycle_step ||= if params[:life_cycle_step].blank?
        nil
      else
        LifeCycleStep.find(params[:life_cycle_step])
      end
    end
    helper_method :search_life_cycle_step
    
    def compare_duplicates
      @dup_drag = Idea.find(params[:other_id])
      @dup_drop = current_object
      @dup_ideas = [@dup_drag, @dup_drop].sort_by { |i| i.created_at }
      update_bucket :add => @dup_ideas
    end
    
    def link_duplicates
      Idea.transaction do
        parent, child = current_object, Idea.find(params[:other_id])
        
        parent.add_duplicate! child
      
        update_bucket :add => parent, :remove => child
        redirect_to edit_admin_idea_path(parent)
      end
    end
    
    include ResourceAdmin
    include BucketHelper
    
  protected

    def default_sort
      if search_pending_moderation?
        ['inappropriate_flags', true]
      else
        ['ideas.created_at', true]
      end
    end
    
    def index_query_options
      conditions = search_life_cycle_step ? {:life_cycle_step_id => params[:life_cycle_step]} : {}
      conditions.merge!({:marked_spam => false}) unless params[:marked_spam] == "true"
      { :conditions => conditions }
      
      # The following allows sorting by comment count, but will_paginate doesn't know what to
      # do with the group clause, so it's disabled for now:

      # conditions = search_life_cycle_step ? {:life_cycle_step_id => params[:life_cycle_step]} : {}
      # conditions.merge!({:marked_spam => false}) unless params[:marked_spam] == "true"
      # cols = Idea.column_names.collect {|c| "ideas.#{c}"}.join(",")
      # { :select => "#{cols}, count(*) AS comment_count",
      #   :conditions => conditions,
      #   :joins => 'LEFT JOIN comments ON comments.idea_id = ideas.id',
      #   :group => "#{cols}" }
    end
    
    def filter_search_results(results)
      # This is a brute-force, but effective, way of filtering spam.  
      # We could alternatively rely on in-query filtering within search_xapian method.
      if params[:marked_spam] != "true"
        results = results.select { |result| !result.marked_spam? }
      end
      if search_life_cycle_step
        results.select{ |idea| idea.life_cycle_step_id == search_life_cycle_step.id }
      else
        results
      end
    end
    
    def set_body_class
      @body_class = 'ideas'
    end
    
  private
    
    def expire_cloud_cache
      expire_fragment :fragment => 'idea_cloud', :controller => '/home', :action => 'show'
    end
    
    # Facade to present the current life cycle step in terms of the UI's drop-down & check boxes.
    # This is only used to populate the UI; javascript responds to changes in the UI to update a hidden field.
    class LifeCycleHandler
      attr_accessor :idea, :life_cycle, :steps_completed
      
      def initialize(idea)
        @idea = idea
        @life_cycle = idea.life_cycle ? idea.life_cycle.id : nil
        @steps_completed = {}
        if @life_cycle
          idea.life_cycle.steps.each do |step|
            break if step == idea.life_cycle_step
            @steps_completed[step.id] = '1'
          end
        end
      end
      
      def method_missing(method, *args)
        if method.to_s =~ /^step_(\d+)/
          @steps_completed[$1.to_i]
        else
          super
        end
      end
      
    end
    
  end
end
