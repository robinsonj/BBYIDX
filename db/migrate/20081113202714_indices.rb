class Indices < ActiveRecord::Migration
  def self.up
    add_index :comments, :author_id
    add_index :comments, :idea_id
    add_index :ideas, :inventor_id
    add_index :ideas_admin_tags, :idea_id
    add_index :ideas_admin_tags, :admin_tag_id
    add_index :ideas_tags, :tag_id
    add_index :ideas_tags, :idea_id
    add_index :tags, :name
    add_index :users, :state
    add_index :users, :email, :unique=>true
    add_index :votes, [:user_id, :idea_id], :unique=>true
  end

  def self.down
    remove_index :tags, :name
    remove_index :comments, :author_id
    remove_index :comments, :idea_id
    remove_index :ideas, :inventor_id
    remove_index :ideas_admin_tags, :idea_id
    remove_index :ideas_admin_tags, :admin_tag_id
    remove_index :ideas_tags, :tag_id
    remove_index :ideas_tags, :idea_id
    remove_index :users, :state
    remove_index :users, :email
    remove_index :votes, [:user_id, :idea_id]
  end
end
