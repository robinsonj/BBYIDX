class IdeaPublisher < Facebooker::Rails::Publisher
  def self.new_idea_template_id
    # Facebooker::Rails::Publisher::FacebookTemplate.find_by_template_name('IdeaPublisher::new_run').bundle_id
    Facebooker::Rails::Publisher::FacebookTemplate.find(:first).bundle_id
  end

  def new_idea_template
    # one_line_story_template "{*actor*} has a new idea for #{BBYIDX::SHORT_SITE_NAME}: {*idea*}."
    
    short_story_template "{*actor*} has a new idea for #{BBYIDX::SHORT_SITE_NAME}.", "{*actor*} has a new idea for #{BBYIDX::SHORT_SITE_NAME}: {*idea*}."
  end

end
