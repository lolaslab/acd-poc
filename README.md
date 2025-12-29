# (A very crude) Accessibility Compat Data Collector

This is a proof of concept for the Accessibility Compat Data Collector, it is in no way meant to be used for production 
or anything important. I would not reccomend running this locally as the JSON from WPT is very large.

## /data/html/elements
The collector populates element support files based on:
- If there are tests for the element in the latest Web Platform Test Run, which will be shown in the `data/util/browsers`
    folder.
- If there is support data in the `data/util/screen-readers/jaws.json` a given element

The screen-reader data is quite robust and includes tests for every html-aam element so the `data/html/missing-elements.txt`
only includes elements for which I couldn't identify WPT tests for.

Each element looks something like this:
```json
  "html": {
    "elements": {
      "a": {
        "__compat": {
          "desc": "With href: a hyperlink\nWith no href: an\nanchor",
          "spec_url": "https://html.spec.whatwg.org/multipage/text-level-semantics.html#the-a-element",
          "support": {
            "chrome/jaws": [
              {
                "version_added": "143.0.7499.169/2",
                "notes": "With href:\n[yes]\nWith no href:\n[none expected]"
              }
            ]
          }
        }
      }
    }
  }
```
There are a few things to note:
```json
    "support": {
        "chrome/jaws": [
            {
                "version_added": "143.0.7499.169/2",
                "notes": "With href:\n[yes]\nWith no href:\n[none expected]"
            }
        ]
    }
```
1. The browser support will either be the browser version where all the browser tests pass or `0` where there is at least
    one failing test. In the case there are one or more failing tests, the notes will be populated with more info.
2. The screen-reader support will either be `1` for supported, `0` for unsupported, or `2` for nuanced. In the case where it is
   `2` the notes will be populated with more info.
3. In this example the screen-reader data actually supports `a with href`, but the data doesn't separate the `a with href` and
    `a without href`.
4. Similarly the browser data for `a` looks like:
    ```json
      "a": [
        {
          "name": "el-a",
          "status": "PASS",
          "parent_test": "/html-aam/roles-contextual.html",
          "browser": "chrome",
          "version": "143.0.7499.169"
        },
        {
          "name": "el-a-no-href",
          "status": "PASS",
          "parent_test": "/html-aam/roles-contextual.html",
          "browser": "chrome",
          "version": "143.0.7499.169"
        },
        {
        "stats": {
          "passes": 2,
          "fails": 0,
          "total_subtests": 2
        }
      ]
   ```
At the moment, I'm only looking at the top-level key (i.e. `a`) and the `stats` key because the sub-test names (i.e. the 
`name` keys) can be unpredictable. (see question 2)

## /data/html/missing-elements.txt
As mentioned above, the `data/html/missing-elements.txt` only includes elements for which I couldn't identify WPT tests for.
However, there are some errors. For example the screen-reader data file names an element `h1- h6`, that doesn't exist in
WPT but there are WPTs for elements `h1` all the way through to `h6`. Similarly, there are various WPTs for `inputs` however
they are all categorised under the key `input`. (see question 2)

## /data/util/browsers
This includes the generated & filtered browser data from WPT, currently for 4 major browsers.

## Limitations

### /data/screen-readers/jaws.json
Tetralogical kindly provided their JSON data however, it doesn't include the browser it's been tested on nor the screen-reader
version.

### Ruby vs Node
I've written this in Ruby because I can be quick in Ruby. The final version of this should be written in Node and utilise
streaming to read and filter the WPT results.

### HTML-AAM
Currently only showing data for HTML-AAM elements in Jaws.

## Questions
1. How many WPT need to pass for an element to be supported? Should we be looking for specific sub tests passing instead
    count?
2. How can we ensure the incoming data is named in a predictable way?