describe Kernel do
  describe '#error!' do
    let(:error) { 'Error message here!' }

    it 'should exit the program' do
      expect { error!(error) }.to raise_error SystemExit
    end
  end

  describe '#enum' do
    let(:variants) { %w[positive negative zero] }

    context 'generates' do
      it 'a module' do
        expect(enum(variants).class).to eq Module
      end

      it 'all possible values provided' do
        # rubocop:disable Lint/ConstantDefinitionInBlock
        NumberTypes = enum variants
        # rubocop:enable Lint/ConstantDefinitionInBlock

        variants.each do |variant|
          expect(instance_eval("NumberTypes::#{variant.capitalize}", __FILE__, __LINE__)).to eq variant # NumerTypes::Positive
        end
      end
    end
  end
end
