-- ================================================================
-- WaveManager  (ServerScriptService)
-- ================================================================
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Workspace          = game:GetService("Workspace")
local Debris             = game:GetService("Debris")

-- ── RemoteEvents ─────────────────────────────────────────────
local StartWave    = ReplicatedStorage:WaitForChild("StartWave")
local WaveStarted  = ReplicatedStorage:WaitForChild("WaveStarted")
local WaveEnded    = ReplicatedStorage:WaitForChild("WaveEnded")
local PlaceTurret  = ReplicatedStorage:WaitForChild("PlaceTurret")
local TurretPlaced = ReplicatedStorage:WaitForChild("TurretPlaced")
local TurretDenied = ReplicatedStorage:WaitForChild("TurretDenied")

-- ── Templates ─────────────────────────────────────────────────
local slimeTemplate  = ReplicatedStorage:WaitForChild("Slimes"):WaitForChild("Slime")
local turretTemplate = ReplicatedStorage:WaitForChild("Turrets"):WaitForChild("BasicTurret")
local bulletTemplate = ReplicatedStorage:WaitForChild("Bullets"):WaitForChild("Bullet")

-- ── Folders ───────────────────────────────────────────────────
local spawnPart       = Workspace:WaitForChild("SpawnPart")
local waypointsFolder = Workspace:WaitForChild("Waypoints")
local turretsFolder   = Workspace:WaitForChild("Turrets")

-- Collect path parts for placement validation
local pathParts = {}
for _, v in ipairs(Workspace:GetChildren()) do
	if v.Name == "Path" and v:IsA("BasePart") then
		table.insert(pathParts, v)
	end
end

-- Precompute pivot-to-bbox-bottom for the turret template
local _tc = turretTemplate:Clone()
local _bcf, _bsz = _tc:GetBoundingBox()
local PIVOT_TO_BOTTOM = _tc:GetPivot().Position.Y - (_bcf.Position.Y - _bsz.Y / 2)
_tc:Destroy()

local function isOnTurret(pos)
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Include
	op.FilterDescendantsInstances = { turretsFolder }
	local hits = Workspace:GetPartBoundsInBox(
		CFrame.new(pos),
		Vector3.new(6, 6, 6),
		op
	)
	return #hits > 0
end

local function isOnPath(pos)
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Include
	op.FilterDescendantsInstances = pathParts
	local hits = Workspace:GetPartBoundsInBox(
		CFrame.new(pos),
		Vector3.new(5, 3, 5),
		op
	)
	return #hits > 0
end
-- ── Ordered waypoints ─────────────────────────────────────────
local waypoints = {}
for i = 1, 100 do
	local wp = waypointsFolder:FindFirstChild(tostring(i))
	if not wp then break end
	table.insert(waypoints, wp)
