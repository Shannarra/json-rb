require_relative 'util'
require_relative 'token'

class Lexer
  attr_reader :text, :tokens, :ip

  def initialize(text)
    @text = text
    @tokens = []
    @ip = 0
  end

  def self.lex!(text)
    l = Lexer.new(text)
    l.lex
  end

  def lex
    while current
      jstr = lex_str

      unless jstr.nil?
        tokens << jstr
        advance
      end

      jnum = lex_num
      tokens << jnum unless jnum.nil?

      jbool = lex_bool
      tokens << jbool unless jbool.nil?

      null = lex_null
      # this reads weird as fuck
      tokens << null unless null.nil?

      if JSON[:WHITESPACE].include?(current)
        advance
      elsif JSON[:SYMBOLS].values.include?(current)
        tokens << current
        advance
      else
        break unless current

        error! "Unknown token \"#{current}\" encountered at #{ip}"
      end
    end

    tokens
  end

  private

  def current
    @text[@ip]
  end

  def advance
    @ip += 1
  end

  def lex_str
    return nil if current != JSON[:SYMBOLS][:QUOTE]

    str = current
    advance
    return (str += current) if current == JSON[:SYMBOLS][:QUOTE]

    loop do
      if current
        str += current
      elsif current.nil?
        error! 'Unterminated string found.'
      end

      advance
      return Token.new(TokenType::String, (str += current)) if current == JSON[:SYMBOLS][:QUOTE]
    end
  end

  def lex_num
    num = ''

    num_chars = (0..10).map(&:to_s) + %w[e - .]

    while current
      break unless num_chars.include?(current)

      num += current
      advance
    end

    return nil if num.empty?

    return Token.new(TokenType::Number, num.to_f) if num.include?('.') || num.include?('e')

    Token.new(TokenType::Number, num.to_i)
  end

  def lex_bool
    bool_vals = JSON[:BOOLEAN]
    possible_values = bool_vals.values.map(&:chars).flatten.uniq

    jbool = ''

    while current
      break unless possible_values.include?(current)

      jbool += current if possible_values.include?(current)
      advance
    end

    case jbool
    when bool_vals[:TRUE]
      Token.new(TokenType::Boolean, true)
    when bool_vals[:FALSE]
      Token.new(TokenType::Boolean, false)
    end
  end

  def lex_null
    null = ''

    while current
      break unless JSON[:NULL].chars.include?(current)

      null += current if JSON[:NULL].chars.include?(current)
      advance
    end

    Token.new(TokenType::Null, nil) if null == JSON[:NULL]
  end
end
