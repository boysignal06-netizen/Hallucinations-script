-- LocalScript

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local airborneSpeed = 200

-- Function to apply the airborne speed logic
local function setupAirborneSpeed(character)
    local humanoid = character:WaitForChild("Humanoid")
    local originalWalkSpeed = humanoid.WalkSpeed

    -- Update speed every frame
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if humanoid.FloorMaterial == Enum.Material.Air then
            humanoid.WalkSpeed = airborneSpeed
        else
            humanoid.WalkSpeed = originalWalkSpeed
        end
    end)

    -- Disconnect when character dies
    humanoid.Died:Connect(function()
        if connection then
            connection:Disconnect()
        end
    end)
end

-- Initial character
if player.Character then
    setupAirborneSpeed(player.Character)
end

-- Reapply on respawn
player.CharacterAdded:Connect(function(char)
    setupAirborneSpeed(char)
end)
