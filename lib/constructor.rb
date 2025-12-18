# frozen_string_literal: true
require 'json'
require 'pry'

class Constructor
  include Enumerable
  BROWSERS_PATH = File.expand_path(
    '../data/util/browsers/',
    __dir__
  )
  def init(directory=BROWSERS_PATH)
    @directory = directory
    binding.pry
    Dir.glob(File.join(@directory, "*.json")).each do |file|
      data = JSON.parse(File.read(file))
      if data["results"]
        # binding.pry
        data["results"].each do |subtest_obj|
          element_file = File.expand_path("../data/html/elements/#{subtest_obj["el-name"]}.json", __dir__)
          element_file_json = File.read(element_file)
        #   TODO: Calculate support data
        # TODO: Update the element json file with the support data
        end
      end
    end
  end
end

#   def iter
#     Dir.glob(File.join(@directory, "*.json")).each do |file|
#       data = JSON.parse(File.read(file))
#       if data.is_a?(Array)
#         binding.pry
#         # data.each { |item| yield item }
#       else
#         yield data
#       end
#     end
#   end
# end

Constructor.new.init