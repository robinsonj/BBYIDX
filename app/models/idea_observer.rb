class IdeaObserver < ActiveRecord::Observer

  def after_save(idea)
    if idea.life_cycle_step_id_changed? && idea.life_cycle_step
      idea.life_cycle_step.admins.each do |admin|
        next unless admin.notify_on_state?
        UserMailer.life_cycle_notification(admin, idea.life_cycle_step).deliver
      end
    end
  end

end
