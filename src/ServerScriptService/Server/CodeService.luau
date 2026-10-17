--!strict
-- CodeService (L1.4, LiveOps domain): Settings → Codes. A code from Definitions/Codes pays once per profile: the
-- reward goes through GrantService (claim "code:<CODE>") and the code is written to the profile's RedeemedCodes,
-- which is never pruned (GrantService prunes claims after 30 days, so the claim alone would not be enough).
-- Pure apart from its deps; LiveOps connects the CodeRedeem remote.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Codes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("Codes")) :: any
local Items = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Items")) :: any

local CodeService = {}

CodeService.MAX_LENGTH = 32

export type Deps = {
	data: (player: any) -> any,
	mutate: (player: any, fn: (any) -> boolean, saveNow: boolean?) -> boolean,
	grant: (player: any, claimId: string, rewards: any, source: string) -> string,
	now: () -> number,
	log: (name: string, fields: any) -> (),
	codes: any?, -- the catalogue (Definitions/Codes unless a test passes its own)
}

-- The definition whose `code` is this text, or nil
function CodeService.find(catalog: any, code: string): any
	for _, id in catalog.ORDER do
		local def = catalog[id]
		if type(def) == "table" and def.code == code then
			return def
		end
	end
	return nil
end

-- "  lighthouse " -> "LIGHTHOUSE"; nil when it cannot be a code (letters and digits only, at most 32)
function CodeService.normalize(text: any): string?
	if type(text) ~= "string" or #text > 64 then
		return nil
	end
	local code = string.upper((string.gsub(text, "%s", "")))
	if #code == 0 or #code > CodeService.MAX_LENGTH or string.find(code, "[^%w]") then
		return nil
	end
	return code
end

local function describe(reward: any): string
	local parts = {}
	if reward.Pearls then
		table.insert(parts, string.format("%d Pearls", reward.Pearls))
	end
	for id in reward.Items or {} do
		local item = Items[id]
		table.insert(parts, if item then item.name else id)
	end
	return table.concat(parts, " and ")
end

-- One attempt. Returns ok and the message for the player.
function CodeService.redeem(player: any, text: any, deps: Deps): (boolean, string)
	local code = CodeService.normalize(text)
	local def = if code then CodeService.find(deps.codes or Codes, code) else nil
	if not code or not def then
		return false, "That code isn't valid."
	end
	if def.expires and deps.now() > def.expires then
		return false, "That code has expired."
	end
	local data = deps.data(player)
	if not data then
		return false, "Your save is still loading. Try again in a moment."
	end
	if type(data.RedeemedCodes) == "table" and data.RedeemedCodes[code] then
		return false, "You already used that code."
	end
	local status = deps.grant(player, "code:" .. code, def.reward, "code")
	if status ~= "granted" and status ~= "duplicate" then
		return false, "Something went wrong, so the code was not used. Try again later."
	end
	deps.mutate(player, function(d: any): boolean
		d.RedeemedCodes[code] = true
		return true
	end, true)
	if status == "duplicate" then
		return false, "You already used that code."
	end
	deps.log("CodeRedeemed", { player = player.Name, code = code })
	return true, string.format("Code redeemed: %s!", describe(def.reward))
end

return CodeService
