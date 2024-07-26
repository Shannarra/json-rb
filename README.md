# JSON-RB [![Ruby CI](https://github.com/Shannarra/json-rb/actions/workflows/ruby.yml/badge.svg)](https://github.com/Shannarra/json-rb/actions/workflows/ruby.yml)

JSON-RB is a simple and effective JSON parser written from scratch in Ruby.

## Features
- [x] Full support of any JSON file provided  
    Testing JSON files included in the [tests](./tests) folder, as well as a full integrated test suite using RSpec and GitHub Actions.
- [x] Extended customizability  
    Support for custom parser configurations have been added.
    Yes, this means that you can parse a custom-styled JSON-based file format with this if that's your heart's desire. More on that in the [customizability](#customizability) section.
- [x] Proven functionality  
    Functionality proven by a number of tests and integrated CI/CD functionality.
    Tested in Ruby versions 3.1, 3.0 and 2.7 in [the actions](https://github.com/Shannarra/json-rb/actions) pipeline.
- [x] Documented development  
      The project has been used for understanding how to develop a JSON parser from scratch and documenting the process, creating a simple tutorial on [how to do this](#how) in the process.

## Why?
I was bored and wanted to test my recursion skills. 

## Okay, sounds cool, but how can I build such a thing?

No matter if you are new to programming and wanna understand how to build parsers, lexers, work with recursion, or if you are an expert 10x senior programmer with 50 years of experience, developing a JSON parser seems like an interesting project to undertake.

This is why I have written a document, aptly called "[building a parser](https://github.com/Shannarra/json-rb/blob/master/docs/building_a_parser.md)", where we go through a step-by-step guide on how to create a *basic* JSON parser from scratch. Give it a read and leave a star on this project if you find it interesting or useful.

## Customizability

The parser is FULLY customizeable. 

This means that you can customize its behaviour fully, and it's really simple how to do so:

### Defaults
If you wanna just use the default configuration, you can just call on the parser and use it normally:
```ruby
  value = JRB.parse! '
{
    "hello": "world",
    "items": [
        1,
        6.9,
        -1200000,
        "Hello World!",
        [
            1,
            2,
            3
        ],
        {
            "hello": "John Doe",
            "false": true,
            "true": false,
            "value": null
        }
    ],
    "foo": {
        "data": {
            "weirdnum": null
        },
        "asd": "ASD",
        "items": []
    }
}'

puts value
```

Using the [default configuration](src/config.rb#28), or in other words, parsing a normal JSON format we can see the following output:

```console
{"hello"=>"world", "items"=>[1, 6.9, -1200000, "Hello World!", [1, 2, 3], {"hello"=>"John Doe", "false"=>true, "true"=>false, "value"=>nil}], "foo"=>{"data"=>{"weirdnum"=>nil}, "asd"=>"ASD", "items"=>[]}}
```

### Custom configurations
Let's say we'd want to parse a JSON-based file with custom characters for the different delimeters. We'll use the following file for example:

```
[
    'foo' → [
        'grades' → {
            2⸲
            3⸲
            4⸲
            5⸲
            6⸲
            [
				'system' → [
					'name' → 'Eastern European'⸲
					'count' → 5⸲
					'max' → 6⸲
					'min' → 2
				]
			]
        }⸲
        'data' → [
            'bar' → 'baz'⸲
            'weirdnum' → -12000000⸲
            'buz' → да⸲
            'gaz' → не⸲
            'user_data' → fuck
        ]
    ]
]
```

In this example, objects are denoted with `[` and `]`, arrays are denoted with `{` and `}`, there are custom words for `true`, `false` and `null` and more. Using the default configuration, the parser won't be able to parse this file. This is why we would like to provide a custom configuration.

Custom configuration can be provided in two separate ways:

#### Passing a config as a hash
If you already have a programatically-developed, stored or generated Hash of the configuration, you can pass it using the `config:` named argument, more on it's structure you can read below.

Example:

```ruby
config = {
    SYMBOLS: {
      COMMA: '⸲',
      COLON: '→',
      LEFTBRACKET: '{',
			RIGHTBRACKET: '}',
      LEFTBRACE: '[',
      RIGHTBRACE: ']',
      QUOTE: 'single'
    },
    WHITESPACE: ['', ' ', "\r", "\b", "\n", "\t"],
    BOOLEAN: {
      TRUE: 'да',
      FALSE: 'не'
    },
    NULL: 'fuck',
	KEYTYPE: 'symbol',
  }
 
  value = JRB.parse!(File.read('./tests/jrb/arrays_instead_of_objects.jrb'), config: config)
  pp value
```

#### Passing a config as a file
If you wanna pass a JSON file with your custom configuration, you can also do so by passing the path to the file to the `config_file:` named argument to `JRB`.

```ruby
  value = JRB.parse!(File.read('./tests/jrb/arrays_instead_of_objects.jrb'), config_file: 'config.json')
  pp value
```

And the config file consists of a normal JSON:
```json
{
    "SYMBOLS": {
        "COMMA": "⸲",
        "COLON": "→",
        "LEFTBRACKET": "{",
		"RIGHTBRACKET": "}",
        "LEFTBRACE": "[",
        "RIGHTBRACE": "]",
        "QUOTE": "single"
    },
    "BOOLEAN": {
        "TRUE": "да",
        "FALSE": "не"
    },
    "NULL": "fuck",
	"KEYTYPE": "symbol",
}
```

The result of either of those custom configuration passing methods is the following:
```console
{:"'foo'"=>
  {:"'grades'"=>[2, 3, 4, 5, 6, {:"'system'"=>{:"'name'"=>"'Eastern European'", :"'count'"=>5, :"'max'"=>6, :"'min'"=>2}}],
   :"'data'"=>{:"'bar'"=>"'baz'", :"'weirdnum'"=>-12000000, :"'buz'"=>true, :"'gaz'"=>false, :"'user_data'"=>nil}}}
```
You will see that with the custom config you'll be able to change literally anything, the type of the keys in the resulting Hash, keywords, item delimiters, quotes and more. Here's a closer look on how this works:


#### Config requirements

The custom config you're providing has several key-value pairs with different required types: 
| Key | Value type|  
|---|---|  
| SYMBOLS | Object. __*Required*__ for **both** config types, see tables below for further information |
| WHITESPACE| Array. __*Required*__ ONLY when passing a config in as a hash. If not provided in a file config the parser will use the default whitespace delimeters |
| BOOLEAN | Object. __*Required for **both** config types, see tables below for further information*__ |
| NULL | String value. Optional. Parser uses default option if not provided. |
| KEYTYPE | String value. Optional. Parser uses default option if not provided. |

ALL values in the following tables can be changed in order to fit your custom format.

##### `SYMBOLS` object requirements
| Key | Value description |  
|---|---|  
| COMMA        | Separator between values in object or array. Default is `,`.|
| COLON        | Separator between key-value pairs in object. Default is `:`.|
| LEFTBRACKET  | Denotes the start of an array. Default is `[`.|
| RIGHTBRACKET | Denotes the end of an array. Default is `]`.|
| LEFTBRACE    | Denotes the start of an object. Default is `{`.|
| RIGHTBRACE   | Denotes the end of an object. Default is `}`.|
| QUOTE        | Denotes a string. Option must be either `single` or `double`, for a single or double quote. Default is `"`.|

##### `BOOLEAN` object requirements
| Key | Value description |  
|---|---|  
| TRUE | Represents the positive boolean value. Default is `true`.|
| FALSE | Represents the positive boolean value. Default is `false`.|

##### Leftover keys
| Key | Value description |  
|---|---|  
| WHITESPACE | Represents an array of ALL possible whitespace characters in your format. |
| NULL | Represents the value `null` in your file. Defaults to `null` if not provided. |
| KEYTYPE | What is the type of the keys the resulting hash will have. Must be either `symbol` for symbol keys or `string` for string keys. Defaults to `string` if not provided. |
