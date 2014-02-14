class VotesController < ApplicationController

  before_filter :authenticate_user!
  protect_from_forgery :except => :create

  def create
    @idea = Idea.find(params[:idea_id])
    @idea.add_vote!(current_user)
    respond_to do |format|
      format.html { redirect_to idea_url(@idea) }
      format.js   { render :partial => 'vote', :locals => { :idea => @idea } }
      format.xml
    end
  end

  def request_as_words
    "vote for ideas"
  end

end
