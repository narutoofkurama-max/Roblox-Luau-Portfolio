local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local DataStoreService=game:GetService("DataStoreService")
local map=workspace:WaitForChild("TomatoMap")
local plots=map:WaitForChild("Plots")
local remote=ReplicatedStorage:WaitForChild("TomatoTutorialEvent")
local letterStore=DataStoreService:GetDataStore("TomatoFirstVisit_v1")
local START_CASH=1
local STAND_COST=1
local UPGRADE_COST=5.10
local BASE_SALE=1
local saleCooldown={}
local touchCooldown={}
local standTweens={}

local function hint(player,message)
    player:SetAttribute("TomatoTutorialMessage",message)
    remote:FireClient(player,message)
end
local function cashFor(player)
    local stats=player:FindFirstChild("leaderstats")
    return stats and stats:FindFirstChild("Cash")
end
local function modelVisible(model,visible)
    if not model then return end
    for _,obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Transparency=visible and (obj:GetAttribute("OriginalTransparency") or 0) or 1
            obj.CanQuery=visible
        elseif obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
            obj.Enabled=visible
        end
    end
end
local function configure(plot)
    local stage=plot:GetAttribute("Stage") or 0
    local pad=plot.PurchaseButton
    pad:SetAttribute("Cost",stage==0 and STAND_COST or 0)
    local ui=pad.ButtonTop:FindFirstChild("PurchaseUI")
    if ui then
        ui.Title.Text="TOMATO STAND"
        ui.Subtitle.Text="new income source"
        ui.CostText.Text="$1.00"
        ui.RewardText.Text="+$1.00 / click"
    end
    local stand=plot.TomatoStand
    local info=stand:FindFirstChild("StandInfo")
    if info then
        info.Title.Text="TOMATO STAND"
        info.Price.Text="$1.00 / CLICK"
    end
    local up=stand:FindFirstChild("UpgradeControl")
    if up then
        up:SetAttribute("Cost",stage>=2 and 0 or UPGRADE_COST)
        local face=up:FindFirstChild("UpgradeSurface")
        local main=face and face:FindFirstChild("ButtonFace")
        local label=main and main:FindFirstChild("UpgradeText")
        local cost=face and face:FindFirstChild("CostText")
        if label then label.Text=stage>=2 and "UPGRADED" or "UPGRADE" end
        if cost then cost.Text=stage>=2 and "MAXED  •  +$2.00 / click" or "$5.10  •  +$2.00 / click" end
    end
end
local function showStage(plot)
    local stage=plot:GetAttribute("Stage") or 0
    modelVisible(plot.PurchaseButton,stage==0)
    modelVisible(plot.TomatoStand,stage>=1)
end
local function plotFor(player)
    for _,plot in ipairs(plots:GetChildren()) do
        if plot:GetAttribute("OwnerUserId")==player.UserId then return plot end
    end
end
local function positionCharacter(character,spawn)
    local root=character:WaitForChild("HumanoidRootPart",10)
    local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",10)
    if not root or not humanoid or not spawn or not spawn.Parent then return end
    task.wait(0.35)
    character:PivotTo(CFrame.new(spawn.Position+Vector3.new(0,4,0))*CFrame.Angles(0,math.rad(spawn.Orientation.Y),0))
    root.AssemblyLinearVelocity=Vector3.zero
    root.AssemblyAngularVelocity=Vector3.zero
end
local function assign(player)
    local plot
    for _,candidate in ipairs(plots:GetChildren()) do
        if candidate:GetAttribute("OwnerUserId")==0 then plot=candidate break end
    end
    if not plot then
        player:SetAttribute("FarmPlotId",0)
        hint(player,"All 10 tomato farms are occupied in this server.")
        return
    end
    plot:SetAttribute("OwnerUserId",player.UserId)
    plot:SetAttribute("OwnerName",player.DisplayName)
    player:SetAttribute("FarmPlotId",plot:GetAttribute("PlotIndex"))
    player:SetAttribute("OwnsTomatoStand",false)
    player:SetAttribute("BasketUpgraded",false)
    local spawn=plot:FindFirstChildWhichIsA("SpawnLocation")
    if spawn then
        player.RespawnLocation=spawn
        player.CharacterAdded:Connect(function(character)
            task.spawn(positionCharacter,character,spawn)
        end)
        if player.Character then task.spawn(positionCharacter,player.Character,spawn) end
    end
    plot.OwnerSign.OwnerUI.OwnerText.Text="BASE "..string.format("%02d",plot:GetAttribute("PlotIndex")).." • "..player.DisplayName
    hint(player,"Use your $1 note to buy the tomato stand.")
end
local function giveIntroIfNew(player)
    -- Studio API access is often disabled; treat every Studio session as a first visit.
    if game:GetService("RunService"):IsStudio() then
        player:SetAttribute("ShowStarterLetter",true)
        return
    end
    local key="player_"..player.UserId
    local ok,seen=pcall(function() return letterStore:GetAsync(key) end)
    if not ok or seen~=true then
        player:SetAttribute("ShowStarterLetter",true)
        if ok then task.spawn(function() pcall(function() letterStore:SetAsync(key,true) end) end) end
    end
end
local function setup(player)
    if player:FindFirstChild("leaderstats") then return end
    local stats=Instance.new("Folder")
    stats.Name="leaderstats"
    stats.Parent=player
    local cash=Instance.new("NumberValue")
    cash.Name="Cash"
    cash.Value=START_CASH
    cash.Parent=stats
    assign(player)
    giveIntroIfNew(player)
