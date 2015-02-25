module Omnitest
  class Project < Omnitest::Core::Dash
    include Omnitest::Core::Logging
    include Omnitest::Core::FileSystem

    class GitOptions < Omnitest::Core::Dash
      required_field :repo, String
      field :branch, String
      field :to, String

      def initialize(data)
        data = { repo: data } if data.is_a? String
        super
      end
    end

    field :name, String
    field :basedir, Pathname
    field :language, String
    field :git, GitOptions

    alias_method :cwd, :basedir

    attr_accessor :psychic, :skeptic

    def psychic
      @psychic ||= Omnitest::Psychic.new(name: name, cwd: basedir, logger: logger, travis: Omnitest.configuration.travis)
    end

    def skeptic
      @skeptic ||= Omnitest::Skeptic.new(psychic)
    end

    def execute(*args)
      psychic.execute(*args)
    end

    def basedir
      self[:basedir] ||= "projects/#{name}"
    end

    def logger
      @logger ||= Omnitest.new_logger(self)
    end

    def clone
      if git.nil? || git.repo.nil?
        logger.info 'Skipping clone because there are no git options'
        return
      end
      branch = git.branch ||= 'master'
      target_dir = git.to ||= basedir
      target_dir = Omnitest::Core::FileSystem.relativize(target_dir, Omnitest.basedir)
      if File.exist? target_dir
        logger.info "Skipping clone because #{target_dir} already exists"
      else
        clone_cmd = "git clone #{git.repo} -b #{branch} #{target_dir}"
        logger.info "Cloning: #{clone_cmd}"
        Omnitest.psychic.execute(clone_cmd)
      end
    end

    def task(task_name, opts = { fail_if_missing: true })
      banner_msg = opts[:custom_banner] || "Running task #{task_name} for #{name}"
      banner banner_msg
      fail "Project #{name} has not been cloned" unless cloned?
      psychic.task(task_name).execute
    rescue Omnitest::Psychic::TaskNotImplementedError => e
      if opts[:fail_if_missing]
        logger.error("Could not run task #{task_name} for #{name}: #{e.message}")
        raise ActionFailed.new("Failed to run task #{task_name} for #{name}: #{e.message}", e)
      else
        logger.warn "Skipping #{task_name} for #{name}, no #{task_name} task exists"
      end
    end

    def workflow(workflow_name)
      workflow_definition = Omnitest.configuration.project_set.workflows[workflow_name]
      fail UserError, "Workflow '#{workflow_name}' is not defined" if workflow_definition.nil?

      workflow = psychic.workflow(workflow_name) do
        workflow_definition.tasks.each do | task_name |
          task task_name
        end
      end

      workflow.execute
    rescue Psychic::TaskNotImplementedError => e
      raise UserError, "Cannot run workflow '#{workflow_name}' for project '#{name}': #{e.message}"
    end

    def bootstrap
      task('bootstrap', custom_banner: "Bootstrapping #{name}", fail_if_missing: false)
    end

    def cloned?
      File.directory? basedir
    end
  end
end
