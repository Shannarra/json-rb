class Parser
  attr_accessor :tokens, :ip

  def initialize(tokens, offset)
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

    error! 'Expected root to be an object!' if is_root && token != JSON[:SYMBOLS][:LEFTBRACE]

    advance
    case token
    when JSON[:SYMBOLS][:LEFTBRACKET] then parse_array
    when JSON[:SYMBOLS][:LEFTBRACE] then parse_object
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

    if current == JSON[:SYMBOLS][:RIGHTBRACE]
      advance
      return object
    end

    while current
      key = current

      if !key.is_a?(Token) || key.type != TokenType::String
        return object if key == JSON[:SYMBOLS][:RIGHTBRACE]

        error! "Expected a string key in object, got \"#{key}\" at #{ip}"
      end

      advance

      error! "Expected a colon separator character after key in object, got \"#{current}\"" unless current == JSON[:SYMBOLS][:COLON]

      advance
      value = parse(offset: @ip)

      object[key.value.tr('"', '')] = unwrap!(value)

      if current == JSON[:SYMBOLS][:RIGHTBRACE]
        advance
        return object
      elsif current != JSON[:SYMBOLS][:COMMA]
        return object unless current

        next if current.string_token?

        error! "Expected a comma after a key-value pair in object, got an \"#{unwrap! current}\""
      end

      advance
    end

    error! "Expected end-of-object symbol #{JSON[:SYMBOLS][:RIGHTBRACE]}"
  end

  def parse_array
    array = []

    return array if current == JSON[:SYMBOLS][:RIGHTBRACKET]

    while current
      item = parse(offset: @ip)
      array << unwrap!(item)

      if current == JSON[:SYMBOLS][:RIGHTBRACKET] || current == JSON[:SYMBOLS][:RIGHTBRACE]
        return array
      elsif current != JSON[:SYMBOLS][:COMMA]
        error! "Expected a '#{JSON[:SYMBOLS][:COMMA]}' , got #{current}"
      else
        advance
      end
    end

    error! "Expected an end-of-array #{JSON[:SYMBOLS][:RIGHTBRACKET]}"
  end

  def unwrap!(value)
    return value.value if value.is_a?(Token)

    if value.is_a?(Array)
      advance
      value.map do |item|
        unwrap!(item)
      end
    end

    value
  end
end
