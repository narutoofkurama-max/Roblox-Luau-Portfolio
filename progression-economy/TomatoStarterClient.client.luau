local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local remote=ReplicatedStorage:WaitForChild("TomatoTutorialEvent")
local playerGui=player:WaitForChild("PlayerGui")
local screen=Instance.new("ScreenGui")
screen.Name="TomatoPlayerUI"
screen.ResetOnSpawn=false
screen.DisplayOrder=20
screen.IgnoreGuiInset=false
screen.Parent=playerGui

local function label(parent,name,pos,size,text,font,textSize,color)
    local t=Instance.new("TextLabel")
    t.Name=name t.Position=pos t.Size=size t.BackgroundTransparency=1
    t.BorderSizePixel=0 t.Text=text t.Font=font t.TextSize=textSize
    t.TextColor3=color t.TextWrapped=true t.TextStrokeColor3=Color3.fromRGB(30,30,30)
    t.TextStrokeTransparency=0 t.Parent=parent return t
end

-- Compact in-game balance strip, similar to the reference HUD.
local hud=Instance.new("Frame")
hud.Name="CashHUD" hud.AnchorPoint=Vector2.new(0.5,0)
hud.Position=UDim2.new(0.5,0,0,8) hud.Size=UDim2.fromOffset(340,52)
hud.BackgroundColor3=Color3.fromRGB(32,37,43) hud.BackgroundTransparency=0.08 hud.Parent=screen
local hudCorner=Instance.new("UICorner") hudCorner.CornerRadius=UDim.new(0,15) hudCorner.Parent=hud
local hudStroke=Instance.new("UIStroke") hudStroke.Color=Color3.fromRGB(14,17,20) hudStroke.Thickness=4 hudStroke.Parent=hud
local balance=label(hud,"Balance",UDim2.new(0,18,0,0),UDim2.new(1,-36,1,0),"$1.00",Enum.Font.GothamBlack,27,Color3.fromRGB(46,255,70))
balance.TextXAlignment=Enum.TextXAlignment.Left
task.spawn(function()
    local stats=player:WaitForChild("leaderstats",20)
    local cash=stats and stats:WaitForChild("Cash",20)
    local function update()
        if cash then balance.Text="$"..string.format("%.2f",cash.Value) end
    end
    if cash then cash.Changed:Connect(update) update() end
end)

-- Transparent tutorial text, with no backing panel.
local hint=label(screen,"Tutorial",UDim2.new(0.5,-300,0,68),UDim2.fromOffset(600,38),
    "Use your $1 note to buy the tomato stand.",Enum.Font.GothamBlack,18,Color3.new(1,1,1))
hint.AnchorPoint=Vector2.new(0,0)
hint.TextXAlignment=Enum.TextXAlignment.Center
local function showHint(text) hint.Text=text end
remote.OnClientEvent:Connect(showHint)
local currentHint=player:GetAttribute("TomatoTutorialMessage")
if currentHint then showHint(currentHint) end
player:GetAttributeChangedSignal("TomatoTutorialMessage"):Connect(function()
    local message=player:GetAttribute("TomatoTutorialMessage")
    if message then showHint(message) end
end)

-- First-visit letter, recreated from UI so the starter bill is actual game art.
local root=Instance.new("Frame")
root.Name="StarterLetter" root.Size=UDim2.fromScale(1,1)
root.BackgroundColor3=Color3.new(0,0,0) root.BackgroundTransparency=0.48
root.Visible=false root.Parent=screen
local paper=Instance.new("Frame")
paper.Name="Paper" paper.AnchorPoint=Vector2.new(0.5,0.5)
paper.Position=UDim2.fromScale(0.5,0.51) paper.Size=UDim2.fromOffset(540,700)
paper.Rotation=-1.2 paper.BackgroundColor3=Color3.fromRGB(255,249,224)
paper.BorderSizePixel=0 paper.ClipsDescendants=false paper.Parent=root
local paperScale=Instance.new("UIScale") paperScale.Scale=1 paperScale.Parent=paper
local paperCorner=Instance.new("UICorner") paperCorner.CornerRadius=UDim.new(0,8) paperCorner.Parent=paper
local paperStroke=Instance.new("UIStroke") paperStroke.Color=Color3.fromRGB(20,20,18) paperStroke.Thickness=6 paperStroke.Parent=paper
local function pLabel(name,pos,size,text,font,textSize,color,align)
    local t=label(paper,name,pos,size,text,font,textSize,color)
    if align then t.TextXAlignment=align end
    t.TextStrokeTransparency=1
    return t
