--[[
    🌀 VR Props Control Panel
    - Clean, NO image, Glowing Rainbow Lines & Labels
    - Info Text on Right
    - Gravity always ON, Gravity button removed
    - Head-part auto-connects to the running player's UserId
    - Created by Vip_Agend
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- AUTO CONNECT TO LOCAL PLAYER'S HEAD PART
local function getHeadPart()
    local headName = tostring(player.UserId) .. "Head"
    local head = Workspace:FindFirstChild(headName)
    if not head then
        head = Workspace:WaitForChild(headName)
    end
    return head
end

local Head = getHeadPart()
local PropsFolder = Workspace:WaitForChild("Props")

local ORBIT_RADIUS = 27
local ORBIT_SPEED = math.pi * 10

local orbitActiveHead = false
local spinningData = {}
local BASE_OFFSET = Vector3.new(0, 55, 0)
local offset = BASE_OFFSET
local forces = {}
local isActive = true
local connections = {}

local function disconnectAll()
    for _, conn in ipairs(connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    connections = {}
end

local function deactivateAll()
    isActive = false
    disconnectAll()
    if ScreenGui then ScreenGui:Destroy() end
end

-- Animated rainbow for TextLabel (one color for whole text, glows, not too fast)
local function animateRainbowText(label, colorOverride)
    local t = 0
    task.spawn(function()
        while label.Parent and isActive do
            t = t + 0.0075
            if colorOverride then
                label.TextColor3 = colorOverride
            else
                local color = Color3.fromHSV(t % 1, 1, 1)
                label.TextColor3 = color
            end
            label.TextStrokeTransparency = 0.2
            label.TextStrokeColor3 = Color3.new(1, 1, 1)
            task.wait(0.04)
        end
    end)
end

-- Explosion visual effect function (unchanged)
local function createExplosionEffect(center, parent)
    if not isActive then return end
    for i = 1, 12 do
        local angle = math.rad(i * 30)
        local radius = math.random(60,100)
        local effect = Instance.new("ImageLabel")
        effect.AnchorPoint = Vector2.new(0.5,0.5)
        effect.Position = UDim2.new(0.5, math.cos(angle)*radius, 0.5, math.sin(angle)*radius)
        effect.Size = UDim2.new(0, math.random(42,58), 0, math.random(42,58))
        effect.BackgroundTransparency = 1
        effect.Image = "rbxassetid://489065390"
        effect.ImageColor3 = Color3.fromRGB(180, 70, 255)
        effect.ImageTransparency = 0.27
        effect.ZIndex = 0
        effect.Parent = parent

        local fadeTween = TweenService:Create(effect, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {ImageTransparency = 1, Size = UDim2.new(0,0,0,0)})
        fadeTween:Play()
        game:GetService("Debris"):AddItem(effect, 0.65)
    end
end

local function initSpinningData()
    spinningData = {}
    for _, part in ipairs(PropsFolder:GetChildren()) do
        local centerPart = (part:IsA("Model") and part.PrimaryPart) or part
        spinningData[part] = {
            angle = math.random() * 2 * math.pi,
            radius = ORBIT_RADIUS,
            centerPart = centerPart,
        }
        if part:IsA("Model") then
            for _, desc in ipairs(part:GetDescendants()) do
                if desc:IsA("BasePart") then
                    desc.Anchored = false
                end
            end
        else
            part.Anchored = false
        end
    end
end
initSpinningData()

local function movePartTowards(part, targetPos, dt)
    if not isActive then return end
    if not part or not part.Parent then return end
    local currentPos = part.Position
    local direction = targetPos - currentPos
    local distance = direction.Magnitude
    if distance < 0.1 then
        part.Velocity = Vector3.new(0, 0, 0)
        part.CFrame = CFrame.new(targetPos)
        return
    end
    local moveVector = direction.Unit * math.min(distance, 30000 * dt)
    part.Velocity = moveVector / dt
end

local function applyAntiGravity(part)
    if part:IsA("BasePart") and not part.Anchored then
        local root = part.AssemblyRootPart or part
        local attach = root:FindFirstChild("AntiG_Attach")
        if not attach then
            attach = Instance.new("Attachment")
            attach.Name = "AntiG_Attach"
            attach.Parent = root
        end
        local vf = root:FindFirstChild("AntiG_VectorForce")
        if not vf then
            vf = Instance.new("VectorForce")
            vf.Name = "AntiG_VectorForce"
            vf.Attachment0 = attach
            vf.RelativeTo = Enum.ActuatorRelativeTo.World
            vf.ApplyAtCenterOfMass = true
            vf.Force = Vector3.new(0,0,0)
            vf.Parent = root
        end
        forces[root] = vf
    end
end

for _, obj in ipairs(PropsFolder:GetDescendants()) do
    applyAntiGravity(obj)
end
PropsFolder.DescendantAdded:Connect(applyAntiGravity)

-- === GUI ===
ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ControlGUI"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0, 460, 0, 315)
Panel.Position = UDim2.new(0.5, -230, 0.5, -157)
Panel.BackgroundColor3 = Color3.fromRGB(30, 34, 64)
Panel.BorderSizePixel = 0
Panel.AnchorPoint = Vector2.new(0.5, 0.5)
Panel.Parent = ScreenGui
local corner = Instance.new("UICorner", Panel)
corner.CornerRadius = UDim.new(0, 18)

-- Movable Menu Logic (drag by top 40 px)
local dragging, dragStart, panelStart
Panel.InputBegan:Connect(function(input)
    if not isActive then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local relY = input.Position.Y - Panel.AbsolutePosition.Y
        if relY <= 40 then
            dragging = true
            dragStart = input.Position
            panelStart = Panel.Position
            Panel.BackgroundTransparency = 0.15
        end
    end
end)
Panel.InputEnded:Connect(function(input)
    if not isActive then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        Panel.BackgroundTransparency = 0
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if not isActive then return end
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Panel.Position = UDim2.new(panelStart.X.Scale, panelStart.X.Offset + delta.X, panelStart.Y.Scale, panelStart.Y.Offset + delta.Y)
    end
end)

-- Top Animated Rainbow Line
local TopLine = Instance.new("TextLabel")
TopLine.Size = UDim2.new(1, 0, 0, 14)
TopLine.Position = UDim2.new(0, 0, 0, 32)
TopLine.BackgroundTransparency = 1
TopLine.Text = string.rep("_", 38)
TopLine.TextScaled = false
TopLine.TextSize = 22
TopLine.TextXAlignment = Enum.TextXAlignment.Center
TopLine.Font = Enum.Font.GothamBlack
TopLine.TextStrokeTransparency = 0.35
TopLine.Parent = Panel
animateRainbowText(TopLine)

-- Title (glowing rainbow, gerade zentriert)
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 33)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.AnchorPoint = Vector2.new(0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🌀 VR Props Control Panel"
Title.TextScaled = true
Title.TextWrapped = true
Title.TextXAlignment = Enum.TextXAlignment.Center
Title.TextYAlignment = Enum.TextYAlignment.Center
Title.Font = Enum.Font.GothamBlack
Title.TextStrokeTransparency = 0.2
Title.TextStrokeColor3 = Color3.new(1,1,1)
Title.Parent = Panel
animateRainbowText(Title)

-- X BUTTON (top right)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -38, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.TextScaled = true
closeBtn.ZIndex = 99
closeBtn.AutoButtonColor = false
closeBtn.Parent = Panel
local closeBtnCorner = Instance.new("UICorner", closeBtn)
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 80, 80)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(220, 40, 40)}):Play()
end)
closeBtn.MouseButton1Click:Connect(function()
    deactivateAll()
end)

