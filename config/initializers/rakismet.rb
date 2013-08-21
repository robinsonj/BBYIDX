BBYIDX::Application.config.rakismet.key = Rails.env.test? ? 'test' : ENV['RAKISMET_KEY']
BBYIDX::Application.config.rakismet.url = BBYIDX::RAKISMET_URL
BBYIDX::Application.config.rakismet.host = 'rest.akismet.com'
