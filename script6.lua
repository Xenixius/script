-- SERVICES
local ps=game:GetService("Players")
local rs=game:GetService("RunService")
local uis=game:GetService("UserInputService")
local cg=game:GetService("CoreGui")
local cam=workspace.CurrentCamera
local lp=ps.LocalPlayer

-- CONFIG
local cfg={
	aim=true,
	lock=false,
	esp=true,
	target={"Human","NPC","Both"},
	tid=3,
	fov=120,
	maxd=350
}

-- ================= UI =================
local gui=Instance.new("ScreenGui",cg)
gui.Name="IA_AimLock"

local fr=Instance.new("Frame",gui)
fr.Size=UDim2.new(0,230,0,190)
fr.Position=UDim2.new(0,20,0,20)
fr.BackgroundColor3=Color3.fromRGB(25,25,25)
fr.BorderSizePixel=0
fr.Active=true
fr.Draggable=true

local function btn(txt,y)
	local b=Instance.new("TextButton",fr)
	b.Size=UDim2.new(1,-20,0,32)
	b.Position=UDim2.new(0,10,0,y)
	b.BackgroundColor3=Color3.fromRGB(40,40,40)
	b.TextColor3=Color3.new(1,1,1)
	b.Font=Enum.Font.GothamBold
	b.TextSize=14
	b.Text=txt
	return b
end

local bAim=btn("Aim: ON",10)
local bLock=btn("AimLock: OFF (T)",52)
local bESP=btn("ESP: ON",94)

local bTar=btn("<  BOTH  >",136)

bAim.MouseButton1Click:Connect(function()
	cfg.aim=not cfg.aim
	bAim.Text="Aim: "..(cfg.aim and "ON" or "OFF")
end)

bLock.MouseButton1Click:Connect(function()
	cfg.lock=not cfg.lock
	bLock.Text="AimLock: "..(cfg.lock and "ON" or "OFF").." (T)"
end)

bESP.MouseButton1Click:Connect(function()
	cfg.esp=not cfg.esp
	bESP.Text="ESP: "..(cfg.esp and "ON" or "OFF")
end)

bTar.MouseButton1Click:Connect(function()
	cfg.tid=cfg.tid%3+1
	bTar.Text="<  "..cfg.target[cfg.tid]:upper().."  >"
end)

-- HOTKEYS
uis.InputBegan:Connect(function(k,g)
	if g then return end
	if k.KeyCode==Enum.KeyCode.LeftControl then
		gui.Enabled=not gui.Enabled
	elseif k.KeyCode==Enum.KeyCode.T then
		cfg.lock=not cfg.lock
		bLock.Text="AimLock: "..(cfg.lock and "ON" or "OFF").." (T)"
	end
end)

-- ================= HELPERS =================
local function alive(h)
	return h and h.Health>0 and h:GetState()~=Enum.HumanoidStateType.Dead
end

local function isPlayerModel(m)
	return ps:GetPlayerFromCharacter(m)
end

local function enemyPlayer(plr)
	if not plr or not lp.Team then return true end
	return plr.Team~=lp.Team
end

local function validModel(m)
	local h=m:FindFirstChildOfClass("Humanoid")
	local hd=m:FindFirstChild("Head")
	if not alive(h) or not hd then return false end

	local pl=isPlayerModel(m)

	if cfg.target[cfg.tid]=="Human" and not pl then return false end
	if cfg.target[cfg.tid]=="NPC" and pl then return false end

	if pl and not enemyPlayer(pl) then return false end

	return true
end

-- ================= ESP =================
local esp={}

local function addESP(p)
	local b=Drawing.new("Square")
	b.Thickness=2
	b.Filled=false
	b.Color=Color3.new(1,0,0)
	esp[p]=b
end

local function delESP(p)
	if esp[p] then esp[p]:Remove() esp[p]=nil end
end

for _,p in ipairs(ps:GetPlayers()) do
	if p~=lp then addESP(p) end
end
ps.PlayerAdded:Connect(addESP)
ps.PlayerRemoving:Connect(delESP)

-- ================= TARGET SEARCH =================
local locked=nil

local function findTarget()
	local best,bd,bh=nil,math.huge,math.huge
	local cp=cam.CFrame.Position
	local look=cam.CFrame.LookVector
	local hfov=cfg.fov*0.5

	local function check(m)
		if not validModel(m) then return end
		local hd=m.Head
		local h=m:FindFirstChildOfClass("Humanoid")

		local v=hd.Position-cp
		local d=v.Magnitude
		if d>cfg.maxd then return end

		local ang=math.deg(math.acos(v.Unit:Dot(look)))
		if ang>hfov then return end

		if d<bd or (d==bd and h.Health<bh) then
			bd=d
			bh=h.Health
			best=hd
		end
	end

	for _,p in ipairs(ps:GetPlayers()) do
		if p~=lp and p.Character then check(p.Character) end
	end

	for _,m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") then check(m) end
	end

	return best
end

-- ================= MAIN LOOP =================
rs.RenderStepped:Connect(function()
	-- ESP
	for p,b in pairs(esp) do
		if cfg.esp and p.Character and validModel(p.Character) then
			local hd=p.Character.Head
			local s,on=cam:WorldToViewportPoint(hd.Position)
			if on then
				local d=(hd.Position-cam.CFrame.Position).Magnitude
				local sz=900/d
				b.Size=Vector2.new(sz,sz*1.5)
				b.Position=Vector2.new(s.X-sz/2,s.Y-sz*0.75)
				b.Visible=true
			else
				b.Visible=false
			end
		else
			b.Visible=false
		end
	end

	-- AIM LOCK
	if cfg.aim then
		if not cfg.lock or not locked or not locked.Parent then
			locked=findTarget()
		end
		if locked then
			cam.CFrame=CFrame.new(cam.CFrame.Position,locked.Position)
		end
	end
end)

warn("Item Asylum AimLock Loaded")
