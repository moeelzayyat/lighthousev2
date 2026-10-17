--!strict
-- ModeTest (S3.1b, D-017): the main-mode test of the public test. Pure.
-- Accounts created on or after MODE_TEST_START are split 50/50 by account id into "Standard" (the 7-night
-- voyage) and "Endless" (Endless Storm: nights until the light goes out, Best Night is the score). The split
-- is a hash of the UserId, so an account keeps its arm forever and no save field is needed. Older accounts
-- are not in the test (nil) and keep the Standard default.

local ModeTest = {}

export type TestConfig = { MODE_TEST_ENABLED: boolean?, MODE_TEST_START: number? }

ModeTest.SALT = "S3.1b"

local function fnv1a(s: string): number
	local h = 2166136261
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		h = (bit32.lshift(h, 24) + h * 403) % 2 ^ 32 -- h * 16777619 without losing precision
	end
	return h
end

-- The arm of one account, or nil when the account is not in the test.
function ModeTest.armFor(userId: number, createdAt: number, config: TestConfig): string?
	if not config.MODE_TEST_ENABLED or createdAt < (config.MODE_TEST_START or math.huge) then
		return nil
	end
	return if fnv1a(ModeTest.SALT .. ":" .. tostring(userId)) % 2 == 0 then "Standard" else "Endless"
end

-- The voyage a departing crew sails when nobody chose another one: Endless only when at least one member is
-- in the test and every tested member is in the Endless arm (a mixed crew sails the default).
function ModeTest.voyageFor(arms: { string }): string?
	local endless = 0
	for _, arm in arms do
		if arm == "Standard" then
			return nil
		elseif arm == "Endless" then
			endless += 1
		end
	end
	return if endless > 0 then "Endless" else nil
end

return ModeTest
