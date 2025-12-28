# frozen_string_literal: true

require 'net/http'
require 'zlib'
require 'stringio'
require 'yajl'
require 'pry-byebug'

class ParseHtmlAamResults
  # @param run is a WPT test run for a specific browser
  # @param labelled_tests is a Set of filtered WPT tests
  def self.local_parse(run, labelled_tests)
    uri = URI(run['raw_results_url'])
    # TODO: refactor to actually implement json streaming when moved to Node
    json_io = Net::HTTP.get(uri)
    filtered_results = {}

    # Init parser
    parser = Yajl::Parser.new(symbolize_keys: true)

    # Populate filtered_results and calculate stats when the parser
    # has finished parsing.
    parser.on_parse_complete = lambda do |json|
      json[:results].each do |test_obj|
        # Exclude tests we don't need
        next unless labelled_tests.include?(test_obj[:test]) &&
          test_obj[:test].include?("html-aam") && !test_obj[:test].include?("tentative")

        test_obj[:subtests]&.map do |s|
          # This is trying to infer the element name from the subtest name but
          # there are inconcistencies, especially where the subtest name uses
          # hypens to delinate specifics. In the case where there are hypens in the
          # name, I split again on the hyphen and get the first word which is usually the
          # element name.
          el_name = s[:name].split.first
          if el_name.start_with?("el-")
            el_name.delete_prefix!("el-")
          end
          el_name = el_name.split("-").first

          if filtered_results.has_key?(el_name)
            filtered_results[el_name] << {
              name: s[:name],
              status: s[:status],
              parent_test: test_obj[:test],
              browser: run['browser_name'],
              version: run['browser_version'],
            }
          else
            filtered_results.merge!( {
              el_name => [
                {
                  name: s[:name],
                  status: s[:status],
                  parent_test: test_obj[:test],
                  browser: run['browser_name'],
                  version: run['browser_version'],
                }
              ],
            })
          end
        end

      end

      # Calculate stats
      filtered_results.each do |element_name, subtests|
        passes = subtests.count { |s| s[:status] == "PASS" }
        fails = subtests.count { |s| s[:status] == "FAIL" }


        filtered_results[element_name] << {
          stats: {
            passes: passes,
            fails: fails,
            total_subtests: subtests.count
          }}
      end
    end

    # Parse json; without this the callback above won't run!
    parser.parse(json_io)

    {
      browser: run['browser_name'],
      version: run['browser_version'],
      results: filtered_results
    }
  end
end