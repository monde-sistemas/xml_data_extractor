<a href="https://badge.fury.io/rb/xml_data_extractor"><img src="https://badge.fury.io/rb/xml_data_extractor.svg" alt="Gem Version" height="18"></a>

# XmlDataExtractor

This gem provides a DSL for extracting formatted data from any XML structure.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'xml_data_extractor'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install xml_data_extractor

## Usage

The general ideia is to declare a ruby Hash that represents the fields structure, containing instructions of how every piece of data should be retrieved from the XML document.

```ruby
structure = { schemas: { character: { path: "xml/FirstName" } } }
xml = "<xml><FirstName>Gandalf</FirstName></xml>"

result = XmlDataExtractor.new(structure).parse(xml)

# result -> { character: "Gandalf" }
```

For convenience, you can write the structure in yaml, which can be easily converted to a ruby hash using `YAML.load(yml).deep_symbolize_keys`.

Considering the following yaml and xml:

```yml
schemas:
  description:
    path: xml/desc
    modifier: downcase
  amount:  
    path: xml/info/price
    modifier: to_f
```
```xml
<xml>
  <desc>HELLO WORLD</desc>
  <info>
    <price>123</price>
  </info>  
</xml>
```

The output is:
```ruby
{
  description: "hello world",
  amount: 123.0
}
```

### Defining the structure

