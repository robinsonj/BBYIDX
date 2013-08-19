# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'
require 'rake/clean'

BBYIDX::Application.load_tasks
CLEAN.include %w(**/*.orig **/*.log **/*.rej)
# task :cron=>[:environment, "ideax:decay", "ideax:purge_spam"]
