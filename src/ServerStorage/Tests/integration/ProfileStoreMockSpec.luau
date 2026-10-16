--!strict
-- R1.3 integration on the real library: PlayerData + GrantService on ProfileStore.Mock (never the real store).
-- Each test uses its own store name so mock records never collide.
return function(T: any)
	local Players = game:GetService("Players")
	local HttpService = game:GetService("HttpService")

	local function fakePlayer(userId: number)
		local p: any = { UserId = userId, Name = "Test" .. userId, DisplayName = "Test" .. userId, Parent = Players, attrs = {}, kicked = nil }
		function p.SetAttribute(self: any, k: string, v: any)
			self.attrs[k] = v
		end
		function p.GetAttribute(self: any, k: string)
			return self.attrs[k]
		end
		function p.Kick(self: any, message: string)
			self.kicked = message
		end
		return p
	end

	local function setup()
		local PlayerData = T.require(game.ServerScriptService.Server.PlayerData)
		local GrantService = T.require(game.ServerScriptService.Server.GrantService)
		local ProfileSchema = T.require(game.ServerScriptService.Server.ProfileSchema)
		local ProfileStore = T.require(game.ServerScriptService.Server.ProfileStore)
		local name = "LK_Test_" .. string.sub(HttpService:GenerateGUID(false), 1, 8)
		local mock = ProfileStore.New(name, ProfileSchema.template()).Mock
		PlayerData.init(nil, nil, { store = mock, mode = "memory" })
		return PlayerData, GrantService, mock
	end

	T.describe("PlayerData on ProfileStore.Mock", function()
		T.it("a new player loads a v2 profile", function()
			local PlayerData, _, mock = setup()
			local p = fakePlayer(201)
			PlayerData._load(mock, p)
			local data = PlayerData.data(p)
			T.expect(data ~= nil).toBe(true)
			T.expect(data.SchemaVersion).toBe(2)
			T.expect(data.Pearls).toBe(0)
			T.expect(data.Owned.DriftwoodHarpoon).toBe(true)
			PlayerData._unload(p)
		end, 10)

		T.it("quick rejoin on the same server keeps Pearls and the claim", function()
			local PlayerData, GrantService, mock = setup()
			local p = fakePlayer(202)
			PlayerData._load(mock, p)
			T.expect(GrantService.Grant(p, "v:result:202", { Pearls = 12 }, "run")).toBe("granted")
			PlayerData.recordRun(p, true, 7)
			PlayerData._unload(p) -- EndSession: last save runs in the background
			local again = fakePlayer(202)
			PlayerData._load(mock, again) -- waits behind the in-flight save
			local data = PlayerData.data(again)
			T.expect(data.Pearls).toBe(12)
			T.expect(data.Stats.Runs).toBe(1)
			T.expect(GrantService.Grant(again, "v:result:202", { Pearls = 12 }, "run")).toBe("duplicate")
			T.expect(data.Pearls).toBe(12)
			PlayerData._unload(again)
		end, 10)

		T.it("spend and buy round-trip through a save", function()
			local PlayerData, GrantService, mock = setup()
			local p = fakePlayer(203)
			PlayerData._load(mock, p)
			GrantService.Grant(p, "c:203", { Pearls = 30 }, "run")
			T.expect(PlayerData.spendPearls(p, 25, "StormHarpoon")).toBe(true)
			PlayerData.addItem(p, "StormHarpoon", 1)
			PlayerData._unload(p)
			local again = fakePlayer(203)
			PlayerData._load(mock, again)
			T.expect(PlayerData.data(again).Pearls).toBe(5)
			T.expect(PlayerData.owns(again, "StormHarpoon")).toBe(true)
			PlayerData._unload(again)
		end, 10)
	end)
end
