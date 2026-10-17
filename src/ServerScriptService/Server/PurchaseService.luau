--!strict
-- PurchaseService (L1.3, Economy domain): Robux purchases of cosmetics. The one place that answers
-- MarketplaceService.ProcessReceipt. A receipt is granted once: the item goes through GrantService with the claim
-- "receipt:<PurchaseId>", so a receipt Roblox sends again (a retry, a second server) is answered "granted"
-- without a second grant. Only items in Definitions/Cosmetics can be bought, and only while ROBUX_ENABLED is on.
-- When the buyer is not in this server or their save is not loaded, the answer is NotProcessedYet and Roblox
-- asks again later (nothing is lost).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cosmetics = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("Cosmetics")) :: any

local PurchaseService = {}

export type Deps = {
	playerByUserId: (userId: number) -> any,
	loaded: (player: any) -> boolean,
	grant: (player: any, claimId: string, rewards: any, source: string) -> string,
	log: (name: string, fields: any) -> (),
	notify: (player: any, text: string) -> (),
	nameOf: (itemId: string) -> string,
	cosmetics: any?, -- the catalogue (Definitions/Cosmetics unless a test passes its own)
}

-- "granted" (Roblox may keep the Robux) or "notYet" (ask again later)
function PurchaseService.process(receipt: any, deps: Deps): string
	local catalog = deps.cosmetics or Cosmetics
	if type(receipt) ~= "table" or type(receipt.PurchaseId) ~= "string" or type(receipt.PlayerId) ~= "number" or type(receipt.ProductId) ~= "number" then
		return "notYet"
	end
	local itemId = if catalog.ROBUX_ENABLED then catalog.itemFor(receipt.ProductId) else nil
	if not itemId then
		deps.log("PurchaseUnknown", { product = receipt.ProductId, user = receipt.PlayerId })
		return "notYet"
	end
	local player = deps.playerByUserId(receipt.PlayerId)
	if not player or not deps.loaded(player) then
		return "notYet"
	end
	local status = deps.grant(player, "receipt:" .. receipt.PurchaseId, { Items = { [itemId] = 1 } }, "robux")
	if status == "granted" then
		deps.log("PurchaseGranted", { player = player.Name, item = itemId, product = receipt.ProductId, robux = receipt.CurrencySpent })
		deps.notify(player, string.format("Thank you! %s is yours. Equip it from your BAG.", deps.nameOf(itemId)))
		return "granted"
	elseif status == "duplicate" then
		return "granted" -- already given for this receipt
	end
	return "notYet"
end

return PurchaseService
