-- Network domain (S5.1): always last. Every handler is connected by now, so the remotes folder is exposed
-- to clients only at the very end of boot (clients wait for ReplicatedStorage.Remotes).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = { Name = "Network" }

function Network.Start(ctx)
	ctx.remotes.Parent = ReplicatedStorage
end

return Network
