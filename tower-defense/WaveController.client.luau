-- ================================================================
-- WaveGui + TurretGui  (LocalScript in StarterGui.WaveGui)
-- All visual elements live in the Explorer under StarterGui.WaveGui
-- Edit sizes, colours, fonts there — no need to touch this script.
-- ================================================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local StartWave    = ReplicatedStorage:WaitForChild("StartWave")
local WaveStarted  = ReplicatedStorage:WaitForChild("WaveStarted")
local WaveEnded    = ReplicatedStorage:WaitForChild("WaveEnded")
local PlaceTurret  = ReplicatedStorage:WaitForChild("PlaceTurret")
local TurretDenied = ReplicatedStorage:WaitForChild("TurretDenied")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local turretTemplate = ReplicatedStorage:WaitForChild("Turrets"):WaitForChild("BasicTurret")

local _tc = turretTemplate:Clone()
local _bcf, _bsz = _tc:GetBoundingBox()
local PIVOT_TO_BOTTOM = _tc:GetPivot().Position.Y - (_bcf.Position.Y - _bsz.Y / 2)
_tc:Destroy()

local gui            = playerGui:WaitForChild("WaveGui")
local banner         = gui:WaitForChild("WaveBanner")
local waveLabel      = banner:WaitForChild("WaveLabel")
local subLabel       = banner:WaitForChild("SubLabel")
local flash          = gui:WaitForChild("FlashLabel")
local bottomBar      = gui:WaitForChild("BottomBar")
local startBtn       = bottomBar:WaitForChild("StartBtn")
local turretBtn      = bottomBar:WaitForChild("TurretBtn")
local placementLabel = bottomBar:WaitForChild("PlacementLabel")

local placingMode   = false
local ghostModel    = nil
local currentHitPos = nil
local canPlace      = false

local GREEN = Color3.fromRGB(0, 255, 100)
local RED   = Color3.fromRGB(255, 60, 60)

local function destroyGhost()
	if ghostModel then ghostModel:Destroy() ghostModel = nil end
end

local function createGhost()
	ghostModel = turretTemplate:Clone()
	ghostModel.Name = "TurretGhost"
	for _, p in ipairs(ghostModel:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true p.CanCollide = false p.CastShadow = false
			p.Color = GREEN p.Transparency = 0.5 p.Material = Enum.Material.Neon
		end
	end
	ghostModel.Parent = workspace
end

local function positionGhostAt(surfacePos)
	if not ghostModel then return end
	ghostModel:PivotTo(CFrame.new(surfacePos.X, surfacePos.Y + PIVOT_TO_BOTTOM, surfacePos.Z))
end

local function tintGhost(ok)
	if not ghostModel then return end
	local col = ok and GREEN or RED
	for _, p in ipairs(ghostModel:GetDescendants()) do
		if p:IsA("BasePart") then p.Color = col end
	end
end

local function isOverTurret(pos)
	local turretsFolder = workspace:FindFirstChild("Turrets")
	if not turretsFolder then return false end
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Include
	op.FilterDescendantsInstances = { turretsFolder }
	local hits = workspace:GetPartBoundsInBox(CFrame.new(pos), Vector3.new(6, 6, 6), op)
	return #hits > 0
end

local function getHoverResult()
	local mouse = player:GetMouse()
	local camera = workspace.CurrentCamera
	if not camera then return nil end
	local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ghostModel
		and { ghostModel, workspace:WaitForChild("Turrets") }
		or { workspace:WaitForChild("Turrets") }
	return workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, params)
end

RunService.RenderStepped:Connect(function()
	if not placingMode then return end
	local result = getHoverResult()
	if result then
		local isPath = result.Instance.Name == "Path" and result.Normal.Y > 0.5
		local onTurret = isOverTurret(result.Position)
		currentHitPos = result.Position
		canPlace = not isPath and not onTurret
		positionGhostAt(result.Position)
		tintGhost(canPlace)
	else
		currentHitPos = nil
		canPlace = false
		if ghostModel then
			local camera = workspace.CurrentCamera
			ghostModel:PivotTo(CFrame.new(camera.CFrame.Position + camera.CFrame.LookVector * 20))
			tintGhost(false)
		end
	end
end)