end
local function owned(player,plot)
    if plot:GetAttribute("OwnerUserId")==player.UserId then return true end
    hint(player,"That tomato farm belongs to another player.")
    return false
end
local function animateStand(plot)
    local stand=plot:FindFirstChild("TomatoStand")
    if not stand then return end
    if standTweens[plot] then for _,t in ipairs(standTweens[plot]) do t:Cancel() end end
    local tweens={}
    standTweens[plot]=tweens
    local info=TweenInfo.new(0.5,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
    for _,obj in ipairs(stand:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Transparency<1 then
            local finalCFrame=obj.CFrame
            obj.CFrame=finalCFrame*CFrame.new(-14,0,0)
            local tween=TweenService:Create(obj,info,{CFrame=finalCFrame})
            table.insert(tweens,tween)
            tween:Play()
        end
    end
end
local function playerFromHit(hit)
    local character=hit and hit:FindFirstAncestorOfClass("Model")
    return character and Players:GetPlayerFromCharacter(character)
end
local function buyStand(player,plot)
    if not owned(player,plot) then return end
    local cash=cashFor(player)
    if not cash then return end
    if (plot:GetAttribute("Stage") or 0)>=1 then
        hint(player,"Stand open! Click the green CLICK bar to sell tomatoes.")
        return
    end
    if cash.Value<STAND_COST then hint(player,"You need $1.00 to open your tomato stand.") return end
    cash.Value-=STAND_COST
    plot:SetAttribute("Stage",1)
    player:SetAttribute("OwnsTomatoStand",true)
    configure(plot) showStage(plot)
    animateStand(plot)
    hint(player,"Stand open! Click the green CLICK bar to sell tomatoes for $1.00.")
end
local function sell(player,plot)
    if not owned(player,plot) then return end
    local stage=plot:GetAttribute("Stage") or 0
    if stage<1 then hint(player,"Buy your $1.00 tomato stand first.") return end
    local now=os.clock()
    if now-(saleCooldown[player.UserId] or 0)<0.35 then return end
    saleCooldown[player.UserId]=now
    local cash=cashFor(player)
    if cash then
        local reward=stage>=2 and 2 or BASE_SALE
        cash.Value+=reward
        hint(player,"TOMATO SOLD  •  +$"..string.format("%.2f",reward))
    end
end
local function upgrade(player,plot)
    if not owned(player,plot) then return end
    local cash=cashFor(player)
    if not cash then return end
    local stage=plot:GetAttribute("Stage") or 0
    if stage<1 then hint(player,"Buy the $1.00 tomato stand first.") return end
    if stage>=2 then hint(player,"Basket upgraded! Each click earns $2.00.") return end
    if cash.Value<UPGRADE_COST then hint(player,"Sell tomatoes until you have $5.10, then click UPGRADE.") return end
    cash.Value-=UPGRADE_COST
    plot:SetAttribute("Stage",2)
    player:SetAttribute("BasketUpgraded",true)
    configure(plot)
    hint(player,"UPGRADE COMPLETE  •  Tomato sales now earn $2.00 each.")
end
local function connect(plot)
    configure(plot) showStage(plot)
    plot.PurchaseButton.ButtonTop.PurchaseClick.MouseClick:Connect(function(player) buyStand(player,plot) end)
    plot.PurchaseButton.ButtonTop.Touched:Connect(function(hit)
        local player=playerFromHit(hit)
        if not player then return end
        local now=os.clock()
        if now-(touchCooldown[player.UserId] or 0)<0.8 then return end
        touchCooldown[player.UserId]=now
        buyStand(player,plot)
    end)
    local stand=plot.TomatoStand
    local click=stand:FindFirstChild("ClickButton")
    if click then click.ClickDetector.MouseClick:Connect(function(player) sell(player,plot) end) end
    local up=stand:FindFirstChild("UpgradeControl")
    if up then
        up.UpgradeClick.MouseClick:Connect(function(player) upgrade(player,plot) end)
        up.Touched:Connect(function(hit)
            local player=playerFromHit(hit)
            if not player then return end
            local now=os.clock()
            if now-(touchCooldown[player.UserId] or 0)<0.8 then return end
            touchCooldown[player.UserId]=now
            upgrade(player,plot)
        end)
    end
    for _,obj in ipairs(stand:GetDescendants()) do
        if obj:GetAttribute("SellTomato") then
            local detector=obj:FindFirstChild("SellClick")
            if detector then detector.MouseClick:Connect(function(player) sell(player,plot) end) end
        end
    end
end
for _,plot in ipairs(plots:GetChildren()) do connect(plot) end
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(player)
    saleCooldown[player.UserId]=nil
    touchCooldown[player.UserId]=nil
    local plot=plotFor(player)
    if plot then
        plot:SetAttribute("OwnerUserId",0)
        plot:SetAttribute("OwnerName","OPEN")
        plot:SetAttribute("Stage",0)
        plot.OwnerSign.OwnerUI.OwnerText.Text="BASE "..string.format("%02d",plot:GetAttribute("PlotIndex")).." • OPEN"
        showStage(plot) configure(plot)
    end
end)
for _,player in ipairs(Players:GetPlayers()) do setup(player) end