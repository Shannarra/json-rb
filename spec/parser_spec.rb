# rubocop:disable Metrics/BlockLength
describe Parser do
  def parse!(text)
    Parser.parse!(Lexer.lex!(text))
  end

  context 'parses items correctly' do
    context 'and returns value expressions for simple values such as' do
      # STD JSON will ignore anything after the first ','
      # in a list of items such as `JSON.parse("1,2,3")`
      # and return the first value before the ',',
      # hence the tests:

      it 'strings' do
        text = '"hello world", "asd"'

        expect(parse!(text)).to eq '"hello world"'
      end

      it 'numbers' do
        text = '1, 6.9, -2, -420.0, 3e6, -2e6'

        expect(parse!(text)).to eq 1
      end

      it 'booleans' do
        text = 'true, false'

        expect(parse!(text)).to eq true
      end

      it 'null' do
        text = 'null'

        expect(parse!(text)).to eq nil
      end

      it 'empty array' do
        text = '[[,]]'

        expect(parse!(text)).to eq [[',']]
      end
    end

    context 'for simplistic json objects' do
      it 'with strings as values' do
        text = '{"prop": "hello world"}'
        result = parse!(text)

        expect(result['prop']).to eq '"hello world"'
      end

      it 'with numbers as values' do
        text = '{"prop": -12e6}'
        result = parse!(text)

        expect(result['prop']).to eq(-1.2e7)
      end

      it 'with booleans as values' do
        text = '{"true": true, "false": false}'
        result = parse!(text)

        expect(result['true']).to eq true
        expect(result['false']).to eq false
      end

      it 'with numbers as values' do
        text = '{"prop": null}'
        result = parse!(text)

        expect(result['prop']).to eq nil
      end
    end

    context 'for simple arrays as values of' do
      it 'strings' do
        text = '{"items": ["hello world", "asd"]}'

        result = parse! text

        expect(result['items']).to match ['"hello world"', '"asd"']
      end

      it 'numbers' do
        text = '{"items": [1, 6.9, -2, -420.0, 3e6, -2e6]}'

        result = parse! text

        expect(result['items']).to match [1, 6.9, -2, -420.0, 3e6, -2e6]
      end

      it 'booleans' do
        text = '{"items": [true, false]}'

        result = parse! text

        expect(result['items']).to match [true, false]
      end

      it 'null' do
        text = '{"items": [null]}'

        result = parse! text

        expect(result['items']).to match [nil]
      end

      it 'mixed bag' do
        text = '{"items":[1,6.9,-12e5,"Hello World!",{"name":"John Doe"}, [2,3,4,5,6]]}}'

        result = parse! text

        expect(result['items']).to match [1, 6.9, -1.2e6, '"Hello World!"', { 'name' => '"John Doe"' }, [2, 3, 4, 5, 6]]
      end
    end

    context 'for simple objects as values' do
      it 'basic non-nested values' do
        text = '{
        "items": {
            "int": 1,
            "float": 6.9,
            "exp": -12e5,
            "str": "Hello World!",
            "object": {"name":"John Doe"},
            "array":[2,3,4,5,6]
        }
      }'

        result = parse! text
        expected_items = {
          int: 1,
          float: 6.9,
          exp: -1.2e6,
          str: '"Hello World!"',
          object: { 'name' => '"John Doe"' },
          array: [2, 3, 4, 5, 6]
        }

        expected_items.each do |(key, value)|
          expect(result['items'][key.to_s]).to eq value
        end
      end
    end

    context 'for tougher deeply nested JSON files' do
      # For more context just see the ./tests/very_nested.json file

      let(:very_nested_json) { File.read('./tests/very_nested.json') }

      # if it doesn't parse none of the tests in this context will pass
      before(:each) do
        @result = parse! very_nested_json
      end

      it 'knows about the top-level keys' do
        expect(@result['problems']).not_to be nil
      end

      it 'knows about the top-level keys' do
        keys = @result['problems'].first.keys
        expect(keys.count).to eq 2
        expect(keys).to eq %w[Diabetes Asthma]
      end

      it 'knows that asthma is empty' do
        items = @result['problems'].first['Asthma'].first

        expect(items).to be_empty
      end

      it 'knows that diabetes is NOT empty' do
        items = @result['problems'].first['Diabetes'].first

        expect(items).not_to be_empty
      end

      it 'can dig to the deepest level' do
        diabetes = @result['problems'].first['Diabetes'].first
        classes = diabetes['medications'].first['medicationsClasses']

        expect(classes.count).to eq 1
        expect(classes.first.count).to eq 2

        # if this passes then everything will, I hope :prayge:
        drug = classes.first['className'].first['associatedDrug'].first
        expect(drug['name']).to eq '"asprin"'
        expect(drug['dose']).to eq '""'
        expect(drug['strength']).to eq '"500 mg"'
      end
    end

    context 'for tricky before-and-after array values' do
      let(:text) do
        '{
             "hello": "world",
             "items": [
                 1,
                 6.9,
                 -1.2e6,
                 "Hello World!",
                 null,
                 false,
                 true,
                 [
                     1,
                     2,
                     3
                 ],
                 {
                     "name": "John Doe",
                     "false": true,
                     "true": false,
                     "value": null
                 }
             ],
             "foo": {
                 "data": {
                     "weirdnum": -4.20e69
                 },
                 "asd": "ASD"
             }
         }'
      end

      before(:each) do
        @result = parse! text
        

        @items_result = [
          1,
          6.9,
          -1_200_000,
          '"Hello World!"',
          nil,
          false,
          true,
          [
            1,
            2,
            3
          ],
          {
            'name' => '"John Doe"',
            'false' => true,
            'true' => false,
            'value' => nil
          }
        ]
      end

      it 'handles values before array' do
        expect(@result['hello']).to eq '"world"'
      end

      context 'handles the array correctly' do
        before(:each) do
          @arr = @result['items']
        end

        it 'and has correct length' do
          expect(@arr.length).to eq @items_result.length
        end

        it 'and has matching values for simple values' do
          expect(@arr[..-2]).to match_array @items_result[..-2]
        end

        it 'and has matching values for nested arrays' do
          expect(@arr[-3..-2]).to match_array @items_result[-3..-2]
        end

        it 'and has matching values for nested objects' do
          expect(@arr[-1]).to match @items_result[-1]
        end
      end

      context 'handles values after array' do
        before(:each) do
          @obj = @result['foo']
        end

        it 'and nested objects correctly' do
          expect(@obj.dig('data', 'weirdnum')).to eq(-4.20e69) # nice
        end

        it 'and object\'s values correctly' do
          expect(@obj['asd']).to eq '"ASD"'
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
