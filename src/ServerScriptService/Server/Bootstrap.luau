--!strict
-- Bootstrap (S5.1): starts the server's domains in the fixed order of architecture §5.2.
-- Every domain is a module returning { Name, Init(ctx)?, Start(ctx)? }. All Inits run first, in order, then
-- all Starts, in order; `ctx` is the shared table domains use to hand each other what they built (the state
-- folder, the remotes, the island refs, helper functions). Network is last: the remotes folder is parented
-- (exposed to clients) only after every other domain has started.

local Bootstrap = {}

Bootstrap.ORDER = { "Platform", "Telemetry", "Data", "Definitions", "Economy", "World", "Encounter", "Crew", "LiveOps", "Network" }

export type Domain = { Name: string, Init: ((ctx: any) -> ())?, Start: ((ctx: any) -> ())? }

-- Errors with a clear message unless the domains are each in ORDER, in that order, once, with Network last.
function Bootstrap.check(domains: { Domain })
	local position: { [string]: number } = {}
	for i, name in Bootstrap.ORDER do
		position[name] = i
	end
	local last = 0
	for _, domain in domains do
		local p = position[domain.Name]
		if not p then
			error("Bootstrap: unknown domain " .. tostring(domain.Name), 2)
		end
		if p <= last then
			error(string.format("Bootstrap: %s must start before %s", domain.Name, Bootstrap.ORDER[last]), 2)
		end
		last = p
	end
	if #domains == 0 or domains[#domains].Name ~= "Network" then
		error("Bootstrap: Network must be the last domain (remotes are exposed last)", 2)
	end
end

-- Checks the order, runs every Init then every Start, logs the order, and returns the steps taken.
function Bootstrap.run(domains: { Domain }, ctx: any, log: ((string, any) -> ())?): { string }
	Bootstrap.check(domains)
	local steps = {}
	for _, domain in domains do
		if domain.Init then
			domain.Init(ctx)
		end
		table.insert(steps, domain.Name .. ":Init")
	end
	for _, domain in domains do
		if domain.Start then
			domain.Start(ctx)
		end
		table.insert(steps, domain.Name .. ":Start")
	end
	if log then
		log("Boot", { order = table.concat(steps, " ") })
	end
	return steps
end

return Bootstrap
