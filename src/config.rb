module Config
  def config!(config: nil)
    @@config = config
    @@config ||= default_config
  end

  def config_from_file!(file)
    error! "Config file \"#{file}\" provided does not exist!" unless File.file? file

    res = JRB.parse!(File.read(file)).symbolize_keys

    quote = res.dig(:SYMBOLS, :QUOTE)

    res[:SYMBOLS][:QUOTE] = case quote
                            when 'double' then '"'
                            when 'single' then "'"
                            else error! "JRB config quote must be either \"single\" or \"double\", got \"#{quote}\""
                            end

    res[:WHITESPACE] = res[:WHITESPACE]&.map { |x| "\"#{x}\"".undump }
    config!(config: res)
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
      NULL: 'null',
      KEYTYPE: 'symbol'
    }.freeze
  end
end
