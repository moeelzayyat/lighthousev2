--!strict
-- A minimal in-memory stand-in with the ProfileStore API that PlayerData uses (StartSessionAsync, Data,
-- AddUserId, Reconcile, Save, EndSession, IsActive, OnSessionEnd). One key = one record; a key with an open
-- session cannot be opened again (StartSessionAsync returns nil, as ProfileStore does when the holder never
-- releases). Data is deep-copied on save and load, like a real round trip. Test-only; never used live.

local FakeProfileStore = {}

local function deepCopy(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local c = {}
	for k, v in t do
		c[k] = deepCopy(v)
	end
	return c
end

local function signal()
	local handlers: { () -> () } = {}
	return {
		Connect = function(_self: any, fn: () -> ())
			table.insert(handlers, fn)
			return { Disconnect = function() end }
		end,
		Fire = function(_self: any)
			for _, fn in handlers do
				fn()
			end
		end,
	}
end

function FakeProfileStore.new(template: any)
	local records: { [string]: any } = {}
	local open: { [string]: boolean } = {}
	local store = { saves = 0, records = records }

	function store.StartSessionAsync(_self: any, key: string, params: any?)
		if params and params.Cancel and params.Cancel() then
			return nil
		end
		if open[key] then
			return nil
		end
		open[key] = true
		local active = true
		local profile: any = {
			Data = if records[key] then deepCopy(records[key]) else deepCopy(template),
			UserIds = {},
			OnSessionEnd = signal(),
		}
		function profile.IsActive(_p: any)
			return active
		end
		function profile.AddUserId(_p: any, id: number)
			table.insert(profile.UserIds, id)
		end
		function profile.Reconcile(_p: any)
			for k, v in template do
				if profile.Data[k] == nil then
					profile.Data[k] = deepCopy(v)
				end
			end
		end
		function profile.Save(_p: any)
			if active then
				records[key] = deepCopy(profile.Data)
				store.saves += 1
			end
		end
		function profile.EndSession(_p: any)
			if not active then
				return
			end
			profile:Save()
			active = false
			open[key] = nil
			profile.OnSessionEnd:Fire()
		end
		return profile
	end

	-- simulate a server crash: the session is gone without a save
	function store.crash(key: string)
		open[key] = nil
	end

	return store
end

return FakeProfileStore
