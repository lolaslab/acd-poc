require 'pry'
require 'json'
SR_RESULTS_PATH = File.expand_path(
  '../data/util/screen-readers/jaws.json',
  __dir__
)

json_string = File.read(SR_RESULTS_PATH)
elements = JSON.parse(json_string)

keys = [
  "Element",
  "Element link 1",
  "Represents",
  "Supported",
  "Notes"
]

elements.each do |elem_obj|
  elem_obj.delete_if do |k, v|
    !keys.any?(k)
  end
end

filename = "data/util/html_aam_elements.json"
File.write(filename, JSON.pretty_generate(elements))