-- Spin button row above axis controls (Gravity button REMOVED)
local TopButtonFrame = Instance.new("Frame")
TopButtonFrame.Size = UDim2.new(1, -24, 0, 36)
TopButtonFrame.Position = UDim2.new(0, 12, 0, 54)
TopButtonFrame.BackgroundTransparency = 1
TopButtonFrame.Parent = Panel

local SpinButton = Instance.new("TextButton")
SpinButton.Size = UDim2.new(1, 0, 1, 0)
SpinButton.Position = UDim2.new(0, 0, 0, 0)
SpinButton.BackgroundColor3 = Color3.fromRGB(150, 70, 255)
SpinButton.TextColor3 = Color3.fromRGB(255,255,255)
SpinButton.Text = "Spin Off"
SpinButton.Font = Enum.Font.GothamSemibold
SpinButton.TextScaled = true
SpinButton.Parent = TopButtonFrame
local SpinCorner = Instance.new("UICorner", SpinButton)
SpinCorner.CornerRadius = UDim.new(0, 8)

-- Axis controls (reset in the center row)
local ContentGrid = Instance.new("Frame")
ContentGrid.Size = UDim2.new(0, 230, 0, 120)
ContentGrid.Position = UDim2.new(0, 12, 0, 96)
ContentGrid.BackgroundTransparency = 1
ContentGrid.Parent = Panel

local axisNames = {"x", "y", "z"}
local axisValues = {X=0, Y=55, Z=0}
local axisLabels = {}
local currentStep = 5
local function updateAxisLabels()
    axisLabels.X.Text = "x: "..axisValues.X
    axisLabels.Y.Text = "y: "..axisValues.Y
    axisLabels.Z.Text = "z: "..axisValues.Z
end

