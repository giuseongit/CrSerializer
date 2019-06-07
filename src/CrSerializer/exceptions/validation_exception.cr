module CrSerializer::Exceptions
  # Exception thrown when an object is not valid and `raise_on_invalid` is true.
  class ValidationException < Exception
    def initialize(@validator : Validator)
      super "Validation tests failed"
    end

    # Returns a validation failed 400 JSON error for easy error handling with REST APIs.
    #
    # ```
    # {
    #   "code":    400,
    #   "message": "Validation tests failed",
    #   "errors":  [
    #     "'password' should not be blank",
    #     "'age' should be greater than 1",
    #   ],
    # }
    # ```
    def to_json : String
      {
        code:    400,
        message: @message,
        errors:  @validator.validation_errors,
      }.to_json
    end

    # Returns failed valications as a string.
    #
    # ```
    # Validation tests failed:  `'password' should not be blank`, `'age' should be greater than 1`.
    # ```
    def to_s : String
      String.build do |str|
        str << "Validation tests failed: "
        @validator.validation_errors.join(str) { |v| str << '`' << v << '`' }
        str << '.'
      end
    end
  end
end
