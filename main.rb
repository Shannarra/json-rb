require 'pry'
require_relative 'src/jrb'

def main
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
  puts value.dig('foo', 'data', 'weirdnum')

  h = {
    SYMBOLS: {
      COMMA: '⸲',
      COLON: '→',
      LEFTBRACKET: '{',
      RIGHTBRACKET: '}',
      LEFTBRACE: '[',
      RIGHTBRACE: ']',
      QUOTE: 'single'
    },
    WHITESPACE: [' ', "\n", "\t"],
    BOOLEAN: {
      TRUE: 'да',
      FALSE: 'не'
    },
    NULL: 'fuck'
  }

  value = JRB.parse!(File.read('./tests/jrb/arrays_instead_of_objects.jrb'), config: h)
  pp value
end

main
