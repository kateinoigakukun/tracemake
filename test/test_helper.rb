# frozen_string_literal: true

require "test/unit"
require "tempfile"
require "securerandom"
require_relative "../lib/tracemake"

# Helper module for tests
module TestHelper
  def with_temp_file(base_name, ext, keep: false)
    tmp_path = File.expand_path(File.join("tmp", "#{base_name}.#{Process.pid}.#{SecureRandom.hex(8)}.#{ext}"))
    FileUtils.mkdir_p(File.dirname(tmp_path))
    FileUtils.touch(tmp_path)
    yield tmp_path
  ensure
    File.unlink(tmp_path) unless keep
  end
end
