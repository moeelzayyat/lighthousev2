-- S2.4 measurement harness (not part of the game; never put it in Studio's tree).
-- Paste into execute_luau (datamodel Client) right after start_stop_play. It plays an unassisted first-time
-- player and logs BOT_* times on LocalPlayer (seconds since the script started). The server console has
-- "PlayerReady ... sinceJoin" and "firstBeamHit ... sinceJoin"; the bot's start offset is
-- PlayerReady.sinceJoin - BOT_Ready, so first beam hit since control = firstBeamHit.sinceJoin - offset.
-- A run counts only when BOT_MinFps stays >= 40: Studio slows to ~15 fps when it is not the focused
-- window, and ProximityPrompts then stop responding.
local fps = 0
local rc = game:GetService("RunService").RenderStepped:Connect(function() fps += 1 end)
task.wait(1)
rc:Disconnect()
if fps < 40 then return "not rendering fully: " .. fps .. " fps" end
-- TEMPTEST (runtime only, client): an unassisted first-time player. It does only what the game tells a new
-- player: walk onto the ship, use the wheel (SAIL NOW), then follow the coach's order on the island
-- (carry oil -> pour it -> take the lamp -> aim at the nearest creature). Human-like 1.0 s pause per step.
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
task.spawn(function() -- frame-rate watch
  local minFps = math.huge
  while lp:GetAttribute("BOT_Done") == nil do
    local n = 0
    local c = game:GetService("RunService").RenderStepped:Connect(function() n += 1 end)
    task.wait(1)
    c:Disconnect()
    minFps = math.min(minFps, n)
    lp:SetAttribute("BOT_MinFps", minFps)
  end
end)
local rs = game:GetService("ReplicatedStorage")
local remotes = rs:WaitForChild("Remotes")
local state = rs:WaitForChild("GameState")
local THINK = 1.0
local t0 = os.clock()
local function log(k) if lp:GetAttribute("BOT_" .. k) == nil then lp:SetAttribute("BOT_" .. k, math.floor((os.clock() - t0) * 10) / 10) end end
local function hum() local c = lp.Character return c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart") end
local function partOf(inst)
  if not inst then return nil end
  if inst:IsA("BasePart") then return inst end
  return inst:IsA("Model") and (inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)) or nil
end
local PFS = game:GetService("PathfindingService")
-- walks like a player: around the tower (pathfinding on the island, straight on the deck), up to 15 s
local function walkTo(pos, within, direct)
  local h, root = hum()
  if not h then return false end
  local deadline = os.clock() + 15
  local function near() return (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude <= within end
  local path = PFS:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
  local ok = pcall(function() path:ComputeAsync(root.Position, pos) end)
  if not direct and ok and path.Status == Enum.PathStatus.Success then
    for _, wp in path:GetWaypoints() do
      if near() or os.clock() > deadline then break end
      if wp.Action == Enum.PathWaypointAction.Jump then h.Jump = true end
      h:MoveTo(wp.Position)
      local t = os.clock()
      while os.clock() - t < 2 and (Vector3.new(wp.Position.X, 0, wp.Position.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude > 2 and not near() do task.wait(0.05) end
    end
  end
  local last, lastAt = root.Position, os.clock()
  while not near() and os.clock() < deadline do
    h:MoveTo(pos)
    task.wait(0.25)
    if (root.Position - last).Magnitude > 1 then
      last, lastAt = root.Position, os.clock()
    elseif os.clock() - lastAt > 1.5 then -- stuck on scenery: jump and sidestep, as a player would
      h.Jump = true
      h:MoveTo(root.Position + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6)))
      task.wait(0.6)
      last, lastAt = root.Position, os.clock()
    end
  end
  return near()
end
local function usePrompt(container, direct)
  local prompt = container and container:FindFirstChildWhichIsA("ProximityPrompt", true)
  local part = partOf(container)
  if not prompt or not part then return false end
  if not walkTo(part.Position, math.max(3, prompt.MaxActivationDistance - 4), direct) then return false end
  prompt:InputHoldBegin()
  task.wait(prompt.HoldDuration + 0.15)
  prompt:InputHoldEnd()
  return true
end
local island = workspace:WaitForChild("Island")
local function nearestCreature()
  local folder = island:FindFirstChild("Creatures")
  local tower = island:FindFirstChild("LighthouseTower", true)
  local c = tower and partOf(tower)
  if not folder or not c then return nil end
  local best, bestD
  for _, m in folder:GetChildren() do
    local p = partOf(m)
    if p then
      local d = (p.Position - c.Position).Magnitude
      if not bestD or d < bestD then best, bestD = p, d end
    end
  end
  return best, c
end
task.spawn(function()
  -- ship: board, then the wheel
  task.wait(THINK)
  local zone = workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("BoardingZone", true)
  if zone then walkTo(zone.Position, 2, true) end -- on the ship: straight across the deck
  local w = os.clock() + 10
  while lp:GetAttribute("Ready") ~= true and os.clock() < w do task.wait(0.2) end
  log("Ready")
  task.wait(THINK)
  local helm
  for _, d in workspace.Lobby:GetDescendants() do if d:IsA("ProximityPrompt") and d.Name == "HelmPrompt" then helm = d end end
  local tries = 0
  while helm and state:GetAttribute("Phase") == "Waiting" and tries < 10 do -- press the wheel again if nothing happened
    usePrompt(helm.Parent, true)
    tries += 1
    task.wait(1.5)
  end
  log("Helm")
  lp:SetAttribute("BOT_HelmTries", tries)
  -- island: follow the coach's order
  while true do
    task.wait(0.2)
    local phase = state:GetAttribute("Phase")
    if phase == "Day" or phase == "Victory" or phase == "Defeat" then break end
    if phase == "Prologue" then
      local keeper = state:GetAttribute("KeeperUserId") == lp.UserId
      local fuel = (state:GetAttribute("Fuel") or 100) / math.max(1, state:GetAttribute("MaxFuel") or 100)
      if lp:GetAttribute("CarryingOil") == true then
        task.wait(THINK); log("ToTank"); usePrompt(island:FindFirstChild("FuelTank", true))
      elseif not keeper and fuel < 0.35 then
        task.wait(THINK); log("ToOil"); usePrompt(island:FindFirstChild("OilPile", true))
      elseif not keeper and (state:GetAttribute("KeeperUserId") or 0) == 0 then
        task.wait(THINK); log("ToLamp"); usePrompt(island:FindFirstChild("LampConsole", true))
      elseif keeper then
        log("Keeper")
        local crab, c = nearestCreature()
        if crab then
          log("Aiming")
          local dx, dz = crab.Position.X - c.Position.X, crab.Position.Z - c.Position.Z
          remotes.BeamControl:FireServer(math.deg(math.atan2(-dx, -dz)))
        end
      end
    end
  end
  log("Done")
end)
return "bot started (" .. fps .. " fps)"