The structure should be defined as a hash inside the `schemas` key. See the [complete example](https://github.com/monde-sistemas/xml_data_extractor/blob/master/spec/complete_example_spec.rb#L5).

When defining the structure you can combine any available command in order to extract and format the data as needed.

The available commands are separated in two general pusposes:

- [Navigation & Extraction](#navigation--extraction)
- [Formatting](#formatting)

### Navigation & Extraction:

The data extraction process is based on `Xpath` using Nokogiri.
* [Xpath introduction](https://blog.scrapinghub.com/2016/10/27/an-introduction-to-xpath-with-examples)  
* [Xpath cheatsheet](https://devhints.io/xpath)

#### path

Defines the `xpath` of the element.
The `path` is the default command of a field definition, so this:
```yml
  schemas:
    description: 
      path: xml/desc
```    
Is equivalent to this:
```yml
  schemas:
    description: xml/desc
```    

It can be defined as a string:
```yml
schemas:
  description:
    path: xml/some_field
```
```xml
<xml>
  <some_field>ABC</some_field>
</xml>
```
```ruby
{ description: "ABC" }
```

Or as a string array:
```yml
schemas:
  address:
    path: [street, info/city]     
```
```xml
<xml>
  <street>Diagon Alley</street>
  <info>
    <city>London</city>
  </info>  
</xml>
```
```ruby
{ address: ["Diagon Alley", "London"] }
```

And even as a hash array, for complex operations:
```yml
schemas:
  address:
    path:
      - path: street
        modifier: downcase
      - path: info/city
        modifier: upcase   
```
```ruby
{ address: ["diagon alley", "LONDON"] }
```

#### attr

Defines a tag attribute which the value should be extracted from, instead of the tag value itself:
```yml
schemas:
  description:
    path: xml/info 
    attr: desc
```
```xml
<xml>
  <info desc="ABC">some stuff<info>
</xml> 
```
```ruby
{ description: "ABC" }
```

Like the path, it can also be defined as a string array.

#### within

To define a root path for the fields:
```yml
schemas:  
  movie:
    within: info/movie_data
    title: original_title
    actor: main_actor
```
```xml
<xml>
  <info>
    <movie_data>
      <original_title>The Irishman</original_title>
      <main_actor>Robert De Niro</main_actor>
    </movie_data>
  </info>
</xml>
```
```ruby
{ movie: { title: "The Irishman", actor: "Robert De Niro" } }
```

#### unescape

This option is pretty usefull when you have embbed XML or HTML inside some tag, like CDATA elements, and you need to unescape them first in order to parse their content:

```yml
schemas:  
  movie:
    unescape: response
    title: response/original_title
    actor: response/main_actor

```

```xml
<xml>
  <response>
    &ltoriginal_title&gt1&ltoriginal_title&gt&ltmain_actor&gt1&ltmain_actor&gt
  </response>
</xml>
```

This XML will be turned into this one during the parsing:

```xml
<xml>
  <response>
    <original_title>The Irishman</original_title>
    <main_actor>Robert De Niro</main_actor>
  </response>
</xml>
```

```ruby
{ movie: { title: "The Irishman", actor: "Robert De Niro" } }
```

#### array_of

Defines the path to a XML collection, which will be looped generating an array of hashes:
```yml
schemas:
  people:
    array_of: characters/character
    name: firstname
    age: age
```
```xml
<xml>
  <characters>
    <character>
      <firstname>Geralt</firstname>
      <age>97</age>
    </character>
    <character>
      <firstname>Yennefer</firstname>
      <age>102</age>
    </character>
  </characters>
</xml>
```
```ruby
{
  people: [
    { name: "Geralt", age: "97" },
    { name: "Yennefer", age: "102" }
  ]
}
```

If you need to loop trough nested collections, you can define an array of paths:
```yml
schemas:
  show:    
    within: show_data
    title: description
    people:
      array_of: [characters/character, info]
      name: name
```
```xml
<xml>
  <show_data>
    <description>Peaky Blinders</description>
    <characters>
      <character>
        <info>
          <name>Tommy Shelby</name>          
        </info>
      </character>
      <character>
        <info>
          <name>Arthur Shelby</name>          
        </info>
        <info>
          <name>Alfie Solomons</name>
        </info>
      </character>
    </characters>
  </show_data>
</xml>
```
```ruby
{
  show: {
    title: "Peaky Blinders",
    people: [
      { name: "Tommy Shelby" },
      { name: "Arthur Shelby" },
      { name: "Alfie Solomons" }      
    ]
  }  
}
```

### link

Works as a JOIN SQL, it gets the value through the expression provided by the tag `link` and replaces the tag `<link>` contained in the tag `path` with the value to search values related to the node which you are parsing. This is needed when the data in the XML is all in the same level and this levels are linked between them and you need to navigate to each level to find all the data in the XML.

Example:
```yml
schemas:
  bookings:
    array_of: booking
    date: booking_date
    document: id
    products:
      array_of:
      accomodation:
        path: ../hotel[booking_id=<link>]/accomodation
        link: id
```
```xml
<xml>
  <booking>
    <id>1</id>
    <booking_date>2020-01-01</booking_date>
  </booking>
  <booking>
    <id>2</id>
    <booking_date>2020-01-02</booking_date>
  </booking>
  <hotel>
    <booking_id>1</booking_id>
    <accomodation>Standard</accomodation>
  </hotel>
  <hotel>
    <booking_id>2</booking_id>
    <accomodation>Premium</accomodation>
  </hotel>
</xml>
```
```ruby
{
  bookings: [
    {
      date: "2020-01-01",
      document: "1"
      products: [
        { accomodation: "Standard" }
      ]
    },
    {
      date: "2020-01-02",
      document: "2"
      products: [
        { accomodation: "Premium" }
      ]
    }
  ]
}
```

In this example if I didn't use the `link` to get only the hotel of each booking, it would have returned two accomodations for each booking and instead of extract a string with the accomodation it would extract an array with all the accomodations for each booking.

You can combine the `link` with `array_of` if you want search for a list of elements filtering by some field, just provide the `path` and the `link`:

```yml
schemas:
  bookings:
    array_of: booking
    date: date
    document: id
    products:
      array_of:
        path: ../products[booking_id=<link>]
        link: id
      ....
```

### uniq_by

Can only be used with **array_of**.

Has a similar behavior like Ruby **uniq** method on arrays, do you provide a path to the `uniq_by` tag and then we will keep only on the array_of the paths that have a diferrent values in the path provided on the tag `uniq_by`, if the value of the path provided in the tag `uniq_by` is equal in more than one path, we will keep the first path and the remaining paths will be ignored. This functionality is useful when some node in the XML is duplicated and it is only necessary to obtain the info from one of the nodes.

```yml
schemas:
  bookings:
    array_of:
      path: booking
      uniq_by: id
    date: bdate
    document: id
```
```xml
<xml>
  <booking>
    <id>1</id>
    <bdate>2020-01-01</bdate>
  </booking>
  <booking>
    <id>1</id>
    <bdate>2020-01-01</bdate>
  </booking>
</xml>
```
```ruby
{
  bookings: [
    {
      date: "2020-01-01",
      document: "1"
    }
  ]
}
```

In the example above if we don't use the tag `uniq_by` there would be extracted two elements with the same data, like:

```ruby
{
  bookings: [
    {
      date: "2020-01-01",
      document: "1"
    },
    {
      date: "2020-01-01",
      document: "1"
    }
  ]
}
```

### array_presence: first_only

The field that contains this property will be only added to the first item of the array.

Can only be used in fields that belong to a node of `array_of`.

```yml
passengers:
  array_of: bookings/booking/passengers
  id:
    path: document
    modifier: to_s
  name:
    attr: [FirstName, LastName]
    modifier:
      - name: join
        params: [" "]
  rav_tax:
    array_presence: first_only
    path: ../rav
    modifier: to_f
```
```xml
<bookings>
  <booking>
    <rav>150<rav>
    <passengers>
      <passenger>
        <document>109.111.019-79</document>
        <FirstName>Marcelo</FirstName>
        <LastName>Lauxen</LastName>
      </passenger>
      <passenger>
        <document>110.155.019-78</document>
        <FirstName>Corona</FirstName>
        <LastName>Virus</LastName>
      </passenger>
    </passengers>
  </booking>
</bookings>
```
```ruby
{
  bookings: [
    {
      passengers: [
        { 
          id: "109.111.019-79",
          name: "Marcelo Lauxen",
          tax_rav: 150.00 
        },
        { 
          id: "110.155.019-78",
          name: "Corona Virus"
        }
      ]
    }
  ]
}
```

In the above example the field `tax_rav` was only included on the first passenger because this field has the `array_presence: first_only` property.

### Formatting:

#### fixed

Defines a fixed value for the field:
```yml
  currency:
    fixed: BRL
```
```ruby
  { currency: "BRL" }
```

#### mapper

Uses a hash of predefined values to replace the extracted value with its respective option.
If the extracted value is not found in any of the mapper options, it will be replaced by the `default` value, but if the default value is not defined, the returned value is not replaced.
```yml
mappers:
  currencies:
    default: unknown
    options:      
      BRL: R$
      USD: [US$, $]
schemas:
  money:    
    array_of: curr_types/type
    path: symbol
    mapper: currencies
```
```xml
  <xml>
    <curr_type>
      <type>
        <symbol>US$</symbol>
      </type>
      <type>
        <symbol>R$</symbol>
      </type>
      <type>
        <symbol>RB</symbol>
      </type>      
      <type>
        <symbol>$</symbol>
      </type>      
    </curr_type>  
  </xml>
```
```ruby
  {
    money: ["USD", "BRL", "unknown", "USD"]
  }
```

#### modifier

Defines a method to be called on the returned value.
```yml
schemas:
  name:
    path: some_field
    modifier: upcase
```
```xml
<xml>
  <some_field>Lewandovski</some_field>
</xml>
```
```ruby
{ name: "LEWANDOVSKI" }
```

You can also pass parameters to the method. In this case you will have to declare the modifier as an array of hashes, with the `name` and `params` keys:
```yml
schemas:
  name:
    path: [firstname, lastname]
    modifier: 
      - name: join
        params: [" "]
      - downcase      
```
```xml
<xml>
  <firstname>Robert</firstname>
  <lastname>Martin</lastname>
</xml>
```
```ruby
{ name: "robert martin" }
```

If you need to use custom methods, you can pass an object containing the methods in the initialization. The custom method will receive the value as parameter:
```yml
schemas:
  name:
    path: final_price
    modifier: format_as_float      
```
```xml
<xml>
  <final_price>R$ 12.99</final_price>  
</xml>
```
```ruby
class MyMethods 
  def format_as_float(value)
    value.gsub(/[^\d.]/, "").to_f    
  end
end

XmlDataExtractor.new(yml, MyMethods.new).parse(xml)
```
```ruby
{ price: 12.99 }
```
