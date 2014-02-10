module Admin
  class ChronologiesController < AdminController
    before_filter :set_body_class

    def show
      @from = decode_time(params[:from])
      @to   = decode_time(params[:to]) + 1.day

      @ideas    = find_in_timeslice Idea, 'not hidden and inventor_id is not null'
      @comments = find_in_timeslice Comment, 'not hidden'
      @votes    = find_in_timeslice Vote
      @all_actions = (@ideas + @comments + @votes).sort_by { |a| a.created_at }
    end

    def format_date(date, long = true)
      date.getlocal.strftime(long ? '%Y/%m/%d %H:%M' : '%m/%d %H:%M')
    end
    helper_method :format_date

    def edit_path_for(model)
      case model
      when Idea
        edit_admin_idea_path(model)
      when Comment
        edit_admin_comment_path(model)
      when Vote
        edit_admin_user_path(model.user)
      end
    end
    helper_method :edit_path_for

  protected

    def set_body_class
      @body_class = 'chronology'
    end

  private

    def decode_time(raw_t)
      raw_t = raw_t.to_f / 1000
      Time.at(raw_t - Time.at(raw_t).utc_offset)  # Client sends millis since *local* epoch; correct for this
    end

    def find_in_timeslice(model, extra_conditions = '')
      extra_conditions = ' and ' + extra_conditions unless extra_conditions.blank?
      #model.find :all, :conditions => ['created_at >= ? and created_at < ?' + extra_conditions, @from.getutc, @to.getutc]
      model.where('created_at >= ? and created_at < ?' + extra_conditions, @from.getutc, @to.getutc).all
    end

  end
end
