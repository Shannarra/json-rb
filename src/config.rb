module Config
  def config!(config: nil)
    @@config = config
    @@config ||= default_config
  end

  def config_from_file!(file)
    error! "Config file \"#{file}\" provided does not exist!" unless File.file? file

    @__res = JRB.parse!(File.read(file)).symbolize_keys

    check_symbols_match!

    check_quotes!

    check_whitespace!

    check_booleans!

    check_keytype!

    check_config_values! @__res.values

    # All checks done, merge with default for non-required keys if they don't exist
    config!(config: default_config.merge(@__res))
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
      KEYTYPE: 'string'
    }.freeze
  end

  private

  def check_symbols_match!
    required_object_check!(:SYMBOLS)
  end

  def check_quotes!
    quote = @__res.dig(:SYMBOLS, :QUOTE)

    @__res[:SYMBOLS][:QUOTE] = case quote
                               when 'double' then '"'
                               when 'single' then "'"
                               else error! "JRB config quote must be either \"single\" or \"double\", got \"#{quote}\""
                               end
  end

  def check_whitespace!
    return unless @__res[:WHITESPACE]

    @__res[:WHITESPACE] = if @__res[:WHITESPACE]
                            @__res[:WHITESPACE]&.map { |x| "\"#{x}\"".undump }
                          else
                            default_config[:WHITESPACE]
                          end
  end

  def check_booleans!
    required_object_check!(:BOOLEAN)
  end

  def check_keytype!
    type = @__res[:KEYTYPE]

    return unless type

    if %w[symbol string].include?(type)
      @__res[:KEYTYPE] = type
    else
      error! "Value for option \"KEYTYPE\" must be either \"symbol\" or \"string\", got a \"#{type}\"."
    end
  end

  def check_config_values!(values)
    values.each do |value|
      if value.is_a?(Hash)
        check_config_values!(value.values)
      elsif value.split.length > 1
        error! "Value for all config values should be only a single word, got a \"#{value}\""
      end
    end
  end

  def required_object_check!(name)
    error! "Config does not provide a required \"#{name}\" object!" unless @__res[name]

    expected_symbols = default_config[name].keys
    res_keys = @__res[name].keys

    all_exist = res_keys.all? { |sym| expected_symbols.include?(sym) }

    leftover = res_keys - expected_symbols
    unless leftover.empty?
      error! "Encountered unexpected keys for required object #{name} in config: \"#{leftover.map(&:to_s).join(', ')}\""
    end

    missing = expected_symbols - res_keys
    error! "The following required keys are missing in object \"#{name}\": #{missing.map(&:to_s).join(', ')}" unless missing.empty?

    error! "\"#{name}\" object in config does not match the required keys #{expected_symbols.map(&:to_s).join(',')}" unless all_exist
  end
end
