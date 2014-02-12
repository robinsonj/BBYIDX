class AddDeviseToUsers < ActiveRecord::Migration
  # def self.up
  #   change_table(:users) do |t|
  #     ## Database authenticatable
  #     t.string :email,              :null => false, :default => ""
  #     t.string :encrypted_password, :null => false, :default => ""

  #     ## Recoverable
  #     t.string   :reset_password_token
  #     t.datetime :reset_password_sent_at

  #     ## Rememberable
  #     t.datetime :remember_created_at

  #     ## Trackable
  #     t.integer  :sign_in_count, :default => 0, :null => false
  #     t.datetime :current_sign_in_at
  #     t.datetime :last_sign_in_at
  #     t.string   :current_sign_in_ip
  #     t.string   :last_sign_in_ip

  #     ## Confirmable
  #     # t.string   :confirmation_token
  #     # t.datetime :confirmed_at
  #     # t.datetime :confirmation_sent_at
  #     # t.string   :unconfirmed_email # Only if using reconfirmable

  #     ## Lockable
  #     # t.integer  :failed_attempts, :default => 0, :null => false # Only if lock strategy is :failed_attempts
  #     # t.string   :unlock_token # Only if unlock strategy is :email or :both
  #     # t.datetime :locked_at


  #     # Uncomment below if timestamps were not included in your original model.
  #     # t.timestamps
  #   end

  #   add_index :users, :email,                :unique => true
  #   add_index :users, :reset_password_token, :unique => true
  #   # add_index :users, :confirmation_token,   :unique => true
  #   # add_index :users, :unlock_token,         :unique => true
  # end

  # def self.down
  #   # By default, we don't want to make any assumption about how to roll back a migration when your
  #   # model already existed. Please edit below which fields you would like to remove in this migration.
  #   raise ActiveRecord::IrreversibleMigration
  # end

    def self.up
    #remove_column :users, :name
    change_column :users, :email, :string, :default => "", :null => false, :limit => 128
    rename_column :users, :crypted_password, :encrypted_password
    change_column :users, :encrypted_password, :string, :limit => 128, :default => "", :null => false
    rename_column :users, :salt, :password_salt
    change_column :users, :password_salt, :string, :default => "", :null => false, :limit => 255
    add_column :users, :reset_password_token, :string
    change_column :users, :remember_token, :string, :limit => 255
    rename_column :users, :remember_token_expires_at, :remember_created_at

    add_column :users, :sign_in_count, :integer, :default => 0
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string

    rename_column :users, :activation_code, :confirmation_token
    change_column :users, :confirmation_token, :string, :limit => 255
    rename_column :users, :activated_at, :confirmed_at

    add_column :users, :confirmation_sent_at, :datetime
  end

  def self.down
    #add_column :users, :name, :string, :limit => 100, :default => ""
    rename_column :users, :encrypted_password, :crypted_password
    change_column :users, :crypted_password, :string, :limit => 40
    rename_column :users, :password_salt, :salt
    change_column :users, :salt, :string, :limit => 40
    remove_column :users, :reset_password_token
    change_column :users, :remember_token, :string, :limit => 40
    rename_column :users, :remember_created_at, :remember_token_expires_at

    remove_column :users, :sign_in_count
    remove_column :users, :current_sign_in_at
    remove_column :users, :last_sign_in_at
    remove_column :users, :current_sign_in_ip
    remove_column :users, :last_sign_in_ip

    rename_column :users, :confirmation_token, :activation_code
    change_column :users, :confirmation_token, :string, :limit => 40
    rename_column :users, :confirmed_at, :activated_at

    remove_column :users, :confirmation_sent_at
  end
end
