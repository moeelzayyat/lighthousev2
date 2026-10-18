--!strict
-- TestRunner: in-house describe/it/expect harness (architecture §24, TEST_PLAN.md).
-- Usage: require(game.ServerStorage.Tests.TestRunner).run()
-- Spec modules live under Tests/unit and Tests/integration, are named "<Name>Spec",
-- and return function(T) that registers describe/it blocks. Specs are cloned before
-- require so edits are picked up without restarting Studio.

local TestRunner = {}

export type TestFn = () -> ()

type Test = { name: string, fn: TestFn, timeout: number }
type Suite = {
	name: string,
	tests: { Test },
	beforeEach: { TestFn },
	afterEach: { TestFn },
	children: { Suite },
	parent: Suite?,
}

export type Result = { passed: number, failed: number, failures: { string }, summary: string, seconds: number }

local DEFAULT_TIMEOUT = 5

-- Studio caches require() across execute_luau calls; run() reloads this module
-- from a clone when its source changed since the cached copy was loaded.
local function readSource(): string?
	local ok, src = pcall(function()
		return (script :: any).Source
	end)
	return if ok then src else nil
end
local LOADED_SOURCE = readSource()

local root: Suite
local current: Suite

local function newSuite(name: string, parent: Suite?): Suite
	return { name = name, tests = {}, beforeEach = {}, afterEach = {}, children = {}, parent = parent }
end

local function reset()
	root = newSuite("", nil)
	current = root
end
reset()

-- Registration ---------------------------------------------------------------

function TestRunner.describe(name: string, fn: () -> ())
	local suite = newSuite(name, current)
	table.insert(current.children, suite)
	local parent = current
	current = suite
	local ok, err = pcall(fn :: any)
	current = parent
	if not ok then
		-- a broken describe body registers one failing test so it is never silent
		table.insert(suite.tests, {
			name = "(describe body)",
			fn = function()
				error(err, 0)
			end,
			timeout = DEFAULT_TIMEOUT,
		})
	end
end

function TestRunner.it(name: string, fn: TestFn, timeout: number?)
	table.insert(current.tests, { name = name, fn = fn, timeout = timeout or DEFAULT_TIMEOUT })
end

function TestRunner.beforeEach(fn: TestFn)
	table.insert(current.beforeEach, fn)
end

function TestRunner.afterEach(fn: TestFn)
	table.insert(current.afterEach, fn)
end

-- Expectations -----------------------------------------------------------------

local function fmt(v: any, depth: number?): string
	local d = depth or 0
	if type(v) == "string" then
		return string.format("%q", v)
	elseif type(v) == "table" then
		if d > 2 then
			return "{...}"
		end
		local keys = {}
		for k in pairs(v) do
			table.insert(keys, k)
		end
		table.sort(keys, function(a, b)
			return tostring(a) < tostring(b)
		end)
		local parts = {}
		for i, k in ipairs(keys) do
			if i > 12 then
				table.insert(parts, "...")
				break
			end
			table.insert(parts, tostring(k) .. "=" .. fmt(v[k], d + 1))
		end
		return "{" .. table.concat(parts, ", ") .. "}"
	end
	return tostring(v)
end
TestRunner.format = fmt

local function deepEqual(a: any, b: any): (boolean, string?)
	if a == b then
		return true, nil
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return false, nil
	end
	for k, v in pairs(a) do
		local ok, path = deepEqual(v, b[k])
		if not ok then
			return false, "." .. tostring(k) .. (path or "")
		end
	end
	for k in pairs(b) do
		if a[k] == nil then
			return false, "." .. tostring(k)
		end
	end
	return true, nil
end
TestRunner.deepEqual = deepEqual

local function fail(msg: string)
	error(msg, 3)
end

export type Expectation = {
	toBe: (expected: any) -> (),
	toEqual: (expected: any) -> (),
	toBeCloseTo: (expected: number, epsilon: number?) -> (),
	toThrow: (pattern: string?) -> (),
	toBeNil: () -> (),
	toBeTruthy: () -> (),
	toBeFalsy: () -> (),
	toBeGreaterThan: (n: number) -> (),
	toBeLessThan: (n: number) -> (),
	toBeGreaterThanOrEqual: (n: number) -> (),
	toBeLessThanOrEqual: (n: number) -> (),
	toContain: (item: any) -> (),
}

