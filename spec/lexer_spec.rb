describe Lexer do
  context 'works correctly for simple values' do
    it 'lexes empty string' do
      expect(Lexer.lex!('')).to eq []
    end

    context 'lexes a JSON' do
      it 'string' do
        text = '"hello world", "I am a
multiline string"'
        result = Lexer.lex!(text)
        tokens = [
          Token.new(TokenType::String, '"hello world"'),
          ',',
          Token.new(TokenType::String, '"I am a
multiline string"')
        ]

        expect(result.length).to eq 3

        tokens.each_with_index do |token, idx|
          expect(result[idx]).to eq token
        end
      end

      it 'numbers' do
        text = '1, 6.9, -2, -420.0, 3e6, -2e6'
        result = Lexer.lex!(text)

        tokens = [
          Token.new(TokenType::Number, 1),
          ',',
          Token.new(TokenType::Number, 6.9),
          ',',
          Token.new(TokenType::Number, -2),
          ',',
          Token.new(TokenType::Number, -420.0),
          ',',
          Token.new(TokenType::Number, 3e6),
          ',',
          Token.new(TokenType::Number, -2e6)
        ]

        expect(result.length).to eq 11

        tokens.each_with_index do |token, idx|
          expect(result[idx]).to eq token
        end
      end

      it 'booleans' do
        text = 'true, false'
        result = Lexer.lex!(text)

        tokens = [
          Token.new(TokenType::Boolean, true),
          ',',
          Token.new(TokenType::Boolean, false)
        ]
        expect(result.length).to eq 3

        tokens.each_with_index do |token, idx|
          expect(result[idx]).to eq token
        end
      end

      it 'null' do
        text = 'null'
        result = Lexer.lex!(text)

        tokens = [
          Token.new(TokenType::Null, nil)
        ]
        expect(result.length).to eq 1

        tokens.each_with_index do |token, idx|
          expect(result[idx]).to eq token
        end
      end

      it 'ignores whitespace' do
        text = '
           '
        result = Lexer.lex!(text)

        expect(result.length).to eq 0
        expect(result).to be_empty
      end

      it 'parses symbols' do
        text = '[[[{,,,}]]]'
        result = Lexer.lex!(text)

        tokens = text.chars
        expect(result.length).to eq text.length

        tokens.each_with_index do |token, idx|
          expect(result[idx]).to eq token
        end
      end

      it 'exists when encountering invalid symbols' do
        text = '\*_/!@#$%^)(+='

        text.chars.each do |char|
          expect { Lexer.lex!(char.to_s) }.to raise_error SystemExit
        end
      end
    end
  end
end
