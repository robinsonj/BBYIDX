require 'digest/sha1'

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  acts_as_authorized_user
  acts_as_authorizable

  # Virtual attribute for the unencrypted password
  attr_accessor :password

  has_many :ideas, :foreign_key => 'inventor_id' do
    def recent_visible(opts = {})
      Idea.populate_comment_counts(
        find :all, opts.reverse_merge(
          :conditions => { :hidden => false, 'users.state' => 'active' },
          :include => [:tags, :inventor],
          :order => 'ideas.created_at desc',
          :limit => 10))
    end
  end
  has_many :currents, :foreign_key => 'inventor_id'
  has_many :comments, :foreign_key => 'author_id' do
    def recent_visible(opts = {})
      find :all, opts.reverse_merge(
        :conditions => { 'comments.hidden' => false, 'ideas.hidden' => false, 'users.state' => 'active' },
        :include => [:idea, :author],
        :order => 'comments.created_at desc',
        :limit => 10)
    end
  end
  has_many :votes do
    def recent_visible(opts = {})
      find :all, opts.reverse_merge(
        :include => { :idea => :inventor },
        :conditions => { 'ideas.hidden' => false, 'users.state' => 'active' },
        :order => 'votes.id desc',
        :limit => 10)
    end
  end
  has_and_belongs_to_many :life_cycle_steps, :join_table => 'life_cycle_steps_admins', :order => 'life_cycle_id, position'
  belongs_to :postal_code
  has_many :roles_users, :dependent => :delete_all
  has_many :roles, :through => :roles_users do
    def for_name(name)
      find :all, :conditions => { :name => name }
    end
  end
  has_and_belongs_to_many :subscribed_ideas,    :class_name => 'Idea',    :join_table => 'ideas_subscribers'
  has_and_belongs_to_many :subscribed_currents, :class_name => 'Current', :join_table => 'currents_subscribers'

  # OAuth support
  has_many :client_applications
  has_many :tokens, :class_name => 'OauthToken', :order => 'authorized_at desc', :include => [:client_application]

  validates_presence_of     :name
  validates_presence_of     :email
  validates_presence_of     :zip_code
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_confirmation_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :name,     :within => 4..100
  validates_length_of       :email,    :within => 3..100
  validates_format_of       :email,    :with => /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i
  validates_uniqueness_of   :email, :case_sensitive => false
  validates_acceptance_of   :terms_of_service, :allow_nil => false, :if => 'new_record?'
  before_save :encrypt_password, :assign_postal_code

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :name, :email, :password, :password_confirmation, :zip_code, :terms_of_service, :tweet_ideas, :facebook_post_ideas, :notify_on_comments, :notify_on_state

  unless !User.table_exists?
    acts_as_tsearch :fields => %w(name email zip_code )
  end

  include AASM

  aasm do
    state :passive
    state :pending, :enter => :registered, :inital => true
    state :active,  :enter => :do_activate
    state :suspended
    state :deleted, :enter => :do_delete

    event :register do
      transitions :from => :passive, :to => :pending, :guard => Proc.new {|u| !(u.crypted_password.blank? && u.password.blank?) }
    end

    event :activate do
      transitions :from => :pending, :to => :active
    end

    event :suspend do
      transitions :from => [:passive, :pending, :active], :to => :suspended
    end

    event :delete do
      transitions :from => [:passive, :pending, :active, :suspended], :to => :deleted
    end

    event :unsuspend do
      transitions :from => :suspended, :to => :active,  :guard => Proc.new { |u| !u.activated_at.blank? }
      transitions :from => :suspended, :to => :pending, :guard => Proc.new { |u| !u.activation_code.blank? }
      transitions :from => :suspended, :to => :passive
    end
  end

