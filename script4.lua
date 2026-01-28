-- SERVICES
local ps = game:GetService("Players")
local rs = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local cg = game:GetService("CoreGui")
local cam = workspace.CurrentCamera
local lp = ps.LocalPlayer

-- SETTINGS
local cfg = {
	Aimbot = {
		Enabled = true,
		FOV = 120,
		MaxDist = 300,
		Target = "Both"
	},
	ESP = {
		Enabled = true,
		Snapline = true
	}
}

-- UI
local gui = Instance.new("ScreenGui", cg)
gui.Name = "FastUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,200,0,130)
frame.Position = UDim2.new(0,20,0,20)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local function label(txt,y)
	local l = Instance.new("TextLabel", frame)
	l.Size = UDim2.new(1,0,0,25)
	l.Position = UDim2.new(0,0,0,y)
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.new(1,1,1)
	l.Font = Enum.Font.GothamBold
	l.TextSize = 14
	l.Text = txt
	return l
end

local t1 = label("Aimbot: ON",0)
local t2 = label("ESP: ON",25)
local t3 = label("Target: BOTH",50)
local t4 = label("LeftCtrl = Hide UI",75)

-- HOTKEYS
uis.InputBegan:Connect(function(k,g)
	if g then return end
	if k.KeyCode == Enum.KeyCode.LeftControl then
		gui.Enabled = not gui.Enabled
	elseif k.KeyCode == Enum.KeyCode.F then
		cfg.Aimbot.Enabled = not cfg.Aimbot.Enabled
		t1.Text = "Aimbot: "..(cfg.Aimbot.Enabled and "ON" or "OFF")
	elseif k.KeyCode == Enum.KeyCode.E then
		cfg.ESP.Enabled = not cfg.ESP.Enabled
		t2.Text = "ESP: "..(cfg.ESP.Enabled and "ON" or "OFF")
	elseif k.KeyCode == Enum.KeyCode.T then
		if cfg.Aimbot.Target == "Human" then cfg.Aimbot.Target="NPC"
		elseif cfg.Aimbot.Target=="NPC" then cfg.Aimbot.Target="Both"
		else cfg.Aimbot.Target="Human" end
		t3.Text="Target: "..cfg.Aimbot.Target:upper()
	end
end)

-- HELPERS
local function alive(h)
	return h and h.Health > 0
end

local function isPlayer(m)
	return ps:GetPlayerFromCharacter(m)
end

local function valid(m)
	local h = m:FindFirstChildOfClass("Humanoid")
	local hd = m:FindFirstChild("Head")
	if not alive(h) or not hd then return false end

	if cfg.Aimbot.Target=="Human" and not isPlayer(m) then return false end
	if cfg.Aimbot.Target=="NPC" and isPlayer(m) then return false end

	return true
end

-- ESP STORAGE
local esp = {}

local function makeESP(p)
	local box = Drawing.new("Square")
	box.Thickness = 2
	box.Filled = false
	box.Color = Color3.new(1,0,0)

	local line = Drawing.new("Line")
	line.Thickness = 1
	line.Color = Color3.new(1,1,1)

	esp[p] = {box,line}
end

local function removeESP(p)
	if esp[p] then
		for _,d in pairs(esp[p]) do d:Remove() end
		esp[p]=nil
	end
end

-- INIT ESP
for _,p in ipairs(ps:GetPlayers()) do
	if p~=lp then makeESP(p) end
end
ps.PlayerAdded:Connect(makeESP)
ps.PlayerRemoving:Connect(removeESP)

-- AIMBOT TARGET
local function getTarget()
	local best,bd,bh=nil,math.huge,math.huge
	local pos = cam.CFrame.Position
	local look = cam.CFrame.LookVector
	local fov = cfg.Aimbot.FOV*0.5

	local function scan(m)
		if not valid(m) then return end
		local hd = m.Head
		local h = m:FindFirstChildOfClass("Humanoid")

		local dir = hd.Position-pos
		local d = dir.Magnitude
		if d>cfg.Aimbot.MaxDist then return end

		local a = math.deg(math.acos(dir.Unit:Dot(look)))
		if a>fov then return end

		if d<bd or (d==bd and h.Health<bh) then
			bd=d
			bh=h.Health
			best=hd
		end
	end

	for _,p in ipairs(ps:GetPlayers()) do
		if p~=lp and p.Character then scan(p.Character) end
	end

	for _,m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") then scan(m) end
	end

	return best
end

-- MAIN LOOP
rs.RenderStepped:Connect(function()
	for p,v in pairs(esp) do
		local c = p.Character
		if cfg.ESP.Enabled and c and valid(c) then
			local hd=c.Head
			local s,on=cam:WorldToViewportPoint(hd.Position)
			if on then
				local d=(hd.Position-cam.CFrame.Position).Magnitude
				local sz=1000/d
				v[1].Size=Vector2.new(sz,sz*1.5)
				v[1].Position=Vector2.new(s.X-sz/2,s.Y-sz*0.75)
				v[1].Visible=true

				v[2].From=Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y)
				v[2].To=Vector2.new(s.X,s.Y)
				v[2].Visible=cfg.ESP.Snapline
			else
				v[1].Visible=false
				v[2].Visible=false
			end
		else
			v[1].Visible=false
			v[2].Visible=false
		end
	end

	if cfg.Aimbot.Enabled then
		local t=getTarget()
		if t then
			cam.CFrame=CFrame.new(cam.CFrame.Position,t.Position)
		end
	end
end)

warn("FAST AIMBOT + ESP LOADED")
