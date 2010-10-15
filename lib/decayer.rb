class Decayer < BatchWorker
  
  # We could move this into conf if we like:
  MAX_RUNS = 500            # How many times should we run before giving up on updating everything?
  BATCH_SIZE = 200          # How many records should we attempt to modify in a single sql update statement?
  MIN_UPDATE_DELAY = 1.hour # How long at a minimum should we wait after applying decay to a record before doing it again?
  
  def self.workers(config)
    [ Decayer.new(Idea, :rating,                     config),
      Decayer.new(User, :recent_contribution_points, config)]
  end
  
  def initialize(model, field, config)
    conf_key = "#{model.name.underscore}_#{field}".to_sym
    half_life = (config[:half_life] || {})[conf_key]
    raise "Missing config[:half_life][:#{conf_key}]" unless half_life
    
    @model, @field, @half_life = model, field.to_s, half_life.to_i
    @now = Time.now  # prevents new records from stringing us along indefinitely
    @update_cutoff_time = @now - MIN_UPDATE_DELAY
  end
  
  def run
    @model.transaction do
      @model.update_all('decayed_at = created_at', "id in (select id from #{@model.to_s.tableize} where decayed_at is null limit #{BATCH_SIZE}) ")
      count = @model.update_all(
        ["#{@field} = #{@field} * pow(2, extract(epoch from (decayed_at - ?)) / ?), decayed_at = ?",  @now, @half_life, @now],
        ["id in (select id from #{@model.to_s.tableize} where decayed_at < ? limit #{BATCH_SIZE})", @update_cutoff_time])
      count > 0
    end
  end
  
  def to_s
    "#{self.class.name}[#{@current_model.name}.#{@field}]"
  end
  
protected
  
  def self.logger
    Rails.logger
  end
  
end
