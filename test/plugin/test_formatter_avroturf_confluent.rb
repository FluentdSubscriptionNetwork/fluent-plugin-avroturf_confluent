require "helper"
require "fluent/plugin/formatter_avroturf_confluent.rb"

class AvroturfConfluentFormatterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
    flunk
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Formatter.new(Fluent::Plugin::AvroturfConfluentFormatter).configure(conf)
  end
end
