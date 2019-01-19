require "./assertion"

module CrSerializer::Assertions
  # Validates a property is greater than or equal to a value
  #
  # Usable on any type that includes `Comparable`
  #
  # ```
  # @[Assert::GreaterThanOrEqual(value: Time.utc_now))]
  # property now : Time
  # ```
  #
  # NOTE: value can be: a hard-coded value like `10`, the name of another property, or the name of a method
  # NOTE: Nil values are considered valid
  class GreaterThanOrEqualAssertion(ActualValueType) < Assertion
    @message : String = "'{{field}}' should be greater than or equal to {{value}}"

    def initialize(field : String, message : String?, @actual : ActualValueType, @value : ActualValueType)
      super field, message
    end

    def valid? : Bool
      (value = @value) && (actual = @actual) ? actual >= value : true
    end
  end
end