function TestRunner.expect(actual: any): Expectation
	local e = {}
	function e.toBe(expected: any)
		if actual ~= expected then
			fail("expected " .. fmt(expected) .. ", got " .. fmt(actual))
		end
	end
	function e.toEqual(expected: any)
		local ok, path = deepEqual(actual, expected)
		if not ok then
			fail("not equal at " .. (path or "(root)") .. ": expected " .. fmt(expected) .. ", got " .. fmt(actual))
		end
	end
	function e.toBeCloseTo(expected: number, epsilon: number?)
		local eps = epsilon or 1e-6
		if type(actual) ~= "number" or math.abs(actual - expected) > eps then
			fail("expected " .. tostring(expected) .. " +/- " .. tostring(eps) .. ", got " .. fmt(actual))
		end
	end
	function e.toThrow(pattern: string?)
		if type(actual) ~= "function" then
			fail("toThrow needs a function, got " .. typeof(actual))
			return
		end
		local ok, err = pcall(actual)
		if ok then
			fail("expected an error, none thrown")
		elseif pattern and not string.find(tostring(err), pattern) then
			fail("error " .. fmt(tostring(err)) .. " does not match " .. fmt(pattern))
		end
	end
	function e.toBeNil()
		if actual ~= nil then
			fail("expected nil, got " .. fmt(actual))
		end
	end
	function e.toBeTruthy()
		if not actual then
			fail("expected truthy, got " .. fmt(actual))
		end
	end
	function e.toBeFalsy()
		if actual then
			fail("expected falsy, got " .. fmt(actual))
		end
	end
	local function cmp(n: number, ok: (number, number) -> boolean, word: string)
		if type(actual) ~= "number" or not ok(actual, n) then
			error("expected " .. fmt(actual) .. " " .. word .. " " .. tostring(n), 3)
		end
	end
	function e.toBeGreaterThan(n: number)
		cmp(n, function(a, b)
			return a > b
		end, ">")
	end
	function e.toBeLessThan(n: number)
		cmp(n, function(a, b)
			return a < b
		end, "<")
	end
	function e.toBeGreaterThanOrEqual(n: number)
		cmp(n, function(a, b)
			return a >= b
		end, ">=")
	end
	function e.toBeLessThanOrEqual(n: number)
		cmp(n, function(a, b)
			return a <= b
		end, "<=")
	end
	function e.toContain(item: any)
		if type(actual) == "string" then
			if not string.find(actual, tostring(item), 1, true) then
				fail(fmt(actual) .. " does not contain " .. fmt(item))
			end
			return
		end
		if type(actual) == "table" then
			for _, v in pairs(actual) do
				if deepEqual(v, item) then
					return
				end
			end
		end
		fail(fmt(actual) .. " does not contain " .. fmt(item))
	end
	return e :: any
end

-- Mocks and clock --------------------------------------------------------------
-- T.mock.service(name, impl) registers a stand-in that code under test reads with
-- T.mock.get(name); every registration is cleared after each test.
-- T.mock.fn(impl?) returns a callable spy that records its calls.

local mockServices: { [string]: any } = {}

export type Spy = { calls: { { any } }, count: number }

TestRunner.mock = {}

function TestRunner.mock.service(name: string, impl: any): any
	mockServices[name] = impl
	return impl
end

function TestRunner.mock.get(name: string): any
	return mockServices[name]
end

function TestRunner.mock.clear()
	table.clear(mockServices)
end

function TestRunner.mock.fn(impl: ((...any) -> ...any)?): any
	local spy = { calls = {}, count = 0 }
	setmetatable(spy, {
		__call = function(_self: any, ...: any): ...any
			spy.count += 1
			table.insert(spy.calls, table.pack(...))
			if impl then
				return impl(...)
			end
			return nil
		end,
	})
	return spy
end

export type Clock = {
	now: () -> number,
	advance: (seconds: number) -> (),
	set: (t: number) -> (),
}

-- Fake clock for advanced-time tests: code under test takes a `now` function.
function TestRunner.clock(start: number?): Clock
	local t = start or 0
	return {
		now = function(): number
			return t
		end,
		advance = function(seconds: number)
			assert(seconds >= 0, "clock cannot go backwards")
			t += seconds
		end,
		set = function(v: number)
			t = v
		end,
	}
end

-- Running ----------------------------------------------------------------------

-- Requires a fresh copy so edits made in Studio since the last run are used. The module's whole folder is
-- cloned once per run, so `script.Parent.Sibling` requires inside it resolve to the same fresh copies.
local folderClones: { [Instance]: Instance } = {}

function TestRunner.require(module: ModuleScript): any
	local parent = module.Parent
	if parent and parent:IsA("Folder") then
		local folder = folderClones[parent]
		if not folder then
			folder = parent:Clone()
			folderClones[parent] = folder
		end
		local copy = (folder :: Instance):FindFirstChild(module.Name)
		if copy and copy:IsA("ModuleScript") then
			return (require :: any)(copy)
		end
	end
	return (require :: any)(module:Clone())
end

