# Tracemake

[![Gem Version](https://badge.fury.io/rb/tracemake.svg)](https://badge.fury.io/rb/tracemake)

A tool to trace `make` command execution and convert it to Chrome Tracing format. This gem allows tracking the execution time of each command in a make process.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tracemake'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install tracemake
```

## Usage

### 1. Run make with this gem as the shell:

```bash
make SHELL="tracemake shell" -j8
```

### 2. Convert the trace to Chrome Tracing format:

```bash
tracemake aggregate -o make-trace.json
```

### 3. Open the resulting JSON file in Chrome's chrome://tracing or https://ui.perfetto.dev/

The trace file will be created in the current directory as `.make.trace`. You can override this location by setting the `TRACE_FILE` environment variable:

```bash
TRACE_FILE=/path/to/trace make SHELL="tracemake shell" -j8
```

> **Note**: When running multiple make commands in sequence, make sure to remove the `.make.trace` file before each run to avoid mixing traces from different make processes:
> ```bash
> rm -f .make.trace
> make SHELL="tracemake shell" -j8
> ```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kateinoigakukun/tracemake.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Tracemake project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/tracemake/blob/main/CODE_OF_CONDUCT.md).