end
pLabel("Address",UDim2.new(1,-205,0,24),UDim2.fromOffset(175,58),
    "Dad Tomato\nTomato Town",Enum.Font.Cartoon,16,Color3.fromRGB(133,127,109),Enum.TextXAlignment.Right)
pLabel("Greeting",UDim2.new(0,42,0,97),UDim2.fromOffset(445,54),
    "Dear Farmer,",Enum.Font.Cartoon,35,Color3.fromRGB(87,83,73),Enum.TextXAlignment.Left)
local headline=pLabel("Headline",UDim2.new(0,58,0,164),UDim2.fromOffset(425,142),
    "Sell Tomatoes.\nMake money.",Enum.Font.PermanentMarker,43,Color3.fromRGB(18,18,18),Enum.TextXAlignment.Left)
headline.TextYAlignment=Enum.TextYAlignment.Center
pLabel("FruitEmblem",UDim2.new(0,65,0,294),UDim2.fromOffset(390,58),
    "🍅      💰      🍅",Enum.Font.GothamBlack,34,Color3.fromRGB(30,30,30),Enum.TextXAlignment.Center)
pLabel("Signature",UDim2.new(1,-240,0,358),UDim2.fromOffset(205,58),
    "— Dad",Enum.Font.Cartoon,38,Color3.fromRGB(102,96,83),Enum.TextXAlignment.Right)
pLabel("Postscript",UDim2.new(0,45,0,440),UDim2.fromOffset(450,72),
    "P.S. Here's a little something to get you started. 😉",Enum.Font.Cartoon,23,Color3.fromRGB(28,28,26),Enum.TextXAlignment.Left)

-- A drawn one-dollar bill tucked over the lower edge of the letter.
local bill=Instance.new("Frame")
bill.Name="OneDollarNote" bill.Position=UDim2.new(0,-12,0,530)
bill.Size=UDim2.fromOffset(368,142) bill.Rotation=-3
bill.BackgroundColor3=Color3.fromRGB(35,197,45) bill.BorderSizePixel=0 bill.Parent=paper
local billCorner=Instance.new("UICorner") billCorner.CornerRadius=UDim.new(0,6) billCorner.Parent=bill
local billStroke=Instance.new("UIStroke") billStroke.Color=Color3.fromRGB(0,84,25) billStroke.Thickness=5 billStroke.Parent=bill
local inner=Instance.new("Frame")
inner.Name="EngravedBorder" inner.Position=UDim2.new(0,8,0,8) inner.Size=UDim2.new(1,-16,1,-16)
inner.BackgroundTransparency=1 inner.BorderSizePixel=0 inner.Parent=bill
local innerStroke=Instance.new("UIStroke") innerStroke.Color=Color3.fromRGB(0,132,31) innerStroke.Thickness=3 innerStroke.Parent=inner
label(bill,"LeftOne",UDim2.new(0,12,0,3),UDim2.fromOffset(43,42),"1",Enum.Font.GothamBlack,32,Color3.fromRGB(0,105,27))
label(bill,"RightOne",UDim2.new(1,-56,0,3),UDim2.fromOffset(43,42),"1",Enum.Font.GothamBlack,32,Color3.fromRGB(0,105,27))
local seal=Instance.new("Frame")
seal.Name="DollarSeal" seal.AnchorPoint=Vector2.new(0.5,0.5)
seal.Position=UDim2.new(0.5,0,0.49,0) seal.Size=UDim2.fromOffset(80,80)
seal.BackgroundColor3=Color3.fromRGB(0,151,37) seal.BorderSizePixel=0 seal.Parent=bill
local sealCorner=Instance.new("UICorner") sealCorner.CornerRadius=UDim.new(1,0) sealCorner.Parent=seal
label(seal,"Dollar",UDim2.fromScale(0,0),UDim2.fromScale(1,1),"$",Enum.Font.GothamBlack,57,Color3.fromRGB(71,240,80))
label(bill,"MoneyText",UDim2.new(0,0,1,-25),UDim2.new(1,0,0,20),"ONE DOLLAR  •  TOMATO TOWN",Enum.Font.GothamBlack,13,Color3.fromRGB(0,90,24))