local function enterPlacementMode()
	placingMode = true
	turretBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 30)
	turretBtn.Text = "✖  CANCEL"
	placementLabel.Visible = true
	createGhost()
end

local function exitPlacementMode()
	placingMode = false
	turretBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
	turretBtn.Text = "🔧  PLACE TURRET"
	placementLabel.Visible = false
	destroyGhost()
end

local mouse = player:GetMouse()
mouse.Button1Down:Connect(function()
	if not placingMode then return end
	if not canPlace or not currentHitPos then return end
	PlaceTurret:FireServer(currentHitPos)
	exitPlacementMode()
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Escape and placingMode then exitPlacementMode() end
end)

turretBtn.MouseButton1Click:Connect(function()
	if placingMode then exitPlacementMode() else enterPlacementMode() end
end)

TurretDenied.OnClientEvent:Connect(function(reason)
	flash.Text = "Can't place there!"
	flash.TextColor3 = Color3.fromRGB(255, 80, 80)
	flash.TextTransparency = 0
	TweenService:Create(flash, TweenInfo.new(1.5), {TextTransparency=1, TextSize=100}):Play()
end)

local function setStartBtn(active)
	if active then
		startBtn.Text = "▶  START WAVE"
		startBtn.BackgroundColor3 = Color3.fromRGB(30, 180, 80)
		startBtn.Active = true
	else
		startBtn.Text = "⏳  WAVE IN PROGRESS..."
		startBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		startBtn.Active = false
	end
end

local function showBanner(wNum, total, count)
	banner.Visible = true
	waveLabel.Text = string.format("WAVE %d / %d", wNum, total)
	subLabel.Text = string.format("%d slimes incoming! 🟢", count)
	for _, l in ipairs({banner, waveLabel, subLabel}) do
		if l:IsA("GuiObject") then l.BackgroundTransparency = 1 end
		if l:IsA("TextLabel") then l.TextTransparency = 1 end
	end
	local ti = TweenInfo.new(0.4, Enum.EasingStyle.Quad)
	TweenService:Create(banner, ti, {BackgroundTransparency=0.3}):Play()
	TweenService:Create(waveLabel, ti, {TextTransparency=0}):Play()
	TweenService:Create(subLabel, ti, {TextTransparency=0}):Play()
end

local function hideBanner()
	local ti = TweenInfo.new(0.4)
	TweenService:Create(banner, ti, {BackgroundTransparency=1}):Play()
	TweenService:Create(waveLabel, ti, {TextTransparency=1}):Play()
	TweenService:Create(subLabel, ti, {TextTransparency=1}):Play()
	task.delay(0.5, function() banner.Visible = false end)
end

local function flashMsg(msg, color)
	flash.Text = msg
	flash.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	flash.TextSize = 72
	flash.TextTransparency = 0
	TweenService:Create(flash, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {TextTransparency=1, TextSize=100}):Play()
end

startBtn.MouseButton1Click:Connect(function()
	if not startBtn.Active then return end
	setStartBtn(false)
	StartWave:FireServer()
end)

WaveStarted.OnClientEvent:Connect(function(wNum, total, count)
	setStartBtn(false)
	showBanner(wNum, total, count)
	flashMsg("WAVE " .. wNum, Color3.fromRGB(255, 220, 50))
end)

WaveEnded.OnClientEvent:Connect(function(allDone, wNum)
	hideBanner()
	if allDone then
		flashMsg("🏆 YOU WIN!", Color3.fromRGB(255, 215, 0))
	else
		flashMsg("✔ WAVE " .. wNum .. " CLEARED!", Color3.fromRGB(80, 255, 120))
	end
	task.delay(2.5, function() setStartBtn(true) end)
end)

print("[WaveGui] Loaded")
