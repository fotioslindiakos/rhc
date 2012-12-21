require 'spec_helper'
require 'rhc/rest'
require 'rhc/rest/base'
require 'rhc/rest/dynamic'

# It's easier to define these here because if defined
# during the tests, they persist.
# This will make sure they are not duplicated
class TestClass < RHC::Rest::Base;
  define_rest_method :simple
  define_rest_method :different_link, :LINK => "FOOBAR"
  define_rest_method :with_event, :event => :foo
end

describe RHC::Rest::Dynamic do
  subject{ TestClass.new }
  let(:link){ method_name.to_s.upcase }
  let(:arguments){ {} }
  let(:options){ {} }

  shared_examples_for "a rest_method" do
    it "should define the rest method" do
      should respond_to(method_name)
    end
    it "should call the method with the correct options" do
      subject.should_receive(:rest_method).once.with(link,arguments,options)
      # TODO: Need the ability to pass arguments
      subject.send(method_name)
    end
  end

  describe "simple rest_method" do
    let(:method_name){ :simple }

    context "with no options" do
      it_should_behave_like "a rest_method"
    end
  end

  describe "different link name" do
    let(:method_name){ :different_link }
    let(:link){ "FOOBAR" }

    context "with no options" do
      it_should_behave_like "a rest_method"
    end
  end

  describe "with event" do
    let(:method_name){ :with_event }
    let(:arguments){ {:event => :foo} }

    context "with no options" do
      it_should_behave_like "a rest_method"
    end
  end
end
