class Idea < ActiveRecord::Base
  STATES = [ 'new', 'under review', 'reviewed', 'coming soon', 'launched' ]
  STATES.freeze
  
  acts_as_authorizable

  belongs_to :inventor, :class_name => 'User'
  belongs_to :current
  has_many :comments, :order => 'comments.created_at', :dependent => :destroy do
    def visible
      r = find :all, :include => :author, :conditions => { :hidden => false, 'users.state' => 'active' }
    end
  end
  has_many :admin_comments, :order => 'admin_comments.created_at', :dependent => :destroy
  has_many :votes, :include => :user, :dependent => :destroy do
    def for(user)
      find :first, :conditions => {:user_id => user.id}
    end
    def active
      find :all, :conditions => { 'users.state' => 'active' }
    end
  end
  has_many :voters, :through => :votes, :source => :user, :class_name => 'User'
  has_and_belongs_to_many :tags, :order => 'name'
  has_and_belongs_to_many :admin_tags, :order => 'name', :join_table => :ideas_admin_tags
  belongs_to :life_cycle_step
  belongs_to :duplicate_of, :class_name => 'Idea'
  has_many :duplicates, :class_name => 'Idea', :foreign_key => 'duplicate_of_id', :dependent => :nullify do
    def visible
      find :all, :include => :inventor, :conditions => { :hidden => false, 'users.state' => 'active' }
    end
  end
  has_and_belongs_to_many :subscribers, :join_table => 'ideas_subscribers', :class_name => 'User'
  
  validates_presence_of :title, :description
  validates_associated :current
  validates_presence_of :status
  validates_inclusion_of :status, :in => STATES, :allow_nil=>true
  validates_length_of :title, :maximum => 120, :if => lambda { |idea| idea.title }
  
  validate :current_not_closed

  before_save :make_tages_unique
  after_save  :record_contribution
  
  def current_not_closed
    errors.add_to_base("You are trying to add/update an idea in a closed current.  That's not allowed.") if closed?
  end
  
  attr_writer :comment_count
  
  include InappropriateFlag
  include SpamFiltering

  def spam_filtering_user
    inventor
  end
  
  def spam_filtering_text
    "#{title}\n#{description}"
  end
  
  def after_create
    send_later :check_spam!
  end
  
  #unless !Idea.table_exists?   
  #! acts_as_tsearch :fields => ['title', 'description',
  #  '(select array_agg(tags.name)::TEXT
  #      from ideas_tags left outer join tags on ideas_tags.tag_id = tags.id
  #     where ideas_tags.idea_id = ideas.id)',
  #  '(select array_agg(admin_tags.name)::TEXT
  #      from ideas_admin_tags left outer join admin_tags on ideas_admin_tags.admin_tag_id = admin_tags.id
  #     where ideas_admin_tags.idea_id = ideas.id)']
  #end

  def self.populate_comment_counts(ideas)
    comment_counts = Comment.find :all,
      :select => 'count(*) as comment_count, idea_id',
      :joins => "INNER JOIN users ON users.id = comments.author_id",
      :conditions => ['idea_id in (?) and hidden = ? and users.state = ?', ideas.map{ |i| i.id }, false, 'active'],
      :group => 'idea_id'
    counts_by_id = Hash.new(0)
    comment_counts.each do |c|
      counts_by_id[c.idea_id] = c.comment_count.to_i
    end
    ideas.each do |idea|
      idea.comment_count = counts_by_id[idea.id]
    end
  end
  
  def update_vote_count
    self.vote_count = votes.active.size
  end
  
  def tag_names
    tags.map{ |tag| tag.name }.sort.join(', ')
  end
  
  def tag_names=(tag_names)
    self.tags = Tag.from_string(tag_names)
  end
  
  def admin_tag_names
    admin_tags.map{ |tag| tag.name }.join(', ')
  end
  
  def admin_tag_names=(tag_names)
    self.admin_tags = AdminTag.from_string(tag_names)
  end
  
  def add_vote!(user)
    transaction do
      user.lock!
      lock!
      unless votes.for(user)
        vote = votes.create!(:user => user)
        if user.active?
          vote.count!
          reload  # because dumb old ActiveRecord aliases the idea inside vote.count!
        end
        if user.id != inventor_id
          user.record_contribution! :vote
        end
        vote
      end
    end
  end
  
  def add_duplicate!(child)
    transaction do
        return if child.duplicate_of
        parent = self  # for clarity
        
        unless child.duplicate_ids.empty?
          raise "Cannot make idea #{child.id} a duplicate child, because it is already a duplicate parent to ideas #{child.duplicate_ids.inspect}"
        end
        
        users_voting_for_both = 0.0
        child.votes.each do |vote|
          if parent.voters.include? vote.user
            users_voting_for_both += 1
          else
            # Do NOT use add_vote!, because we want to copy the potentially decayed rating of the child over,
            # instead of making these old votes all count afresh (and thus be overvalued).
            parent.votes.create! :user => vote.user
          end
        end
        
        # When merging votes, we can't actually disentangle the parent and child votes if any users voted for both.
        # As an approximation, we prorate the child's rating according to the percentage of child voters who also
        # voted for the parent. This does a reasonable job of preventing overscoring of the parent after the merge,
        # while still roughly respecting the time-dependent voting system. -PPC
        
        child.rating *= 1 - users_voting_for_both / child.votes.count unless child.votes.empty?
        child.duplicate_of = parent
        child.save!
        
        parent.rating += child.rating
        parent.save!
    end
  end
  
  def remove_duplicate!(child)
    transaction do
      return unless child.duplicate_of == self
      parent = self
      
      child.votes.each do |vote|
        parent_vote = parent.votes.for(vote.user)
        parent_vote.destroy if parent_vote
      end
      
      parent.rating -= child.rating
      parent.save!
      child.duplicate_of = nil
      child.save!
    end
  end
  
  def description_excerpt(excerpt_size = 400)
    desc_compact = description.gsub(/\s+/, ' ')  # Remove line breaks & extra space for compact excerpt
    if desc_compact.length <= excerpt_size
      desc_compact
    else
      desc_compact[0...excerpt_size-3] + '...'  # TODO: respect word boundaries
    end
  end
  
  def comment_count
    @comment_count ||= (attributes[:comment_count] || comments.visible.size)
  end
  
  def make_tages_unique
    self.tags.uniq!
    update_vote_count
    self.current_id = Current::DEFAULT_CURRENT_ID unless current_id
  end
  
  def record_contribution
    if inventor && inventor_id_change && !@contribution_recorded
      inventor.record_contribution! :idea
      @contribution_recorded = true  # prevents double-recording when callbacks cause a reentrant save
    end
    notify_subscribers!
  end
  
  def visible?
    !hidden && inventor && inventor.active?
  end
  
  def life_cycle
    life_cycle_step.nil? ? nil : life_cycle_step.life_cycle
  end
  
  def closed?
    !current.nil? && self.current.closed_or_expired?
  end
    
  def editing_expired?
    created_at < 15.minutes.ago
  end
  
  def editable_by?(user)
    user == inventor && !editing_expired?
  end
  
  def should_notify_subscribers?
    spam_checked? && visible?
  end
  
  def notify_subscribers!
    if !notifications_sent? && current && should_notify_subscribers?
      current.subscribers.each do |subscriber|
        Delayed::Job.enqueue IdeaNotificationJob.new(subscriber, self)
      end
      self.notifications_sent = true
      self.save!
    end
  end
  
end
