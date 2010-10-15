require 'fastercsv'

namespace :db do
  desc "Load seed data into the current environment's database."
  task :seed => [ :environment, :'db:migrate' ] do
    PostalCode.transaction do
      
      # This reassigns IDs; find an alternative!
      # PostalCode.connection.execute("truncate postal_codes")
      if PostalCode.count > 0
        puts "Database already contains #{PostalCode.count} postal codes. Skipping postal code loading. " +
             "We'll need to fix the seed script to preserve the postal_codes.id column if we want to update the postal codes table.\n"
      else
        puts "Loading postal codes..."
        s = "insert into postal_codes (code, lat, lon) values "
        pc = []
        fname = File.join(File.dirname(__FILE__), "../../db/data/zips.csv.gz")
        raise "can't find zips.csv: #{fname}" unless File.exists? fname
        handle = Zlib::GzipReader.new(File.open(fname))
        FasterCSV.new(handle).each do |r|
          r = r.map{|x| x.gsub(/'/,'')}
          pc << PostalCode.send(:sanitize_sql_array, (["(?, ?, ?)", r[0], r[2].to_f, r[3].to_f]))
        end

        ActiveRecord::Base.connection.execute(s<<pc.join(","))
      end
      
      # Uncomment to create admin user from cmd line
      
      # admin_role = Role.find(:all, :conditions => {:name => 'admin', :authorizable_type => nil}).first
      # admin_user = admin_role.users.first if admin_role
      # if admin_user
      #   puts "Admin user already exists: #{admin_user.email}"
      # else
      #   puts "Creating admin user..."
      #   admin_email    = ask('Admin user email: ')
      #   admin_password = ask('Admin user password: ') {|q| q.echo = '*' }
      #   admin_user = User.create!(
      #     :name => "Administrator",
      #     :email => admin_email,
      #     :zip_code => DEFAULT_ZIP_CODE,
      #     :password => admin_password,
      #     :password_confirmation => admin_password,
      #     :terms_of_service => '1')
      #   
      #   puts "Granting admin privileges to #{admin_user.email}..."
      #   admin_user.activate!
      #   admin_user.has_role 'admin'
      #   admin_user.has_role 'editor', User
      #   admin_user.has_role 'editor', Idea
      #   admin_user.has_role 'editor', Comment
      #   admin_user.has_role 'editor', Current
      #   admin_user.has_role 'editor', LifeCycle
      #   admin_user.has_role 'editor', ClientApplication
      #   admin_user.save!
      # end
      
      puts "Seed complete."
    end
  end
end
