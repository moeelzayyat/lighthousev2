--!strict
-- S5.1: the server boots its domains in the fixed order of architecture §5.2, Inits before Starts, with the
-- remotes exposed last; a wrong order refuses to boot.
return function(T: any)
	local Bootstrap = T.require(game.ServerScriptService.Server.Bootstrap)

	-- Fake domains that record each phase they run
	local function fakes(names: { string }, record: { string }): { any }
		local list = {}
		for _, name in names do
			table.insert(list, {
				Name = name,
				Init = function(ctx: any)
					table.insert(record, name .. ":Init")
					ctx[name] = true
				end,
				Start = function(_ctx: any)
					table.insert(record, name .. ":Start")
				end,
			})
		end
		return list
	end

	local function swapped(a: number, b: number): { string }
		local names = table.clone(Bootstrap.ORDER)
		names[a], names[b] = names[b], names[a]
		return names
	end

	T.describe("order", function()
		T.it("is the architecture §5.2 boot order, Network last", function()
			T.expect(Bootstrap.ORDER).toEqual({ "Platform", "Telemetry", "Data", "Definitions", "Economy", "World", "Encounter", "Crew", "LiveOps", "Network" })
		end)

		T.it("has a domain module for every name, and nothing else", function()
			local folder = game.ServerScriptService.Server:FindFirstChild("Domains")
			T.expect(folder).toBeTruthy()
			local names = {}
			for _, child in (folder :: Instance):GetChildren() do
				if child:IsA("ModuleScript") then
					table.insert(names, child.Name)
				end
			end
			table.sort(names)
			local expected = table.clone(Bootstrap.ORDER)
			table.sort(expected)
			T.expect(names).toEqual(expected)
		end)

		T.it("accepts the real order", function()
			local ok = pcall(Bootstrap.check, fakes(Bootstrap.ORDER, {}))
			T.expect(ok).toBe(true)
		end)

		T.it("trips on a swapped phase", function()
			T.expect(function()
				Bootstrap.check(fakes(swapped(5, 6), {})) -- Economy and World swapped
			end).toThrow("Economy must start before World")
			T.expect(function()
				Bootstrap.check(fakes(swapped(1, 2), {})) -- Platform and Telemetry swapped
			end).toThrow("must start before")
		end)

		T.it("trips when Network is not last, a domain repeats, or an unknown domain appears", function()
			T.expect(function()
				Bootstrap.check(fakes(swapped(9, 10), {}))
			end).toThrow("must start before")
			T.expect(function()
				Bootstrap.check(fakes({ "Platform", "Telemetry" }, {}))
			end).toThrow("Network must be the last domain")
			T.expect(function()
				Bootstrap.check(fakes({ "Platform", "Platform", "Network" }, {}))
			end).toThrow("must start before")
			T.expect(function()
				Bootstrap.check(fakes({ "Platform", "Harbor", "Network" }, {}))
			end).toThrow("unknown domain Harbor")
		end)
	end)

	T.describe("run", function()
		T.it("runs every Init in order, then every Start in order, and logs it", function()
			local record = {}
			local logged: { any } = {}
			local ctx = {}
			local steps = Bootstrap.run(fakes(Bootstrap.ORDER, record), ctx, function(name: string, data: any)
				table.insert(logged, { name, data })
			end)
			local expected = {}
			for _, name in Bootstrap.ORDER do
				table.insert(expected, name .. ":Init")
			end
			for _, name in Bootstrap.ORDER do
				table.insert(expected, name .. ":Start")
			end
			T.expect(record).toEqual(expected)
			T.expect(steps).toEqual(expected)
			T.expect(#logged).toBe(1)
			T.expect(logged[1][1]).toBe("Boot")
			T.expect(logged[1][2].order).toBe(table.concat(expected, " "))
			T.expect((ctx :: any).Network).toBe(true) -- every domain shares one ctx
		end)

		T.it("runs nothing when the order is wrong", function()
			local record = {}
			T.expect(function()
				Bootstrap.run(fakes(swapped(3, 4), record), {}, nil)
			end).toThrow("must start before")
			T.expect(#record).toBe(0)
		end)

		T.it("works with domains that only have one phase", function()
			local names = {}
			local list = {}
			for _, name in Bootstrap.ORDER do
				table.insert(list, {
					Name = name,
					Start = if name == "Network" then function(_ctx: any) table.insert(names, name) end else nil,
				})
			end
			Bootstrap.run(list, {}, nil)
			T.expect(names).toEqual({ "Network" })
		end)
	end)
end
