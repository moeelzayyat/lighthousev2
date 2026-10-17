-- Definitions domain (S5.4): every catalog (creatures, weapons, items, ammo, upgrades, forecasts, voyages and the
-- bus events) is checked by `_Registry` before any other domain uses it. A bad definition stops the boot here
-- with one message listing every problem, so the remotes are never exposed and nobody can join a broken server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = script.Parent.Parent
local Registry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("_Registry"))
local EventLog = require(Server.EventLog)

local Definitions = { Name = "Definitions" }

function Definitions.Init(_ctx)
	local count = Registry.assertValid()
	EventLog.log("Definitions", { checked = count })
end

return Definitions
