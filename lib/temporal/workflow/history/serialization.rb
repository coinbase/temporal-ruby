module Temporal
  class Workflow
    class History
      # Functions for deserializing workflow histories from JSON and protobuf. These are useful
      # in writing replay tests
      #
      # `from_` methods return Temporal::Workflow::History instances.`
      # `to_` methods take Temporalio::Api::History::V1::History instances
      #
      # This asymmetry stems from our own internal history representation being a projection
      # of the "full" history.
      class Serialization
        # Parse History from a JSON string
        def self.from_json(json)
          raw_history = Temporalio::Api::History::V1::History.decode_json(json, ignore_unknown_fields: true)
          Workflow::History.new(raw_history.events)
        end

        # Convert a raw history to JSON. This method is typically only used by methods on Workflow::Client
        def self.to_json(raw_history, pretty_print: true)
          json = raw_history.to_json
          if pretty_print
            # pretty print JSON to make it more debuggable
            ::JSON.pretty_generate(::JSON.load(json))
          else
            json
          end
        end

        def self.from_json_file(path)
          self.from_json(File.read(path))
        end

        def self.to_json_file(raw_history, path, pretty_print: true)
          json = self.to_json(raw_history, pretty_print: pretty_print)
          File.write(path, json)
        end

        def self.from_protobuf(protobuf)
          raw_history = Temporalio::Api::History::V1::History.decode(protobuf)
          Workflow::History.new(raw_history.events)
        end

        def self.to_protobuf(raw_history)
          raw_history.to_proto
        end

        def self.from_protobuf_file(path)
          self.from_protobuf(File.open(path, 'rb', &:read))
        end
        
        def self.to_protobuf_file(raw_history, path)
          protobuf = self.to_protobuf(raw_history)
          File.open(path, 'wb') do |f|
            f.write(protobuf)
          end
        end
      end
    end
  end
end