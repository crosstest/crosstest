require 'hashie/dash'
require 'hashie/extensions/coercion'

module Crosstest
  class FeatureNotImplementedError < StandardError
    def initialize(feature)
      super "Feature #{feature} is not implemented"
    end
  end
  class Project < Crosstest::ManifestSection
    class GitOptions < Crosstest::ManifestSection
      property :repo, required: true
      property :branch
      property :to

      def initialize(data)
        data = { repo: data } if data.is_a? String
        super
      end
    end

    include Crosstest::Core::Logging
    include Crosstest::Core::FileSystem
    property :name
    property :basedir, required: true
    property :language
    coerce_key :basedir, Pathname
    property :git
    coerce_key :git, GitOptions

    attr_accessor :runner

    def initialize(data)
      data[:basedir] = File.absolute_path(data[:basedir])
      super
    end

    def runner
      @runner ||= Crosstest::Psychic.new(cwd: basedir, logger: logger)
    end

    def logger
      @logger ||= Crosstest.new_logger(self)
    end

    def clone
      if git.nil? || git.repo.nil?
        logger.info 'Skipping clone because there are no git options'
        return
      end
      branch = git.branch ||= 'master'
      target_dir = git.to ||= basedir
      if File.exist? target_dir
        logger.info "Skipping clone because #{target_dir} already exists"
      else
        clone_cmd = "git clone #{git.repo} -b #{branch} #{target_dir}"
        logger.info "Cloning: #{clone_cmd}"
        Crosstest.global_runner.execute(clone_cmd)
      end
    end

    def task(task_name, custom_banner = nil)
      if custom_banner
        banner custom_banner
      else
        banner "Running task #{task_name} for #{name}"
      end
      fail "Project #{task_name} has not been cloned" unless cloned?
      runner.execute_task(task_name)
    rescue Crosstest::Psychic::TaskNotImplementedError => e
      logger.error("Could not run task #{task_name} for #{name}: #{e.message}")
      raise ActionFailed.new("Failed to run task #{task_name} for #{name}: #{e.message}", e)
    end

    def bootstrap
      task('bootstrap', "Bootstrapping #{name}")
    rescue Crosstest::Psychic::TaskNotImplementedError
      logger.warn "Skipping bootstrapping for #{name}, no bootstrap task exists"
    end

    def build_scenario(scenario_data)
      scenario_data[:basedir] ||= basedir
      scenario_data[:project] ||= self
      scenario_data[:suite] ||= ''
      begin
        scenario_data[:source_file] ||= Core::FileSystem.find_file basedir, scenario_data[:name]
        scenario_data[:source_file] = Core::FileSystem.relativize(scenario_data[:source_file], scenario_data[:basedir])
      rescue Errno::ENOENT
        scenario_data[:source_file] = nil
      end
      Scenario.new scenario_data
    end

    def cloned?
      File.directory? basedir
    end
  end
end
