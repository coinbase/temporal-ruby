module Temporal
  module Concerns
    module InputDeserializer
      def deserialize(input)
        JSON.deserialize(input)
      rescue Oj::ParseError, ::JSON::ParserError
        # JSON.parse now runs before Oj.load, so newline-split Go-client input raises
        # JSON::ParserError instead of Oj::ParseError. Do not rescue JSONDisallowedClassError.
        # Copied over from the Cadence side, similar situation happening with Temporal
        #
        # cadence official go-client serializes / deserializes input in a different format than this ruby client
        # adding additional deserialization logic here to help read input that is passed from go-client
        # https://github.com/uber-go/cadence-client/blob/0.18.x/internal/encoding.go#L45-L58
        #
        # this ruby client serializes / deserializes everything as one big string like below:
        # [1012474654, "second input"]
        #
        # while go client serializes input as separate input followed by line break
        # 1012474654
        # second input
        args = input.split(/\n/)
        res = args.map do |arg|
          JSON.deserialize(arg)
        end
      end
    end
  end
end