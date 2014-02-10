# module GravatarHelper::PublicMethods
#   alias_method :gravatar_url_without_bbyidx_default, :gravatar_url

#   def gravatar_url(email, opts = {})
#     opts[:default] ||= "/images/default-avatar-#{opts[:size] || 50}.png"
#     unless opts[:default] =~ /:\/\//
#       opts[:default] = request.protocol + request.host_with_port + opts[:default]
#     end
#     gravatar_url_without_bbyidx_default(email, opts)
#   end
# end
