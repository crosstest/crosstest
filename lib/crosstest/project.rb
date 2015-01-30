module Crosstest
  class Project < Crosstest::Core::Dash
    include Crosstest::Core::Logging
    include Crosstest::Core::FileSystem

    class GitOptions < Crosstest::Core::Dash
      required_field :repo, String
      field :branch, String
      field :to, String

      def initialize(data)
        data = { repo: data } if data.is_a? String
        super
      end
    end

    field :name, String
    field :basedir, Pathname, required: true
    field :language, String
    field :git, GitOptions

    alias_method :cwd, :basedir

    attr_accessor :psychic

    def psychic
      @psychic ||= Crosstest::Psychic.new(cwd: basedir, logger: logger)
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
      target_dir = Crosstest::Core::FileSystem.relativize(target_dir, Crosstest.basedir)
      if File.exist? target_dir
        logger.info "Skipping clone because #{target_dir} already exists"
      else
        clone_cmd = "git clone #{git.repo} -b #{branch} #{target_dir}"
        logger.info "Cloning: #{clone_cmd}"
        Crosstest.global_runner.execute(clone_cmd)
      end
    end

    def task(task_name, opts = { fail_if_missing: true })
      banner_msg = opts[:custom_banner] || "Running task #{task_name} for #{name}"
      banner banner_msg
      fail "Project #{name} has not been cloned" unless cloned?
      psychic.task(task_name).execute
    rescue Crosstest::Psychic::TaskNotImplementedError => e
      if opts[:fail_if_missing]
        logger.error("Could not run task #{task_name} for #{name}: #{e.message}")
        raise ActionFailed.new("Failed to run task #{task_name} for #{name}: #{e.message}", e)
      else
        logger.warn "Skipping #{task_name} for #{name}, no #{task_name} task exists"
      end
    end

    def bootstrap
      task('bootstrap', custom_banner: "Bootstrapping #{name}", fail_if_missing: false)
    end

    def cloned?
      File.directory? basedir
    end
  end
end
