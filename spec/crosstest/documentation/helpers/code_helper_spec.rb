module Crosstest
  module Code2Doc
    module Helpers
      describe CodeHelper do
        let(:project) { Fabricate(:project) }
        let(:scenario) do
          Fabricate(:scenario_definition, name: @source_file).build(project).tap do | scenario |
            scenario.source_file = @source_file
          end
        end
        let(:source) do
          %q(
            # This snippet should not be in the output.
            puts "Random: #{rand}"

            # Snippet: Hello, world!
            puts 'Hello, world!'

            # Nor should this snippet
            puts 'Done'
                    )
        end
        let(:expected_snippet) do
          "
            puts 'Hello, world!'
                    "
        end

        around do | example |
          with_files(source: source) do | files |
            @source_file = files.first
            example.run
          end
        end

        describe '#snippet_after' do
          it 'returns the code block after the match (string)' do
            snippet = scenario.snippet_after 'Snippet: Hello, world!'
            expect(snippet.strip).to eq(expected_snippet.strip)
          end

          it 'returns the code block after the match (regex)' do
            snippet = scenario.snippet_after(/Snippet: .*/)
            expect(snippet.strip).to eq(expected_snippet.strip)
          end

          it 'returns nothing if no match is found' do
            snippet = scenario.snippet_after 'Nothing matches'
            expect(snippet).to be_empty
          end
        end

        describe '#snippet_between' do
          # Yes, whitespace doesn't work very well w/ snippet_between
          let(:expected_snippet) do
            %q(
           puts "Random: #{rand}"
# Snippet: Hello, world!
            puts 'Hello, world!'
                        )
          end

          it 'inserts all code blocks between the matching regexes' do
            snippet = scenario.snippet_between 'This snippet should not be in the output', 'Nor should this snippet'
            expect(snippet.strip).to eq(expected_snippet.strip)
          end

          it 'inserts nothing unless both matches are found' do
            # Neither match
            snippet = scenario.snippet_between 'foo', 'bar'
            expect(snippet.strip).to be_empty

            # First matches
            snippet = scenario.snippet_between 'This snippet should not be in the output', 'foo'
            expect(snippet.strip).to be_empty

            # Last matches
            snippet = scenario.snippet_between 'foo', 'Nor should this snippet'
            expect(snippet.strip).to be_empty
          end

        end

        describe '#code_block' do
          it 'generates markdown code blocks by default' do
            expected = "```ruby\n" + source + "\n```\n"
            code_block = scenario.code_block(scenario.source, 'ruby')
            expect(code_block).to eq(expected)
          end

          it 'generates rst for format :rst' do
            indented_source = source.lines.map do|line|
              "  #{line}"
            end.join("\n")
            expected = ".. code-block:: ruby\n" + indented_source + "\n"
            code_block = scenario.code_block(scenario.source, 'ruby', format: :rst)
            expect(code_block).to eq(expected)
          end
        end

        def generate_doc_for(template_file, source_file)
          doc_gen = DocumentationGenerator.new(template_file, 'testing')
          scenario = Fabricate(:scenario_definition, name: 'test').build(project)
          scenario.source_file = source_file
          doc_gen.process(scenario)
        end

        def with_files(files)
          tmpfiles = []
          begin
            files.each do |k, v|
              file = Tempfile.new(k.to_s)
              file.write(v)
              file.close
              tmpfiles << file
            end
            yield tmpfiles.map(&:path)
          ensure
            tmpfiles.each(&:unlink)
          end
        end

      end
    end
  end
end
