require_relative 'parser'
require_relative 'lexer'

class JRB
  include Config

  attr_reader :config,
              :text

  def initialize(text, config: nil, file: nil)
    @text = text

    if file
      config_from_file!(file)
    else
      config!(config: config)
    end
  end

  def parse
    Parser.parse! Lexer.lex! text
  end

  def self.parse!(text, config: nil, config_file: nil)
    JRB.new(text, config: config, file: config_file).parse
  end
end
