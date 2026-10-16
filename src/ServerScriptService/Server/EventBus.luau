--!strict
-- EventBus (R1.6): typed publish/subscribe for cross-domain reactions (architecture §5.3, docs/EVENTS.md).
-- EventLog owns the server's bus and exposes it as EventLog.Publish / EventLog.Subscribe.
--   * a publish is checked against the catalog (Shared/Events); unknown names, missing or mistyped fields and
--     Instance values are rejected (not delivered) and counted
--   * each handler runs in its own thread inside pcall: a consumer error is counted and warned once per
--     event name, never propagated to the publisher, and a yielding handler never blocks it

export type Payload = { [string]: any }
export type Handler = (Payload) -> ()
export type Stats = { published: number, delivered: number, rejected: number, handlerErrors: number }
export type Bus = {
	Publish: (name: string, payload: Payload) -> boolean,
	Subscribe: (name: string, handler: Handler) -> () -> (),
	validate: (name: string, payload: any) -> (boolean, string?),
	stats: Stats,
}

local EventBus = {}

local function typeMatches(value: any, expected: string): boolean
	local optional = string.sub(expected, -1) == "?"
	local base = if optional then string.sub(expected, 1, -2) else expected
	if value == nil then
		return optional
	end
	return type(value) == base
end

local function containsInstance(value: any, depth: number): boolean
	if typeof(value) == "Instance" then
		return true
	end
	if type(value) == "table" and depth < 4 then
		for k, v in value do
			if containsInstance(k, depth + 1) or containsInstance(v, depth + 1) then
				return true
			end
		end
	end
	return false
end

function EventBus.new(catalog: { [string]: { [string]: string } }, warnFn: ((string) -> ())?): Bus
	local subscribers: { [string]: { Handler } } = {}
	local warned: { [string]: boolean } = {}
	local stats: Stats = { published = 0, delivered = 0, rejected = 0, handlerErrors = 0 }
	local say = warnFn or warn

	local function warnOnce(key: string, text: string)
		if not warned[key] then
			warned[key] = true
			say(text)
		end
	end

	local function validate(name: string, payload: any): (boolean, string?)
		local schema = catalog[name]
		if not schema then
			return false, "unknown event " .. tostring(name)
		end
		if type(payload) ~= "table" then
			return false, "payload must be a table"
		end
		for field, expected in schema do
			if not typeMatches(payload[field], expected) then
				return false, string.format("field %s should be %s, got %s", field, expected, typeof(payload[field]))
			end
		end
		if containsInstance(payload, 0) then
			return false, "payload carries an Instance"
		end
		return true, nil
	end

	local bus: Bus
	bus = {
		stats = stats,
		validate = validate,
		Publish = function(name: string, payload: Payload): boolean
			stats.published += 1
			local ok, why = validate(name, payload)
			if not ok then
				stats.rejected += 1
				warnOnce("reject:" .. tostring(name), string.format("[EventBus] rejected %s: %s", tostring(name), tostring(why)))
				return false
			end
			local list = subscribers[name]
			if list then
				for _, handler in table.clone(list) do
					task.spawn(function()
						local handlerOk, err = pcall(handler, payload)
						if handlerOk then
							stats.delivered += 1
						else
							stats.handlerErrors += 1
							warnOnce("handler:" .. name, string.format("[EventBus] a %s handler failed: %s", name, tostring(err)))
						end
					end)
				end
			end
			return true
		end,
		Subscribe = function(name: string, handler: Handler): () -> ()
			assert(catalog[name] ~= nil, "EventBus: cannot subscribe to unknown event " .. tostring(name))
			local list = subscribers[name]
			if not list then
				list = {}
				subscribers[name] = list
			end
			table.insert(list, handler)
			return function()
				local current = subscribers[name]
				local index = current and table.find(current, handler)
				if current and index then
					table.remove(current, index)
				end
			end
		end,
	}
	return bus
end

return EventBus
