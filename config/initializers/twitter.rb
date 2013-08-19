if BBYIDX::TWITTER_ENABLED
  TWITTER_CONFIG = if ENV['TWITTER_API_KEY']
    { 'key'    => ENV['TWITTER_API_KEY'],
      'secret' => ENV['TWITTER_API_SECRET'] }
  else
    YAML.load(File.read(Rails.root.to_s + '/config/' + 'twitter.yml'))[RAILS_ENV]
  end
end