-- Runs fn in its own thread so tests may yield (async); fails on error or timeout.
local function runFn(fn: TestFn, timeout: number): (boolean, string?)
	local done = false
	local ok, err = true, nil :: string?
	local thread = task.spawn(function()
		local s, e = pcall(fn :: any)
		ok = s
		err = if s then nil else tostring(e)
		done = true
	end)
	local t0 = os.clock()
	while not done do
		if os.clock() - t0 > timeout then
			pcall(task.cancel, thread)
			return false, string.format("timed out after %.1fs", timeout)
		end
		task.wait()
	end
	return ok, err
end

type Ctx = { passed: number, failed: number, failures: { string }, filter: string?, verbose: boolean, lines: { string } }

local function runSuite(suite: Suite, prefix: string, befores: { TestFn }, afters: { TestFn }, ctx: Ctx)
	local path = if suite.name == "" then prefix else (if prefix == "" then suite.name else prefix .. " > " .. suite.name)
	local b = table.clone(befores)
	for _, f in ipairs(suite.beforeEach) do
		table.insert(b, f)
	end
	local a = table.clone(suite.afterEach)
	for _, f in ipairs(afters) do
		table.insert(a, f)
	end
	for _, test in ipairs(suite.tests) do
		local full = if path == "" then test.name else path .. " > " .. test.name
		if ctx.filter == nil or string.find(full, ctx.filter, 1, true) then
			TestRunner.mock.clear()
			local ok, err = true, nil :: string?
			for _, f in ipairs(b) do
				ok, err = runFn(f, test.timeout)
				if not ok then
					err = "beforeEach: " .. tostring(err)
					break
				end
			end
			if ok then
				ok, err = runFn(test.fn, test.timeout)
			end
			for _, f in ipairs(a) do
				local aok, aerr = runFn(f, test.timeout)
				if ok and not aok then
					ok, err = false, "afterEach: " .. tostring(aerr)
				end
			end
			TestRunner.mock.clear()
			if ok then
				ctx.passed += 1
				if ctx.verbose then
					table.insert(ctx.lines, "  PASS " .. full)
				end
			else
				ctx.failed += 1
				local line = "  FAIL " .. full .. "\n       " .. tostring(err)
				table.insert(ctx.failures, line)
				table.insert(ctx.lines, line)
			end
		end
	end
	for _, child in ipairs(suite.children) do
		runSuite(child, path, b, a, ctx)
	end
end

export type RunOptions = { filter: string?, verbose: boolean?, folders: { string }?, quiet: boolean?, root: Instance? }

-- Loads every "*Spec" ModuleScript under Tests/<folders> (default unit, integration)
-- and runs it. Prints and returns "<N> passed, <M> failed".
function TestRunner.run(options: RunOptions?): Result
	local opts: RunOptions = options or {}
	if opts.root == nil and script.Parent ~= nil then
		local src = readSource()
		if src ~= nil and src ~= LOADED_SOURCE then
			local fresh = (require :: any)(script:Clone())
			return fresh.run({
				filter = opts.filter,
				verbose = opts.verbose,
				folders = opts.folders,
				quiet = opts.quiet,
				root = script.Parent,
			})
		end
	end
	reset()
	table.clear(folderClones)
	local started = os.clock()
	local ctx: Ctx = { passed = 0, failed = 0, failures = {}, filter = opts.filter, verbose = opts.verbose == true, lines = {} }
	local testsFolder = opts.root or script.Parent
	local specs: { ModuleScript } = {}
	for _, folderName in ipairs(opts.folders or { "unit", "integration" }) do
		local folder = testsFolder and testsFolder:FindFirstChild(folderName)
		if folder then
			for _, d in ipairs(folder:GetDescendants()) do
				if d:IsA("ModuleScript") and string.sub(d.Name, -4) == "Spec" then
					table.insert(specs, d)
				end
			end
		end
	end
	table.sort(specs, function(x, y)
		return x:GetFullName() < y:GetFullName()
	end)
	for _, spec in ipairs(specs) do
		local ok, err = pcall(function()
			local register = TestRunner.require(spec)
			assert(type(register) == "function", "spec must return function(T)")
			TestRunner.describe(string.sub(spec.Name, 1, -5), function()
				register(TestRunner)
			end)
		end)
		if not ok then
			ctx.failed += 1
			local line = "  FAIL (load) " .. spec:GetFullName() .. "\n       " .. tostring(err)
			table.insert(ctx.failures, line)
			table.insert(ctx.lines, line)
		end
	end
	runSuite(root, "", {}, {}, ctx)
	reset()
	local seconds = os.clock() - started
	local summary = string.format("%d passed, %d failed", ctx.passed, ctx.failed)
	if not opts.quiet then
		print("[TestRunner] " .. #specs .. " spec module(s)\n" .. table.concat(ctx.lines, "\n"))
		print(string.format("[TestRunner] %s (%.2fs)", summary, seconds))
	end
	return { passed = ctx.passed, failed = ctx.failed, failures = ctx.failures, summary = summary, seconds = seconds }
end

return TestRunner
