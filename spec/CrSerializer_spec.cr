require "./spec_helper"

class SerializedNameTest
  include CrSerializer::Json

  @[CrSerializer::Json::Options(serialized_name: "years_young")]
  property age : Int32
end

class ExposeTest
  include CrSerializer::Json

  @[CrSerializer::Json::Options(expose: false)]
  property age : Int32

  property name : String
end

class EmitNullTest
  include CrSerializer::Json

  @[CrSerializer::Json::Options(emit_null: true)]
  property age : Int32?

  property name : String

  property im_null : String? = nil
end

class AccessorTest
  include CrSerializer::Json

  @[CrSerializer::Json::Options(accessor: get_name)]
  property name : String

  def get_name : String
    @name.upcase
  end
end

class ReadOnlyTest
  include CrSerializer::Json

  property age : Int32

  @[CrSerializer::Json::Options(readonly: true)]
  property name : String?

  @[CrSerializer::Json::Options(readonly: true)]
  property password : String = "ADefaultPassword"
end

class NoAnnotationsTest
  include CrSerializer::Json

  property age : Int32
  property name : String
  property password : String
end

class NestedTest
  include CrSerializer::Json

  property name : Name

  property age : Age
end

class NestedArrayTest
  include CrSerializer::Json

  property name : Name

  property age : Age

  property friends : Array(Friend)
end

class NestedValidTest
  include CrSerializer::Json

  @[Assert::Valid]
  property name : Name

  property age : Age
end

class NestedArrayValidTest
  include CrSerializer::Json

  property name : Name

  property age : Age

  @[Assert::Valid]
  property friends : Array(Friend)
end

class Age
  include CrSerializer::Json

  @[Assert::LessThan(value: 10)]
  property yrs : Int32?
end

class Name
  include CrSerializer::Json

  @[Assert::EqualTo(value: "foo")]
  property n : String
end

class Friend
  include CrSerializer::Json

  @[Assert::EqualTo(value: "Jim")]
  property n : String
end

@[CrSerializer::Options(raise_on_invalid: true)]
class RaiseTest
  include CrSerializer::Json

  @[Assert::EqualTo(value: 10)]
  property age : Int32
end

@[CrSerializer::Options(validate: false)]
class ValidateTest
  include CrSerializer::Json

  @[Assert::EqualTo(value: 10)]
  property age : Int32
end

@[CrSerializer::Options(exclusion_policy: CrSerializer::ExclusionPolicy::EXCLUDE_ALL)]
class ExcludeAlltest
  include CrSerializer::Json

  property age : Int32 = 22
  property name : String = "Joe"

  @[CrSerializer::Json::Options(expose: true)]
  property value : String = "foo"
end

