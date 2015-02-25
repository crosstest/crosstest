module Omnitest
  describe DocumentationGenerator do
    let(:scenario_name) { 'Quine' }
    # let(:search_path) { 'spec/fixtures/src-doc' }
    let(:bound_data) { double }

    describe 'process' do
      let(:generated_doc) { generator.process bound_data }

      context 'when template is readable' do
        subject(:generator) { DocumentationGenerator.new('spec/fixtures/src-doc/quine.md.erb', scenario_name) }

        it 'processes the template' do
          expect(generated_doc).to include 'Examples for Quine scenario:'
        end
      end

      context 'when template is not readable' do
        subject(:generator) { DocumentationGenerator.new('non_existant_file.md', scenario_name) }
        it 'processes the template' do
          expect(generated_doc).to be_nil
        end
      end
    end

    describe 'code2doc' do
      subject(:generator) { DocumentationGenerator.new }

      let(:source_code) do
        <<-eos.gsub(/^( |\t)+/, '')
        #!/usr/bin/env ruby

        # Comments are documentation
        puts 'And this is a code block'
        eos
      end

      let(:source_file) do
        file = Tempfile.new(['source', '.rb'])
        file.write source_code
        file.close
        file.path
      end

      it 'converts source code to documentation' do
        expect(generator.code2doc(source_file, 'ruby')).to eq(
          <<-eos.gsub(/^( |\t)+/, '')
          Comments are documentation

          ```ruby
          puts 'And this is a code block'
          ```

          eos
        )
      end
    end
  end
end
