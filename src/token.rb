TokenType = enum %w[
  Symbol
  Boolean
  Null
  Number
  String
]

class Token
  attr_reader :type, :value

  def initialize(type, value)
    @type = type
    @value = value
  end

  def to_s
    "Token<[#{type}] = #{value}>"
  end

  def ==(other)
    return value == other unless other.is_a? Token

    type == other.type && value == other.value
  end

  TokenType.constants.map { |type| type.to_s.downcase }.each do |type|
    define_method("#{type}_token?") { is_a?(Token) && self.type == type.capitalize }
  end
end
