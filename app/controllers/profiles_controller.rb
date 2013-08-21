class ProfilesController < ApplicationController
  
  before_filter :populate_user
  
  def populate_user
    @body_class = 'profile'
    @user = User.find(params[:id])
    
    resource_gone unless @user.active? || @user == current_user
  end
  
  def show
    respond_to do |format|
      format.html do
        if ajax_request?
          render :text => render_recent(params)
        end
      end
      format.xml
    end
  end
  
  def render_recent(params)
    model = params[:recent]
    collection, partial = case model
      when 'ideas'    then [@user.ideas,    'ideas/idea']
      when 'comments' then [@user.comments, 'comments/comment']
      when 'votes'    then [@user.votes,    'vote']
      else raise 'Invalid value for "recent" param'
    end
    
    render_to_string_html_safe :partial => 'recent', :locals => {
      :model => model,
      :collection => collection,
      :offset => params[:offset].to_i,
      :limit  => params[:limit].to_i,
      :partial => partial }
  end
  helper_method :render_recent
  
  def page_title
    "User Profile: #{@user.name}" if @user
  end
    
end
