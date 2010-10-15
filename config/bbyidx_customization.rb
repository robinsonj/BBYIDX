module BBYIDX
  COMPANY_NAME = 'YOUR_COMPANY_NAME'
  SHORT_SITE_NAME = 'BBYIDX'
  LONG_SITE_NAME = "#{COMPANY_NAME} #{SHORT_SITE_NAME}"

  PRODUCTION_HOST = 'bbyidx.com'
  STAGING_HOST = 'bbyidx.com'

  TWITTER_ENABLED = true

  # Facebook support is experimental, and currently broken. We invite you to improve it!
  FACEBOOK_ENABLED = false

  SESSION_KEY = '_ideax_session'
  SESSION_SECRET = '771febbdd045c2170c576873cbd34bc3458d5571b9d35feeafae294a389eec4e58f23f7518dfac41a9e272fffe5d88ab8ab0f523f439b71f8cd60f8b07a55616'

  CONTRIBUTION_SCORES = {
    :idea    => 10,
    :comment => 2,
    :vote    => 1
  }

  # Get ID from http://addthis.com
  ADDTHIS_ID = 'YOUR_ADDTHIS_ID'

  GOOGLE_WEBMASTER_KEY = "YOUR_GOOGLE_WEBMASTER_KEY"
end
