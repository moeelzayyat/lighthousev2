--!strict
-- R1.1 sample tests: the harness checks itself (matchers, async, mocks + clock).
return function(T: any)
	T.describe("TestRunner", function()
		T.it("matchers pass on true statements and throw on false ones", function()
			T.expect(1 + 1).toBe(2)
			T.expect({ a = 1, b = { 2, 3 } }).toEqual({ a = 1, b = { 2, 3 } })
			T.expect(0.1 + 0.2).toBeCloseTo(0.3)
			T.expect(nil).toBeNil()
			T.expect(5).toBeGreaterThan(4)
			T.expect({ "x", "y" }).toContain("y")
			T.expect(function()
				error("boom")
			end).toThrow("boom")
			-- a false expectation must raise, with the path of the first difference
			T.expect(function()
				T.expect({ a = 1 }).toEqual({ a = 2 })
			end).toThrow("not equal at %.a")
			T.expect(function()
				T.expect(3).toBe(4)
			end).toThrow("expected 4, got 3")
		end)

		T.it("async tests may yield", function()
			local flag = false
			task.delay(0.05, function()
				flag = true
			end)
			task.wait(0.1)
			T.expect(flag).toBe(true)
		end)

		T.it("mock services, spies and the fake clock", function()
			local store = T.mock.service("Store", { value = 7 })
			T.expect(T.mock.get("Store")).toBe(store)
			local spy = T.mock.fn(function(x: number): number
				return x * 2
			end)
			T.expect(spy(21)).toBe(42)
			T.expect(spy.count).toBe(1)
			T.expect(spy.calls[1][1]).toBe(21)
			local clock = T.clock(100)
			clock.advance(86400)
			T.expect(clock.now()).toBe(86500)
			T.expect(function()
				clock.advance(-1)
			end).toThrow("backwards")
		end)
	end)
end
