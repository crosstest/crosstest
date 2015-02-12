module Crosstest
  module Command
    class Generate < Thor
      namespace :generate

      autoload :Dashboard, 'crosstest/command/generators/dashboard'
      register Dashboard, 'dashboard', 'dashboard', 'Create a report dashboard'
      tasks['dashboard'].options = Dashboard.class_options

      autoload :Code2Doc, 'crosstest/command/generators/code2doc'
      register Code2Doc, 'code2doc', 'code2doc [PROJECT|REGEXP|all] [SCENARIO|REGEXP|all]',
               'Generates documenation from sample code for one or more scenarios'
      tasks['code2doc'].options = Command::Generate::Code2Doc.class_options

      autoload :Documentation, 'crosstest/command/generators/documentation'
      register Documentation, 'generate', 'generate', 'Generates documentation, reports or other files from templates'
      tasks['generate'].options = Documentation.class_options
      tasks['generate'].long_description = <<-eos
      Generates documentation, reports or other files from templates. The templates may use Thor actions and Padrino helpers
      in order to inject data from Crosstest test runs, code samples, or other sources.

      Available templates: #{Command::Generate::Documentation.generator_names.join(', ')}
      You may also run it against a directory containing a template with the --source option.
      eos

      # FIXME: Help shows unwanted usage, e.g. "crosstest crosstest:command:report:code2_doc"
    end
  end
end
