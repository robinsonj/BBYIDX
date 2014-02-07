class Fixtures < (RUBY_VERSION < '1.9' ? YAML::Omap : Hash)
  cattr_accessor :current_fixtures
  cattr_accessor :current_test_class

  def self.destroy_fixtures(table_names)
    NestedScenarios.delete_tables(table_names)
  end

  # Support for loading root-level fixtures: fixture cache keys based on fixture path + table name.  
  def self.create_fixtures(fixtures_directory, table_names, class_names = {})
    table_names = [table_names].flatten.compact.map { |n| n.to_s }
    fixture_keys = table_names.inject({}){|collector, table_name| collector[table_name] = "#{fixtures_directory}/#{table_name}"; collector}
    connection  = block_given? ? yield : ActiveRecord::Base.connection

    table_names_to_fetch = table_names.reject { |table_name| fixture_is_cached?(connection, fixture_keys[table_name]) }
    unless table_names_to_fetch.empty?
      ActiveRecord::Base.silence do
        connection.disable_referential_integrity do
          fixtures_map = {}

          fixtures = table_names_to_fetch.map do |table_name|
            fixtures_map[fixture_keys[table_name]] = Fixtures.new(connection, File.split(table_name.to_s).last, class_names[table_name.to_sym], File.join(fixtures_directory, table_name.to_s))
          end

          all_loaded_fixtures.update(fixtures_map)

          connection.transaction(:requires_new => true) do

            # fixtures.reverse.each { |fixture| fixture.delete_existing_fixtures } # done elsewhere now
            fixtures.each { |fixture| fixture.insert_fixtures }

            # Cap primary key sequences to max(pk).
            if connection.respond_to?(:reset_pk_sequence!)
              table_names.each do |table_name|
                connection.reset_pk_sequence!(table_name)
              end
            end
          end

          cache_fixtures(connection, fixtures_map)
        end
      end
    end
    # cached_fixtures(connection, table_names)
    cached_fixtures(connection, fixture_keys.values)
  end
end

module ActiveRecord #:nodoc:
  module TestFixtures #:nodoc:

    def self.included(base)
      base.class_eval do
        setup :setup_fixtures
        teardown :teardown_fixtures

        superclass_delegating_accessor :fixture_path
        superclass_delegating_accessor :fixture_table_names
        superclass_delegating_accessor :fixture_class_names
        superclass_delegating_accessor :use_transactional_fixtures
        superclass_delegating_accessor :use_instantiated_fixtures   # true, false, or :no_instances
        superclass_delegating_accessor :pre_loaded_fixtures

        self.fixture_table_names = []
        self.use_transactional_fixtures = false
        self.use_instantiated_fixtures = true
        self.pre_loaded_fixtures = false

        self.fixture_class_names = {}

        superclass_delegating_accessor :scenario_path
        superclass_delegating_accessor :load_root_fixtures
        superclass_delegating_accessor :root_table_names
        superclass_delegating_accessor :scenario_table_names
        self.load_root_fixtures = false
        
        def all_table_names
          ((self.root_table_names || []) + (self.scenario_table_names || [])).uniq
        end
      end

      base.extend ClassMethods
    end

    module ClassMethods
      def scenario(scenario_name = nil, options = {})
        NestedScenarios::Builder.rebuild_all_if_needed(scenario_name)

        case scenario_name
          when Hash
            self.load_root_fixtures = scenario_name.delete(:root) if scenario_name.key? :root
            scenario_name = scenario_name.join('/')
          when Symbol, String
            self.load_root_fixtures = options.delete(:root) if options.key? :root
            scenario_name = scenario_name.to_s
          else
            raise ArgumentError, "Scenario must be a symbol, string or hash. You gave #{scenario_name.class}."
        end

        self.scenario_path = "#{self.fixture_path}/#{scenario_name}" if scenario_name
        self.fixtures(:all)
      end

      def fixtures(*table_names)
        if table_names.first == :all
          self.root_table_names = load_table_names_in_path(self.fixture_path)
          self.scenario_table_names = self.scenario_path ? load_table_names_in_path(self.scenario_path) : []

          table_names = self.root_table_names + self.scenario_table_names
          table_names.uniq!
        else
          table_names = table_names.flatten.map { |n| n.to_s }
        end

        self.fixture_table_names |= table_names

        require_fixture_classes(table_names)
        setup_fixture_accessors(table_names)
      end

      private

      def load_table_names_in_path(path)
        table_names = Dir["#{path}/*.yml"]# + Dir["#{path}/*.csv"] # no CSVs, please.
        table_names.map! { |f| File.basename(f).split('.')[0..-2].join('.') }
        return table_names
      end
    end

    private

    def load_fixtures
      @loaded_fixtures = {}
      current_fixtures = self.fixture_path.to_s + self.scenario_path.to_s
      if Fixtures.current_fixtures != current_fixtures
        Fixtures.current_fixtures = current_fixtures
        Fixtures.reset_cache
      end
      if self.load_root_fixtures || self.scenario_path.blank?
        root_fixtures = Fixtures.create_fixtures(self.fixture_path, self.root_table_names, fixture_class_names)
      end

      if self.scenario_path
        scenario_fixtures = Fixtures.create_fixtures(self.scenario_path, self.scenario_table_names, fixture_class_names)
      end

      [root_fixtures, scenario_fixtures].each do |fixtures|
        next if fixtures.nil?

        if fixtures.instance_of?(Fixtures)
          update_loaded_fixtures(fixtures)
        else
          fixtures.each { |f| update_loaded_fixtures(f) }
        end
      end
    end

    def update_loaded_fixtures(fixtures)
      if @loaded_fixtures[fixtures.table_name]
        fixtures.each{|fixture| @loaded_fixtures[fixtures.table_name] << fixture }
      else
        @loaded_fixtures[fixtures.table_name] = fixtures
      end
    end

    def setup_fixtures_with_scenario_check
      if (Fixtures.current_test_class != self.class || !self.use_transactional_fixtures)
        Fixtures.destroy_fixtures self.all_table_names
        Fixtures.reset_cache
      end
      Fixtures.current_test_class = self.class
      setup_fixtures_without_scenario_check
    end

    alias_method_chain :setup_fixtures, :scenario_check
  end
end
