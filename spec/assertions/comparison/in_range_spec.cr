require "../../spec_helper"

class InRangeTest
  include CrSerializer::Json

  @[CrSerializer::Assertions::InRange(range: 0_f64..100_f64)]
  property age : Int64
end

class InRangeTestMessage
  include CrSerializer::Json

  @[CrSerializer::Assertions::InRange(range: 0_f64..100_f64, min_message: "Age cannot be negative", max_message: "You cannot live more than 100 years")]
  property age : Int32?
end

describe "Assertions::InRange" do
  it "should be valid" do
    model = InRangeTest.deserialize(%({"age": 12}))
    model.validator.valid?.should be_true
  end

  describe "with out of range property" do
    it "should be invalid" do
      model = InRangeTest.deserialize(%({"age": 150}))
      model.validator.valid?.should be_false
      model.validator.errors.size.should eq 1
      model.validator.errors.first.should eq "'age' has failed the in_range_assertion"
    end
  end

  describe "with a custom message" do
    it "should use correct min_message" do
      model = InRangeTestMessage.deserialize(%({"age": -50}))
      model.validator.valid?.should be_false
      model.validator.errors.size.should eq 1
      model.validator.errors.first.should eq "Age cannot be negative"
    end

    it "should use correct max_message" do
      model = InRangeTestMessage.deserialize(%({"age": 150}))
      model.validator.valid?.should be_false
      model.validator.errors.size.should eq 1
      model.validator.errors.first.should eq "You cannot live more than 100 years"
    end
  end
end
