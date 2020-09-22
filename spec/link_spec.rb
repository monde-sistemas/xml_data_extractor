require "yaml"
require "json"

RSpec.describe "Link" do
  subject { XmlDataExtractor.new(structure).parse(xml) }

  context "when linked path is in an array of paths" do
    let(:xml) do
      <<~XML
        <Sales>
          <Sale>
            <Locator>Y968XB</Locator>
            <IssueDate>22/07/2019</IssueDate>
            <Tickets>
              <Ticket>
                <Code>10248270</Code>
                <Exchange>3,7408000</Exchange>
                <Passengers>
                  <Passenger>
                    <Name>FERNANDES/DAVID</Name>
                    <Kind>ADT</Kind>
                  </Passenger>
                </Passengers>
              </Ticket>
            </Tickets>
            <Totals>
              <Incentive>16,65</Incentive>
            </Totals>
          </Sale>
          <Sale>
            <Locator>Y968XB</Locator>
            <IssueDate>22/07/2019</IssueDate>
            <Tickets>
              <Ticket>
                <Code>10248271</Code>
                <Exchange>3,7408000</Exchange>
                <Passengers>
                  <Passenger>
                    <Name>FERNANDES/LUIZ</Name>
                    <Kind>ADT</Kind>
                  </Passenger>
                </Passengers>
              </Ticket>
            </Tickets>
            <Totals>
              <Incentive>12,61</Incentive>
            </Totals>
          </Sale>
        </Sales>
      XML
    end
  
    let(:yml) do
      <<~YML
        schemas:
          bookings:
            array_of:
              path: Sales/Sale
              uniq_by: Locator
            date: IssueDate
            document: Locator
            products:
              array_of: Tickets/Ticket
              exchange_rate: Exchange
              incentive:
                path: ['../../../../Sales/Sale[Locator="<link>"]/Totals/Incentive', Exchange]
                link: ../../Locator
      YML
    end
  
    let(:structure) { YAML.safe_load(yml).deep_symbolize_keys }

    let(:expected_result) do
      {
        bookings: [
          {
            date: "22/07/2019",
            document: "Y968XB",
            products: [
              {
                exchange_rate: "3,7408000",
                incentive: [["16,65", "12,61"], "3,7408000"]
              }
            ]
          }          
        ]
      }
    end

    it "extracts the data of the linked path" do
      expect(JSON.pretty_generate(subject)).to eq JSON.pretty_generate(expected_result)
    end
  end
end