module Crosstest
  describe Configuration do
    subject(:configuration) { Configuration.new }

    describe '.project_set' do
      it 'parses the YAML file and registers the project set' do
        original_project_set = configuration.project_set
        configuration.project_set = 'spec/fixtures/crosstest.yaml'
        new_project_set = configuration.project_set
        expect(original_project_set).to_not eq(new_project_set)
        expect(new_project_set).to(be_an_instance_of(ProjectSet))
      end
    end

    describe '.manifest' do
      it 'parses the YAML file and registers the manifest' do
        original_manifest = configuration.skeptic.manifest
        configuration.skeptic.manifest_file = 'spec/fixtures/skeptic.yaml'
        new_manifest = configuration.skeptic.manifest
        expect(original_manifest).to_not eq(new_manifest)
        expect(new_manifest).to(be_an_instance_of(Skeptic::TestManifest))
      end
    end
  end
end
