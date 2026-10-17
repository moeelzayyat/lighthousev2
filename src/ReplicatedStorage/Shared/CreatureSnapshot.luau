--!strict
-- CreatureSnapshot (S4.2/S4.3): the binary creature snapshot the server sends 12 times a second over an
-- UnreliableRemoteEvent, and the client's interpolation helper. Pure.
-- Layout: header [serverTime f64][count u16], then per creature
--   [id u16][kind u8][x f32][y f32][z f32][yaw u8][state u8][hp u8]   (18 bytes)
-- kind = index into kinds(Creatures); yaw in 1/256 turns (the beam's bearing convention: 0 faces -Z);
-- hp = health fraction * 255; state = the bit flags below.

local CreatureSnapshot = {}

CreatureSnapshot.HEADER = 10
CreatureSnapshot.ENTRY = 18
CreatureSnapshot.MAX_PER_PACKET = 50 -- 10 + 50 * 18 = 910 bytes, under the 1000-byte unreliable payload limit

CreatureSnapshot.MOVING = 1
CreatureSnapshot.LIT = 2 -- in the wide beam or the sweep
CreatureSnapshot.BURNING = 4 -- in the focused beam
CreatureSnapshot.HIT = 8 -- just hit (white flash)
CreatureSnapshot.IN_WATER = 16
CreatureSnapshot.TARGET_CANNON = 32 -- eye colour: orange
CreatureSnapshot.TARGET_PLAYER = 64 -- eye colour: red (neither = the tower, yellow)
CreatureSnapshot.DYING = 128 -- killed: the client plays the burst and removes it
-- S6.5: both target bits together (never a real target) = the creature is telegraphing its move
CreatureSnapshot.TELEGRAPH = CreatureSnapshot.TARGET_CANNON + CreatureSnapshot.TARGET_PLAYER

function CreatureSnapshot.isTelegraph(state: number): boolean
	return state // CreatureSnapshot.TARGET_CANNON % 4 == 3
end

export type Entry = { id: number, kind: number, x: number, y: number, z: number, yaw: number, state: number, hp: number }
export type Sample = { t: number, x: number, y: number, z: number, yaw: number }

-- The creature types as a list both sides agree on: catalog entries with health, sorted by name.
function CreatureSnapshot.kinds(catalog: { [string]: any }): { string }
	local list = {}
	for name, def in catalog do
		if type(def) == "table" and def.health ~= nil then
			table.insert(list, name)
		end
	end
	table.sort(list)
	return list
end

-- Encodes entries[first..last] (default: all).
function CreatureSnapshot.encode(entries: { Entry }, serverTime: number, first: number?, last: number?): buffer
	local i0, i1 = first or 1, last or #entries
	local n = math.max(0, i1 - i0 + 1)
	local b = buffer.create(CreatureSnapshot.HEADER + CreatureSnapshot.ENTRY * n)
	buffer.writef64(b, 0, serverTime)
	buffer.writeu16(b, 8, n)
	local o = CreatureSnapshot.HEADER
	for i = i0, i1 do
		local e = entries[i]
		buffer.writeu16(b, o, e.id % 65536)
		buffer.writeu8(b, o + 2, e.kind)
		buffer.writef32(b, o + 3, e.x)
		buffer.writef32(b, o + 7, e.y)
		buffer.writef32(b, o + 11, e.z)
		buffer.writeu8(b, o + 15, math.floor((e.yaw % 360) / 360 * 256 + 0.5) % 256)
		buffer.writeu8(b, o + 16, e.state)
		buffer.writeu8(b, o + 17, math.clamp(math.floor(e.hp * 255 + 0.5), 0, 255))
		o += CreatureSnapshot.ENTRY
	end
	return b
end

-- Returns the server time and the entries; nil when the buffer is malformed.
function CreatureSnapshot.decode(b: buffer): (number?, { Entry })
	local len = buffer.len(b)
	if len < CreatureSnapshot.HEADER then
		return nil, {}
	end
	local t = buffer.readf64(b, 0)
	local n = buffer.readu16(b, 8)
	if len < CreatureSnapshot.HEADER + CreatureSnapshot.ENTRY * n then
		return nil, {}
	end
	local list: { Entry } = table.create(n)
	local o = CreatureSnapshot.HEADER
	for _ = 1, n do
		table.insert(list, {
			id = buffer.readu16(b, o),
			kind = buffer.readu8(b, o + 2),
			x = buffer.readf32(b, o + 3),
			y = buffer.readf32(b, o + 7),
			z = buffer.readf32(b, o + 11),
			yaw = buffer.readu8(b, o + 15) / 256 * 360,
			state = buffer.readu8(b, o + 16),
			hp = buffer.readu8(b, o + 17) / 255,
		})
		o += CreatureSnapshot.ENTRY
	end
	return t, list
end

-- Position and yaw at render time t from a history ordered oldest first. Before the first sample it holds
-- the first; past the last it holds the last (no extrapolation). Yaw takes the short way round.
function CreatureSnapshot.sample(history: { Sample }, t: number): (number, number, number, number)
	local n = #history
	if n == 0 then
		return 0, 0, 0, 0
	end
	local last = history[n]
	if t >= last.t then
		return last.x, last.y, last.z, last.yaw
	end
	for i = n, 2, -1 do
		local a, b = history[i - 1], history[i]
		if a.t <= t then
			local u = if b.t > a.t then (t - a.t) / (b.t - a.t) else 1
			local turn = ((b.yaw - a.yaw + 180) % 360) - 180
			return a.x + (b.x - a.x) * u, a.y + (b.y - a.y) * u, a.z + (b.z - a.z) * u, (a.yaw + turn * u) % 360
		end
	end
	local first = history[1]
	return first.x, first.y, first.z, first.yaw
end

return CreatureSnapshot
