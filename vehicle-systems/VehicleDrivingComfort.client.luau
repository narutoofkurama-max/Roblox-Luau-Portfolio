local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local car,humanoid
local handbrake=0
local initialFov=70
local initialJump=true
local function leave()
 if humanoid then humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,initialJump) end
 if car then
  for _,name in {"RL","RR"} do
   local wheel=car:FindFirstChild("Wheels") and car.Wheels:FindFirstChild(name)
   if wheel then local p=wheel.CurrentPhysicalProperties wheel.CustomPhysicalProperties=PhysicalProperties.new(p.Density,car:GetAttribute("RearGrip") or 1.15,0,100,100) end
  end
 end
 car=nil handbrake=0
 workspace.CurrentCamera.FieldOfView=initialFov
end
local function bind(character)
 leave()
 humanoid=character:WaitForChild("Humanoid")
 humanoid.Seated:Connect(function(active,seat)
  if not active then leave() return end
  if seat and seat.Name=="DriveSeat" and seat.Parent:FindFirstChild("A-Chassis Tune") then
   car=seat.Parent
   initialFov=workspace.CurrentCamera.FieldOfView
   initialJump=humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
   humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
  end
 end)
 humanoid.Died:Connect(leave)
end
player.CharacterAdded:Connect(bind)
if player.Character then bind(player.Character) end
UIS.InputBegan:Connect(function(key,processed)
 if not processed and car and key.KeyCode==Enum.KeyCode.F then humanoid.Sit=false end
end)
RunService.Heartbeat:Connect(function(dt)
 if not car then return end
 if not car.Parent or humanoid.SeatPart~=car.DriveSeat then leave() return end
 local gui=player.PlayerGui:FindFirstChild("A-Chassis Interface")
 local target=gui and gui.Values.PBrake.Value and 1 or 0
 handbrake+=(target-handbrake)*math.min(1,dt*5)
 for _,name in {"RL","RR"} do
  local w=car.Wheels[name] local p=w.CurrentPhysicalProperties
  w.CustomPhysicalProperties=PhysicalProperties.new(p.Density,(car:GetAttribute("RearGrip") or 1.15)-.6*handbrake,0,100,100)
 end
 local camera=workspace.CurrentCamera
 camera.FieldOfView+=(initialFov+math.clamp(car.DriveSeat.AssemblyLinearVelocity.Magnitude/165,0,1)*7-camera.FieldOfView)*math.min(1,dt*3)
end)