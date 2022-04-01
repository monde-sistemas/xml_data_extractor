# frozen_string_literal: true

require "yaml"
require "json"

RSpec.describe "InParent" do
  subject { XmlDataExtractor.new(structure).parse(xml) }

  context "when the parent has more than nine nodes" do
    let(:xml) do
      <<~XML
        <Hotels>
          <Hotel>
            <name>Hotel 1</name>
            <Bookings>
              <Booking>
                <id>01</id>
              </Booking>
            </Bookings>
          </Hotel>
          <Hotel>
            <name>Hotel 2</name>
            <Bookings>
              <Booking>
                <id>02</id>
              </Booking>
            </Bookings>
          </Hotel>
          <Hotel>
            <name>Hotel 3</name>
            <Bookings>
              <Booking>
                <id>03</id>
              </Booking>
            </Bookings>
          </Hotel>
          <Hotel>
            <name>Hotel 4</name>
            <Bookings>
              <Booking>
                <id>04</id>
              </Booking>
            </Bookings>
          </Hotel>
          <Hotel>
            <name>Hotel 5</name>
            <Bookings>
              <Booking>
                <id>05</id>
              </Booking>
            </Bookings>
          </Hotel>
          <Hotel>
            <name>Hotel 6</name>
            <Bookings>
              <Booking>
                <id>06</id>
              </Booking>
            </Bookings>
          </Hotel>
          <Hotel>
            <name>Hotel 7</name>
            <Bookings>
              <Booking>
                <id>07</id>
              </Booking>
            </Bookings>
          </Hotel>
          <Hotel>
            <name>Hotel 8</name>
            <Bookings>
              <Booking>
                <id>08</id>
              </Booking>
            </Bookings>
          </Hotel>
          <Hotel>
            <name>Hotel 9</name>
            <Bookings>
              <Booking>
                <id>09</id>
              </Booking>
            </Bookings>
          </Hotel>
          <Hotel>
            <name>Hotel 10</name>
            <Bookings>
              <Booking>
                <id>10</id>
              </Booking>
            </Bookings>
          </Hotel>
          <Hotel>
            <name>Hotel 11</name>
            <Bookings>
              <Booking>
                <id>11</id>
              </Booking>
            </Bookings>
          </Hotel>
        </Hotels>
      XML
    end

    let(:yml) do
      <<~YML
        schemas:
          bookings:
            products:
              array_of: ["Hotels/Hotel", "Bookings/Booking"]
              supplier:
                id: id
                name:
                  in_parent: Hotel
                  path: name
      YML
    end

    let(:structure) { YAML.safe_load(yml).deep_symbolize_keys }

    let(:expected_result) do
      {
        bookings: {
          products: [
            {
              supplier: {
                id: "01",
                name: "Hotel 1"
              }
            },
            {
              supplier: {
                id: "02",
                name: "Hotel 2"
              }
            },
            {
              supplier: {
                id: "03",
                name: "Hotel 3"
              }
            },
            {
              supplier: {
                id: "04",
                name: "Hotel 4"
              }
            },
            {
              supplier: {
                id: "05",
                name: "Hotel 5"
              }
            },
            {
              supplier: {
                id: "06",
                name: "Hotel 6"
              }
            },
            {
              supplier: {
                id: "07",
                name: "Hotel 7"
              }
            },
            {
              supplier: {
                id: "08",
                name: "Hotel 8"
              }
            },
            {
              supplier: {
                id: "09",
                name: "Hotel 9"
              }
            },
            {
              supplier: {
                id: "10",
                name: "Hotel 10"
              }
            },
            {
              supplier: {
                id: "11",
                name: "Hotel 11"
              }
            }
          ]
        }
      }
    end

    it "extract the parent data" do
      expect(JSON.pretty_generate(subject)).to eq JSON.pretty_generate(expected_result)
    end
  end
end
