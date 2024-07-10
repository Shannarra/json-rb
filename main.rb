require 'pry'

require_relative 'src/parser'
require_relative 'src/lexer'

class JRB
  def self.parse!(text)
    Parser.parse! Lexer.lex! text
  end
end

def main
  value = JRB.parse! '
{
    "foo": {
        "grades": [
            2,
            3,
            4,
            5,
            6,
            {
                "asd": "asd"
            }
        ],
        "data": {
            "bar": "baz",
            "weirdnum": -12e9,
            "buz": true,
            "gaz": false,
            "user_data": null
        }
    }
}
'
  puts value
  puts value.dig('foo', 'data', 'weirdnum')

  value = JRB.parse! File.read('./tests/medical.json')
  puts value['imaging'][1]['location']
end

main
