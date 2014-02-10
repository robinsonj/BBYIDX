# Base behavior for all admin controllers. Includes shared security, queries, and utilities.

module Admin
  class AdminController < ApplicationController
    layout 'admin'

    before_filter :admin_required
    before_filter :editor_required, :except => [:index, :show, :edit, :new, :create]
    # TODO: If we want create permission separate from edit permission, uncomment the
    # following and remove new & create from previous line:
    #before_filter :creator_required, :only => [:new, :create]

    def show_if_nonzero(n)
      (n.to_f != 0) ? n : '&nbsp;'
    end
    helper_method :show_if_nonzero

    def paginate_pending_moderation(current_model, default_per_page, sort_sql = 'inappropriate_flags desc')
      current_model.paginate(
        :all,
        :conditions => ['inappropriate_flags > 0 and hidden = ?', false],
        :order => sort_sql,
        :page => params[:page],
        :per_page => params[:per_page] || default_per_page)
    end

    def request_as_words
      super + " in the admin interface"
    end

    def all_life_cycles
      #@all_life_cycles ||= LifeCycle.find(:all, :include => :steps, :order => 'created_at').reject { |lc| lc.steps.empty? }
      @all_life_cycles ||= LifeCycle.include('steps').order('created_at').all.reject { |lc| lc.steps.empty? }
    end
    helper_method :all_life_cycles

    def disable_form_unless_editor(form_object)
      unless editor?
        "<script type='text/javascript'>
          $('#{dom_id(form_object, :edit)}').getElements().each(function(elem) {
            if(elem.type == 'submit') {
              elem.style.display = 'none'
            } else {
              elem.disable()
            }
          })
        </script>"
      end
    end
    helper_method :disable_form_unless_editor

  end
end
