# BBYIDX - Share you ideas

BBYIDX is a free and open source idea-gathering application written in Ruby and distributed
under the GNU Affero General Public License.

## Requirements

### Rails

BBYIDX runs on Rails 2.3. It does not (yet) run on Rails 3. Don't worry about installing the correct version of
Rails and all the gems and plugins; bundler should take care of all that automatically.

### Database

The app requires PostgreSQL 8.3 or newer.

You will encounter errors on other databases. Queries use Postgres-specific syntax. Full text search won't work,
since it uses the PostgreSQL-specific tsearch plugin.

Want to run it on MySQL? We welcome patches!

## Configuration

You will first need to edit the following files to get the app running in your environemnt:

* config/bbyidx_customization.rb
* config/database.yml
* config/newrelic.yml       (if you want performance metrics from NewRelic)
* config/twitter.yml        (if you want Twitter integration)
* config/facebooker.yml     (if you want Facebook integration)

## Local Installation

1. `bundle install`
2. `bundle exec rake db:migrate`
3. `bundle exec rake db:seed`
4. `rails s`

The first time you visit the app, it will prompt you to create an admin user.

## Customization

To customize the UI, edit / create files in the following directories:

* app/views/custom/
* public/stylesheets/sass/
* public/images/

**NOTE:** UI elements that pertain to your brand need not be contributed back to the open source project.

### Running the test suite

To verify the code you have checked out:

    rake test
    
If you submit patches, please make sure that they don't break existing tests.

## Heroku Installation

The following steps* will walk you through getting BBYIDX running on Heroku, our favorite cloud platform.
These steps must be executed from the project root directory.

1. `heroku create YOUR-APP-NAME`
2. `heroku addons:add sendgrid:free` (See the [Sendgrid](http://addons.heroku.com/sendgrid) docs for plans and pricing)
3. `git push heroku master`
4. `heroku rake db:migrate`
5. `heroku restart`
6. `heroku rake db:seed`
7. `heroku open`

_* NOTE: The [heroku client library](http://rubygems.org/gems/heroku) is required for these steps._
