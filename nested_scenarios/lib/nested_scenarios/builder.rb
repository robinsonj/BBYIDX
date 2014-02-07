require 'fileutils'

class Object
  def scenario(scenario, &block)
    if block.nil?
      raise NoMethodError, "undefined method `scenario' for #{inspect}"
    else
      NestedScenarios::Builder.new(scenario, &block).build
    end
  end

  alias_method :build_scenario, :scenario
end

class NestedScenarios::Builder
  @@select_sql = "SELECT * FROM %s"

  def self.build_all
    files = []
    files += Dir.glob(NestedScenarios::Builder.fixtures_dir + '/**/scenario.rb')
    files += Dir.glob(NestedScenarios::Builder.fixtures_dir + '/**/scenarios.rb')

    files.each do |scenario_rb|
      puts "Reading #{scenario_rb.gsub(RAILS_ROOT, '')} scenario file:"
      require scenario_rb
      puts
    end
  end

  def self.rebuild_all_if_needed(scenario)
    @scenario = scenario
    unless @automatic_build_checked
      self.build_all if self.scenarios_file_changed?
      @automatic_build_checked = true
    end
  end

  def self.fixtures_dir(*paths)
    File.join(RAILS_ROOT, spec_or_test_dir, 'fixtures', *paths)
  end

  def self.spec_or_test_dir
    File.exists?(File.join(RAILS_ROOT, 'spec')) ? 'spec' : 'test'
  end

  def self.fixtures_dir_exists?(dir = @scenario)
    File.exists? self.fixtures_dir(dir)
  end

  def self.fixture_file_exists?
    File.exists? fixture_file
  end

  def self.scenarios_file_changed?
    can_trigger_rebuild = [
      self.fixtures_dir('scenarios.rb'),
      File.join(RAILS_ROOT, 'db', 'migrate')
    ]

    can_trigger_rebuild.any? { |file| self.older_than_scenario? file }
  end

  def self.older_than_scenario?(file)
    scenario_dir = self.fixtures_dir(@scenario.to_s)
    return true unless File.exists?(scenario_dir) # it has been deleted!
    if File.exists?(file)
      rebuild = File.mtime(file) > File.mtime(scenario_dir)
      puts "Rebuilding Nested Scenarios: #{file} is newer than #{scenario_dir}" if rebuild
      rebuild
    end
  end

  def initialize(scenario, &block)
    case scenario
      when Hash
        @scenario = scenario.join('/')
      when Symbol, String
        @scenario = scenario.to_s
      else
        raise "I don't know how to build `#{scenario.inspect}'"
    end

    @block        = block
    @custom_names = {}
  end

  def build
    say "Building scenario `#{@scenario}'"
    NestedScenarios.delete_tables

    surface_errors { instance_eval(&@block) }
    FileUtils.mkdir_p self.class.fixtures_dir(@scenario)
    FileUtils.touch self.class.fixtures_dir(@scenario)

    dump_tables
  end

  def names_from_ivars!
    instance_values.each do |var, value|
      name(var, value) if value.is_a? ActiveRecord::Base
    end
  end

  protected

  def say(*messages)
    puts messages.map { |message| "=> #{message}" }
  end

  def write_fixture_file(fixture_data)
    File.open(fixture_file, 'w') do |file|
      file.write fixture_data.to_yaml
    end
  end

  def fixture_file
    self.class.fixtures_dir(@scenario, "#{@table_name}.yml")
  end

  def surface_errors
    yield
  rescue Object => error
    puts
    say "There was an error building scenario `#{@scenario}'", error.inspect
    puts
    puts error.backtrace
    puts
    exit!
  end

  def name(custom_name, model_object)
    key = [model_object.class.name, model_object.id]
    @custom_names[key] = custom_name
    model_object
  end

  def record_name(record_hash)
    key = [@table_name.classify, record_hash['id'].to_i]
    @record_names << (name = @custom_names[key] || inferred_record_name(record_hash) )
    name
  end

  def inferred_record_name(record_hash)
    NestedScenarios.record_name_fields.each do |try|
      if name = record_hash[try]
        inferred_name = name.underscore.gsub(/\W/, ' ').squeeze(' ').tr(' ', '_')
        count = @record_names.select { |name| name =~ /#{inferred_name}(_\d+)?/ }.size
        return count.zero? ? inferred_name : "#{inferred_name}_#{count}"
      end
    end

    "#{@table_name}_#{@row_index.succ!}"
  end

  def dump_tables
    fixtures = NestedScenarios.tables.inject([]) do |files, table_name|
      @table_name = table_name
      rows = ActiveRecord::Base.connection.select_all(@@select_sql % @table_name)
      next files if rows.empty?

      @row_index      = '000'
      @record_names = []
      fixture_data = rows.inject({}) do |hash, record|
        hash.merge(record_name(record) => record)
      end

      write_fixture_file fixture_data

      files + [File.basename(fixture_file)]
    end
    say "Built scenario `#{@scenario}' with #{fixtures.to_sentence}"
  end
end
