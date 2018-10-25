require "../interfaces/comparison_assertion"

module CrSerializer::Assertions
  # Validates a property is greater than a value
  #
  # Usable on only Number properties
  #
  # ```
  # @[CrSerializer::Assertions::GreaterThan(value: 100)]
  # property age : Int64
  # ```
  #
  # NOTE: Nil values are considered valid
  class GreaterThanAssertion(ActualValueType) < ComparisonAssertion(NUMERIC_DATA_TYPES?)
    def valid? : Bool?
      val = @value
      act = @actual
      return unless val && act
      act > val
    end
  end
end