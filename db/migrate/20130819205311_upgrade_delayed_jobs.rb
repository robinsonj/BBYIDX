class UpgradeDelayedJobs < ActiveRecord::Migration
  def up
    add_column :delayed_jobs, :queue, :string
    add_index :delayed_jobs, [:priority, :run_at], :name => 'delayed_jobs_priority'
  end

  def down
    remove_column :delayed_jobs, :queue
    remove_index :delayed_jobs, :delayed_jobs_priority
  end
end
