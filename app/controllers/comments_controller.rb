class CommentsController < ApplicationController
  has_rakismet

  before_filter :authenticate_user!, :except => [:index, :show]
  # before_filter :login_required, :except => [:index, :show]
  before_filter :owner_required, :only => :update

  param_accessible :comment => [:text]

  make_resourceful do
    actions :new, :create, :update
    belongs_to :idea

    before :create do
      @comment.author = current_user
      @comment.ip = request.remote_ip
      @comment.user_agent = request.user_agent
    end

    response_for :create do |format|
      format.html do
        flash[:info] = "Thanks! Your comment has been posted. <strong><a href='#comment_#{@comment.id}'>View comment &raquo;</a></strong>"
        redirect_to idea_url(@idea)
      end
      format.xml do
        render :template => 'comments/show'
      end
    end

    response_for :create_fails do |format|
      format.html { render :template => 'comments/new' }
      format.xml  { render :template => 'validation_errors' }
    end

    before :update do
      @idea = @comment.idea
    end

    response_for :update do |format|
      format.html do
        flash[:info] = "Thanks! Your comment has been updated. <strong><a href='#comment_#{@comment.id}'>View comment &raquo;</a></strong>"
        redirect_to idea_url(@idea)
      end
    end

    response_for :update_fails do |format|
      format.html { render :template => 'ideas/show' }
    end
  end

  def index
    @body_class = "comments-page"
    unless fragment_exist?(['comments', CGI.escape(params.inspect)])
      current_objects
    end

    respond_to do |format|
      format.html
      format.rss { render :content_type => 'application/rss+xml'}
    end
  end

  def current_objects
    @comments ||= begin
      query_opts = {
        :page => params[:page],
        :per_page => 20,
        :order => 'comments.created_at DESC',
        :include => [:author, :idea],
        :conditions => { 'users.state' => 'active', 'comments.hidden' => false, 'ideas.hidden' => false }}
      query_opts[:conditions][:idea_id] = idea.id if idea
      Comment.paginate query_opts
    end
  end

  def idea
    @idea ||= Idea.find(params[:idea_id]) if params[:idea_id]
  end
  helper_method :idea

  def owner_required(*return_to_args)
    @comment ||= Comment.find(params[:id])
    @comment.author == current_user || access_denied("You can't update other user's comments", return_to_args)
  end

  def page_title
    "Comments"
  end

end
