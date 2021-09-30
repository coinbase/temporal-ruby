require 'temporal/errors'

module Temporal
  # See https://docs.temporal.io/docs/content/what-is-a-parent-close-policy/ for more information
  class ParentClosePolicy
    class InvalidParentClosePolicy < ClientError; end

    attr_reader :policy

    def initialize(policy)
      @policy = policy
    end

    def validate!
      unless %i[terminate abandon request_cancel].include?(@policy)
        raise InvalidParentClosePolicy, 'Invalid parent close policy, only :abandon, :terminate, :request_cancel are allowed'
      end
    end
  end
end
