class InappropriateController < ApplicationController
  
  def flag
    # We probably could use reflection safely here, but I'm paranoid about sanitizing user input. -PPC
    current_model = case(params[:model])
      when 'idea'    then Idea
      when 'comment' then Comment
      else raise "Illegal model: #{params[:model]}"
    end
    model = current_model.find(params[:id])
    model.flag_as_inappropriate!
    flagged_as_inappropriate(model)
    render :partial => 'xxx', :locals => { :model => model }
  end
  
  include ApplicationHelper
  helper_method :flagged_as_inappropriate?
  
end
