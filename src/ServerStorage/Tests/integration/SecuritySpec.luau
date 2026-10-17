--!strict
-- B1.3: the anti-exploit suite (architecture §24 security tests), run against the LIVE handlers in a Play server.
-- NetGuard.connect exposes each client -> server handler in Studio as ServerStorage.NetHooks.<Remote>, so these
-- tests call exactly what a client's FireServer reaches, as the real player in the harbor (not crew) or as a fake
-- non-owner player. Nothing here may change the player's profile: every test compares it before and after.
-- Needs a Play server with one player (Test → Play); in Edit mode it fails with a clear message.
return function(T: any)
	local Players = game:GetService("Players")
	local HttpService = game:GetService("HttpService")
	local LogService = game:GetService("LogService")
	local NetGuard = T.require(game.ServerScriptService.Server.NetGuard) -- RATES only (the live buckets are the game's)
	local counters = game.ServerScriptService.Server.NetGuard -- the game's Allowed_/Limited_ attributes
	local state = game.ReplicatedStorage:FindFirstChild("GameState")

	local requestN = 0
	local function rid(): string
		requestN += 1
		return string.format("sec-%d-%d", os.time() % 100000, requestN)
	end

	local function setup(): (Folder, Player)
		local hooks = game.ServerStorage:FindFirstChild("NetHooks")
		local player = Players:GetPlayers()[1]
		if not hooks or not player then
			error("SecuritySpec needs a Play server with one player (NetHooks exist only while playing in Studio)")
		end
		return hooks :: Folder, player
	end

	local function fire(remote: string, player: any, ...: any): (boolean, string?)
		local hooks = setup()
		local hook = hooks:FindFirstChild(remote) :: BindableFunction?
		assert(hook, "no hook for " .. remote)
		return hook:Invoke(player, ...)
	end

	local function profile(player: Player): any
		local hooks = setup()
		local json = (hooks:FindFirstChild("_Profile") :: BindableFunction):Invoke(player)
		assert(type(json) == "string", "the player's profile is not loaded")
		return HttpService:JSONDecode(json)
	end

	local function world(player: Player): any
		local upgrades = {}
		for name, value in (state :: Instance):GetAttributes() do
			if string.sub(name, 1, 8) == "Upgrade_" then
				upgrades[name] = value
			end
		end
		return {
			profile = profile(player),
			shells = (state :: Instance):GetAttribute("Shells"),
			upgrades = upgrades,
			voyage = (state :: Instance):GetAttribute("VoyageDef"),
			ready = player:GetAttribute("Ready"),
		}
	end

	local function allowed(remote: string): number
		return (counters:GetAttribute("Allowed_" .. remote) :: number?) or 0
	end

	local function logSince(count: number, text: string): boolean
		local history = LogService:GetLogHistory()
		for i = count + 1, #history do
			if string.find(history[i].message, text, 1, true) then
				return true
			end
		end
		return false
	end

	T.describe("every remote is guarded", function()
		T.it("each contract remote has a live hook, and no handler connects around NetGuard", function()
			local hooks = setup()
			for remote in NetGuard.RATES do
				T.expect(hooks:FindFirstChild(remote) ~= nil).toBe(true)
			end
			local around = {}
			for _, inst in game.ServerScriptService:GetDescendants() do
				if inst:IsA("LuaSourceContainer") and inst.Name ~= "NetGuard" then
					local src = (inst :: any).Source :: string
					if string.find(src, "OnServerEvent", 1, true) or string.find(src, "OnServerInvoke", 1, true) then
						table.insert(around, inst:GetFullName())
					end
				end
			end
			T.expect(around).toEqual({})
		end)
	end)

	T.describe("invalid IDs", function()
		T.it("unknown items, upgrades, voyages and actions are refused and change nothing", function()
			local _, player = setup()
			local before = world(player)
			local reached = { ShopRequest = allowed("ShopRequest"), LoadoutRequest = allowed("LoadoutRequest"), BuyUpgrade = allowed("BuyUpgrade"), MerchantRequest = allowed("MerchantRequest") } -- (an unknown Trader action is dropped before the guard)
			local calls: { { any } } = {
				{ "ShopRequest", rid(), "buy", "NoSuchItem", 1 },
				{ "ShopRequest", rid(), "buy", "BeamSharedLantern", 1 }, -- earned only, never sold
				{ "ShopRequest", rid(), "buy", "FlareGun", -5 },
				{ "ShopRequest", rid(), "sell", { "table" }, 1 },
				{ "LoadoutRequest", rid(), "equip", "NoSuchItem" },
				{ "LoadoutRequest", rid(), "equip", "TidecallerBlades" }, -- not owned
				{ "LoadoutRequest", rid(), "nope", 42 },
				{ "BuyUpgrade", "NoSuchUpgrade", rid() },
				{ "MerchantRequest", rid(), "buy", "NoSuchItem", 1 },
				{ "MerchantRequest", rid(), "buy", "Heal", 1e9 },
				{ "TraderRequest", rid(), "nope" },
				{ "ChooseVoyage", "NoSuchVoyage" },
				{ "ChooseVoyage", "ModeTest" }, -- test-only voyage
				{ "ForecastVote", "NoSuchForecast" },
				{ "CoachEvent", "shown", "NoSuchPrompt" },
				{ "LampShift", "NoSuchShift", true },
				{ "ShopRequest", string.rep("x", 500), "buy", "FlareGun", 1 }, -- oversized request id
			}
			for _, call in calls do
				local ok, err = fire(call[1], player, table.unpack(call, 2))
				if not ok then
					error(call[1] .. " handler errored: " .. tostring(err))
				end
				task.wait(0.22) -- past the shop/loadout double-click guard, so each request is decided
			end
			-- the requests reached the decision (not just the rate limit) and nothing changed
			for remote, n in reached do
				T.expect(allowed(remote)).toBeGreaterThan(n)
			end
			T.expect(world(player)).toEqual(before)
		end, 15)
	end)

	T.describe("non-finite vectors and numbers", function()
		T.it("NaN and ±inf aims and numbers are dropped before the rate limit", function()
			local _, player = setup()
			local before = world(player)
			local attack, beam = allowed("Attack"), allowed("BeamControl")
			local nan = 0 / 0
			for _, v in { Vector3.new(nan, 0, 0), Vector3.new(math.huge, 0, 0), Vector3.new(0, -math.huge, 0), Vector3.new(0, 0, nan) } do
				fire("Attack", player, v)
			end
			fire("Attack", player, "not a vector")
			fire("Attack", player, nil)
			for _, n in { nan, math.huge, -math.huge } do
				fire("BeamControl", player, n)
			end
			fire("AdminRequest", player, rid(), "inspect", nan, nil)
			T.expect(allowed("Attack")).toBe(attack)
			T.expect(allowed("BeamControl")).toBe(beam)
			T.expect(world(player)).toEqual(before)
		end)
	end)

	T.describe("non-crew Shell spend", function()
		T.it("a harbor player cannot spend the crew's Shells at the bench or the merchant", function()
			local _, player = setup()
			T.expect(player:GetAttribute("Ready") == true).toBe(false) -- in the harbor, not crew
			local before = world(player)
			local logs = #LogService:GetLogHistory()
			local merchant = allowed("MerchantRequest")
			fire("BuyUpgrade", player, "LensPower", rid())
			task.wait(0.35)
			fire("MerchantRequest", player, rid(), "buy", "Heal", 1)
			task.wait(0.1)
			T.expect(logSince(logs, "Only the voyage crew can spend the crew's Shells.")).toBe(true)
			T.expect(allowed("MerchantRequest")).toBe(merchant + 1) -- decided, and refused (Shells unchanged below)
			T.expect(world(player)).toEqual(before)
		end)
	end)

	T.describe("admin probing", function()
		T.it("a non-owner's inspect, grant and rollback are refused and logged; Pearls unchanged", function()
			local _, player = setup()
			local before = world(player)
			local logs = #LogService:GetLogHistory()
			local probe = { UserId = 12345, Name = "Probe", DisplayName = "Probe" }
			fire("AdminRequest", probe, rid(), "grant", player.UserId, 500)
			fire("AdminRequest", probe, rid(), "rollback", player.UserId, "2026-10-01")
			fire("AdminRequest", probe, rid(), "inspect", player.UserId, nil)
			task.wait(0.1)
			T.expect(logSince(logs, "[AdminDataService] refused grant from user 12345")).toBe(true)
			T.expect(logSince(logs, "[AdminDataService] refused rollback from user 12345")).toBe(true)
			T.expect(logSince(logs, "[AdminDataService] refused inspect from user 12345")).toBe(true)
			T.expect(world(player)).toEqual(before)
		end)
	end)

	-- last: it drains the player's buckets
	T.describe("50x spam", function()
		T.it("every remote, 50 requests at once: accepted <= burst + refill, and nothing changes", function()
			local _, player = setup()
			local before = world(player)
			local args: { [string]: () -> { any } } = {
				Attack = function() return { Vector3.new(0, -500, 0) } end,
				BeamControl = function() return { 0 } end,
				LampAction = function() return { "refuel" } end,
				LampShift = function() return { "NoSuchShift", true } end,
				BuyUpgrade = function() return { "NoSuchUpgrade", rid() } end,
				ShopRequest = function() return { rid(), "buy", "NoSuchItem", 1 } end,
				TraderRequest = function() return { rid(), "nope" } end,
				LoadoutRequest = function() return { rid(), "equip", "NoSuchItem" } end,
				GearAction = function() return { "sync" } end,
				SetReady = function() return { false } end,
				VoteRematch = function() return {} end,
				EnterLobby = function() return {} end,
				ReportDevice = function() return { "Keyboard" } end,
				CoachEvent = function() return { "shown", "NoSuchPrompt" } end,
				ForecastVote = function() return { "NoSuchForecast" } end,
				AdminRequest = function() return { rid(), "nope", 1, nil } end,
				ChooseVoyage = function() return { "NoSuchVoyage" } end,
				MerchantRequest = function() return { rid(), "buy", "NoSuchItem", 1 } end,
			}
			local over = {}
			for remote, rate in NetGuard.RATES do
				local make = args[remote]
				assert(make, "no spam arguments for " .. remote)
				local start, t0 = allowed(remote), os.clock()
				for _ = 1, 50 do
					fire(remote, player, table.unpack(make()))
				end
				local limit = rate[2] + math.ceil(rate[1] * (os.clock() - t0)) + 1
				local accepted = allowed(remote) - start
				if accepted > limit then
					table.insert(over, string.format("%s accepted %d of 50 (limit %d)", remote, accepted, limit))
				end
			end
			T.expect(over).toEqual({})
			T.expect(world(player).profile).toEqual(before.profile)
		end, 20)
	end)
end
