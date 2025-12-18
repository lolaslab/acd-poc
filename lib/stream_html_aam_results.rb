# frozen_string_literal: true

require 'net/http'
require 'zlib'
require 'stringio'
require 'yajl'
require 'pry'

class StreamHtmlAamResults
  # @param run is a WPT test run for a specific browser
  # @param labelled_tests is a Set of filtered WPT tests
  def self.stream_and_filter(run, labelled_tests)
    uri = URI(run['raw_results_url'])
    json_io = Net::HTTP.get(uri)
    filtered_results = []

    parser = Yajl::Parser.new(symbolize_keys: true)
    parser.on_parse_complete = lambda do |json|
      json[:results].each do |test_obj|
        next unless labelled_tests.include?(test_obj[:test]) &&
          test_obj[:test].include?("html-aam") && !test_obj[:test].include?("tentative")
          test_obj[:subtests]&.map { |s|
            # This is trying to infer the element name from the subtest name but
            # there are inconcistencies, especially where the subtest name uses
            # hypens to delinate specifics
            name = s[:name].split.first
            if name.start_with?("el-")
              name.delete_prefix!("el-")
            end
            filtered_results << {
              el_name: name,
              name: s[:name],
              status: s[:status],
              parent_test: test_obj[:test],
              browser: run['browser_name'],
              version: run['browser_version'],
            }
          }
      end
    end

    parser.parse(json_io)
    {
      browser: run['browser_name'],
      version: run['browser_version'],
      results: filtered_results
    }
  end
end