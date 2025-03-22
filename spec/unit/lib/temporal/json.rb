require 'temporal/json'

describe Temporal::JSON do
  let(:hash) { { 'one' => 'one', two: :two, ':three' => ':three' } }
  let(:json) { '{"^i":1,"one":"one",":two":":two","\u003athree":"\u003athree"}' }

  describe '.serialize' do
    it 'generates JSON string' do
      expect(described_class.serialize(hash)).to eq(json)
    end

    it 'does not raise error on circular entries' do
      author = Struct.new('Author', :name, :books)
      book = Struct.new('Book', :author)
      author_entry = author.new(name: 'David')
      book_entry = book.new(title: 'test', author: author)

      author_entry.books = [book_entry]
      json = described_class.serialize(author_entry)

      result = described_class.deserialize(json)
      expect(result).to eq(author_entry)
    end
  end

  describe '.deserialize' do
    it 'parses JSON string' do
      expect(described_class.deserialize(json)).to eq(hash)
    end

    it 'parses empty string to nil' do
      expect(described_class.deserialize('')).to eq(nil)
    end

    it 'parses nil' do
      expect(described_class.deserialize(nil)).to eq(nil)
    end
  end
end