for i, axis in ipairs(axisNames) do
    local yPos = (i-1)*36
    -- Minus
    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0, 32, 0, 28)
    minus.Position = UDim2.new(0, 0, 0, yPos)
    minus.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    minus.Text = "<"
    minus.TextColor3 = Color3.fromRGB(255,255,255)
    minus.Font = Enum.Font.GothamBold
    minus.TextScaled = true
    minus.Parent = ContentGrid
    local minusCorner = Instance.new("UICorner", minus)
    minusCorner.CornerRadius = UDim.new(0, 6)

    -- Value
    local value = Instance.new("TextLabel")
    value.Size = UDim2.new(0, 60, 0, 28)
    value.Position = UDim2.new(0, 38, 0, yPos)
    value.BackgroundTransparency = 1
    value.Text = axis..": "..axisValues[axis:upper()]
    value.TextColor3 = Color3.fromRGB(255,255,255)
    value.Font = Enum.Font.Gotham
    value.TextScaled = true
    value.Parent = ContentGrid
    axisLabels[axis:upper()] = value

    -- Plus
    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0, 32, 0, 28)
    plus.Position = UDim2.new(0, 102, 0, yPos)
    plus.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    plus.Text = ">"
    plus.TextColor3 = Color3.fromRGB(255,255,255)
    plus.Font = Enum.Font.GothamBold
    plus.TextScaled = true
    plus.Parent = ContentGrid
    local plusCorner = Instance.new("UICorner", plus)
    plusCorner.CornerRadius = UDim.new(0, 6)

    -- Reset (only in center/y row)
    if i == 2 then
        local ResetButton = Instance.new("TextButton")
        ResetButton.Size = UDim2.new(0, 55, 0, 28)
        ResetButton.Position = UDim2.new(0, 157, 0, yPos)
        ResetButton.BackgroundColor3 = Color3.fromRGB(175, 255, 120)
        ResetButton.Text = "Reset"
        ResetButton.TextColor3 = Color3.fromRGB(60,60,60)
        ResetButton.Font = Enum.Font.GothamBold
        ResetButton.TextScaled = true
        ResetButton.ZIndex = 2
        ResetButton.Parent = ContentGrid
        local ResetUICorner = Instance.new("UICorner", ResetButton)
        ResetUICorner.CornerRadius = UDim.new(0, 10)
        local ResetStroke = Instance.new("UIStroke", ResetButton)
        ResetStroke.Thickness = 3
        ResetStroke.Color = Color3.fromRGB(80,255,80)
        ResetStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        ResetButton.MouseButton1Click:Connect(function()
            if not isActive then return end
            axisValues.X = 0
            axisValues.Y = 55
            axisValues.Z = 0
            offset = Vector3.new(axisValues.X, axisValues.Y, axisValues.Z)
            updateAxisLabels()
            createExplosionEffect(Panel.Position, ScreenGui)
        end)
    end

    -- Button logic
    minus.MouseButton1Click:Connect(function()
        if not isActive then return end
        local key = axis:upper()
        axisValues[key] = axisValues[key] - currentStep
        updateAxisLabels()
        offset = Vector3.new(axisValues.X, axisValues.Y, axisValues.Z)
        createExplosionEffect(Panel.Position, ScreenGui)
    end)
    plus.MouseButton1Click:Connect(function()
        if not isActive then return end
        local key = axis:upper()
        axisValues[key] = axisValues[key] + currentStep
        updateAxisLabels()
        offset = Vector3.new(axisValues.X, axisValues.Y, axisValues.Z)
        createExplosionEffect(Panel.Position, ScreenGui)
    end)
end

-- Info Text (right side, white, glowing)
local infoFrame = Instance.new("Frame")
infoFrame.Parent = Panel
infoFrame.BackgroundTransparency = 1
infoFrame.Size = UDim2.new(0, 194, 0, 120)
infoFrame.Position = UDim2.new(0, 250, 0, 96)

local infoText = Instance.new("TextLabel")
infoText.Parent = infoFrame
infoText.Size = UDim2.new(1, 0, 1, 0)
infoText.Position = UDim2.new(0, 0, 0, 0)
infoText.BackgroundTransparency = 1
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.TextYAlignment = Enum.TextYAlignment.Top
infoText.Font = Enum.Font.Gotham
infoText.TextSize = 16
infoText.RichText = true
infoText.TextWrapped = true
infoText.Text = "Use:\n\n• Spin: When on and hold the grab button objekts fly arround you head \n• Gravity: <b>always On</b>, lets objekts stay in the air, coordinates where it spin  (x/y/z)\n• Reset: Make the normal (x/y/z) position."
infoText.TextColor3 = Color3.new(1, 1, 1)
infoText.TextStrokeTransparency = 0.15
infoText.TextStrokeColor3 = Color3.new(1, 1, 1)
animateRainbowText(infoText, Color3.new(1, 1, 1))

