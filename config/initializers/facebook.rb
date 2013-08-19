if BBYIDX::FACEBOOK_ENABLED
  if ENV['FACEBOOK_APP_ID']
    Facebooker2.configuration = {
      :app_id  => ENV['FACEBOOK_APP_ID'],
      :api_key => ENV['FACEBOOK_API_KEY'],
      :secret  => ENV['FACEBOOK_APP_SECRET'] }
  else
    Facebooker2.load_facebooker_yaml
  end
end
