# frozen_string_literal: true

require "yaml"
require "json"

RSpec.describe "Complete Example" do
  subject { XmlDataExtractor.new(structure, custom_methods).parse(xml) }

  let(:xml) do
    <<~XML
      <xml>
        <movies_list>
          <movie>
            <policy>
              &lt;span style=&quot;font-family: Verdana;&quot; trebuchet=&quot;&quot; ms&quot;;=&quot;&quot; font-size:=&quot;&quot; small;=&quot;&quot; color:=&quot;&quot; rgb(102,=&quot;&quot; 102,=&quot;&quot; 102);&quot;=&quot;&quot;&gt;
                Copyright &copy; 2010 by Wily E. &amp;amp; &lt;br&gt;Coyote All rights reserved.|&lt;/br&gt;
              &lt;/span&gt;
            </policy>
            <description>The Lord of the Rings: The Fellowship of the Ring</description>
            <total_minutes>209</total_minutes>
            <year>2001</year>
            <main_gen>ADV</main_gen>
            <actors>
              <actor>
                <firstname>Orlando</firstname>
                <surname>Bloom</surname>
                <char_name>Legolas</char_name>
              </actor>
              <actor>
                <firstname>Ian</firstname>
                <surname>Mckellen</surname>
                <char_name>Gandalf</char_name>
              </actor>
            </actors>
          </movie>
        </movies_list>
      </xml>
    XML
  end

  let(:yml) do
    <<~YML
      mappers:
        genres:
          default: unknown
          options:
            fiction: FIC
            adventure: ADV
      schemas:
        movies:
          array_of: movies_list/movie
          title: description
          year:
            path: year
            modifier: to_i
          duration:
            path: total_minutes
            modifier: minutes_to_hours
          genre:
            path: main_gen
            mapper: genres
          cast:
            array_of: actors/actor
            name:
              path: [firstname, surname]
              modifier:
                name: join
                params: [" "]
            character: char_name
    YML
  end
  let(:structure) { YAML.safe_load(yml).deep_symbolize_keys }

  let(:custom_methods) do
    Class.new do
      def minutes_to_hours(value)
        total_minutes = value.to_i
        hours = total_minutes / 60
        minutes = total_minutes % 60
        "#{hours}h #{minutes}min"
      end
    end.new
  end

  let(:expected_result) do
    {
      movies: [
        title: "The Lord of the Rings: The Fellowship of the Ring",
        year: 2001,
        duration: "3h 29min",
        genre: "adventure",
        cast: [
          {
            name: "Orlando Bloom",
            character: "Legolas"
          },
          {
            name: "Ian Mckellen",
            character: "Gandalf"
          }
        ]
      ]
    }
  end

  it { expect(JSON.pretty_generate(subject)).to eq JSON.pretty_generate(expected_result) }
end