##########

  # Old authentication plugin

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  # def self.authenticate(email, password)
  #   return nil unless user = find_by_login(email, password)
  #   user.active? ? user : nil
  # end

  # # Authenticates a user's login & password without checking that they are active.
  # def self.find_by_login(email, password)
  #   u = find :first, :conditions => {:email => email} # need to get the salt
  #   u && u.authenticated?(password) ? u : nil
  # end

  # def self.find_top_contributors(all_time = false, opts = {})
  #   find :all, opts.reverse_merge(
  #     :conditions => [
  #       'state = ? and (select count(*) from roles_users where roles_users.user_id = users.id) = 0', 'active'],
  #     :order => all_time ? 'contribution_points desc' : 'recent_contribution_points desc')
  # end

  # # Encrypts some data with the salt.
  # def self.encrypt(password, salt)
  #   Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  # end

  # # Encrypts the password with the user salt
  # def encrypt(password)
  #   self.class.encrypt(password, salt)
  # end

  # def authenticated?(password)
  #   crypted_password == encrypt(password)
  # end

##########

  # def remember_token?
  #   remember_token_expires_at && Time.now.utc < remember_token_expires_at
  # end

  # # These create and unset the fields required for remembering users between browser closes
  # def remember_me
  #   remember_me_for 2.weeks
  # end

  # def remember_me_for(time)
  #   remember_me_until time.from_now.utc
  # end

  # def remember_me_until(time)
  #   self.remember_token_expires_at = time
  #   self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
  #   save(:validate => false)
  # end

  # def forget_me
  #   self.remember_token_expires_at = nil
  #   self.remember_token            = nil
  #   save(:validate => false)
  # end

  # Returns true if the user has just been activated.
  def recently_activated?
    @recently_activated
  end

  def clear_recently_activated
    @recently_activated = false
  end

  def reset_activation_code
    self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end

  def admin?
    self.has_role? 'admin'
  end
  alias_method :admin, :admin?

  def admin=(new_admin)
    if(new_admin)
      self.has_role 'admin'
    else
      self.has_no_role 'admin'
    end
  end

  def record_contribution!(contrib_type)
    score = CONTRIBUTION_SCORES[contrib_type]
    raise "Unknown contribution type: #{contrib_type.inspect}" unless score
    transaction do
      lock!
      self.contribution_points        = (contribution_points || 0) + score
      self.recent_contribution_points = (recent_contribution_points || 0) + score
      save!
    end
  end

  def recalculate_contribution_points
    self.contribution_points = (
      CONTRIBUTION_SCORES[:idea]    * ideas.recent_visible(:limit => nil).count +
      CONTRIBUTION_SCORES[:comment] * comments.recent_visible(:limit => nil).count +
      CONTRIBUTION_SCORES[:vote]    * votes.count)
  end

  def linked_to_twitter?
    !(twitter_token.blank? || twitter_secret.blank? || twitter_handle.blank?)
  end

  def twitter_is_only_auth_method?
    linked_to_twitter? && !linked_to_facebook? && crypted_password.blank?
  end

  def unlink_twitter
    self.twitter_token = self.twitter_secret = self.twitter_handle = nil
    self.tweet_ideas = false
  end

  def linked_to_facebook?
    !(facebook_uid.blank? || facebook_access_token.blank?)
  end

  def facebook_is_only_auth_method?
    linked_to_facebook? && !linked_to_twitter? && crypted_password.blank?
  end

  def unlink_facebook
    self.facebook_uid = self.facebook_access_token = self.facebook_name = nil
    self.facebook_post_ideas = false
  end

  def count_votes
    votes.each { |vote| vote.count! }  # Only affects votes not already counted
  end

  protected
    # before filter
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") if new_record?
      self.crypted_password = encrypt(password)
    end

    def password_required?
      return true unless password_confirmation.blank?
      return false if linked_to_twitter? || linked_to_facebook?
      crypted_password.blank? || !password.blank? || !password_confirmation.blank?
    end

    def password_confirmation_required?
      !password.blank?
    end

    def registered
      self.deleted_at = nil
      reset_activation_code unless linked_to_twitter? || linked_to_facebook?
      save!
    end

    def do_delete
      self.deleted_at = Time.now.utc
    end

    def do_activate
      @recently_activated = true
      self.activated_at = Time.now.utc
      self.deleted_at = self.activation_code = nil
    end

    def assign_postal_code
      self.postal_code = PostalCode.find_by_text(zip_code)
    end
end
