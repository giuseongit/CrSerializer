require "../../spec_helper"

class GreaterThanOrEqualTest
  include CrSerializer::Json

  @[CrSerializer::Assertions::GreaterThanOrEqual(value: 10)]
  property age : Int32?
end

class GreaterThanOrEqualTestMessage
  include CrSerializer::Json

  @[CrSerializer::Assertions::GreaterThanOrEqual(value: 12, message: "Age should be greater than or equal to 12")]
  property age : Int32
end

class GreaterThanOrEqualTestPropertyPath
  include CrSerializer::Json

  @[CrSerializer::Assertions::GreaterThanOrEqual(property_path: current_age)]
  property age : Int32

  property current_age : Int32 = 15
end

class GreaterThanOrEqualTestMissingValue
  include CrSerializer::Json

  @[CrSerializer::Assertions::GreaterThanOrEqual]
  property age : Int32
end

describe "Assertions::GreaterThanOrEqual" do
  it "should be valid" do
    model = GreaterThanOrEqualTest.deserialize(%({"age": 10}))
    model.validator.valid?.should be_true
  end

  describe "with bigger property" do
    it "should be invalid" do
      model = GreaterThanOrEqualTest.deserialize(%({"age": -12}))
      model.validator.valid?.should be_false
      model.validator.errors.size.should eq 1
      model.validator.errors.first.should eq "'age' has failed the greater_than_or_equal_assertion"
    end
  end

  describe "with nil property" do
    it "should be invalid" do
      model = GreaterThanOrEqualTest.deserialize(%({"age": null}))
      model.validator.valid?.should be_false
      model.validator.errors.size.should eq 1
      model.validator.errors.first.should eq "'age' has failed the greater_than_or_equal_assertion"
    end
  end

  describe "with a custom message" do
    it "should use correct message" do
      model = GreaterThanOrEqualTestMessage.deserialize(%({"age": 9}))
      model.validator.valid?.should be_false
      model.validator.errors.size.should eq 1
      model.validator.errors.first.should eq "Age should be greater than or equal to 12"
    end
  end

  describe "with a property path" do
    it "should use the property path's value" do
      model = GreaterThanOrEqualTestPropertyPath.deserialize(%({"age": 15}))
      model.validator.valid?.should be_true
    end
  end

  describe "with a missing field" do
    it "should raise an exception" do
      expect_raises CrSerializer::Exceptions::MissingFieldException, "Missing required field(s). value or property_path must be supplied" { GreaterThanOrEqualTestMissingValue.deserialize(%({"age": 15})) }
    end
  end
end
