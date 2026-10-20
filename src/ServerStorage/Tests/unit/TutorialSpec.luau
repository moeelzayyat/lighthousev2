--!strict
-- TUT.1 (D-059): the first-time tutorial. New saves start with it to do, saves from before it existed skip it once
-- they have a finished voyage, the client can only say "finished" (never undo it), and the tutorial has a Skip,
-- harbor and voyage steps and no timer.
return function(T: any)
	local ProfileSchema = T.require(game.ServerScriptService.Server.ProfileSchema)
	local NetGuard = T.require(game.ServerScriptService.Server.NetGuard)

	T.describe("the tutorial", function()
		T.it("is to do on a new save, and done on an old save that has finished a voyage", function()
			T.expect(ProfileSchema.template().TutorialDone).toBe(false)
			local veteran = ProfileSchema.template() :: any
			veteran.TutorialDone = nil
			veteran.Stats.Runs = 4
			local fixed = ProfileSchema.validate(veteran)
			T.expect(fixed.TutorialDone).toBe(true)
			local newcomer = ProfileSchema.template() :: any
			newcomer.TutorialDone = nil
			T.expect(ProfileSchema.validate(newcomer).TutorialDone).toBe(false)
		end)

		T.it("has a rate-limited remote that only accepts true", function()
			T.expect(NetGuard.RATES.TutorialDone ~= nil).toBe(true)
			local data = (game.ServerScriptService.Server.Domains.Data :: any).Source :: string
			T.expect(data).toContain("done ~= true")
		end)

		T.it("walks the harbor and the voyage, can be skipped, and has no timer", function()
			local src = (game.StarterPlayer.StarterPlayerScripts.Client.Tutorial :: any).Source :: string
			for _, id in { "quartermaster", "bag", "board", "sail", "oil", "tank", "strike", "shells", "finish" } do
				T.expect(src).toContain('id = "' .. id .. '"')
			end
			T.expect(src).toContain('"Skip"')
			T.expect(string.find(src, "task.delay", 1, true) == nil).toBe(true) -- nothing moves on by itself: no timer
		end)
	end)
end
