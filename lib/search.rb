# frozen_string_literal: true

require 'httparty'
require 'json'
require 'set'

class Search
  WPT_SEARCH_URL = 'https://wpt.fyi/api/search'

  # @param run_ids is an array of IDs from WPT runs
  # @param label is the metadata label used to search WPT;
  # this label is listed in the wpt-metadata repo
  def self.get_labelled_tests(run_ids, label='a11y')
    payload = { run_ids: run_ids, query: { label: label } }
    resp = HTTParty.post(
      WPT_SEARCH_URL,
      body: payload.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    raise "Failed to fetch search results" unless resp.code == 200
    data = JSON.parse(resp.body)
    Set.new(data['results'].map { |r| r['test'] })
  end
end