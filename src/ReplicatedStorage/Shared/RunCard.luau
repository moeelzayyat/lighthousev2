--!strict
-- RunCard (S2.5): the one-line voyage summary a player can copy from the Results screen to share. Pure.
-- Example: "Lighthouse Keepers · The light held: 7 of 7 nights · Standard Voyage · 15:35 · crew of 2"

local Voyages = require(script.Parent:WaitForChild("Definitions"):WaitForChild("Voyages"))

local RunCard = {}

export type Results = {
	result: string?,
	nightReached: number?,
	totalNights: number?,
	voyage: string?,
	duration: number?,
	crew: { any }?,
	crewSize: number?, -- the sailing crew (crew lists only members who did something)
}

local function clock(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", s // 60, s % 60)
end

function RunCard.text(r: Results): string
	local total = r.totalNights or 0
	local parts = { "Lighthouse Keepers" }
	local def = if r.voyage then (Voyages :: any)[r.voyage] else nil
	local endless = type(def) == "table" and def.endless == true
	if r.result == "Victory" then
		table.insert(parts, string.format("The light held: %d of %d nights", total, total))
	elseif endless then
		table.insert(parts, string.format("Endless Storm: reached night %d", math.max(1, r.nightReached or 1))) -- S3.1b
	else
		table.insert(parts, string.format("Lost on night %d of %d", math.max(1, r.nightReached or 1), total))
	end
	if type(def) == "table" and def.displayName and not endless then
		table.insert(parts, def.displayName)
	end
	table.insert(parts, clock(r.duration or 0))
	local crew = r.crewSize or (if r.crew then #r.crew else 0)
	if crew == 1 then
		table.insert(parts, "solo")
	elseif crew > 1 then
		table.insert(parts, string.format("crew of %d", crew))
	end
	return table.concat(parts, " \u{00B7} ")
end

return RunCard
