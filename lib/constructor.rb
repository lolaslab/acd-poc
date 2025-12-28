# frozen_string_literal: true
require 'json'
require 'pry-byebug'
require 'yajl'

class Constructor
  include Enumerable
  CHROME_PATH = File.expand_path(
    '../data/util/browsers/chrome.json',
    __dir__
  )
  JAWS_PATH = File.expand_path(
    '../data/util/screen-readers/jaws.json',
    __dir__
  )
  def self.init(browser = CHROME_PATH, screen_reader = JAWS_PATH)
    # iterate over the screen reader object
    screen_reader_io = File.open(screen_reader, 'r')
    browser_obj = JSON.parse(File.read(browser))
    browser_results = browser_obj["results"]
    browser_version = browser_obj["version"]

    parser = Yajl::Parser.new(symbolize_keys: true)
    parser.on_parse_complete = lambda do |sr_element_obj|
      sr_element_obj.each do |sr_data|
        element = sr_data[:Element]
        # find the element object per element in the browser object, skip if there are no tests for this element
        if browser_results[element].nil?
          File.write("data/html/missing-elements.txt", "#{element} \n", mode: 'a')
          next
        end
        browser_element = browser_results[element]
        # check the screen reader object "supported" key
        #   if "yes" then the screen reader supports the object
        if sr_data[:Support] == "[yes]"
          sr_support = "1"
        elsif sr_data[:Support] == "[no]"
          sr_support = "0"
        else
          sr_support = "2"
          notes = sr_data[:Support]
        end
        # check the stats object in the browser object
        browser_element_stats = browser_element[-1]["stats"]
        #   if the total == the passes then the browser supports the object
        if browser_element_stats["passes"] == browser_element_stats["total_subtests"]
          b_support = browser_version
        else
          b_support = 0
        end
        # find the element file per element in the screen reader object
        element_acd_filename = "data/html/elements/#{element}.json"
        if File.zero?(element_acd_filename)
          puts "Skipping empty file for: #{element}"
          element_acd_obj = {}
        else
          element_acd_obj = JSON.parse(File.read(element_acd_filename))
          compat_node = element_acd_obj.dig("html", "elements", element, "__compat")
          compat_node["support"] = {
            "chrome/jaws" => "#{b_support}/#{sr_support}"
          }
          if notes
            compat_node["notes"] = notes
          end
          File.write(element_acd_filename, JSON.pretty_generate(element_acd_obj))
        end
      end
    end


    #   update the element file with
    #     "support": {
    #         "chrome/jaws": {
    #           "version_added: "brow_v/sr_v",
    #
    #         }
    #      }

    parser.parse(screen_reader_io)
  end
end

puts Constructor.init