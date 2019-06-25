# Lightweight MarkLogic test runner

This was created because of two problems:
1) The only standardized test suite for MarkLogic is Roxy or [this offshoot](https://github.com/marklogic-community/marklogic-unit-test), which requires a TON of things to be placed in _exactly_ the right location.
2) MarkLogic `require` in SJS doesn't really work out of the box with node modules.

By lightweight, this repo requires the [`chai` assertion library](https://www.chaijs.com/), but after that has only a single XQuery file that exposes the following endpoint:
```xquery
import module namespace lwtr = "lightweight-testrunner" at "./runner.xqy";
lwtr:run(map:map())
```

The map has the following three keys:
- `project-root`(string): absolute path from the AppServer root to where the test runner should consider "the root of the project". When in doubt, this should be `/`; this was added because this test runner was developed for a project included as a submodule of other projects.
- `path-to-chai`(string): the runner expects Chai to be installed at `{$project-root}/node_modules/chai/chai.js`; if it is not, this can be overridden by passing an absolute path from the AppServer root to where the `chai.js` main entry point is.
- `modules`(string+): a set of absolute paths from the AppServer root to a series of SJS modules. Each module will be executed in a context that has the following global variables exposed:
	- `chai`: the result of `require('path/to/chai.js')`
	- `projectRoot`: the value of `project-root` passed into the runner
	- `it(description[string], execute[function])`: call this function to register a test for execution.

The test suite will require every path in `modules`, let the tests get loaded, execute them, and return [JUnit-compliant XML](https://github.com/windyroad/JUnit-Schema/blob/master/JUnit.xsd) that describes their execution.

This is written in XQuery because I've found it easier to return XML that way; this executes SJS because it was developed to test code written in both XQuery and SJS, and because it's easier in MarkLogic to import XQuery into SJS (because of the automatic conversion from hyphen-case to camelCase) than inverse (because who wants to deal with `xdmp:javascript-eval` every ten lines?).

The project this was built for is in a private repo that I can guarantee you have no use for, but I'll try to update this as we update the source. If you somehow stumble upon this because you get annoyed to hell with Roxy, please let me know and I'll do whatever I can to incorporate whatever changes you need.
