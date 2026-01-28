-- Services [cite: 1]
local v0 = game:GetService("Players")
local v1 = game:GetService("RunService")
local v2 = game:GetService("UserInputService")
local v3 = game:GetService("TweenService")
local v4 = game:GetService("CoreGui")
local v5 = workspace.CurrentCamera
local v6 = v0.LocalPlayer

-- Configuration Table [cite: 1]
local v7 = {
    ESP = {
        Enabled = false,
        BoxColor = Color3.new(1, 0, 0.3),
        DistanceColor = Color3.new(1, 1, 1),
        HealthGradient = {Color3.new(0, 1, 0), Color3.new(1, 1, 0), Color3.new(1, 0, 0)},
        SnaplineEnabled = true,
        SnaplinePosition = "Center",
        RainbowEnabled = false
    },
    Aimbot = {
        Enabled = false, 
        FOV = 100, 
        MaxDistance = 500, 
        ShowFOV = false, 
        TargetPart = "Head",
        Keybind = Enum.KeyCode.LeftControl -- Added Keybind
    }
}

local v8 = 0.5
local v9 = {}

-- Setup ESP for new players 
local function v10(v371)
    if v371 == v6 then return end
    local v373 = {
        Box = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        Distance = Drawing.new("Text"),
        Snapline = Drawing.new("Line")
    }
    
    for _, v515 in pairs(v373) do
        v515.Visible = false
        if v515.Type == "Square" then
            v515.Thickness = 2
            v515.Filled = false
        end
    end
    
    v373.Box.Color = v7.ESP.BoxColor
    v373.Snapline.Color = v7.ESP.BoxColor
    v373.Distance.Size = 16
    v373.Distance.Center = true
    v373.Distance.Color = v7.ESP.DistanceColor
    v9[v371] = v373
end

-- Update ESP visuals [cite: 2, 3, 4]
local function v11(v374, v375)
    if not v7.ESP.Enabled or not v374.Character then
        for _, v460 in pairs(v375) do v460.Visible = false end
        return
    end

    local v376 = v374.Character:FindFirstChildOfClass("Humanoid")
    local v377 = v374.Character:FindFirstChild("Head")

    -- Dead Check for ESP 
    if not v376 or v376.Health <= 0 or not v377 then
        for _, v541 in pairs(v375) do v541.Visible = false end
        return
    end

    local v378, v379 = v5:WorldToViewportPoint(v377.Position)
    if not v379 then
        for _, v544 in pairs(v375) do v544.Visible = false end
        return
    end

    local v380 = (v377.Position - v5.CFrame.Position).Magnitude
    local v381 = 1000 / v380
    
    v375.Box.Size = Vector2.new(v381, v381 * 1.5)
    v375.Box.Position = Vector2.new(v378.X - (v381 / 2), v378.Y - (v381 * 0.75))
    v375.Box.Visible = true

    local v385 = v376.Health / v376.MaxHealth
    v375.HealthBar.Size = Vector2.new(4, v381 * 1.5 * v385)
    v375.HealthBar.Position = Vector2.new(v378.X + (v381 / 2) + 2, (v378.Y - (v381 * 0.75)) + (v381 * 1.5 * (1 - v385)))
    v375.HealthBar.Visible = true

    v375.Distance.Text = math.floor(v380) .. "m"
    v375.Distance.Position = Vector2.new(v378.X, v378.Y + (v381 * 0.75) + 5)
    v375.Distance.Visible = true
    
    if v7.ESP.SnaplineEnabled then
        v375.Snapline.From = Vector2.new(v378.X, v378.Y + (v381 * 0.375))
        local v441 = (v7.ESP.SnaplinePosition == "Bottom" and v5.ViewportSize.Y) or (v7.ESP.SnaplinePosition == "Top" and 0) or (v5.ViewportSize.Y / 2)
        v375.Snapline.To = Vector2.new(v5.ViewportSize.X / 2, v441)
        v375.Snapline.Visible = true
    else
        v375.Snapline.Visible = false
    end
end

-- Nearest Enemy Targeter with Dead Check [cite: 4, 5]
local function v12()
    local v395 = nil
    local v396 = v7.Aimbot.MaxDistance
    local v397 = v7.Aimbot.FOV

    for _, v429 in pairs(v0:GetPlayers()) do
        if v429 ~= v6 and v429.Character and v429.Character:FindFirstChild("Head") then
            local Hum = v429.Character:FindFirstChildOfClass("Humanoid")
            -- Dead Check 
            if Hum and Hum.Health > 0 then
                local Head = v429.Character.Head
                local ScreenPos, OnScreen = v5:WorldToViewportPoint(Head.Position)
                
                if OnScreen then
                    local MousePos = v2:GetMouseLocation()
                    local ScreenDist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                    
                    if ScreenDist <= v397 then
                        local WorldDist = (v5.CFrame.Position - Head.Position).Magnitude
                        -- Prioritize NEAREST enemy 
                        if WorldDist < v396 then
                            v396 = WorldDist
                            v395 = v429
                        end
                    end
                end
            end
        end
    end
    return v395
end

-- UI Setup (Summary of [cite: 6-15])
local v13 = Drawing.new("Circle")
v13.Thickness = 2
v13.NumSides = 100
v13.Visible = false
v13.Color = Color3.new(1, 1, 1)

local v20 = Instance.new("ScreenGui", v4)
v20.Name = "ScriptGUI"

local v26 = Instance.new("Frame", v20)
v26.Size = UDim2.new(0, 370, 0, 300)
v26.Position = UDim2.new(0, 10, 0, 10)
v26.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
v26.Active = true
v26.Draggable = true

local v52 = Instance.new("Frame", v26) -- Title bar [cite: 6]
v52.Size = UDim2.new(1, 0, 0, 30)
v52.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)

local v59 = Instance.new("TextLabel", v52)
v59.Text = "Optimized Script v1.1.0"
v59.Size = UDim2.new(1, -30, 1, 0)
v59.TextColor3 = Color3.new(1, 1, 1)

-- Main Loop [cite: 23, 24]
v1.RenderStepped:Connect(function()
    v13.Visible = v7.Aimbot.ShowFOV
    v13.Radius = v7.Aimbot.FOV
    v13.Position = v2:GetMouseLocation()

    for p, d in pairs(v9) do v11(p, d) end

    -- Aimbot execution with Keybind (Left Ctrl) [cite: 19, 24]
    if v7.Aimbot.Enabled and v2:IsKeyDown(v7.Aimbot.Keybind) then
        local Target = v12()
        if Target and Target.Character and Target.Character:FindFirstChild("Head") then
            v5.CFrame = CFrame.new(v5.CFrame.Position, Target.Character.Head.Position)
        end
    end
end)

-- Player Events [cite: 24, 25]
for _, p in ipairs(v0:GetPlayers()) do v10(p) end
v0.PlayerAdded:Connect(v10)
v0.PlayerRemoving:Connect(function(v427)
    if v9[v427] then
        for _, d in pairs(v9[v427]) do d:Remove() end
        v9[v427] = nil
    end
end)

warn("✅ Script Active: Hold Left Ctrl to Aim")
