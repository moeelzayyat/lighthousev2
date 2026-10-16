--!strict
-- R1.3 integration: PlayerData on a ProfileStore-compatible mock store (never the real store).
-- Fake players are plain tables with the Player members PlayerData uses.
return function(T: any)
	local Players = game:GetService("Players")

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
		local store = T.require(game.ServerStorage.Tests.fixtures.FakeProfileStore).new(ProfileSchema.template())
		PlayerData.init(nil, nil, { store = store, mode = "memory" })
		return PlayerData, GrantService, store
	end

	T.describe("PlayerData on a mock store", function()
		T.it("a new player gets a v2 profile: starters, CreatedAt, first play day", function()
			local PlayerData, _, store = setup()
			local p = fakePlayer(101)
			PlayerData._load(store, p)
			local data = PlayerData.data(p)
			T.expect(data.SchemaVersion).toBe(2)
			T.expect(data.Pearls).toBe(0)
			T.expect(data.Owned.DriftwoodHarpoon).toBe(true)
			T.expect(data.CreatedAt > 0).toBe(true)
			T.expect(data.Stats.PlayDays).toBe(1)
			T.expect(p.attrs.ProfileState).toBe("memory")
			T.expect(p.attrs.RunsCompleted).toBe(0)
			T.expect(PlayerData.get(p).pearls).toBe(0) -- v1-shaped view for old callers
		end)

		T.it("load, change, leave, reload = same data (quick rejoin keeps Pearls)", function()
			local PlayerData, GrantService, store = setup()
			local p = fakePlayer(102)
			PlayerData._load(store, p)
			T.expect(GrantService.Grant(p, "v1:result:102", { Pearls = 12 }, "run")).toBe("granted")
			PlayerData.recordRun(p, true, 7)
			PlayerData._unload(p)
			local again = fakePlayer(102)
			PlayerData._load(store, again)
			local data = PlayerData.data(again)
			T.expect(data.Pearls).toBe(12)
			T.expect(data.Stats.Runs).toBe(1)
			T.expect(data.Stats.Victories).toBe(1)
			T.expect(data.Grants["v1:result:102"] ~= nil).toBe(true)
		end)

		T.it("a replayed claim after a rejoin still grants once", function()
			local PlayerData, GrantService, store = setup()
			local p = fakePlayer(103)
			PlayerData._load(store, p)
			GrantService.Grant(p, "v9:result:103", { Pearls = 5 }, "run")
			PlayerData._unload(p)
			local again = fakePlayer(103)
			PlayerData._load(store, again)
			T.expect(GrantService.Grant(again, "v9:result:103", { Pearls = 5 }, "run")).toBe("duplicate")
			T.expect(PlayerData.data(again).Pearls).toBe(5)
		end)

		T.it("Pearl grants and purchases are saved immediately", function()
			local PlayerData, GrantService, store = setup()
			local p = fakePlayer(104)
			PlayerData._load(store, p)
			local before = store.saves
			GrantService.Grant(p, "c1", { Pearls = 30 }, "run")
			T.expect(store.saves).toBe(before + 1)
			T.expect(store.records.player_104.Pearls).toBe(30)
			T.expect(PlayerData.spendPearls(p, 25, "StormHarpoon")).toBe(true)
			T.expect(store.records.player_104.Pearls).toBe(5)
			T.expect(PlayerData.spendPearls(p, 25, "StormHarpoon")).toBe(false)
		end)

		T.it("a save still held by another server is never loaded as a new player: kick, no profile", function()
			local PlayerData, _, store = setup()
			local first = fakePlayer(105)
			PlayerData._load(store, first)
			local second = fakePlayer(105) -- same account, session still open
			PlayerData._load(store, second)
			T.expect(PlayerData.data(second)).toBeNil()
			T.expect(second.attrs.ProfileState).toBe("failed")
			T.expect(second.kicked ~= nil).toBe(true)
		end)

		T.it("a player who left while loading never gets a session", function()
			local PlayerData, _, store = setup()
			local p = fakePlayer(106)
			p.Parent = nil
			PlayerData._load(store, p)
			T.expect(PlayerData.data(p)).toBeNil()
			T.expect(p.kicked).toBeNil()
		end)

		T.it("S2.1: a win's unlock is saved, mirrored as an attribute and survives a rejoin", function()
			local PlayerData, _, store = setup()
			local p = fakePlayer(108)
			PlayerData._load(store, p)
			T.expect(p.attrs.Unlock_LongVoyage).toBe(false)
			T.expect(PlayerData.unlock(p, "LongVoyage")).toBe(true)
			T.expect(p.attrs.Unlock_LongVoyage).toBe(true)
			T.expect(PlayerData.unlock(p, "NoSuchUnlock")).toBe(false)
			PlayerData._unload(p)
			local again = fakePlayer(108)
			PlayerData._load(store, again)
			T.expect(again.attrs.Unlock_LongVoyage).toBe(true)
			T.expect(PlayerData.data(again).Unlocks.LongVoyage).toBe(true)
		end)

		T.it("S2.2: leaving at night 5 keeps the 4 Pearls banked at dawn; a replayed dawn grants once", function()
			local PlayerData, GrantService, store = setup()
			local DawnBanking = T.require(game.ServerScriptService.Server.DawnBanking)
			local Config = T.require(game.ReplicatedStorage.Shared.Config)
			local p = fakePlayer(109)
			PlayerData._load(store, p)
			local deps = {
				config = Config,
				grant = function(_, claimId: string, rewards: any): string
					return (GrantService.Grant(p, claimId, rewards, "dawn"))
				end,
				notify = function() end,
			}
			for night = 1, 4 do
				DawnBanking.bank("vLeave", night, { 109 }, deps)
			end
			DawnBanking.bank("vLeave", 4, { 109 }, deps) -- replayed dawn
			T.expect(PlayerData.data(p).Pearls).toBe(4)
			PlayerData._unload(p) -- leaves during night 5
			local again = fakePlayer(109)
			PlayerData._load(store, again)
			T.expect(PlayerData.data(again).Pearls).toBe(4)
			T.expect(PlayerData.data(again).Grants["vLeave:night4:109"] ~= nil).toBe(true)
			T.expect(GrantService.Grant(again, "vLeave:night4:109", { Pearls = 1 }, "dawn")).toBe("duplicate")
			T.expect(PlayerData.data(again).Pearls).toBe(4)
			DawnBanking.forget("vLeave")
		end)

		T.it("a stored profile with bad types is repaired on load", function()
			local PlayerData, _, store = setup()
			local ProfileSchema = T.require(game.ServerScriptService.Server.ProfileSchema)
			local bad = ProfileSchema.template() :: any
			bad.Pearls = "lots"
			store.records.player_107 = bad
			local p = fakePlayer(107)
			PlayerData._load(store, p)
			T.expect(PlayerData.data(p).Pearls).toBe(0)
		end)
	end)
end
