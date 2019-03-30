# Defines a custom assertion's annotation and registers with the `ASSERTIONS` constant.
#
# ```
# register_assertion(Assert::MyCustom, [:value])
# ```
macro register_assertion(name, fields)
  module CrSerializer::Assertions
    annotation {{name.id}}; end
    {% CrSerializer::Assertions::ASSERTIONS[name] = fields %}
  end
end

# :nodoc:
module Assert
  # Creates the assertion annotations
  {% for t in CrSerializer::Assertions::ASSERTIONS %}
      # :nodoc:
      annotation {{t}}; end
  {% end %}
end
