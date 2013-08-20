module Admin
  class LifeCyclesController < AdminController
    before_filter :set_body_class
    
    include ActionView::Helpers::JavaScriptHelper
    
    in_place_edit_for :life_cycle, :name
    in_place_edit_for :life_cycle_step, :name
    
    def edit
    end
    
    def reorder
      update_life_cycle do |life_cycle|
        step_order = params["life_cycle_#{life_cycle.id}"]
        step_order.each_with_index do |step_id, index|
          step = LifeCycleStep.find(step_id)
          raise "Wrong life cycle" unless step.life_cycle_id == life_cycle.id
          step.position = index + 1
          step.save!
        end
      end
      render :text => 'OK'
    end
    
    def create
      respond_to do |format|
        format.html do
          LifeCycle.transaction do
            new_cycle = LifeCycle.create :name => params[:value]
            
            if new_cycle.valid?
              # Add a "DONE" step to the newly created cycle, to help the users remember that such a step must exist
              new_cycle.steps.create! :name => 'DONE'
              
              # Insert new cycle into page
              js = "$('life_cycle_new').insert({ before: '"
              js << escape_javascript(render_to_string(
                      :partial => 'life_cycle', :locals => { :life_cycle => new_cycle }))
              js << "' });"
            else
              js = "alert('#{escape_javascript(new_cycle.errors.full_messages.to_sentence)}.');"
            end
            
            # Clear content of in-place editor for new cycle name, which now says "Saving...."
            js << "$('life_cycle_new_editor').innerHTML = '';"
            
            render :text => js, :content_type => 'text/javascript'
          end
        end
      end
    end
    
    def create_step
      respond_to do |format|
        format.html do
          update_life_cycle do |life_cycle|
            new_step = life_cycle.steps.create :name => params[:value]
            if new_step.valid?
              if life_cycle.steps.size > 1
                # Insert *before* last element, so that "DONE" is always last by default
                new_step.insert_at(life_cycle.steps.size - 1)
                before_dom_id = "step_#{life_cycle.steps.last.id}"
              else
                # Only one in list
                before_dom_id = "life_cycle_#{life_cycle.id}_new"
              end
              js = "$('#{before_dom_id}').insert({ before: '"
              js << escape_javascript(render_to_string(
                      :partial => 'life_cycle_step', :locals => { :life_cycle_step => new_step, :life_cycle => life_cycle }))
              js << "' });"
              js << render_to_string(
                      :partial => 'life_cycle_sortable', :locals => { :life_cycle => life_cycle })  # new elem should be sortable
              js << ';'
            else
              js = "alert('#{escape_javascript(new_step.errors.full_messages.to_sentence)}.');"
            end
            js << "$('life_cycle_#{life_cycle.id}_new_editor').innerHTML = '';"  # Clear "Saving..." message
            render :text => js, :content_type => 'text/javascript'
          end
        end
      end
    end
    
    def delete
      update_life_cycle do |life_cycle|
        unless life_cycle.steps.empty?
          Idea.update_all(
            {:life_cycle_step_id => reassign_to_id},
            {:life_cycle_step_id => life_cycle.steps.map{ |step| step.id }})
        end
        
        life_cycle.destroy
        
        redirect_to :action => :edit
      end
    end
    
    def delete_step
      LifeCycleStep.transaction do
        step = LifeCycleStep.find(params[:id])
        step.life_cycle.lock!
        step.reload
        
        Idea.update_all(
          {:life_cycle_step_id => reassign_to_id},
          {:life_cycle_step_id => step.id})
        
        step.destroy
        
        redirect_to :action => :edit
      end
    end
    
  private
  
    def update_life_cycle
      LifeCycle.transaction do
        yield LifeCycle.find(params[:id], :lock => true)
      end
    end
    
    def lc_dom_id
      "life_cycle_#{@life_cycle.id}"
    end
    helper_method :lc_dom_id
    
    def reassign_to_id
      if params[:reassign_to].blank?
        nil
      else
        LifeCycleStep.find(params[:reassign_to]).id # ensure it exists
      end
    end
    
    def set_body_class
      @body_class = 'life-cycles'
    end
    
  end
end
