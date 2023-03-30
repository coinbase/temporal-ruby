require 'temporal/errors'

describe 'search attributes' do
  let(:attribute_1) { 'Age' }
  let(:attribute_2) { 'Name' }

  def cleanup
    custom_attributes = Temporal.list_custom_search_attributes
    Temporal.remove_custom_search_attributes(attribute_1) if custom_attributes.include?(attribute_1)
    Temporal.remove_custom_search_attributes(attribute_2) if custom_attributes.include?(attribute_2)
  end

  before do
    cleanup
  end

  after do
    cleanup
  end

  it 'add' do
    Temporal.add_custom_search_attributes(
      {
        attribute_1 => :int,
        attribute_2 => :keyword
      }
    )

    custom_attributes = Temporal.list_custom_search_attributes
    expect(custom_attributes).to include(attribute_1 => :int)
    expect(custom_attributes).to include(attribute_2 => :keyword)
  end

  it 'add duplicate fails' do
    Temporal.add_custom_search_attributes(
      {
        attribute_1 => :int
      }
    )

    expect do
      Temporal.add_custom_search_attributes(
        {
          attribute_1 => :int
        }
      )
    end.to raise_error(Temporal::SearchAttributeAlreadyExistsFailure)
  end

  it 'remove' do
    Temporal.add_custom_search_attributes(
      {
        attribute_1 => :int,
        attribute_2 => :keyword
      }
    )

    Temporal.remove_custom_search_attributes(attribute_1, attribute_2)

    custom_attributes = Temporal.list_custom_search_attributes
    expect(custom_attributes).not_to include(attribute_1 => :int)
    expect(custom_attributes).not_to include(attribute_2 => :keyword)
  end

  it 'remove non-existent fails' do
    expect do
      Temporal.remove_custom_search_attributes(attribute_1, attribute_2)
    end.to raise_error(Temporal::NotFoundFailure)
  end
end
