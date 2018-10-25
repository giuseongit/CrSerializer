require "json"
require "./validator"

# :nodoc:
class Array(T)
  def serialize : String
    self.map(&.serialize)
  end

  def self.deserialize(string_or_io) : Array(T)
    Array(T).from_json string_or_io
  end
end

module CrSerializer::Json
  # :nodoc:
  annotation Options; end

  include JSON::Serializable

  @[JSON::Field(ignore: true)]
  @[CrSerializer::Json::Options(expose: false)]
  # See `Validator`
  getter validator : CrSerializer::Validator = CrSerializer::Validator.new

  macro included
    # Deserializes a JSON string into an object
    def self.deserialize(json_string : String) : self
      from_json(json_string)
    end
  end

  # :nodoc:
  def after_initialize : self
    # Deserialization options
    {% begin %}
      {% for ivar in @type.instance_vars %}
        {% ann = ivar.annotation(CrSerializer::Json::Options) %}
        {% if ann && ann[:readonly] == true %}
          self.{{ivar.id}} = {{ivar.default_value}}
        {% end %}
      {% end %}
    {% end %}

    # Validations
    {% begin %}
      {% cann = @type.annotation(CrSerializer::Options) %}
      {% if !cann || cann[:validate] == true || cann[:validate] == nil %}
        {% for ivar in @type.instance_vars %}
          {% for t, v in CrSerializer::Assertions::ASSERTIONS %}
            {% ann = ivar.annotation(t.resolve) %}
              {% if ann %}
                @validator.assertions << {{t.id}}Assertion({{ivar.type.stringify.id}}).new({{ivar.stringify}},{{ann[:message]}},{{ivar.id}},{{v.select { |fi| ann[fi] }.map { |f| "#{f.id}: #{ann[f]}" }.join(',').id}})
              {% end %}
          {% end %}
        {% end %}
      {% end %}
      {% if cann && cann[:raise_on_invalid] == true %}
        raise CrSerializer::Exceptions::ValidationException.new self.validator unless self.validator.valid?
      {% end %}
    {% end %}
    self
  end

  # Serializes the object to JSON
  def serialize : String
    {% begin %}
      {% properties = {} of Nil => Nil %}
      {% cann = @type.annotation(::CrSerializer::Options) %}
      {% for ivar in @type.instance_vars %}
        {% cr_ann = ivar.annotation(::CrSerializer::Json::Options) %}
        {% unless (cann && cann[:exclusion_policy] == :exclude_all) && (!cr_ann || cr_ann[:expose] != true) %}
          {% if (!cr_ann || (cr_ann && (cr_ann[:expose] == true || cr_ann[:expose] == nil))) %}
            {%
              properties[ivar.id] = {
                serialized_name: ((cr_ann && cr_ann[:serialized_name]) || ivar).id.stringify,
                emit_null:       (cr_ann && cr_ann[:emit_null] == true) ? true : false,
                value:           (cr_ann && cr_ann[:accessor]) ? cr_ann[:accessor] : ivar.id,
              }
            %}
          {% end %}
        {% end %}
      {% end %}
      json = JSON.build do |json|
        json.object do
          {% for name, value in properties %}
            json.field {{value[:serialized_name]}}, {{value[:value]}} {% unless value[:emit_null] %} unless {{name.id}}.nil? {% end %}
          {% end %}
        end
      end
      json
    {% end %}
  end
end
