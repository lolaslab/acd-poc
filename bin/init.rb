require 'json'
require 'pry'

# Create JSON for each HTML AAM Element
SR_RESULTS_PATH = File.expand_path(
  '../data/util/screen-readers/jaws.json',
  __dir__
)

json_string = File.read(SR_RESULTS_PATH)
elements = JSON.parse(json_string)

keys = [
  "Element",
  "Element link 1",
]

elements.each do |elem_obj|
  elem_obj.delete_if do |k, v|
    !keys.any?(k)
  end
end

elements.each do |elem_obj|
  filename = "data/html/elements/#{elem_obj["Element"]}.json"
  File.write(filename, JSON.pretty_generate(elem_obj))
end
