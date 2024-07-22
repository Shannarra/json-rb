require_relative 'config'

class Parser
  include Config

  attr_accessor :tokens, :ip

  def initialize(tokens, offset)
    @@config ||= default_config

    @tokens = tokens
    @ip = offset
  end

  def self.parse!(tokens, is_root: false, offset: 0)
    parser = Parser.new(tokens, offset)
    parser.parse(is_root: is_root)
  end

  def parse(is_root: false, offset: 0)
    @ip = offset
    token = current

    error! 'Expected root to be an object!' if is_root && token != @@config[:SYMBOLS][:LEFTBRACE]

    advance
    case token
    when @@config[:SYMBOLS][:LEFTBRACKET] then parse_array
    when @@config[:SYMBOLS][:LEFTBRACE] then parse_object
    else
      unwrap! token
    end
  end

  private

  def current
    @tokens[@ip]
  end

  def advance
    @ip += 1
  end

  def parse_object
    object = {}

    if current == @@config[:SYMBOLS][:RIGHTBRACE]
      advance
      return object
    end

    while current
      key = current

      unless key.is_a?(Token) && key.string_token?
        return object if key == @@config[:SYMBOLS][:RIGHTBRACE]

        error! "Expected a string key in object, got \"#{key}\" at #{ip}"
      end

      advance

      error! "Expected a colon separator character after key in object, got \"#{current}\"" unless current == @@config[:SYMBOLS][:COLON]

      advance
      value = parse(offset: @ip)

      object[key.value.tr('"', '')] = unwrap!(value)

      if current == @@config[:SYMBOLS][:RIGHTBRACE]
        advance
        return object
      elsif current != @@config[:SYMBOLS][:COMMA]
        return object unless current

        next if current.is_a?(Token) && current.string_token?

        error! "Expected a comma after a key-value pair in object, got an \"#{unwrap! current}\""
      end

      advance
    end

    error! "Expected end-of-object symbol #{@@config[:SYMBOLS][:RIGHTBRACE]}"
  end

  def parse_array
    array = []

    return array if current == @@config[:SYMBOLS][:RIGHTBRACKET]

    while current
      item = parse(offset: @ip)
      array << unwrap!(item)

      if current == @@config[:SYMBOLS][:RIGHTBRACKET]
        return array
      elsif current == @@config[:SYMBOLS][:RIGHTBRACE]
        error! 'Improperly closed array in object'
      elsif current != @@config[:SYMBOLS][:COMMA]
        error! "Expected a '#{@@config[:SYMBOLS][:COMMA]}' , got #{current}"
      else
        advance
      end
    end

    error! "Expected an end-of-array #{@@config[:SYMBOLS][:RIGHTBRACKET]}"
  end

  def unwrap!(value)
    if value.is_a?(Token)
      return value.value.tr('"', '') if value.string_token?

      return value.value
    end

    if value.is_a?(Array)
      advance
      value.map do |item|
        unwrap!(item)
      end
    end

    value
  end
end
