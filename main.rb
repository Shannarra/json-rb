require 'pry'

require_relative 'src/parser'
require_relative 'src/lexer'

class JRB
  def self.parse!(text)
    Parser.parse! Lexer.lex! text
  end
end

def main
  value = JRB.parse! '{"items":[1,6.9,-1200000,"Hello World!",[1,2,3],{"name":"John Doe"}]}'
  puts value
  puts value.dig('foo', 'data', 'weirdnum')

  value = JRB.parse! File.read('./tests/very_nested.json')
  puts value
end

main
