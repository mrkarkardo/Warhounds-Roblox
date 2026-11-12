-- WARHOUNDS WeaponClient
-- Controls: Left click = fire, Right click = aim (hold), R = reload,
--           1 = primary, 2 = secondary, mouse wheel / Q = swap.
-- Gamepad: R2 fire, L2 aim, X reload, Y swap. Mobile: on-screen Fire / Aim (toggle) / Reload / Swap.
-- The server re-checks every shot; this script handles feel: recoil, spread, effects, ammo display.
-- Works for any gun in WeaponStats (see the notes at the top of that module).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

local Stats = require(ReplicatedStorage:WaitForChild("WeaponStats"))
local Ballistics = require(ReplicatedStorage:WaitForChild("Ballistics"))
local Effects = require(ReplicatedStorage:WaitForChild("WeaponEffects"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local FireRemote = Remotes:WaitForChild("Fire")
local ReloadRemote = Remotes:WaitForChild("Reload")
local HitConfirm = Remotes:WaitForChild("HitConfirm")
local AmmoSync = Remotes:WaitForChild("AmmoSync")
local SwitchWeapon = Remotes:WaitForChild("SwitchWeapon")

local SPRINT_TO_FIRE = 0.12 -- delay before the first shot when you fire out of a sprint
local SCOPE_AT = 0.92       -- how far into aiming the scope view takes over

-- wait for the server to hand out the loadout
while not (character:GetAttribute("Weapon") and character:GetAttribute("PrimaryWeapon")) do
	if humanoid.Health <= 0 then return end
	task.wait()
end

-- per-gun ammo for this life
local guns = {}
local function gunState(name)
	local g = guns[name]
	if not g then
		local s = Stats[name]
		g = { ammo = s.MagSize, reserve = s.Reserve }
		guns[name] = g
	end
	return g
end

local weapon, stats, gun
local triggerHeld, triggerFresh, aimHeld, reloading, dead = false, false, false, false, false
local lastShot, lastTrigger, fireDelayUntil, equipUntil = 0, 0, 0, 0
local bloom, aimAmt = 0, 0
local pendingPitch, pendingYaw = 0, 0
local shotCount = 0
local reloadToken = nil

local function hud()
	local pg = player:FindFirstChild("PlayerGui")
	return pg and pg:FindFirstChild("HUD")
end

local function showAmmo()
	character:SetAttribute("Ammo", gun.ammo)
	character:SetAttribute("Reserve", gun.reserve)
end

local function stopReload()
	reloadToken = nil
	reloading = false
	character:SetAttribute("Reloading", false)
end

local function setActive(name)
	local s = Stats[name]
	if not s then return end
	stopReload()
	weapon, stats, gun = name, s, gunState(name)
	equipUntil = os.clock() + (s.EquipTime or 0.4)
	bloom, aimAmt = 0, 0
	triggerFresh = false
	character:SetAttribute("AimFov", s.AimFov)
	character:SetAttribute("Scoped", false)
	showAmmo()
end
setActive(character:GetAttribute("Weapon"))
character:GetAttributeChangedSignal("Weapon"):Connect(function()
	local name = character:GetAttribute("Weapon")
	if name and name ~= weapon then setActive(name) end
end)

local function viewmodelMuzzle()
	local vm = camera:FindFirstChild("Viewmodel")
	local handle = vm and vm.PrimaryPart
	local m = handle and handle:FindFirstChild("Muzzle")
	if m then return m.WorldCFrame, handle end
	return nil, nil
end

-- current cone of fire (degrees)
local function currentSpread()
	local sp = stats.Spread
	local vel = root.AssemblyLinearVelocity
	local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	local base = sp.Hip + (sp.Aim - sp.Hip) * aimAmt
	local move = math.clamp(speed / 22, 0, 1.5) * sp.MovePenalty * (1 - 0.8 * aimAmt)
	local air = grounded and 0 or sp.AirPenalty * (1 - 0.5 * aimAmt)
	return base + move + air + bloom * (1 - 0.6 * aimAmt)
end

local function reload()
	if reloading or dead or os.clock() < equipUntil or gun.ammo >= stats.MagSize or gun.reserve <= 0 then return end
	reloading = true
	local token = {}
	reloadToken = token
	local s, g = stats, gun
	ReloadRemote:FireServer()
	if s.ReloadPerShell then
		-- one shell at a time; firing or switching stops it
		character:SetAttribute("ReloadDuration", s.ReloadPerShell)
		character:SetAttribute("Reloading", true)
		task.spawn(function()
			while reloadToken == token and not dead do
				character:SetAttribute("ShellLoad", os.clock())
				task.wait(s.ReloadPerShell)
				if reloadToken ~= token or dead then return end
				g.ammo += 1
				g.reserve -= 1
				showAmmo()
				if g.ammo >= s.MagSize or g.reserve <= 0 then stopReload() return end
			end
		end)
	else
		local duration = (g.ammo == 0) and s.EmptyReloadTime or s.ReloadTime
		character:SetAttribute("ReloadDuration", duration)
		character:SetAttribute("Reloading", true)
		task.delay(duration, function()
			if reloadToken ~= token or dead then return end
			local take = math.min(s.MagSize - g.ammo, g.reserve)
			g.ammo += take
			g.reserve -= take
			showAmmo()
			stopReload()
		end)
	end
end

local function fire()
	if reloading then stopReload() end -- only shell reloads get here (interrupting them)
	lastShot = os.clock()
	gun.ammo -= 1
	showAmmo()
	shotCount += 1
	character:SetAttribute("ShotCount", shotCount)

	-- one direction per pellet, each random inside the spread cone
	local cone = math.rad(currentSpread())
	local camCf = camera.CFrame
	local dirs = {}
	for i = 1, (stats.Pellets or 1) do
		local a = cone * math.sqrt(math.random())
		local th = math.random() * math.pi * 2
		dirs[i] = (camCf * CFrame.Angles(math.sin(th) * a, math.cos(th) * a, 0)).LookVector
	end
	local origin = camCf.Position
	FireRemote:FireServer(origin, dirs)

	-- instant local visuals (the server does the real hit check)
	local muzzleCf, handle = viewmodelMuzzle()
	local visualBudget = Effects.ShotBudget()
	if muzzleCf then
		Effects.MuzzleFlash(muzzleCf, stats.Class, visualBudget)
		if stats.Sounds and stats.Sounds.Fire then Effects.PlaySound(stats.Sounds.Fire, handle, 0.55) end
	end
	for index, dir in ipairs(dirs) do
		local result = Ballistics.Cast(origin, dir, stats.MaxRange, stats.Penetration, { character, camera })
		if muzzleCf and index == 1 then Effects.Tracer(muzzleCf.Position, result.endPos, stats.Class, shotCount) end
		for _, imp in ipairs(result.impacts) do Effects.Impact(imp, visualBudget) end
		if result.humanoid then Effects.BodyHit(result.endPos, visualBudget) end
	end

	-- recoil + bloom
	local recoilMul = 1 - (1 - stats.Recoil.AimMultiplier) * aimAmt
	pendingPitch += stats.Recoil.Up * recoilMul * (0.85 + math.random() * 0.3)
	pendingYaw += (math.random() * 2 - 1) * stats.Recoil.Side * recoilMul
	bloom = math.min(bloom + stats.Spread.BloomPerShot, stats.Spread.BloomMax)
end

local function switchTo(slot)
	if dead then return end
	local name = character:GetAttribute(slot .. "Weapon")
	if name and name ~= weapon then SwitchWeapon:FireServer(slot) end
end
local function swap()
	switchTo(weapon == character:GetAttribute("PrimaryWeapon") and "Secondary" or "Primary")
end

-- ===== scope view =====
local scopeGui = Instance.new("ScreenGui")
scopeGui.Name = "ScopeOverlay"
scopeGui.IgnoreGuiInset = true
scopeGui.ResetOnSpawn = true
scopeGui.DisplayOrder = -1 -- under the HUD
scopeGui.Enabled = false
do
	-- a clear circle with a huge black outline covers everything outside the lens
	local lens = Instance.new("Frame")
	lens.Name = "Lens"
	lens.AnchorPoint = Vector2.new(0.5, 0.5)
	lens.Position = UDim2.fromScale(0.5, 0.5)
	lens.Size = UDim2.fromScale(0.9, 0.9)
	lens.SizeConstraint = Enum.SizeConstraint.RelativeYY
	lens.BackgroundTransparency = 1
	lens.Parent = scopeGui
	Instance.new("UICorner", lens).CornerRadius = UDim.new(0.5, 0)
	local edge = Instance.new("UIStroke")
	edge.Thickness = 3000
	edge.Color = Color3.new(0, 0, 0)
	edge.Parent = lens
	local function line(name, size, pos)
		local f = Instance.new("Frame")
		f.Name = name
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Size = size
		f.Position = pos
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.BorderSizePixel = 0
		f.Parent = lens
	end
	-- duplex reticle: thick outer posts, thin center cross
	line("H", UDim2.new(1, 0, 0, 1), UDim2.fromScale(0.5, 0.5))
	line("V", UDim2.new(0, 1, 1, 0), UDim2.fromScale(0.5, 0.5))
	line("PostL", UDim2.new(0.32, 0, 0, 4), UDim2.fromScale(0.16, 0.5))
	line("PostR", UDim2.new(0.32, 0, 0, 4), UDim2.fromScale(0.84, 0.5))
	line("PostB", UDim2.new(0, 4, 0.32, 0), UDim2.fromScale(0.5, 0.84))
	local dot = Instance.new("Frame")
	dot.Name = "Dot"
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromOffset(3, 3)
	dot.BackgroundColor3 = Color3.fromRGB(220, 30, 30)
	dot.BorderSizePixel = 0
	dot.Parent = lens
end
scopeGui.Parent = player:WaitForChild("PlayerGui")

-- ===== input =====
local function onFire(_, state)
	if state == Enum.UserInputState.Begin then
		triggerHeld = true
		triggerFresh = true
		if character:GetAttribute("Sprinting") then fireDelayUntil = os.clock() + SPRINT_TO_FIRE end
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		triggerHeld = false
		triggerFresh = false
	end
	return Enum.ContextActionResult.Pass
end

local function onAim(_, state, input)
	if input and input.UserInputType == Enum.UserInputType.Touch then
		if state == Enum.UserInputState.Begin then aimHeld = not aimHeld end -- toggle on mobile
	elseif state == Enum.UserInputState.Begin then
		aimHeld = true
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		aimHeld = false
	end
	return Enum.ContextActionResult.Pass
end

local function onReload(_, state)
	if state == Enum.UserInputState.Begin then reload() end
	return Enum.ContextActionResult.Pass
end

local function onSwitch(action, state, input)
	if state ~= Enum.UserInputState.Begin and not (input and input.UserInputType == Enum.UserInputType.MouseWheel) then
		return Enum.ContextActionResult.Pass
	end
	if character:GetAttribute("MenuOpen") then return Enum.ContextActionResult.Pass end
	if action == "Primary" then switchTo("Primary")
	elseif action == "Secondary" then switchTo("Secondary")
	else swap() end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("Fire", onFire, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
ContextActionService:BindAction("Aim", onAim, true, Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL2)
ContextActionService:BindAction("Reload", onReload, true, Enum.KeyCode.R, Enum.KeyCode.ButtonX)
ContextActionService:BindAction("Primary", onSwitch, false, Enum.KeyCode.One)
ContextActionService:BindAction("Secondary", onSwitch, false, Enum.KeyCode.Two)
ContextActionService:BindAction("Swap", onSwitch, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonY, Enum.UserInputType.MouseWheel)
ContextActionService:SetTitle("Fire", "Fire")
ContextActionService:SetTitle("Aim", "Aim")
ContextActionService:SetTitle("Reload", "Reload")
ContextActionService:SetTitle("Swap", "Swap")
ContextActionService:SetPosition("Fire", UDim2.new(1, -110, 0.45, 0))
ContextActionService:SetPosition("Aim", UDim2.new(1, -190, 0.45, 0))
ContextActionService:SetPosition("Reload", UDim2.new(1, -110, 0.45, -80))
ContextActionService:SetPosition("Swap", UDim2.new(1, -190, 0.45, -80))

-- ===== server messages =====
HitConfirm.OnClientEvent:Connect(function(killed)
	local h = hud()
	local ev = h and h:FindFirstChild("ShowHitMarker")
	if ev then ev:Fire(killed) end
end)

AmmoSync.OnClientEvent:Connect(function(name, serverAmmo, serverReserve)
	if type(name) ~= "string" or not Stats[name] then return end
	local g = gunState(name)
	if name == weapon and reloading then return end
	g.ammo, g.reserve = serverAmmo, serverReserve
	if name == weapon then showAmmo() end
end)

local burstLeft = 0 -- BURST guns: shots still to come from the current trigger pull

-- ===== per frame (after the camera updates, so recoil sticks) =====
RunService:BindToRenderStep("WeaponClient", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if dead then return end
	local now = os.clock()

	-- no shooting or aiming while the Tab menu is open (you can still move) or during the match-start freeze
	if character:GetAttribute("MenuOpen") or character:GetAttribute("Frozen") then
		triggerHeld, triggerFresh, aimHeld = false, false, false
	end

	local equipping = now < equipUntil
	local wantAim = aimHeld and not equipping
	aimAmt += ((wantAim and 1 or 0) - aimAmt) * math.min(1, dt / stats.AimTime * 2.5)
	character:SetAttribute("Aiming", wantAim)
	local scoped = stats.Scope == true and wantAim and aimAmt > SCOPE_AT and not reloading
	scopeGui.Enabled = scoped
	character:SetAttribute("Scoped", scoped)

	bloom = math.max(0, bloom - stats.Spread.BloomRecover * dt)
	character:SetAttribute("Spread", currentSpread())

	local cycled = now - lastShot >= 60 / stats.RPM
	local magReloading = reloading and not stats.ReloadPerShell
	if burstLeft > 0 then
		-- a burst finishes on its own once started (stops early on empty, reload, swap or menu)
		if gun.ammo <= 0 or magReloading or equipping or character:GetAttribute("MenuOpen") then
			burstLeft = 0
		elseif cycled then
			burstLeft -= 1
			fire()
			if burstLeft == 0 then fireDelayUntil = now + (stats.BurstDelay or 0.18) end
		end
	elseif triggerHeld then
		lastTrigger = now
		local auto = stats.FireMode == "AUTO"
		local canPull = auto or triggerFresh
		if gun.ammo <= 0 then
			if canPull and not reloading then reload() end -- auto reload when you pull on empty
		elseif canPull and cycled and not magReloading and not equipping and now >= fireDelayUntil then
			triggerFresh = false
			if stats.FireMode == "BURST" then burstLeft = (stats.BurstCount or 3) - 1 end
			fire()
		end
	end
	character:SetAttribute("Firing", now - lastTrigger < 0.3)

	-- apply recoil smoothly over a few frames
	if math.abs(pendingPitch) > 1e-4 or math.abs(pendingYaw) > 1e-4 then
		local k = math.min(1, dt * 22)
		local p, y = pendingPitch * k, pendingYaw * k
		pendingPitch -= p
		pendingYaw -= y
		camera.CFrame = camera.CFrame * CFrame.Angles(math.rad(p), math.rad(y), 0)
	end
end)

-- tear down on death AND when the character is replaced without dying (leaving the range,
-- changing zone): otherwise the old bindings keep firing from a character that no longer exists
local cleanedUp = false
local function cleanup()
	if cleanedUp then return end
	cleanedUp = true
	dead = true
	reloadToken = nil
	triggerHeld, aimHeld = false, false
	if character.Parent then
		character:SetAttribute("Aiming", false)
		character:SetAttribute("Scoped", false)
	end
	scopeGui:Destroy()
	RunService:UnbindFromRenderStep("WeaponClient")
	for _, a in ipairs({ "Fire", "Aim", "Reload", "Primary", "Secondary", "Swap" }) do ContextActionService:UnbindAction(a) end
end
humanoid.Died:Connect(cleanup)
script.Destroying:Connect(cleanup)
character.AncestryChanged:Connect(function(_, parent) if not parent then cleanup() end end)