end
print("[WaveManager] Waypoints:", #waypoints)

-- ── Wave config ───────────────────────────────────────────────
local WAVE_CONFIG = {
	{ count = 2, spawnDelay = 1.5, speed = 5, health = 10 },
	{ count = 7, spawnDelay = 1.5, speed = 5, health = 10 },
	{ count = 12, spawnDelay = 1.5, speed = 5, health = 10 },
	{ count = 16, spawnDelay = 1.5, speed = 5, health = 10 },
	{ count = 25, spawnDelay = 1.5, speed = 5, health = 10 },
}

-- ── State ─────────────────────────────────────────────────────
local currentWave   = 0
local waveActive    = false
local activeSlimes  = {}
local placedTurrets = {}
local placementCooldown = {}
local waveRequestCooldown = {}

-- ================================================================
-- HEALTH BAR
-- ================================================================
local function makeHealthBar(parent, maxHp, hpRef)
	local bb = Instance.new("BillboardGui")
	bb.Size        = UDim2.new(0, 60, 0, 8)
	bb.StudsOffset = Vector3.new(0, 3.5, 0)
	bb.AlwaysOnTop = false
	bb.Parent      = parent

	local bg = Instance.new("Frame")
	bg.Size                 = UDim2.new(1,0,1,0)
	bg.BackgroundColor3     = Color3.fromRGB(40,40,40)
	bg.BorderSizePixel      = 0
	bg.Parent               = bb

	local bar = Instance.new("Frame")
	bar.Name             = "Bar"
	bar.Size             = UDim2.new(1,0,1,0)
	bar.BackgroundColor3 = Color3.fromRGB(0,210,70)
	bar.BorderSizePixel  = 0
	bar.Parent           = bg

	local function update()
		local pct = math.clamp(hpRef.value / maxHp, 0, 1)
		bar.Size = UDim2.new(pct, 0, 1, 0)
		if      pct > 0.5  then bar.BackgroundColor3 = Color3.fromRGB(0,210,70)
		elseif  pct > 0.25 then bar.BackgroundColor3 = Color3.fromRGB(220,180,0)
		else                    bar.BackgroundColor3 = Color3.fromRGB(220,50,50) end
	end
	return update
end

-- ================================================================
-- SLIME SYSTEM
-- ================================================================
local ARRIVE = 2.5

local function faceDir(part, dir2D)
	if dir2D.Magnitude < 0.01 then return end
	local a = math.atan2(dir2D.X, dir2D.Z)
	part.CFrame = CFrame.new(part.Position) * CFrame.Angles(0, a, 0)
end

local function removeFromActive(part)
	for i = #activeSlimes, 1, -1 do
		if activeSlimes[i].part == part then
			table.remove(activeSlimes, i)
		end
	end
end

local function walkPath(part, speed, onDone)
	task.spawn(function()
		for _, wp in ipairs(waypoints) do
			if not (part and part.Parent) then return end
			local tgt = Vector3.new(wp.Position.X, part.Position.Y, wp.Position.Z)
			while part and part.Parent do
				local diff = Vector3.new(tgt.X - part.Position.X, 0, tgt.Z - part.Position.Z)
				if diff.Magnitude <= ARRIVE then break end
				local dt   = task.wait()
				local step = math.min(speed * dt, diff.Magnitude)
				local dir  = diff.Unit
				part.Position = part.Position + Vector3.new(dir.X*step, 0, dir.Z*step)
				faceDir(part, diff)
			end
		end
		if onDone then onDone() end
	end)
end

local function damageSlime(entry, dmg)
	entry.hpRef.value = math.max(0, entry.hpRef.value - dmg)
	entry.updateBar()
	if entry.hpRef.value <= 0 and entry.part and entry.part.Parent then
		entry.part:Destroy()
	end
end

local function spawnSlime(cfg)
	local s = slimeTemplate:Clone()
	s.Name       = "SlimeEnemy"
	s.Anchored   = true
	s.CanCollide = false
	local sp = spawnPart.Position
	s.Position = Vector3.new(
		sp.X + math.random(-1,1),
		sp.Y + s.Size.Y / 2,
		sp.Z + math.random(-1,1)
	)
	s.Parent = Workspace

	local hpRef  = { value = cfg.health }
	local entry  = { part = s, hpRef = hpRef }
	entry.updateBar = makeHealthBar(s, cfg.health, hpRef)

	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 20
	cd.Parent = s
	cd.MouseClick:Connect(function() damageSlime(entry, 5) end)

	table.insert(activeSlimes, entry)
	s.AncestryChanged:Connect(function() removeFromActive(s) end)

	if waypoints[1] then
		faceDir(s, Vector3.new(waypoints[1].Position.X - sp.X, 0, waypoints[1].Position.Z - sp.Z))
	end

	walkPath(s, cfg.speed, function()
		if s and s.Parent then s:Destroy() end
	end)
end

-- ================================================================
-- WAVE RUNNER
-- ================================================================
local function allDead()
	for _, e in ipairs(activeSlimes) do
		if e.part and e.part.Parent then return false end
	end
	return true
end

local function runWave(idx)
	waveActive   = true
	activeSlimes = {}
	local cfg    = WAVE_CONFIG[idx]
	WaveStarted:FireAllClients(idx, #WAVE_CONFIG, cfg.count)
	for i = 1, cfg.count do
		spawnSlime(cfg)
		if i < cfg.count then task.wait(cfg.spawnDelay) end
	end
	repeat task.wait(0.5) until allDead()
	task.wait(2)
	waveActive = false
	WaveEnded:FireAllClients(idx >= #WAVE_CONFIG, idx)
end

StartWave.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if now - (waveRequestCooldown[player.UserId] or 0) < 0.5 then return end
	waveRequestCooldown[player.UserId] = now
	if waveActive then return end
	if currentWave >= #WAVE_CONFIG then currentWave = 0 end
	currentWave += 1
	print("[WaveManager] Wave", currentWave, "by", player.Name)
	runWave(currentWave)
end)

-- ================================================================
-- TURRET PLACEMENT
-- ================================================================
local function placeTurret(pos)
	local model = turretTemplate:Clone()
	model.Name  = "Turret"

	local head  = model:FindFirstChild("Head")
	local shoot = model:FindFirstChild("Shoot")

	local basePart = nil
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") and p ~= head and p ~= shoot then
			if not basePart or p.Position.Y < basePart.Position.Y then
				basePart = p
			end
		end
	end
	if not basePart then basePart = model:FindFirstChildWhichIsA("BasePart") end
	if not head or not shoot or not basePart then
		model:Destroy()
		return nil
	end
	model.PrimaryPart = basePart

	-- Place turret: pivot sits PIVOT_TO_BOTTOM above the surface hit point
	model:PivotTo(CFrame.new(pos.X, pos.Y + PIVOT_TO_BOTTOM, pos.Z))

	-- Strip welds, anchor everything, disable collision
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("WeldConstraint") or d:IsA("Weld") then d:Destroy() end
		if d:IsA("BasePart") then
			d.Anchored   = true
			d.CanCollide = false
		end
	end

	model.Parent = turretsFolder

	local staticParts = { basePart }
	local neckPart = nil
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") and p ~= head and p ~= shoot and p ~= basePart then
			if not neckPart or p.Position.Y < neckPart.Position.Y then
				neckPart = p
			end
		end
	end
	if neckPart then table.insert(staticParts, neckPart) end
	local staticSet = {}
	for _, p in ipairs(staticParts) do staticSet[p] = true end

	local rotatables = {}
	local function addRotatable(part)
		table.insert(rotatables, {
			part   = part,
			offset = head.CFrame:ToObjectSpace(part.CFrame),
		})
	end
	addRotatable(head)
	for _, child in ipairs(head:GetDescendants()) do
		if child:IsA("BasePart") then addRotatable(child) end
	end
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") and not staticSet[p] and p ~= head then
			addRotatable(p)
		end
	end

	local entry = {
		model      = model,
		head       = head,
		shoot      = shoot,
		rotatables = rotatables,
		lastShot   = 0,
		range      = 20,
		damage     = 5,
		cooldown   = 2.0,
	}
	table.insert(placedTurrets, entry)
	return entry
end

PlaceTurret.OnServerEvent:Connect(function(player, pos)
	if typeof(pos) ~= "Vector3" then return end
	if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z then return end
	local now = os.clock()
	if now - (placementCooldown[player.UserId] or 0) < 0.15 then return end
	placementCooldown[player.UserId] = now
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - pos).Magnitude > 150 then
		TurretDenied:FireClient(player, "toofar")
		return
	end
	if isOnPath(pos) then
		TurretDenied:FireClient(player, "onpath")
		return
	end
	if isOnTurret(pos) then
		TurretDenied:FireClient(player, "onturret")
		return
	end
	if not placeTurret(pos) then
		TurretDenied:FireClient(player, "invalidtemplate")
		return
	end
	TurretPlaced:FireAllClients(pos)
	print("[WaveManager] Turret placed at", pos, "by", player.Name)
end)

-- ================================================================
-- TURRET SHOOT LOOP
-- ================================================================
local function shootBullet(entry, targetPos)
	local origin = entry.shoot.Position
	local dir    = (targetPos - origin)
	if dir.Magnitude < 0.1 then return end

	local b = bulletTemplate:Clone()
	-- Cylinder axis is X; rotate -90 deg around Y so +X faces the target
	b.CFrame     = CFrame.new(origin, targetPos) * CFrame.Angles(0, -math.pi/2, 0)
	b.Anchored   = false
	b.CanCollide = false
	b.Parent     = Workspace

	local bv = Instance.new("BodyVelocity")
	bv.Velocity  = dir.Unit * 120
	bv.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
	bv.Parent    = b

	Debris:AddItem(b, 1.5)

	local hit = false
	b.Touched:Connect(function(other)
		if hit then return end
		if other.Name == "SlimeEnemy" then
			hit = true
			for _, se in ipairs(activeSlimes) do
				if se.part == other then
					damageSlime(se, entry.damage)
					break
				end
			end
			b:Destroy()
		end
	end)
end

local function turretThink(entry)
	if not (entry.head and entry.head.Parent) then return end

	-- Find nearest slime in range (always, for continuous aiming)
	local best, bestDist = nil, math.huge
	for _, se in ipairs(activeSlimes) do
		if se.part and se.part.Parent then
			local d = (se.part.Position - entry.head.Position).Magnitude
			if d <= entry.range and d < bestDist then
				best, bestDist = se.part, d
			end
		end
	end

	if not best then return end

	-- Always aim toward the target (continuous rotation)
	-- Barrel points along head's RightVector (+X), so rotate -90 deg around Y
	-- so that +X (not -Z) faces the target
	local targetPos = Vector3.new(best.Position.X, entry.head.Position.Y, best.Position.Z)
	local newHeadCF = CFrame.lookAt(entry.head.Position, targetPos) * CFrame.Angles(0, math.pi/2, 0)
	for _, r in ipairs(entry.rotatables) do
		r.part.CFrame = newHeadCF * r.offset
	end

	-- Only fire when cooldown has elapsed
	local now = tick()
	if now - entry.lastShot < entry.cooldown then return end
	entry.lastShot = now
	shootBullet(entry, best.Position)
end

game:GetService("Players").PlayerRemoving:Connect(function(player)
	placementCooldown[player.UserId] = nil
	waveRequestCooldown[player.UserId] = nil
end)

-- Main loop
task.spawn(function()
	while true do
		task.wait(0.1)
		for _, entry in ipairs(placedTurrets) do
			turretThink(entry)
		end
	end
end)

print(string.format("[WaveManager] Ready — %d waves, %d waypoints", #WAVE_CONFIG, #waypoints))