JSON = {
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

module Kernel
  def enum(values)
    Module.new do |mod|
      values.each_with_index { |v, _| mod.const_set(v.to_s.capitalize, v.to_s) }

      def mod.inspect
        "#{name} {#{constants.join(', ')}}"
      end
    end
  end

  def error!(message)
    puts "[ERROR]: #{message}"
    exit(1)
  end
end
