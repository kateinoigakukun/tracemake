# frozen_string_literal: true

require_relative "test_helper"

class TracemakeTest < Test::Unit::TestCase
  include TestHelper

  def test_span_name_without_c_flag
    span = Tracemake::Span.new(0, 1, 0, ["echo", "hello"], nil)
    assert_equal "echo hello", span.name
  end

  def test_span_name_with_c_flag
    span = Tracemake::Span.new(0, 1, 0, ["-c", "echo", "hello"], nil)
    assert_equal "echo hello", span.name
  end

  def test_slots_schedule_and_free
    slots = Tracemake::Slots.new
    pid1 = 1001
    pid2 = 1002

    # First slot assignment
    slot1 = slots.schedule(pid1)
    assert_equal 0, slot1
    assert slots.busy_slots.include?(slot1)
    assert_equal slot1, slots.slot_by_pid[pid1]

    # Second slot assignment
    slot2 = slots.schedule(pid2)
    assert_equal 1, slot2
    assert slots.busy_slots.include?(slot2)
    assert_equal slot2, slots.slot_by_pid[pid2]

    # Free first slot
    slots.free(pid1)
    assert_false slots.busy_slots.include?(slot1)
    assert_false slots.slot_by_pid.key?(pid1)

    # Reuse first slot
    slot3 = slots.schedule(1003)
    assert_equal 0, slot3
  end

  def test_e2e_simple_make
    with_temp_file("make_trace", "txt", keep: true) do |trace_file|
      # Run make with tracemake as shell
      system({ "TRACE_FILE" => trace_file }, "make", "-C", "test/fixtures", "SHELL=#{exe_path}/tracemake shell", "-j2")

      # Convert trace to Chrome Tracing format
      with_temp_file("trace", "json", keep: true) do |output_file|
        processor = Tracemake::MakeTrace2ChromeTracing.new
        processor.generate(trace_file, output_file)

        # Verify the Chrome Tracing output
        result = JSON.parse(File.read(output_file))
        events = result["traceEvents"]
        assert_operator events.length, :>=, 6 # 3 commands * 2 events each at least

        # Verify commands are present
        commands = events.map { |e| e["name"] }.uniq
        assert_include commands, "echo \"Building step1\""
        assert_include commands, "sleep 1"
        assert_include commands, "echo \"Linking step1 and step2 into program\""

        # Verify events are properly ordered
        timestamps = events.filter { |e| e["ph"] == "B" }.map { |e| e["ts"] }
        assert_equal timestamps.sort, timestamps

        # Verify each command has both begin and end events
        commands = events.group_by { |e| e["name"] }
        commands.each do |name, cmd_events|
          assert_equal 0, cmd_events.length % 2, "Command #{name} should have both begin and end events"
          assert_equal ["B", "E"], cmd_events.map { |e| e["ph"] }.uniq.sort
        end
      end
    end
  end

  private

  def exe_path
    File.expand_path("../exe", __dir__)
  end
end
