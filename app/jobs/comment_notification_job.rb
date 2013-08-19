class CommentNotificationJob
  
  attr_accessor :user_id, :comment_id
  
  def initialize(user, comment)
    @user_id = user.id
    @comment_id = comment.id
  end
  
  def perform
    user = User.find(user_id)
    comment = Comment.find(comment_id)
    if comment.should_notify_subscribers?  # check again in case we were marked spam after job was schedule
      UserMailer.comment_notification(user, comment).deliver
    end
  end
  
end
