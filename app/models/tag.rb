class Tag < ActiveRecord::Base
  
  has_and_belongs_to_many :ideas, :join_table => :frutso
  
  include TagHelper
  
  def self.find_top_tags(limit)
    Tag.find_with_idea_counts(:limit => limit, :order => 'idea_count DESC, tags.name')
  end
end
