-- World domain (S5.1/S5.2): the island and the pirate-ship lobby are built here, and the island's ground is
-- sampled once (S4.1) so creatures never raycast while they move.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = script.Parent.Parent
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ground = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Ground"))
local EventLog = require(Server.EventLog)
local IslandBuilder = require(Server.IslandBuilder)
local LobbyBuilder = require(Server.LobbyBuilder)
local PlaceRole = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlaceRole"))

local World = { Name = "World" }

function World.Init(ctx)
	ctx.refs = IslandBuilder.build()
	ctx.lobbyRefs = LobbyBuilder.build(ctx.refs) -- the pirate-ship lobby (also moves the Quartermaster aboard)
	-- D-046: the harbor has several ships around its island; the isle and the one-place game keep the first ship
	if PlaceRole.isHarbor() then
		local angles = table.move(Config.HARBOR_SHIP_ANGLES, 1, math.min(Config.HARBOR_SHIPS, #Config.HARBOR_SHIP_ANGLES), 1, {})
		ctx.lobbyRefs.ships = LobbyBuilder.buildExtraShips(ctx.lobbyRefs, angles)
	end
end

function World.Start(_ctx)
	-- Until the grid is ready, Ground.heightAt raycasts as before
	task.spawn(function()
		local started = os.clock()
		local samples = Ground.buildGrid(Config.ISLAND_CENTER.X, Config.ISLAND_CENTER.Z, Config.GROUND_GRID_RADIUS)
		EventLog.log("GroundGrid", { samples = samples, seconds = math.floor((os.clock() - started) * 100) / 100 })
	end)
end

return World
