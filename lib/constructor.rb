# frozen_string_literal: true
require 'json'
require 'pry-byebug'
require 'yajl'

class Constructor
  include Enumerable
  BROWSERS_PATH = File.expand_path(
    '../data/util/browsers/',
    __dir__
  )
  def init(directory=BROWSERS_PATH)
    @directory = directory
    Dir.glob(File.join(@directory, "*.json")).each do |file|
      File.open(file, 'r') do |io|
        parser = Yajl::Parser.new(symbolize_keys: true)
        parser.on_parse_complete = lambda do |json|
          if json["results"]
            # binding.pry
            json["results"].each do |subtest_obj|
              element_file = File.expand_path("../data/html/elements/#{subtest_obj.first}.json", __dir__)
              File.open(element_file, 'r') do |element_io|
                element_data = Yajl::Parser.parse(element_io)
                # binding.pry
                # TODO: Update the element json file with the support data
              end
            end
          end
        end
      end
    end
  end
end

puts Constructor.new.init