describe CrSerializer do
  describe "serialize" do
    describe "serialized_name" do
      it "should serialize correctly" do
        model = SerializedNameTest.new
        model.age = 77
        model.serialize.should eq %({"years_young":77})
      end
    end

    describe "expose" do
      it "should serialize correctly" do
        model = ExposeTest.new
        model.name = "John"
        model.age = 77
        model.serialize.should eq %({"name":"John"})
      end
    end

    describe "emit_null" do
      it "should serialize correctly" do
        model = EmitNullTest.new
        model.name = "John"
        model.im_null = "foo"
        model.serialize.should eq %({"age":null,"name":"John","im_null":"foo"})
      end

      it "should not emit_null by default" do
        model = EmitNullTest.new
        model.name = "John"
        model.serialize.should eq %({"age":null,"name":"John"})
      end
    end

    describe "accessor" do
      it "should serialize correctly" do
        model = AccessorTest.new
        model.name = "John"
        model.serialize.should eq %({"name":"JOHN"})
      end
    end

    describe "exclusion_policy" do
      it "should not expose properties by default" do
        model = ExcludeAlltest.new
        model.serialize.should eq %({"value":"foo"})
      end
    end
  end

  describe "deserialize" do
    describe "readonly" do
      it "should deserialize correctly" do
        model = ReadOnlyTest.deserialize %({"name":"Secret","age":22,"password":"monkey"})
        model.age.should eq 22
        model.name.should be_nil
        model.password.should eq "ADefaultPassword"
      end
    end

    describe "with no annotations" do
      it "should deserialize correctly" do
        model = NoAnnotationsTest.deserialize %({"name":"Secret","age":22,"password":"monkey"})
        model.age.should eq 22
        model.name.should eq "Secret"
        model.password.should eq "monkey"
      end
    end

    describe "nested classes" do
      context "without valid assertion" do
        context "with single objects" do
          describe "when all properties are valid" do
            it "should deserialize correctly" do
              model = NestedTest.deserialize %({"name":{"n": "foo"},"age":{"yrs": 5}})
              model.age.should be_a Age
              model.age.validator.valid?.should be_true
              model.age.yrs.should eq 5
              model.name.should be_a Name
              model.name.validator.valid?.should be_true
              model.name.n.should eq "foo"
            end
          end

          describe "when a proeprty subclass is invalid" do
            it "should not invalidate parent object" do
              model = NestedTest.deserialize %({"name":{"n": "bar"},"age":{"yrs": 15}})
              model.validator.valid?.should be_true
              model.age.validator.valid?.should be_false
              model.age.validator.errors.first.should eq "'yrs' should be less than 10"
              model.name.validator.valid?.should be_false
              model.name.validator.errors.first.should eq "'n' should be equal to foo"
            end
          end
        end

        context "with an array of objects" do
          describe "when all properties are valid" do
            it "should deserialize correctly" do
              model = NestedArrayTest.deserialize %({"name":{"n": "foo"},"age":{"yrs": 5},"friends":[{"n":"Jim"},{"n":"Jim"}]})
              model.validator.valid?.should be_true
              model.age.should be_a Age
              model.age.validator.valid?.should be_true
              model.age.yrs.should eq 5
              model.name.should be_a Name
              model.name.validator.valid?.should be_true
              model.name.n.should eq "foo"
              model.friends.should be_a Array(Friend)
              model.friends[0].validator.valid?.should be_true
              model.friends[0].n.should eq "Jim"
              model.friends[1].validator.valid?.should be_true
              model.friends[1].n.should eq "Jim"
            end
          end

          describe "when a proeprty subclass is invalid" do
            it "should not invalidate parent object" do
              model = NestedArrayTest.deserialize %({"name":{"n": "bar"},"age":{"yrs": 15},"friends":[{"n":"Bob"},{"n":"Jim"}]})
              model.validator.valid?.should be_true
              model.age.validator.valid?.should be_false
              model.age.validator.errors.first.should eq "'yrs' should be less than 10"
              model.name.validator.valid?.should be_false
              model.name.validator.errors.first.should eq "'n' should be equal to foo"
              model.friends[0].validator.valid?.should be_false
              model.friends[0].validator.errors.first.should eq "'n' should be equal to Jim"
              model.friends[1].validator.valid?.should be_true
            end
          end
        end
      end

      context "with valid assertion" do
        context "with single objects" do
          describe "when all properties are valid" do
            it "should deserialize correctly and be valid" do
              model = NestedValidTest.deserialize %({"name":{"n": "foo"},"age":{"yrs": 5}})
              model.age.should be_a Age
              model.age.yrs.should eq 5
              model.name.should be_a Name
              model.name.n.should eq "foo"
            end
          end

          describe "when a proeprty subclass is invalid" do
            it "should invalidate the parent object" do
              model = NestedValidTest.deserialize %({"name":{"n": "bar"},"age":{"yrs": 15}})
              model.validator.valid?.should be_false
              model.age.validator.valid?.should be_false
              model.age.validator.errors.first.should eq "'yrs' should be less than 10"
              model.name.validator.valid?.should be_false
              model.name.validator.errors.first.should eq "'n' should be equal to foo"
            end
          end
        end

        context "with an array of objects" do
          describe "when all properties are valid" do
            it "should deserialize correctly" do
              model = NestedArrayValidTest.deserialize %({"name":{"n": "foo"},"age":{"yrs": 5},"friends":[{"n":"Jim"},{"n":"Jim"}]})
              model.validator.valid?.should be_true
              model.age.should be_a Age
              model.age.validator.valid?.should be_true
              model.age.yrs.should eq 5
              model.name.should be_a Name
              model.name.validator.valid?.should be_true
              model.name.n.should eq "foo"
              model.friends.should be_a Array(Friend)
              model.friends[0].validator.valid?.should be_true
              model.friends[0].n.should eq "Jim"
              model.friends[1].validator.valid?.should be_true
              model.friends[1].n.should eq "Jim"
            end
          end

          describe "when a proeprty subclass is invalid" do
            it "should invalidate parent object" do
              model = NestedArrayValidTest.deserialize %({"name":{"n": "bar"},"age":{"yrs": 15},"friends":[{"n":"Bob"},{"n":"Jim"}]})
              model.validator.valid?.should be_false
              model.age.validator.valid?.should be_false
              model.age.validator.errors.first.should eq "'yrs' should be less than 10"
              model.name.validator.valid?.should be_false
              model.name.validator.errors.first.should eq "'n' should be equal to foo"
              model.friends[0].validator.valid?.should be_false
              model.friends[0].validator.errors.first.should eq "'n' should be equal to Jim"
              model.friends[1].validator.valid?.should be_true
            end
          end
        end
      end
    end

    describe "class options" do
      describe "raise_on_invalid" do
        it "should raise correct exception" do
          expect_raises CrSerializer::Exceptions::ValidationException, "Validation tests failed" { RaiseTest.deserialize %({"age":22}) }
        end

        it "should build correct exception object" do
          begin
            RaiseTest.deserialize %({"age":22})
          rescue ex : CrSerializer::Exceptions::ValidationException
            ex.message.should eq "Validation tests failed"
            ex.to_json.should eq %({"code":400,"message":"Validation tests failed","errors":["'age' should be equal to 10"]})
          end
        end
      end

      describe "validate" do
        it "should not run validations when validate is set to false" do
          model = ValidateTest.deserialize %({"age":22})
          model.validator.valid?.should be_true
          model.age.should eq 22
        end
      end
    end
  end
end