local letterDismissed=false
local continueButton
local noteClick=Instance.new("TextButton")
noteClick.Name="ClickTheDollar"
noteClick.Size=UDim2.fromScale(1,1)
noteClick.Position=UDim2.fromScale(0,0)
noteClick.BackgroundTransparency=1
noteClick.Text=""
noteClick.AutoButtonColor=false
noteClick.ZIndex=15
noteClick.Parent=bill

local noteAnimating=false
noteClick.Activated:Connect(function()
    if noteAnimating or not root.Visible then return end
    noteAnimating=true
    letterDismissed=true
    continueButton.Active=false
    local absolutePosition=bill.AbsolutePosition
    local absoluteSize=bill.AbsoluteSize
    bill.Parent=screen
    bill.AnchorPoint=Vector2.new(0.5,0.5)
    bill.Position=UDim2.fromOffset(absolutePosition.X+absoluteSize.X/2,absolutePosition.Y+absoluteSize.Y/2)
    bill.Size=UDim2.fromOffset(absoluteSize.X,absoluteSize.Y)
    bill.Rotation=-3
    bill.ZIndex=50
    noteClick:Destroy()
    for _,gui in ipairs(bill:GetDescendants()) do
        if gui:IsA("GuiObject") then gui.ZIndex=51 end
    end
    root.Visible=false
    local camera=workspace.CurrentCamera
    local viewport=camera and camera.ViewportSize or Vector2.new(1280,720)
    local centerInfo=TweenInfo.new(0.38,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    local centerTween=TweenService:Create(bill,centerInfo,{Position=UDim2.fromOffset(viewport.X/2,viewport.Y/2),Size=UDim2.fromOffset(250,96),Rotation=2})
    centerTween:Play()
    centerTween.Completed:Wait()
    local hudCenter=hud.AbsolutePosition+hud.AbsoluteSize/2
    local flyTween=TweenService:Create(bill,TweenInfo.new(0.42,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Position=UDim2.fromOffset(hudCenter.X,hudCenter.Y),Size=UDim2.fromOffset(50,24),Rotation=0})
    flyTween:Play()
    flyTween.Completed:Wait()
    bill:Destroy()
    local oldColor=hudStroke.Color
    hudStroke.Color=Color3.fromRGB(82,255,101)
    TweenService:Create(hudStroke,TweenInfo.new(0.45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Color=oldColor}):Play()
end)
label(paper,"PaperClip",UDim2.new(0,55,0,515),UDim2.fromOffset(42,78),"📎",Enum.Font.GothamBlack,42,Color3.fromRGB(220,220,210))

continueButton=Instance.new("TextButton")
continueButton.Name="Continue" continueButton.AnchorPoint=Vector2.new(1,1)
continueButton.Position=UDim2.new(1,-16,1,-16) continueButton.Size=UDim2.fromOffset(160,44)
continueButton.BackgroundColor3=Color3.fromRGB(39,171,58) continueButton.Text="START SELLING  →"
continueButton.TextColor3=Color3.new(1,1,1) continueButton.TextStrokeColor3=Color3.fromRGB(14,65,25)
continueButton.TextStrokeTransparency=0 continueButton.TextSize=15 continueButton.Font=Enum.Font.GothamBlack
continueButton.ZIndex=20 continueButton.Parent=paper
local continueCorner=Instance.new("UICorner") continueCorner.CornerRadius=UDim.new(0,12) continueCorner.Parent=continueButton
local continueStroke=Instance.new("UIStroke") continueStroke.Color=Color3.fromRGB(15,83,29) continueStroke.Thickness=3 continueStroke.Parent=continueButton
continueButton.Activated:Connect(function() letterDismissed=true root.Visible=false end)

local function scaleLetter()
    local camera=workspace.CurrentCamera
    if not camera then return end
    local viewport=camera.ViewportSize
    paperScale.Scale=math.min(1,viewport.X/620,viewport.Y/760)
end
scaleLetter()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(scaleLetter) end
local function maybeShowLetter()
    if not letterDismissed and player:GetAttribute("ShowStarterLetter")==true then root.Visible=true end
end
player:GetAttributeChangedSignal("ShowStarterLetter"):Connect(maybeShowLetter)
task.delay(1,maybeShowLetter)

-- Each client colors only its own buttons, so one player's balance cannot recolor another player's pads.
local function refreshButtons()
    local map=workspace:FindFirstChild("TomatoMap")
    local plots=map and map:FindFirstChild("Plots")
    if not plots then return end
    local stats=player:FindFirstChild("leaderstats")
    local cashObj=stats and stats:FindFirstChild("Cash")
    local cash=cashObj and cashObj.Value or 0
    for _,plot in ipairs(plots:GetChildren()) do
        local owner=plot:GetAttribute("OwnerUserId")
        local stage=plot:GetAttribute("Stage") or 0
        local pad=plot:FindFirstChild("PurchaseButton")
        local top=pad and pad:FindFirstChild("ButtonTop")
        local cost=pad and (pad:GetAttribute("Cost") or 1)
        if top then
            if owner==player.UserId and stage==0 then
                top.Color=cash>=cost and Color3.fromRGB(35,224,70) or Color3.fromRGB(230,48,54)
            else
                top.Color=Color3.fromRGB(90,94,98)
            end
        end
        local stand=plot:FindFirstChild("TomatoStand")
        local upgrade=stand and stand:FindFirstChild("UpgradeControl")
        local ui=upgrade and upgrade:FindFirstChild("UpgradeSurface")
        local face=ui and ui:FindFirstChild("ButtonFace")
        local price=ui and ui:FindFirstChild("CostText")
        local upgradeCost=upgrade and (upgrade:GetAttribute("Cost") or 5.1)
        if face and price then
            if owner==player.UserId and stage==1 then
                local canAfford=cash>=upgradeCost
                face.BackgroundColor3=canAfford and Color3.fromRGB(48,205,64) or Color3.fromRGB(190,55,58)
                price.TextColor3=canAfford and Color3.fromRGB(71,255,104) or Color3.fromRGB(255,94,94)
            elseif stage>=2 and owner==player.UserId then
                face.BackgroundColor3=Color3.fromRGB(66,132,77)
                price.TextColor3=Color3.fromRGB(210,240,210)
            else
                face.BackgroundColor3=Color3.fromRGB(110,113,118)
                price.TextColor3=Color3.fromRGB(66,255,96)
            end
        end
    end
end
task.spawn(function()
    local map=workspace:WaitForChild("TomatoMap")
    local plots=map:WaitForChild("Plots")
    for _,plot in ipairs(plots:GetChildren()) do
        plot:GetAttributeChangedSignal("OwnerUserId"):Connect(refreshButtons)
        plot:GetAttributeChangedSignal("Stage"):Connect(refreshButtons)
    end
    refreshButtons()
end)
player:GetAttributeChangedSignal("FarmPlotId"):Connect(refreshButtons)
task.spawn(function()
    local stats=player:WaitForChild("leaderstats",20)
    local cash=stats and stats:WaitForChild("Cash",20)
    if cash then cash.Changed:Connect(refreshButtons) end
    refreshButtons()
end)