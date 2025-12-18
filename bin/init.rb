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
  "Represents"
]

elements.each do |elem_obj|
  elem_obj.delete_if do |k, v|
    !keys.any?(k)
  end
  filename = "data/html/elements/#{elem_obj["Element"]}.json"

  updated_json = {
    "html" => {
      "elements" => {
        elem_obj["Element"] => {
          "__compat" => {
            "desc" => elem_obj["Represents"],
            "spec_url" => elem_obj["Element link 1"]
          }
        }
      }
    }
  }

  File.write(filename, JSON.pretty_generate(updated_json))
end
