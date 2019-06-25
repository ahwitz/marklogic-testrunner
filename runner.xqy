module namespace lwtr = "lightweight-testrunner";

declare function lwtr:run(
    $options as map:map
) as element(testsuites)
{
    (: Project root param is in case this isn't the root of an appserver :)
    let $project-root := map:get($options, "project-root")

    (: Get (or guess at) the path to Chai :)
    let $path-to-chai := if ("path-to-chai" = map:keys($options))
        then map:get($options, "project-root")
        else concat($project-root, "/node_modules/chai/chai.js")

    (: Modules is a list of modules that expose `it` tests :)
    let $modules := map:get($options, "modules")

    (: To make sure things get loaded correctly, current filesystem path :)
    let $absolute-project-root := concat(xdmp:modules-root(), $project-root)

    (: Load Chai :)
    let $chai := xdmp:javascript-eval("var global = {}; require(pathToChai);", map:new((
        map:entry("pathToChai", $path-to-chai)
    )), <options xmlns="xdmp:eval">
        <isolation>same-statement</isolation>
    </options>)

    (: For each module, load the tests; `it`, `projectRoot`, and `chai` are exposed as globals :)
    let $tests := map:new((
        for $module in $modules
        return map:entry($module, xdmp:javascript-eval("var tests = {};
            function it(desc, execute){ tests[desc] = execute;};
            require(module);
            tests;
        ", map:new((
            map:entry("module", concat($absolute-project-root, '/', $module)),
            map:entry("chai", $chai),
            map:entry("projectRoot", $project-root)
        )), <options xmlns="xdmp:eval">
            <isolation>same-statement</isolation>
        </options>))
    ))

    let $keys := map:keys($tests)
    return <testsuites>
    {
        (: For each of the stacked modules, create a testsuite... :)
        for $module in $keys
        return <testsuite package="{$module}" name="{$module}" id="{index-of($keys, $module) - 1}">
        {
            let $suite-start := current-dateTime()
            let $cases := (
                (: Run each test, with error catching :)
                let $module-tests := map:get($tests, $module)
                for $test-desc in map:keys($module-tests)
                let $test := map:get($module-tests, $test-desc)
                let $start-time := current-dateTime()
                let $error := (
                    try {
                        $test()
                    }
                    catch($error) {
                        $error
                    }
                )
                return <testcase classname="{$module}" name="{$test-desc}" time="{(current-dateTime() - $start-time) div xs:dayTimeDuration('PT0.001S')}">
                {
                    (: JUnit distinguishes failures from errors :)
                    if ($error) then
                        if (matches($error//error:expr, "AssertionError"))
                        then <failure type="{$error//error:frame[matches(./error:uri/text(), 'chai.js$')][last()]/error:operation}" message="{$error//error:datum}"></failure>
                        else <error type="{$error//error:code}" message="{$error//error:message}">{$error}</error>
                    else ()
                }
                </testcase>
            )

            (: Return a set of attributes that we won't know until we get done with everything, then return the cases themselves :)
            return (
                attribute tests {count($cases)},
                attribute failures {count($cases/failure)},
                attribute errors {count($cases/error)},
                attribute time {(current-dateTime() - $suite-start) div xs:dayTimeDuration('PT0.001S')},
                $cases
            )
        }
        </testsuite>
    }
    </testsuites>
};
