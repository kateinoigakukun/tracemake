# frozen_string_literal: true

require "json"
require "set"
require "optparse"
require "fileutils"
require_relative "tracemake/version"

module Tracemake
  class Error < StandardError; end

  # Represents a time span for a command execution
  class Span < Struct.new(:start, :pid, :sid, :command, :stop)
    def name
      _command = command
      _command = command[1..-1] if command[0] == "-c"
      _command.join(" ")
    end

    def b_event
      {
        "name" => name,
        "ph" => "B",
        "ts" => start * 1_000_000,
        "pid" => 0,
        "tid" => sid,
        "args" => {
          "command" => command
        }
      }
    end

    def e_event
      {
        "name" => name,
        "ph" => "E",
        "ts" => stop * 1_000_000,
        "pid" => 0,
        "tid" => sid,
        "args" => {}
      }
    end
  end

  # Manages slots for process visualization
  class Slots
    attr_reader :slot_by_pid, :busy_slots, :number_of_slots

    def initialize
      @slot_by_pid = {}
      @busy_slots = Set.new
      @number_of_slots = 0
    end

    def schedule(pid)
      @number_of_slots.times do |i|
        unless @busy_slots.include?(i)
          @busy_slots.add(i)
          @slot_by_pid[pid] = i
          return i
        end
      end

      slot_id = @number_of_slots
      @number_of_slots += 1
      @busy_slots.add(slot_id)
      @slot_by_pid[pid] = slot_id
      slot_id
    end

    def free(pid)
      slot_id = @slot_by_pid[pid]
      return if slot_id.nil?
      @busy_slots.delete(slot_id)
      @slot_by_pid.delete(pid)
    end
  end

  # Writer for MakeTrace format
  class MakeTraceWriter
    def initialize(trace_file)
      @trace_file = trace_file
      FileUtils.mkdir_p(File.dirname(@trace_file))
    end

    def write_begin_event(pid, time, args)
      write_event({
        "pid" => pid,
        "type" => "B",
        "time" => time,
        "args" => args
      })
    end

    def write_end_event(pid, time, exit_status = nil)
      event = {
        "pid" => pid,
        "type" => "E",
        "time" => time
      }
      event["exit_status"] = exit_status if exit_status
      write_event(event)
    end

    private

    def write_event(event)
      File.open(@trace_file, "a") do |f|
        f.flock(File::LOCK_EX)
        f.write(JSON.generate(event) + "\n")
        f.flush
      end
    end
  end

  # Main class for converting make trace to Chrome Tracing format
  class MakeTrace2ChromeTracing
    def initialize
      @open_spans = Set.new
      @closed_spans = []
    end

    def generate(input_file, output_file)
      events = parse_events(input_file)
      process_events(events)
      spans = @closed_spans.sort_by(&:start)
      generate_output(spans, output_file)
    end

    private

    def parse_events(input_file)
      events = []
      lines = File.readlines(input_file)
      while line = lines.shift
        events << JSON.parse(line)
      end
      events.sort_by { |e| e["time"] }
    end

    def process_events(events)
      slots = Slots.new

      events.each do |event|
        if event["type"] == "B"
          pid, ts, cmd = event["pid"], event["time"], event["args"]
          sid = slots.schedule(pid)
          @open_spans.add(Span.new(ts, pid, sid, cmd, nil))
        elsif event["type"] == "E"
          pid, ts = event["pid"], event["time"]
          slots.free(pid)

          found = false
          @open_spans.each do |span|
            if span.pid == pid
              @open_spans.delete(span)
              span.stop = ts
              @closed_spans << span
              found = true
              break
            end
          end
          $stderr.puts "Warning: no start for pid #{pid}" unless found
        end
      end
    end

    def generate_output(spans, output_file)
      events = []
      spans.each do |span|
        events << span.b_event
        events << span.e_event
      end

      File.write(
        output_file,
        JSON.generate({ "traceEvents" => events, "displayTimeUnit" => "ms" })
      )
    end
  end

  # Command line interface
  class CLI
    def initialize(argv)
      @argv = argv
      @trace_file = ENV["TRACE_FILE"] || ".make.trace"
    end

    def run
      case @argv.shift
      when "shell"
        run_shell
      when "aggregate"
        run_aggregate
      else
        show_usage
      end
    end

    private

    def run_shell
      shell_args = @argv
      writer = MakeTraceWriter.new(@trace_file)
      writer.write_begin_event(Process.pid, Time.now.to_f, shell_args)

      Kernel.system("/bin/sh", *shell_args)
      exit_status = $?

      writer.write_end_event(Process.pid, Time.now.to_f, exit_status.exitstatus)
      Kernel.exit(exit_status.exitstatus)
    end

    def run_aggregate
      options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: tracemake aggregate [options]"
        opts.on("-o", "--output FILE", "Output file") do |v|
          options[:output] = v
        end
      end.parse!(@argv)

      output_file = options[:output]
      if output_file.nil?
        puts "Output file is required."
        exit 1
      end

      processor = MakeTrace2ChromeTracing.new
      processor.generate(@trace_file, output_file)
      puts "Trace aggregated to #{output_file}"
    end

    def show_usage
      puts "Usage: tracemake aggregate [<input_file>] -o <output_file>"
      puts "       tracemake shell <command>"
      exit 1
    end
  end
end
