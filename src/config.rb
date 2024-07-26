module Config
  def config!(config: nil)
    if config.nil?
      @@config = default_config
    else
      error! 'Config must be a non-empty hash' if !config.is_a?(Hash) || config.empty?

      perform_config_checks!(config, with_whitespace: true)

      @@config = config
    end
  end

  def config_from_file!(file)
    error! "Config file \"#{file}\" provided does not exist!" unless File.file? file

    res = JRB.parse!(File.read(file)).symbolize_keys

    perform_config_checks!(res)

    # All checks done, merge with default for non-required keys if they don't exist
    config!(config: default_config.merge(res))
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

  def perform_config_checks!(config, with_whitespace: false)
    check_symbols_match! config

    check_quotes! config

    check_whitespace! config, force: with_whitespace

    check_booleans! config

    check_null! config

    check_keytype! config

    check_config_values! config.values
  end

  def check_symbols_match!(config)
    required_object_check!(config, :SYMBOLS)
  end

  def check_quotes!(config)
    quote = config.dig(:SYMBOLS, :QUOTE)

    config[:SYMBOLS][:QUOTE] = case quote
                               when 'double' then '"'
                               when 'single' then "'"
                               else error! "JRB config quote must be either \"single\" or \"double\", got \"#{quote}\""
                               end
  end

  def check_whitespace!(config, force: false)
    if force
      error! 'WHITESPACE array must be provided when passing configuration with config: option.' unless config[:WHITESPACE]
    else
      return unless config[:WHITESPACE]
    end

    config[:WHITESPACE] = if config[:WHITESPACE]
                            config[:WHITESPACE]&.map { |x| "\"#{x}\"".undump }
                          else
                            default_config[:WHITESPACE]
                          end
  end

  def check_booleans!(config)
    required_object_check!(config, :BOOLEAN)
  end

  def check_null!(config)
    config[:NULL] = default_config[:NULL] if config[:NULL].nil? || config[:NULL].empty?
  end

  def check_keytype!(config)
    type = config[:KEYTYPE]

    unless type
      config[:KEYTYPE] = default_config[:KEYTYPE]
      return
    end

    if %w[symbol string].include?(type)
      config[:KEYTYPE] = type
    else
      error! "Value for option \"KEYTYPE\" must be either \"symbol\" or \"string\", got a \"#{type}\"."
    end
  end

  def check_config_values!(values)
    values.each do |value|
      if value.is_a?(Hash)
        check_config_values!(value.values)
      elsif value.is_a?(Array)
        error! 'Value for all array items should be a single word' if value.any? { |x| x.split.length > 1 }
      elsif value.split.length > 1
        error! "Value for all config values should be only a single word, got a \"#{value}\""
      end
    end
  end

  def required_object_check!(config, name)
    error! "Config does not provide a required \"#{name}\" object!" unless config[name]

    expected_symbols = default_config[name].keys
    config_keys = config[name].keys

    all_exist = config_keys.all? { |sym| expected_symbols.include?(sym) }

    leftover = config_keys - expected_symbols
    unless leftover.empty?
      error! "Encountered unexpected keys for required object #{name} in config: \"#{leftover.map(&:to_s).join(', ')}\""
    end

    missing = expected_symbols - config_keys
    error! "The following required keys are missing in object \"#{name}\": #{missing.map(&:to_s).join(', ')}" unless missing.empty?

    error! "\"#{name}\" object in config does not match the required keys #{expected_symbols.map(&:to_s).join(',')}" unless all_exist
  end
end
