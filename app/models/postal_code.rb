class PostalCode < ActiveRecord::Base

  def self.find_by_text(text)
    text =~ /\d{5}/
    #PostalCode.find(:first, :conditions => { :code => $& })
    PostalCode.where(:code => $&).first
  end

  def readonly?
    true
  end

end
