BBYIDX::Application.config.rakismet.key = ENV['RAILS_ENV'] == 'test' ? 'test' : ENV['RAKISMET_KEY']
BBYIDX::Application.config.rakismet.url = BBYIDX::RAKISMET_URL
BBYIDX::Application.config.rakismet.host = 'rest.akismet.com'
