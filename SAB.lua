-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 🔥 Destroy old GUI if it exists (prevents duplicates after reset)
if playerGui:FindFirstChild("StealBrainrotGui") then
    playerGui.StealBrainrotGui:Destroy()
end

-- Function that builds everything
local function initScript(character)
    local humanoid = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")

    -- Helpers
    local function saveData(name, data)
        local stored = playerGui:FindFirstChild("SavedPositions")
        if not stored then
            stored = Instance.new("Folder")
            stored.Name = "SavedPositions"
            stored.Parent = playerGui
        end
        local obj = stored:FindFirstChild(name)
        if not obj then
            obj = Instance.new("StringValue")
            obj.Name = name
            obj.Parent = stored
        end
        if typeof(data) == "Vector3" then
            data = {X = data.X, Y = data.Y, Z = data.Z}
        end
        obj.Value = HttpService:JSONEncode(data)
    end

    local function loadData(name)
        local stored = playerGui:FindFirstChild("SavedPositions")
        if stored and stored:FindFirstChild(name) then
            local ok, data = pcall(function()
                return HttpService:JSONDecode(stored[name].Value)
            end)
            if ok then
                if data.X then
                    return Vector3.new(data.X, data.Y, data.Z)
                else
                    return data
                end
            end
        end
        return nil
    end

    -- === MAIN GUI ===
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StealBrainrotGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 220, 0, 250)
    mainFrame.Position = UDim2.new(0.5, -110, 0.7, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)
    mainFrame.BorderSizePixel = 0
    mainFrame.AnchorPoint = Vector2.new(0.5,0)
    mainFrame.Parent = screenGui
    mainFrame.Active = true
    mainFrame.Draggable = true

    -- Restore GUI pos
    local savedPos = loadData("MainFramePos")
    if savedPos then
        mainFrame.Position = UDim2.new(savedPos.XScale, savedPos.XOffset, savedPos.YScale, savedPos.YOffset)
    end

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,30)
    title.BackgroundTransparency = 1
    title.Text = "Steal A Brainrot"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.SourceSansBold
    title.TextScaled = true
    title.Parent = mainFrame

    -- Save GUI pos button
    local saveGuiBtn = Instance.new("TextButton")
    saveGuiBtn.Size = UDim2.new(0,100,0,25)
    saveGuiBtn.Position = UDim2.new(1,-110,0,5)
    saveGuiBtn.BackgroundColor3 = Color3.fromRGB(0,170,255)
    saveGuiBtn.Text = "Save GUI Pos"
    saveGuiBtn.Parent = mainFrame
    saveGuiBtn.MouseButton1Click:Connect(function()
        saveData("MainFramePos", {
            XScale = mainFrame.Position.X.Scale,
            XOffset = mainFrame.Position.X.Offset,
            YScale = mainFrame.Position.Y.Scale,
            YOffset = mainFrame.Position.Y.Offset
        })
    end)

    -- === FLOAT BUTTON ===
    local floatBtn = Instance.new("TextButton")
    floatBtn.Size = UDim2.new(0,200,0,40)
    floatBtn.Position = UDim2.new(0,10,0,40)
    floatBtn.BackgroundColor3 = Color3.fromRGB(0,0,255)
    floatBtn.TextColor3 = Color3.fromRGB(255,255,255)
    floatBtn.Text = "Float: OFF"
    floatBtn.Parent = mainFrame

    local floatPart, flying = nil, false
    local horizontalSpeed, verticalSpeed = 25, 3

    local function createFloatPart()
        if not character:FindFirstChild("HumanoidRootPart") then return end
        floatPart = Instance.new("Part")
        floatPart.Size = Vector3.new(6,1,6)
        floatPart.Anchored = true
        floatPart.CanCollide = true
        floatPart.Material = Enum.Material.Neon
        floatPart.Color = Color3.fromRGB(0,0,255)
        floatPart.CFrame = hrp.CFrame - Vector3.new(0, hrp.Size.Y/2 + floatPart.Size.Y/2, 0)
        floatPart.Parent = workspace
        flying = true
    end

    local function disableFloat()
        if floatPart then floatPart:Destroy() end
        floatPart, flying = nil, false
    end

    floatBtn.MouseButton1Click:Connect(function()
        if flying then
            disableFloat()
            floatBtn.Text = "Float: OFF"
        else
            createFloatPart()
            floatBtn.Text = "Float: ON"
        end
    end)

    RunService.RenderStepped:Connect(function(dt)
        if flying and floatPart and hrp then
            local pos, target = floatPart.Position,
                Vector3.new(hrp.Position.X, hrp.Position.Y - hrp.Size.Y/2 - floatPart.Size.Y/2, hrp.Position.Z)
            floatPart.Position = Vector3.new(
                pos.X + (target.X-pos.X)*math.clamp(horizontalSpeed*dt,0,1),
                pos.Y + (target.Y-pos.Y)*math.clamp(verticalSpeed*dt,0,1),
                pos.Z + (target.Z-pos.Z)*math.clamp(horizontalSpeed*dt,0,1)
            )
        end
    end)

    -- === AUTO WALK BUTTON ===
    local walkBtn = Instance.new("TextButton")
    walkBtn.Size = UDim2.new(0,200,0,40)
    walkBtn.Position = UDim2.new(0,10,0,90)
    walkBtn.BackgroundColor3 = Color3.fromRGB(0,255,0)
    walkBtn.Text = "Auto Walk: OFF"
    walkBtn.Parent = mainFrame

    local savePosBtn = Instance.new("TextButton")
    savePosBtn.Size = UDim2.new(0,200,0,30)
    savePosBtn.Position = UDim2.new(0,10,0,140)
    savePosBtn.BackgroundColor3 = Color3.fromRGB(0,170,255)
    savePosBtn.Text = "Save Walk Position"
    savePosBtn.Parent = mainFrame

    local savedWalkPosition = loadData("AutoWalkTarget")
    local walking, speedBoost = false, 1

    savePosBtn.MouseButton1Click:Connect(function()
        savedWalkPosition = hrp.Position
        saveData("AutoWalkTarget", hrp.Position)
    end)

    local function walkToPosition(targetPos)
        if not targetPos or humanoid.Health <= 0 then return end
        humanoid.WalkSpeed = 16 + speedBoost
        while walking and humanoid.Health > 0 do
            local path = PathfindingService:CreatePath()
            path:ComputeAsync(hrp.Position, targetPos)
            local waypoints = path:GetWaypoints()
            if #waypoints == 0 then break end
            for _, wp in ipairs(waypoints) do
                if not walking then break end
                humanoid:MoveTo(wp.Position)
                local reached = humanoid.MoveToFinished:Wait(2)
                if not reached then break end
            end
            if (hrp.Position - targetPos).Magnitude < 5 then
                walking = false
                walkBtn.Text = "Auto Walk: OFF"
                humanoid.WalkSpeed = 16
                return
            end
            task.wait(0.5)
        end
        humanoid.WalkSpeed = 16
    end

    walkBtn.MouseButton1Click:Connect(function()
        walking = not walking
        walkBtn.Text = walking and "Auto Walk: ON" or "Auto Walk: OFF"
        if walking then
            task.spawn(function()
                while walking and humanoid.Health > 0 do
                    if savedWalkPosition then
                        walkToPosition(savedWalkPosition)
                    end
                    task.wait(1)
                end
            end)
        else
            humanoid.WalkSpeed = 16
        end
    end)

    -- === FLOAT V2 BUTTON ===
    local floatV2Btn = Instance.new("TextButton")
    floatV2Btn.Size = UDim2.new(0,200,0,40)
    floatV2Btn.Position = UDim2.new(0,10,0,180)
    floatV2Btn.BackgroundColor3 = Color3.fromRGB(255,0,0)
    floatV2Btn.Text = "Float V2: OFF"
    floatV2Btn.Parent = mainFrame

    local flyingV2, flySpeed = false, 20
    floatV2Btn.MouseButton1Click:Connect(function()
        flyingV2 = not flyingV2
        floatV2Btn.Text = flyingV2 and "Float V2: ON" or "Float V2: OFF"
    end)

    RunService.RenderStepped:Connect(function()
        if flyingV2 and humanoid.Health > 0 and hrp then
            local lookDir = workspace.CurrentCamera.CFrame.LookVector
            hrp.Velocity = lookDir * flySpeed + Vector3.new(0, -2, 0)
        end
    end)
end

-- Run once
initScript(player.Character or player.CharacterAdded:Wait())

-- Re-run on respawn
player.CharacterAdded:Connect(function(char)
    task.wait(1)
    if playerGui:FindFirstChild("StealBrainrotGui") then
        playerGui.StealBrainrotGui:Destroy()
    end
    initScript(char)
end)
