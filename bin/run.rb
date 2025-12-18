require 'json'
require_relative '../lib/fetch_runs'
require_relative '../lib/search'
require_relative '../lib/stream_html_aam_results'

runs = FetchRuns.get_stable_runs
run_ids = runs.map { |r| r['id'] }

labelled_tests = Search.get_labelled_tests(run_ids)

runs.each do |run|
  puts "Processing #{run['browser_name']} #{run['browser_version']}..."

  # Getting only HTML AAM results
  filtered_run = StreamHtmlAamResults.stream_and_filter(run, labelled_tests)
  filename = "data/util/browsers/#{run['browser_name'].downcase}.json"
  File.write(filename, JSON.pretty_generate(filtered_run))
  puts "Saved #{filtered_run[:results].size} tests to #{filename}"
end

puts "All browsers processed successfully."

