# frozen_string_literal: true
require 'json'
require 'pry'

class XConstructor

  CHROME_PATH = File.expand_path(
    '../data/util/browsers/chrome.json',
    __dir__
  )
  ELEMENTS_PATH = File.expand_path(
    '../data/util/html_aam_elements.json',
    __dir__
  )
  def self.get_html_aam_browser_results(browser_data_path=CHROME_PATH)
    json_string = File.read(browser_data_path)
    browser_json = JSON.parse(json_string)
    browser_json["results"].each do |test|
      if test.key?("/html-aam/names.html")
        @html_aam_names = test.values[0]
        break
      end
    end
    @html_aam_names
  end

  def self.match_test_to_feature(test_hash)
    @comp = {}
    test_hash.each do |subtest|
      subtest_name = subtest["name"]
      element = subtest["name"].split.first

      unless @comp.include?(element)
        @comp[element] = []
      end
      if subtest_name.include?(element)
        @comp[element] << subtest
      end
    end
    @comp
  end

  def self.calculate_pass_rate(test_hash)
    test_hash.each_value do |tests|
      pass = 0
      fail = 0
      tests.each do |t|
        if t["status"] == "PASS"
          pass += 1
        else
          fail += 1
        end
      end
      tests << {
        "total" => tests.length,
        "pass" => pass,
        "fail" => fail
      }
    end
    test_hash
  end

  def self.ex(constructed_test, elements_file=ELEMENTS_PATH)
    json_string = File.read(elements_file)
    elements_json = JSON.parse(json_string)

    elements_json.each do |elem_obj|
      if constructed_test.keys.any?(elem_obj["Element"])
        element = elem_obj["Element"]
        t = constructed_test[element]
        elem_obj["tests"] = t

      end
    end
    # binding.pry
    puts elements_json
  end
end

# a = X-constructor.get_html_aam_browser_results
# b = X-constructor.match_test_to_feature(a)
# c = X-constructor.calculate_pass_rate(b)
# d = X-constructor.ex(c)
