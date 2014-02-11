module SpamFiltering
  def self.included(klass)
    klass.class_eval do
      include Rakismet::Model
      rakismet_attrs  :author       => proc { spam_filtering_user.name },
                      :author_email => proc { spam_filtering_user.email },
                      :user_ip    => :ip,
                      :user_agent => :agent,
                      :content    => :spam_filtering_text,
                      :permalink  => proc { "#{Rakismet::URL}/#{self.class.name.pluralize.underscore}/#{self.id}" }

      validates_presence_of :ip, :on => :create
      validates_presence_of :user_agent, :on => :create
    end
  end

  def marked_spam=(spam)
    self[:marked_spam] = spam
    self[:hidden] = true if spam
  end

  def check_spam!
    Timeout::timeout(60) do
      self.marked_spam ||= self.spam? if Rakismet::KEY
      self.spam_checked = true
      self.save!
    end
  end

end
