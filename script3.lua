local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Config = {
    ESP = {
        Enabled = false,
        BoxColor = Color3.new(1, 0, 0),
        DistanceColor = Color3.new(1,1,1),
        HealthGradient = {Color3.new(0,1,0), Color3.new(1,1,0), Color3.new(1,0,0)},
        SnaplineEnabled = true,
        SnaplinePosition = "Center",
        RainbowEnabled = false,
    },
    Aimbot = {
        Enabled = false,
        FOV = 50,
        MaxDistance = 200,
        ShowFOV = false,
        TargetPart = "Head",
        RequireKey = true, -- require key hold (LeftControl)
    }
}

local hueSpeed = 0.5
local drawings = {}

local function createESPForPlayer(plr)
    if plr == LocalPlayer then return end
    local d = {
        Box = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        Distance = Drawing.new("Text"),
        Snapline = Drawing.new("Line"),
    }
    d.HealthBar.Filled = true
    d.Distance.Center = true
    d.Distance.Size = 16
    for _, obj in pairs(d) do
        obj.Visible = false
        if obj.Type == "Square" then
            obj.Thickness = 2
            obj.Filled = false
        end
    end
    d.Box.Color = Config.ESP.BoxColor
    d.Snapline.Color = Config.ESP.BoxColor
    drawings[plr] = d
end

local function updateESPForPlayer(plr, d)
    if not Config.ESP.Enabled or not plr.Character then
        for _, obj in pairs(d) do obj.Visible = false end
        return
    end
    local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
    local head = plr.Character:FindFirstChild("Head")
    if not humanoid or humanoid.Health <= 0 or not head then
        for _, obj in pairs(d) do obj.Visible = false end
        return
    end
    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then
        for _, obj in pairs(d) do obj.Visible = false end
        return
    end
    local dist = (head.Position - Camera.CFrame.Position).Magnitude
    local scale = math.clamp(1000 / math.max(dist, 1), 20, 1000)
    d.Box.Size = Vector2.new(scale, scale * 1.5)
    d.Box.Position = Vector2.new(screenPos.X - (scale/2), screenPos.Y - (scale * 0.75))
    d.Box.Visible = true

    local hpRatio = humanoid.Health / math.max(humanoid.MaxHealth, 1)
    local gradIndex = math.clamp(1 + math.floor((1 - hpRatio) * (#Config.ESP.HealthGradient - 1)), 1, #Config.ESP.HealthGradient)
    local color = Config.ESP.HealthGradient[gradIndex]
    d.HealthBar.Size = Vector2.new(4, scale * 1.5 * hpRatio)
    d.HealthBar.Position = Vector2.new(d.Box.Position.X + scale/2 + 4, d.Box.Position.Y + (scale * (1 - hpRatio)))
    d.HealthBar.Color = color
    d.HealthBar.Visible = true

    d.Distance.Text = tostring(math.floor(dist)) .. "m"
    d.Distance.Position = Vector2.new(screenPos.X, screenPos.Y + (scale * 0.4))
    d.Distance.Visible = true

    if Config.ESP.SnaplineEnabled then
        local from = Vector2.new(screenPos.X, screenPos.Y + (scale * 0.2))
        local toY = (Config.ESP.SnaplinePosition == "Bottom") and Camera.ViewportSize.Y
                    or (Config.ESP.SnaplinePosition == "Top") and 0
                    or Camera.ViewportSize.Y/2
        d.Snapline.From = from
        d.Snapline.To = Vector2.new(Camera.ViewportSize.X/2, toY)
        d.Snapline.Visible = true
    else
        d.Snapline.Visible = false
    end
end

local function getBestTarget()
    local best = nil
    local bestDist = math.huge
    local fov = Config.Aimbot.FOV
    local camLook = Camera.CFrame.LookVector
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if head and humanoid and humanoid.Health and humanoid.Health > 0 then
                local dir = (head.Position - Camera.CFrame.Position)
                local dirUnit = dir.Unit
                local angle = math.deg(math.acos(math.clamp(dirUnit:Dot(camLook), -1, 1)))
                if angle <= fov/2 then
                    local d = dir.Magnitude
                    if d <= Config.Aimbot.MaxDistance then
                        local ray = Ray.new(Camera.CFrame.Position, dirUnit * math.min(500, d))
                        local hitPart = workspace:FindPartOnRayWithWhitelist(ray, {plr.Character})
                        if hitPart and hitPart:IsDescendantOf(plr.Character) then
                            if d < bestDist then
                                bestDist = d
                                best = plr
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local showFOVCircle = Drawing.new("Circle")
showFOVCircle.Thickness = 2
showFOVCircle.NumSides = 100
showFOVCircle.Filled = false
showFOVCircle.Visible = Config.Aimbot.ShowFOV
showFOVCircle.Color = Color3.new(1,1,1)

local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "ScriptGUI"
gui.DisplayOrder = 1000

-- create ESP drawings for existing players
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then createESPForPlayer(p) end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then
        createESPForPlayer(p)
        p.CharacterAdded:Connect(function()
            if drawings[p] then
                for _, obj in pairs(drawings[p]) do pcall(function() obj:Remove() end) end
                drawings[p] = nil
            end
            createESPForPlayer(p)
        end)
        p.CharacterRemoving:Connect(function()
            if drawings[p] then
                for _, obj in pairs(drawings[p]) do pcall(function() obj:Remove() end) end
                drawings[p] = nil
            end
        end)
    end
end)
Players.PlayerRemoving:Connect(function(p)
    if drawings[p] then
        for _, obj in pairs(drawings[p]) do pcall(function() obj:Remove() end) end
        drawings[p] = nil
    end
end)

local aimKeyHeld = false
UserInputService.InputBegan:Connect(function(inp, gameProcessed)
    if gameProcessed then return end
    if inp.KeyCode == Enum.KeyCode.LeftControl then
        aimKeyHeld = true
    end
    -- keep original UI toggle on RightShift
    if inp.KeyCode == Enum.KeyCode.RightShift then
        -- toggle GUI visibility
        -- (original UI code kept elsewhere)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.LeftControl then
        aimKeyHeld = false
    end
end)

RunService.RenderStepped:Connect(function()
    showFOVCircle.Visible = Config.Aimbot.ShowFOV
    if Config.ESP.RainbowEnabled and Config.Aimbot.ShowFOV then
        local h = (tick() * hueSpeed) % 1
        showFOVCircle.Color = Color3.fromHSV(h, 1, 1)
    end
    showFOVCircle.Radius = (Config.Aimbot.FOV/2) * (Camera.ViewportSize.Y / 600)
    showFOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for plr, d in pairs(drawings) do
        pcall(function() updateESPForPlayer(plr, d) end)
    end

    if Config.Aimbot.Enabled then
        local shouldAim = not Config.Aimbot.RequireKey or aimKeyHeld
        if shouldAim then
            local target = getBestTarget()
            if target and target.Character and target.Character:FindFirstChild(Config.Aimbot.TargetPart) then
                local tpart = target.Character[Config.Aimbot.TargetPart]
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, tpart.Position)
            end
        end
    end
end)
