require_relative 'parser'
require_relative 'lexer'

class JRB
  attr_reader :config,
              :text

  def initialize(text, config:)
    @text = text
    @config = config
    @config ||= default_config
  end

  def parse
    Parser.parse! Lexer.lex! text
  end

  def self.parse!(text, config: nil)
    JRB.new(text, config: config).parse
  end

  def default_config
    {
      SYMBOLS: {
        COMMA: ',',
        COLON: ':',
        LEFTBRACKET: '[',
        RIGHTBRACKET: ']',
        LEFTBRACE: '{',
        RIGHTBRACE: '}',
        QUOTE: '"'
      },
      WHITESPACE: ['', ' ', "\r", "\b", "\n", "\t"],
      BOOLEAN: {
        TRUE: 'true',
        FALSE: 'false'
      },
      NULL: 'null'
    }.freeze
  end
end
