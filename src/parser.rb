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

    error! 'Expected root to be an object!' if is_root && token.value != @@config[:SYMBOLS][:LEFTBRACE]

    advance
    case token.value
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

  def prev
    @tokens[@ip - 1]
  end

  def parse_object
    object = {}

    if current == @@config[:SYMBOLS][:RIGHTBRACE]
      advance
      return with_matching_key_type(object)
    end

    while current
      key = current

      unless key.is_a?(Token) && key.string_token?
        return with_matching_key_type(object) if key == @@config[:SYMBOLS][:RIGHTBRACE]

        error! "Expected a string key in object, got #{current.value_with_position}"
      end

      advance
      unless current == @@config[:SYMBOLS][:COLON]
        error! "Expected a colon separator character after key in object, got #{current.value_with_position}"
      end

      advance
      value = parse(offset: @ip)

      object[key.value.tr('"', '')] = unwrap!(value)

      if current == @@config[:SYMBOLS][:RIGHTBRACE]
        advance
        return with_matching_key_type(object)
      elsif current != @@config[:SYMBOLS][:COMMA]
        return with_matching_key_type(object) unless current

        next if current.string_token? && prev.symbol_token?

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
        error! "Improperly closed array in object, got #{current.value_with_position}"
      elsif current != @@config[:SYMBOLS][:COMMA]
        error! "Expected a '#{@@config[:SYMBOLS][:COMMA]}' , got #{current.value_with_position}"
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

  def with_matching_key_type(obj)
    case @@config[:KEYTYPE]
    when 'symbol' then obj.symbolize_keys
    when 'string' then obj.stringify_keys
    end
  end
end
