class UserMailer < ActionMailer::Base
  
  def mail(headers, &block)
    @user = headers.delete(:user)
    
    headers[:to]      ||= "#{@user.email}"
    headers[:from]    ||= BBYIDX::EMAIL_FROM_ADDRESS
    headers[:subject]   = "[#{BBYIDX::SHORT_SITE_NAME.upcase}] #{headers[:subject]}"
    headers[:date]    ||= Time.now
    
    super(headers, &block)
  end
  
  def signup_notification(user)
    @url = activate_url(:activation_code => user.activation_code)
    mail user: user, subject: 'Please activate your new account'
  end
  
  def activation(user)
    @url= root_url
    mail user: user, subject: 'Your account has been activated!'
  end
  
  def password_reset(user)
    @url = password_reset_url(:activation_code => user.activation_code)
    mail user: user, subject: 'Password reset'
  end
  
  def password_change_notification(user)
    @url = home_url('contact')
    mail user: user, subject: 'Your password was changed'
  end
  
  def email_change_notification(user, old_email)
    @url = home_url('contact')
    mail user: user, to: old_email, subject: 'Your email was changed'
  end
  
  def comment_notification(user, comment)
    @comment = comment
    @url = idea_url(comment.idea)
    @unsubscribe_url = unsubscribe_idea_url(comment.idea)
    @owner = (user == comment.idea.inventor)
    mail user: user, subject: "New comment on idea \"#{strip_funkies(comment.idea.title)}\""
  end
  
  def idea_in_current_notification(user, idea)
    @idea = idea
    @url = idea_url(idea)
    @unsubscribe_url = unsubscribe_current_url(idea.current)
    mail user: user, subject: "New idea in current \"#{strip_funkies(idea.current.title)}\""
  end
  
  def life_cycle_notification(user, life_cycle_step)
    @life_cycle_step = life_cycle_step
    @url = admin_root_url
    mail user: user, subject: "New idea requiring attention in #{life_cycle_step.name}"
  end
  
protected

  def strip_funkies(s)
    s.gsub(/[<>&]/, '')
  end

end
