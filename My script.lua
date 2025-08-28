local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
math.randomseed(tick())

-- Store original lighting
local originalBrightness = Lighting.Brightness
local originalAmbient = Lighting.Ambient
local originalOutdoor = Lighting.OutdoorAmbient

-- Persistent GUI
local function createGUI()
    local existing = PlayerGui:FindFirstChild("HallucinationGUI")
    if existing then return existing end

    local gui = Instance.new("ScreenGui")
    gui.Name = "HallucinationGUI"
    gui.ResetOnSpawn = false
    gui.Parent = PlayerGui

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0,150,0,40)
    toggle.Position = UDim2.new(0.5,-75,0,10)
    toggle.BackgroundColor3 = Color3.new(0.2,0,0)
    toggle.TextColor3 = Color3.new(1,1,1)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextScaled = true
    toggle.Text = "Hallucinations: OFF"
    toggle.Name = "Toggle"
    toggle.Parent = gui

    -- Make button draggable
    local dragging = false
    local dragInput, dragStart, startPos
    toggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = toggle.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    toggle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            toggle.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                        startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    return gui
end

local gui = createGUI()
local toggle = gui:FindFirstChild("Toggle")
local hallucinations = false

toggle.MouseButton1Click:Connect(function()
    hallucinations = not hallucinations
    if hallucinations then
        toggle.Text = "Hallucinations: ON"
        toggle.BackgroundColor3 = Color3.new(0,0.3,0)
    else
        toggle.Text = "Hallucinations: OFF"
        toggle.BackgroundColor3 = Color3.new(0.2,0,0)
    end
end)

-- Reset lighting when respawning
player.CharacterAdded:Connect(function()
    Lighting.Brightness = originalBrightness
    Lighting.Ambient = originalAmbient
    Lighting.OutdoorAmbient = originalOutdoor
end)

-- Spawn a black figure 20 studs in front, disappears after 3 sec
local function spawnBlockFigure()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local root = player.Character.HumanoidRootPart
    local frontPos = root.Position + root.CFrame.LookVector * 20 + Vector3.new(0,3,0)

    local originalSky = Lighting:FindFirstChild("Sky") and Lighting.Sky:Clone() or nil

    -- Red/black sky
    Lighting.Ambient = Color3.new(0.2,0,0)
    Lighting.OutdoorAmbient = Color3.new(0,0,0)
    local sky = Instance.new("Sky")
    sky.Name = "HallucinationSky"
    sky.Parent = Lighting

    local model = Instance.new("Model")
    model.Name = "BlackFigure"

    local function createPart(size, pos)
        local part = Instance.new("Part")
        part.Size = size
        part.Color = Color3.new(0,0,0)
        part.Anchored = true
        part.CanCollide = false
        part.Position = pos
        part.Parent = model
        return part
    end

    local torso = createPart(Vector3.new(2,3,1), frontPos)
    model.PrimaryPart = torso
    createPart(Vector3.new(2,2,1), torso.Position + Vector3.new(0,2.5,0))
    createPart(Vector3.new(1,3,1), torso.Position + Vector3.new(-1.5,0,0))
    createPart(Vector3.new(1,3,1), torso.Position + Vector3.new(1.5,0,0))
    createPart(Vector3.new(1,3,1), torso.Position + Vector3.new(-0.5,-3,0))
    createPart(Vector3.new(1,3,1), torso.Position + Vector3.new(0.5,-3,0))

    model.Parent = workspace

    -- Destroy after 3 sec and restore sky
    task.delay(3,function()
        if model then model:Destroy() end
        if sky then sky:Destroy() end
        if originalSky then originalSky.Parent = Lighting end
        Lighting.Ambient = originalAmbient
        Lighting.OutdoorAmbient = originalOutdoor
    end)
end

-- Black screen flash
local function blackFlash()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,1,0)
    frame.Position = UDim2.new(0,0,0,0)
    frame.BackgroundColor3 = Color3.new(0,0,0)
    frame.BackgroundTransparency = 0
    frame.Parent = gui
    task.delay(0.3,function() frame:Destroy() end)
end

-- Randomly scramble texts to "פרחים"
local function scrambleTexts()
    for _, d in ipairs(PlayerGui:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            d.Text = "פרחים"
        end
    end
end

-- Random black fog
local function randomFog()
    local originalFogEnd = Lighting.FogEnd
    local originalFogStart = Lighting.FogStart

    Lighting.FogColor = Color3.new(0,0,0)
    Lighting.FogStart = math.random(10,50)
    Lighting.FogEnd = Lighting.FogStart + math.random(20,100)

    task.delay(math.random(2,5),function()
        Lighting.FogStart = originalFogStart
        Lighting.FogEnd = originalFogEnd
    end)
end

-- Gradual darkening every minute
local function gradualDarkening()
    local maxSteps = 5
    local stepDelay = 12
    local stepAmount = originalBrightness / maxSteps
    while true do
        if hallucinations then
            for i = 1, maxSteps do
                Lighting.Brightness = math.max(0, Lighting.Brightness - stepAmount)
                task.wait(stepDelay)
            end
            Lighting.Brightness = originalBrightness
        else
            task.wait(1)
        end
    end
end

-- Hallucination effects loop (black flash, texts, fog)
local function hallucinationLoop()
    while true do
        if hallucinations then
            if math.random() < 0.5 then blackFlash() end
            if math.random() < 0.3 then scrambleTexts() end
            if math.random() < 0.4 then randomFog() end
        end
        task.wait(math.random(3,6))
    end
end

-- Black figure spawn loop (every 1 minute)
local function blackFigureLoop()
    while true do
        if hallucinations then
            spawnBlockFigure()
        end
        task.wait(60)
    end
end

-- Start loops
task.spawn(hallucinationLoop)
task.spawn(gradualDarkening)
task.spawn(blackFigureLoop)
