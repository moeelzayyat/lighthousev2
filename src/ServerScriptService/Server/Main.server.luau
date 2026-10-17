-- Main (server entry point, S5.1): starts the domains in the fixed order of architecture §5.2. Everything
-- the server does lives in a domain under Server.Domains; Bootstrap refuses to boot on a wrong order.

local Server = script.Parent
local Domains = Server.Domains
local Bootstrap = require(Server.Bootstrap)
local EventLog = require(Server.EventLog)

local domains = {}
for _, name in Bootstrap.ORDER do
	table.insert(domains, require(Domains[name]))
end

Bootstrap.run(domains, {}, EventLog.log)
