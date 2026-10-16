--!strict
-- R1.8: admin tools on mock stores: snapshots, rollback (online and at next load), grant, owner-only access.
return function(T: any)
	local Players = game:GetService("Players")
	local OWNER = 11752219158

	local function fakePlayer(userId: number)
		local p: any = { UserId = userId, Name = "Test" .. userId, DisplayName = "Test" .. userId, Parent = Players, attrs = {} }
		function p.SetAttribute(self: any, k: string, v: any)
			self.attrs[k] = v
		end
		function p.GetAttribute(self: any, k: string)
			return self.attrs[k]
		end
		function p.Kick() end
		return p
	end

	local function setup(nowValue: number)
		local PlayerData = T.require(game.ServerScriptService.Server.PlayerData)
		local GrantService = T.require(game.ServerScriptService.Server.GrantService)
		local ProfileSchema = T.require(game.ServerScriptService.Server.ProfileSchema)
		local Admin = T.require(game.ServerScriptService.Server.AdminDataService)
		local profileStore = T.require(game.ServerStorage.Tests.fixtures.FakeProfileStore).new(ProfileSchema.template())
		PlayerData.init(nil, nil, { store = profileStore, mode = "memory" })
		local online: { [number]: any } = {}
		local logs: { string } = {}
		local snapshots = Admin.memoryStore()
		local serial = 0
		Admin.init({
			playerData = PlayerData,
			grant = GrantService,
			store = snapshots,
			findPlayer = function(id: number)
				return online[id]
			end,
			now = function()
				return nowValue
			end,
			log = function(name: string, _fields: any)
				table.insert(logs, name)
			end,
			newId = function()
				serial += 1
				return tostring(serial)
			end,
		})
		local function join(userId: number)
			local p = fakePlayer(userId)
			online[userId] = p
			PlayerData._load(profileStore, p)
			Admin.onProfileLoaded(userId) -- what the ProfileLoaded bus event does live
			return p
		end
		local function leave(p: any)
			online[p.UserId] = nil
			PlayerData._unload(p)
		end
		return Admin, PlayerData, snapshots, join, leave, logs
	end

	local DAY = 86400
	local T0 = 1792108800 -- 2026-10-16 00:00 UTC

	T.describe("AdminDataService", function()
		T.it("keeps one snapshot per day, the 7 newest", function()
			local Admin = setup(T0)
			local r = nil
			for i = 1, 10 do
				r = Admin.addSnapshot(r, Admin.dayKey(T0 + i * DAY), { Pearls = i })
			end
			r = Admin.addSnapshot(r, Admin.dayKey(T0 + 10 * DAY), { Pearls = 999 }) -- same day: first copy wins
			local n = 0
			for _ in r.days do
				n += 1
			end
			T.expect(n).toBe(7)
			T.expect(r.days[Admin.dayKey(T0 + 10 * DAY)].Pearls).toBe(10)
			T.expect(r.days[Admin.dayKey(T0 + 3 * DAY)]).toBeNil()
		end)

		T.it("a non-whitelisted call is rejected and logged", function()
			local Admin, _, _, join, _, logs = setup(T0)
			join(500)
			local ok, why = Admin.handle(12345, "grant", 500, 100)
			T.expect(ok).toBe(false)
			T.expect(why).toBe("not allowed")
			T.expect(logs).toContain("AdminRejected")
		end)

		T.it("rollback of an online mock profile restores the snapshot", function()
			local Admin, PlayerData, snapshots, join = setup(T0 + 5 * DAY)
			-- a snapshot from 3 days ago with 99 Pearls
			snapshots.values.player_501 = { days = { [Admin.dayKey(T0 + 2 * DAY)] = { Pearls = 99, SchemaVersion = 2 } } }
			local p = join(501)
			T.expect(Admin.handle(OWNER, "grant", 501, 40)).toBe(true)
			T.expect(PlayerData.data(p).Pearls).toBe(40)
			local ok = Admin.handle(OWNER, "rollback", 501, Admin.dayKey(T0 + 2 * DAY))
			T.expect(ok).toBe(true)
			T.expect(PlayerData.data(p).Pearls).toBe(99)
			T.expect(PlayerData.data(p).Owned.DriftwoodHarpoon).toBe(true) -- snapshot validated on the way in
		end)

		T.it("rollback of an offline player is applied at the next load", function()
			local Admin, PlayerData, _, join, leave = setup(T0)
			local p = join(502) -- today's snapshot: 0 Pearls
			Admin.handle(OWNER, "grant", 502, 25)
			leave(p)
			local ok, msg = Admin.handle(OWNER, "rollback", 502, Admin.dayKey(T0))
			T.expect(ok).toBe(true)
			T.expect(msg).toContain("next joins")
			local again = join(502)
			T.expect(PlayerData.data(again).Pearls).toBe(0)
		end)

		T.it("inspect, and refusals for bad input", function()
			local Admin, _, _, join = setup(T0)
			join(503)
			local ok, info = Admin.handle(OWNER, "inspect", 503)
			T.expect(ok).toBe(true)
			T.expect(info.online).toBe(true)
			T.expect(info.data.SchemaVersion).toBe(2)
			T.expect(info.snapshotDays).toEqual({ Admin.dayKey(T0) })
			T.expect((Admin.handle(OWNER, "grant", 503, -5))).toBe(false)
			T.expect((Admin.handle(OWNER, "grant", 999, 5))).toBe(false) -- not online
			T.expect((Admin.handle(OWNER, "rollback", 503, "yesterday"))).toBe(false)
			T.expect((Admin.handle(OWNER, "rollback", 503, "2020-01-01"))).toBe(false) -- no snapshot
			T.expect((Admin.handle(OWNER, "delete", 503))).toBe(false)
		end)
	end)
end
