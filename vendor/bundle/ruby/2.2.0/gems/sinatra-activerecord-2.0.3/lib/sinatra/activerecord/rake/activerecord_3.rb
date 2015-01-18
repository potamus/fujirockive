require "active_support/string_inquirer"

module Rails
  extend self

  def root
    Pathname.new(Rake.application.original_dir)
  end

  def env
    ActiveSupport::StringInquirer.new(ENV["RACK_ENV"] || "development")
  end

  def application
    seed_loader = Object.new
    seed_loader.instance_eval do
      def load_seed
        load "db/seeds.rb"
      end
    end
    seed_loader
  end
end

Rake::Task.define_task("db:environment")
Rake::Task["db:load_config"].clear
Rake::Task.define_task("db:rails_env")
