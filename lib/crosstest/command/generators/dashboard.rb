require 'json'
require 'crosstest/reporters'

module Crosstest
  module Command
    class Generate
      class Dashboard < Thor::Group
        include Thor::Actions
        include Crosstest::Core::FileSystem
        module Helpers
          include Crosstest::Core::Util::String
          # include Padrino::Helpers::RenderHelpers # requires sinatra-compatible render method
          include Padrino::Helpers::TagHelpers
          include Padrino::Helpers::OutputHelpers
          include Padrino::Helpers::AssetTagHelpers

          def projects
            Crosstest.projects.map do |project|
              slugify(project.name)
            end
          end

          def results
            manifest = Crosstest.manifest
            rows = []
            grouped_scenarios = manifest.scenarios.values.group_by { |scenario| [scenario.suite, scenario.name] }
            grouped_scenarios.each do |(suite, name), scenarios|
              row = {
                slug_prefix: slugify(suite, name),
                suite: suite,
                scenario: name
              }
              Crosstest.projects.each do |project|
                scenario = scenarios.find { |c| c.project == project }
                row[slugify(project.name)] = scenario.status_description
              end
              rows << row
            end
            rows
          end

          def as_json(data)
            JSON.dump(data)
          rescue => e
            JSON.dump(to_utf(data))
          end

          def to_utf(data)
            Hash[
              data.collect do |k, v|
                if v.respond_to?(:collect)
                  [k, to_utf(v)]
                elsif v.respond_to?(:encoding)
                  [k, v.dup.encode('UTF-8')]
                else
                  [k, v]
                end
              end
            ]
          end

          def status(status, msg = nil, _color = :cyan)
            "<strong>#{status}</strong> <em>#{msg}</em>"
          end

          def bootstrap_color(color)
            bootstrap_classes = {
              green: 'success',
              cyan: 'primary',
              red: 'danger',
              yellow: 'warning'
            }
            bootstrap_classes.key?(color) ? bootstrap_classes[color] : color
          end
        end

        include Helpers

        class_option :destination, default: 'reports/'
        class_option :code_style, default: 'github'

        def self.source_root
          Crosstest::Reporters::GENERATORS_DIR
        end

        def report_name
          @report_name ||= self.class.name.downcase.split('::').last
        end

        def add_framework_to_source_root
          source_paths.map do | path |
            path << "/#{report_name}"
          end
        end

        def set_destination_root
          self.destination_root = options[:destination]
        end

        def setup
          @tabs = {}
          @tabs['Dashboard'] = 'dashboard.html'
          Crosstest.setup(options)
        end

        def create_spy_reports
          reports = Crosstest::Skeptic::Spies.reports[:dashboard]
          reports.each do | report_class |
            if report_class.respond_to? :tab_name
              @active_tab = report_class.tab_name
              @tabs[@active_tab] = report_class.tab_target
            else
              @active_tab = nil
            end
            report_class.tabs = @tabs
            invoke report_class, args, options
          end if reports
        end

        def copy_assets
          directory Crosstest::Reporters::ASSETS_DIR, 'assets'
        end

        def copy_base_structure
          @active_tab = 'Dashboard'
          directory 'files', '.'
        end

        def create_results_json
          create_file 'matrix.json', as_json(results)
        end

        def create_test_reports
          Crosstest.manifest.scenarios.values.each do |scenario|
            @scenario = scenario
            template 'templates/_test_report.html.tt', "details/#{scenario.slug}.html"
          end
        end
      end
    end
  end
end
