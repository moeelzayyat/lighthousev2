--!strict
-- S4.2/S4.3: the creature snapshot codec and the client's interpolation.
return function(T: any)
	local Snap = T.require(game.ReplicatedStorage.Shared.CreatureSnapshot)
	local Creatures = T.require(game.ReplicatedStorage.Shared.Creatures)

	local function close(a: number, b: number, eps: number): boolean
		return math.abs(a - b) <= eps
	end

	T.describe("codec", function()
		T.it("round-trips every field (f32 positions, yaw to 1/256 turn, hp to 1/255)", function()
			local entries = {
				{ id = 7, kind = 2, x = 12.25, y = 10.7, z = -88.5, yaw = 123.4, state = Snap.MOVING + Snap.LIT, hp = 0.42 },
				{ id = 65535, kind = 0, x = -0.001, y = -0.5, z = 91.99, yaw = 359.9, state = Snap.DYING, hp = 1 },
			}
			local t, list = Snap.decode(Snap.encode(entries, 1234.5678))
			T.expect(t).toBe(1234.5678)
			T.expect(#list).toBe(2)
			for i, e in entries do
				local d = list[i]
				T.expect(d.id).toBe(e.id)
				T.expect(d.kind).toBe(e.kind)
				T.expect(close(d.x, e.x, 1e-3) and close(d.y, e.y, 1e-3) and close(d.z, e.z, 1e-3)).toBe(true)
				T.expect(close(((d.yaw - e.yaw + 180) % 360) - 180, 0, 360 / 256)).toBe(true)
				T.expect(d.state).toBe(e.state)
				T.expect(close(d.hp, e.hp, 1 / 255)).toBe(true)
			end
		end)

		T.it("50 creatures fit one unreliable packet (<= 1000 bytes); 18 bytes each", function()
			local entries = {}
			for i = 1, 50 do
				table.insert(entries, { id = i, kind = 1, x = i, y = 0, z = -i, yaw = 0, state = 0, hp = 1 })
			end
			T.expect(buffer.len(Snap.encode(entries, 0))).toBe(910)
			T.expect(buffer.len(Snap.encode(entries, 0, 11, 20))).toBe(10 + 18 * 10)
			T.expect(Snap.MAX_PER_PACKET * Snap.ENTRY + Snap.HEADER <= 1000).toBe(true)
		end)

		T.it("a short buffer decodes to nothing", function()
			local t, list = Snap.decode(buffer.create(5))
			T.expect(t).toBeNil()
			T.expect(#list).toBe(0)
		end)

		T.it("kinds: every catalog creature, sorted, fits a byte", function()
			local kinds = Snap.kinds(Creatures)
			T.expect(#kinds >= 4 and #kinds < 256).toBe(true)
			T.expect(table.find(kinds, "RockCrab") ~= nil).toBe(true)
			for i = 2, #kinds do
				T.expect(kinds[i - 1] < kinds[i]).toBe(true)
			end
		end)
	end)

	T.describe("interpolation", function()
		local h = {
			{ t = 1.0, x = 0, y = 0, z = 0, yaw = 350 },
			{ t = 1.1, x = 10, y = 2, z = -10, yaw = 10 },
		}
		T.it("halfway between two snapshots is halfway (yaw the short way through 0)", function()
			local x, y, z, yaw = Snap.sample(h, 1.05)
			T.expect(close(x, 5, 1e-9) and close(y, 1, 1e-9) and close(z, -5, 1e-9)).toBe(true)
			T.expect(close(yaw, 0, 1e-9) or close(yaw, 360, 1e-9)).toBe(true)
		end)

		T.it("holds the first before, the last after (no extrapolation)", function()
			local x0 = Snap.sample(h, 0.5)
			local x1 = Snap.sample(h, 9)
			T.expect(x0).toBe(0)
			T.expect(x1).toBe(10)
		end)
	end)
end
