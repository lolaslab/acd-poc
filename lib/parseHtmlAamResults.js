'use strict';

const https = require('https');
const { chain } = require('stream-chain');
const { parser } = require('stream-json');
const { pick } = require('stream-json/filters/Pick');
const { streamArray } = require('stream-json/streamers/StreamArray');

/**
 * Downloads a WPT raw results JSON and restructures it, using HTTP and JSON
 * streaming so the full payload is never held in memory at once.
 *
 * @param {Object} run - A WPT run object from the /api/runs endpoint.
 *   Expected keys: raw_results_url, browser_name, browser_version
 * @param {Set<string>} labelledTests - Set of test paths that carry the
 *   target label (e.g. 'a11y'), from the /api/search endpoint.
 * @returns {Promise<{browser: string, version: string, results: Object}>}
 */
function parseHtmlAamResults(run, labelledTests) {
  return new Promise((resolve, reject) => {
    const filteredResults = {};
    const url = new URL(run.raw_results_url);

    https.get(url, (response) => {
      if (response.statusCode !== 200) {
        response.resume(); // drain the socket so it can be reused
        reject(new Error(`HTTP ${response.statusCode} fetching ${run.raw_results_url}`));
        return;
      }

      // chain() pipes each stage into the next and propagates errors.
      //
      // response          – Node.js Readable: raw bytes arrive here as the
      //                     download progresses; nothing is buffered up front.
      // parser()          – stream-json tokeniser: converts the byte stream
      //                     into a stream of JSON tokens.
      // pick(...)         – discards every token that isn't inside the
      //                     top-level "results" key, so we never pay the cost
      //                     of materialising any other part of the document.
      // streamArray()     – assembles each element of the results array into
      //                     a plain JS value and emits { key, value } objects.
      const pipeline = chain([
        response,
        parser(),
        pick({ filter: 'results' }),
        streamArray(),
      ]);

      pipeline.on('data', ({ value: testObj }) => {
        // Apply the same three-part filter as the Ruby implementation:
        //   1. must be in the set of accessibility-labelled tests
        //   2. must live under html-aam
        //   3. must not be a tentative test
        if (
          !labelledTests.has(testObj.test) ||
          !testObj.test.includes('html-aam') ||
          testObj.test.includes('tentative')
        ) {
          return;
        }

        for (const subtest of (testObj.subtests ?? [])) {
          // Infer element name from the subtest name.
          // The subtest name begins with the element name (space-delimited),
          // with an optional "el-" prefix and optional hyphen-separated
          // qualifiers — mirrors the heuristic in parse_html_aam_results.rb.
          let elName = subtest.name.split(' ')[0];
          if (elName.startsWith('el-')) {
            elName = elName.slice(3);
          }
          elName = elName.split('-')[0];

          const subtestData = {
            name: subtest.name,
            status: subtest.status,
            parent_test: testObj.test,
            browser: run.browser_name,
            version: run.browser_version,
          };

          if (filteredResults[elName]) {
            filteredResults[elName].push(subtestData);
          } else {
            filteredResults[elName] = [subtestData];
          }
        }
      });

      pipeline.on('end', () => {
        // Append a stats summary to each element's subtest list.
        for (const subtests of Object.values(filteredResults)) {
          const passes = subtests.filter(s => s.status === 'PASS').length;
          const fails = subtests.filter(s => s.status === 'FAIL').length;
          subtests.push({
            stats: {
              passes,
              fails,
              total_subtests: subtests.length,
            },
          });
        }

        resolve({
          browser: run.browser_name,
          version: run.browser_version,
          results: filteredResults,
        });
      });

      pipeline.on('error', reject);
    }).on('error', reject);
  });
}

module.exports = { parseHtmlAamResults };
