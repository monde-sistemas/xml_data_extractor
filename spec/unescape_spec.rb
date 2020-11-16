require "yaml"
require "json"

RSpec.describe "Unescape" do
  subject { XmlDataExtractor.new(structure).parse(xml) }

  context "when the XML contains embedded escaped XML content" do
    shared_examples_for "match extracted values" do
      it { expect(JSON.pretty_generate(subject)).to eq JSON.pretty_generate(expected_result) }
    end
  
    let(:xml) do
      <<~XML
        <xml>
          <response>&lt;root&gt;&lt;error&gt;&lt;message&gt;Something went wrong&lt;/message&gt;&lt;/error&gt;&lt;/root&gt;</response>
        </xml>
      XML
    end
  
    let(:yml) do
      <<~YML
        schemas:
          error:
            unescape: response
            message: root/error/message
      YML
    end
    let(:structure) { YAML.safe_load(yml).deep_symbolize_keys }
  
    let(:expected_result) do
      {
        error: {
          message: "Something went wrong",
        }
      }
    end
  
    include_examples "match extracted values"
  
    context "when the tag to be unescaped is already a valid XML node" do
      let(:xml) do
        <<~XML
          <xml>
            <response>
              <root>
                <error>
                  <message>Something went wrong</message>
                </error>
              </root>
            </response>
          </xml>
        XML
      end
  
      include_examples "match extracted values"
    end
  end
end