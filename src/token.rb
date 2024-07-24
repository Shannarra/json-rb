TokenType = enum %w[
  Symbol
  Boolean
  Null
  Number
  String
]

class Token
  attr_reader :type, :value, :line, :col

  def initialize(type, value, line, col)
    @type = type
    @value = value
    @line = line
    @col = col
  end

  def position
    "#{line}:#{col}"
  end

  def value_with_position
    "#{value || '"null"'} at #{position}"
  end

  def to_s
    "Token<[#{type}] = #{value}> #{position}"
  end

  def ==(other)
    return value == other unless other.is_a? Token

    type == other.type && value == other.value
  end

  TokenType.constants.map { |type| type.to_s.downcase }.each do |type|
    define_method("#{type}_token?") { is_a?(Token) && self.type == type.capitalize }
  end
end
