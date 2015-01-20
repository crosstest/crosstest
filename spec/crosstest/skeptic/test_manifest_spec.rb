module Crosstest
  module Skeptic
    describe TestManifest do
      describe '#from_yaml' do
        subject(:manifest) { described_class.from_yaml 'spec/fixtures/skeptic.yaml' }

        it 'initializes a manifest' do
          expect(manifest).to be_an_instance_of TestManifest
        end

        it 'processes ERB' do
          expect(manifest.global_env.LOCALE).to eq(ENV['LANG'])
        end

        it 'parses global_env' do
          expect(manifest.global_env).to be_an_instance_of TestManifest::Environment
        end

        it 'parses suites' do
          expect(manifest.suites).to be_an_instance_of ::Hash
          manifest.suites.each_value do | suite |
            expect(suite).to be_an_instance_of TestManifest::Suite
          end
        end
      end
    end
  end
end
