# frozen_string_literal: true

require 'httparty'
require 'json'

class FetchRuns
  # Get only the latest run for stable browsers
  WPT_RUNS_URL = 'https://wpt.fyi/api/runs?label=stable&max-count=1'

  def self.get_stable_runs
    resp = HTTParty.get(WPT_RUNS_URL)
    raise "Failed to fetch runs" unless resp.code == 200
    JSON.parse(resp.body)
  end
end
