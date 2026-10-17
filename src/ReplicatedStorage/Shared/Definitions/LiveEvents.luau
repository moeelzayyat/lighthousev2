--!strict
-- Definitions/LiveEvents (LO.1): live-ops events (not the event bus: that is Shared/Events). Each is switched on by
-- a window in server time (UTC seconds), so an event starts and ends without a publish. An event may bring a voyage
-- (Definitions/Voyages, `event = <id>`), which the crew card offers to everyone while the event is on. Windows are
-- D-037 (recommendation): the owner moves them by changing `starts`/`ends` here. Checked by _Registry at boot.

export type EventDef = {
	id: string,
	displayName: string,
	blurb: string,
	voyage: string?, -- the voyage it offers
	starts: number, -- os.time() UTC, inclusive
	ends: number, -- os.time() UTC, exclusive
}

local LiveEvents = {
	ORDER = { "ShipwreckRescue" },

	ShipwreckRescue = {
		id = "ShipwreckRescue",
		displayName = "Shipwreck Rescue",
		blurb = "A ship broke up on the rocks. Carry its castaways to the lighthouse.",
		voyage = "Rescue",
		starts = 1792195200, -- 2026-10-17 00:00 UTC
		ends = 1794009600, -- 2026-11-07 00:00 UTC
	} :: EventDef,
}

-- Is this event on at time `now` (UTC seconds)?
function LiveEvents.isOn(id: string, now: number): boolean
	local def = (LiveEvents :: any)[id]
	return type(def) == "table" and type(def.starts) == "number" and now >= def.starts and now < def.ends
end

-- The ids of the events on at time `now`, in ORDER
function LiveEvents.active(now: number): { string }
	local list = {}
	for _, id in LiveEvents.ORDER do
		if LiveEvents.isOn(id, now) then
			table.insert(list, id)
		end
	end
	return list
end

return LiveEvents
