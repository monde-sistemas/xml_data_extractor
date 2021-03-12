RSpec.describe Extract::Expression do
  let(:hash) { { key: '1', foo: 'bar' }}
  let(:expression_class) { described_class.new(expression, hash)}

  context "when is a single condition" do
    let(:expression) {"'key' == '1'"}

    it { expect(expression_class.evaluate).to eq(true)}
  end

  context "when is a multiple conditions" do
    let(:expression) {"'key' == '1' && 'foo' == 'bar'"}

    it { expect(expression_class.evaluate).to eq(true)}
  end
end