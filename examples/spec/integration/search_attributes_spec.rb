require 'temporal/errors'

describe 'search attributes' do
  let(:attribute_1) { 'Age' }
  let(:attribute_2) { 'Name' }

  def cleanup
    custom_attributes = Temporal.list_custom_search_attributes
    custom_attributes.keys.intersection([attribute_1, attribute_2]).each do |attribute|
      Temporal.remove_custom_search_attributes(attribute)
    end
  end

  before do
    cleanup
  end

  after do
    cleanup
  end

  # Depending on the visibility storage backend of the server, recreating a search attribute
  # is either ignored so long as the tpe is the same (Elastic Search) or it raises
  # an error (SQL). This function ensures consistent state upon exit.
  def safe_add(attributes)
    begin
      Temporal.add_custom_search_attributes(attributes)
    rescue => e
      # This won't always throw but when it does it needs to be of this type
      expect(e).to be_instance_of(Temporal::SearchAttributeAlreadyExistsFailure)
    end
  end

  it 'add' do
    safe_add({ attribute_1 => :int, attribute_2 => :keyword })

    custom_attributes = Temporal.list_custom_search_attributes
    expect(custom_attributes).to include(attribute_1 => :int)
    expect(custom_attributes).to include(attribute_2 => :keyword)
  end

  it 'add duplicate fails' do
    safe_add({ attribute_1 => :int })

    # This, however, will always throw
    expect do
      Temporal.add_custom_search_attributes(
        {
          attribute_1 => :int
        }
      )
    end.to raise_error(Temporal::SearchAttributeAlreadyExistsFailure)
  end

  it 'remove' do
    safe_add({ attribute_1 => :int, attribute_2 => :keyword })

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