-- Step Buttons Row (below axis controls)
local StepFrame = Instance.new("Frame")
StepFrame.Size = UDim2.new(0, 210, 0, 32)
StepFrame.Position = UDim2.new(0, 12, 0, 202)
StepFrame.BackgroundTransparency = 1
StepFrame.Parent = Panel

local stepSizes = {5,10,25}
local stepBtns = {}

local function updateStepBtnColors()
    for _, step in ipairs(stepSizes) do
        local btn = stepBtns[step]
        if btn then
            if step == currentStep then
                btn.BackgroundColor3 = Color3.fromRGB(100,255,120)
                btn.TextColor3 = Color3.fromRGB(20,20,30)
            else
                btn.BackgroundColor3 = Color3.fromRGB(60,60,80)
                btn.TextColor3 = Color3.fromRGB(255,255,255)
            end
        end
    end
end

for i, step in ipairs(stepSizes) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 38, 0, 28)
    btn.Position = UDim2.new(0, (i-1)*58, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(60,60,80)
    btn.Text = tostring(step)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Parent = StepFrame
    btn.ZIndex = 8
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 7)
    stepBtns[step] = btn
    btn.MouseButton1Click:Connect(function()
        if not isActive then return end
        currentStep = step
        updateStepBtnColors()
        createExplosionEffect(Panel.Position, ScreenGui)
    end)
end
updateStepBtnColors()

-- Bottom Animated Rainbow Line
local BottomLine = Instance.new("TextLabel")
BottomLine.Size = UDim2.new(1, 0, 0, 14)
BottomLine.Position = UDim2.new(0, 0, 1, -48)
BottomLine.BackgroundTransparency = 1
BottomLine.Text = string.rep("_", 38)
BottomLine.TextScaled = false
BottomLine.TextSize = 22
BottomLine.TextXAlignment = Enum.TextXAlignment.Center
BottomLine.Font = Enum.Font.GothamBlack
BottomLine.TextStrokeTransparency = 0.35
BottomLine.Parent = Panel
animateRainbowText(BottomLine)

-- Created by label (glowing/animated)
local creditLabel = Instance.new("TextLabel")
creditLabel.Size = UDim2.new(1, 0, 0, 26)
creditLabel.Position = UDim2.new(0, 0, 1, -30)
creditLabel.BackgroundTransparency = 1
creditLabel.Text = "Created by Vip_Agend"
creditLabel.TextScaled = true
creditLabel.Font = Enum.Font.Gotham
creditLabel.TextStrokeTransparency = 0.2
creditLabel.TextStrokeColor3 = Color3.new(1,1,1)
creditLabel.Parent = Panel
animateRainbowText(creditLabel)

-- Spin logic
local function setButtonStates()
    SpinButton.BackgroundColor3 = orbitActiveHead and Color3.fromRGB(60, 220, 100) or Color3.fromRGB(150, 70, 255)
end

SpinButton.MouseButton1Click:Connect(function()
    if not isActive then return end
    orbitActiveHead = not orbitActiveHead
    SpinButton.Text = orbitActiveHead and "Spin On" or "Spin Off"
    setButtonStates()
    createExplosionEffect(Panel.Position, ScreenGui)
end)

SpinButton.MouseEnter:Connect(function()
    if not isActive then return end
    TweenService:Create(SpinButton, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(220, 60, 220)}):Play()
end)
SpinButton.MouseLeave:Connect(function()
    if not isActive then return end
    setButtonStates()
end)

setButtonStates()
updateAxisLabels()

local LEFT_GRAB = Enum.KeyCode.ButtonL1
local leftGrabDown = false

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not isActive then return end
    if gameProcessed then return end
    if input.KeyCode == LEFT_GRAB then
        leftGrabDown = true
    end
end))
table.insert(connections, UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if not isActive then return end
    if input.KeyCode == LEFT_GRAB then
        leftGrabDown = false
    end
end))

table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    if not isActive then return end
    -- Gravity always ON
    for part, vf in pairs(forces) do
        if part and vf then
            vf.Force = Vector3.new(0, part.AssemblyMass * Workspace.Gravity, 0)
            part.Velocity = Vector3.new(0,0,0)
            part.RotVelocity = Vector3.new(0,0,0)
        end
    end
    if orbitActiveHead and leftGrabDown then
        local pivot = Head:GetPivot()
        local orbitCenter = pivot.Position + offset
        for part, data in pairs(spinningData) do
            if part and part.Parent and data.centerPart then
                data.angle = data.angle + ORBIT_SPEED * dt
                local x = math.cos(data.angle) * data.radius
                local z = math.sin(data.angle) * data.radius
                local y = 0
                local targetPos = orbitCenter + Vector3.new(x, y, z)
                movePartTowards(data.centerPart, targetPos, dt)
            end
        end
    end
end))
