-- WARHOUNDS client-side weapon effects. Callers may supply class and shot number for sizing and cadence.
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Effects = {}
local folder
local holes = {}
local MAX_HOLES = 80
local HOLE_LIFETIME = 12
local SCORCH_LIFETIME = 10
local FLASH_FRONT = "rbxassetid://102955940755279"
local FLASH_SIDE = "rbxassetid://129889449766098"
local BUILTIN_SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local AMBER = Color3.fromRGB(255, 183, 92)
local WHITE = Color3.fromRGB(255, 244, 218)
local rng = Random.new()

local flashScale = { PISTOLS = 0.72, LMGS = 1.22, ["SNIPER RIFLES"] = 1.25 }
local surfaceKinds = {}
for name, materials in pairs({
	Concrete = { "Concrete", "Brick", "Rock", "Slate", "Cobblestone", "Limestone", "Granite", "Basalt", "Sandstone", "Pavement", "Asphalt" },
	Metal = { "Metal", "CorrodedMetal", "DiamondPlate", "Foil" },
	Wood = { "Wood", "WoodPlanks" },
	Dirt = { "Ground", "Grass", "LeafyGrass", "Sand", "Mud", "Pebble" },
	Glass = { "Glass", "Ice" },
}) do
	for _, material in ipairs(materials) do surfaceKinds[Enum.Material[material]] = name end
end

local function asset(attribute, fallback)
	local value = script:GetAttribute(attribute)
	if type(value) == "string" and value:match("^rbxassetid://%d+$") then return value end
	return fallback
end

local function getFolder()
	if folder and folder.Parent then return folder end
	folder = workspace:FindFirstChild("WeaponEffects") or Instance.new("Folder")
	folder.Name = "WeaponEffects"
	folder.Parent = workspace
	return folder
end

local function part(name, size, cf, color, material, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Parent = getFolder()
	return p
end

local function origin(name, cf, lifetime)
	local p = part(name, Vector3.one * 0.06, cf, WHITE, nil, 1)
	Debris:AddItem(p, lifetime)
	return p
end

local function attachment(parent, offset)
	local a = Instance.new("Attachment")
	a.Position = offset or Vector3.zero
	a.Parent = parent
	return a
end

local function curve(startValue, endValue)
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, startValue),
		NumberSequenceKeypoint.new(1, endValue),
	})
end

local function burst(parent, settings, count, budget)
	if budget then
		count = math.min(count, budget.remaining)
		budget.remaining -= count
	end
	if count <= 0 then return end
	local p = Instance.new("ParticleEmitter")
	p.Enabled = false
	p.Rate = 0
	for key, value in pairs(settings) do p[key] = value end
	p.Parent = parent
	p:Emit(count)
end

function Effects.ShotBudget()
	return { remaining = 30 }
end

local function smoke(parent, color, size, speed, life, count, budget)
	burst(parent, {
		Texture = asset("SmokeTexture", BUILTIN_SMOKE),
		Color = ColorSequence.new(color),
		Size = curve(size * 0.45, size),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.48),
			NumberSequenceKeypoint.new(0.24, 0.32),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Lifetime = NumberRange.new(life * 0.7, life),
		Speed = NumberRange.new(speed * 0.45, speed),
		SpreadAngle = Vector2.new(24, 24),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-45, 45),
		Acceleration = Vector3.new(0, 2.6, 0),
		Drag = 3.4,
		EmissionDirection = Enum.NormalId.Front,
		LightInfluence = 0.65,
	}, count, budget)
end

local function sparks(parent, count, budget)
	burst(parent, {
		Texture = SPARK,
		Color = ColorSequence.new(WHITE, AMBER),
		LightEmission = 0.85,
		Size = curve(0.095, 0.024),
		Transparency = curve(0.06, 1),
		Lifetime = NumberRange.new(0.06, 0.14),
		Speed = NumberRange.new(9, 20),
		SpreadAngle = Vector2.new(35, 35),
		EmissionDirection = Enum.NormalId.Front,
		Acceleration = Vector3.new(0, -10, 0),
		Drag = 3,
	}, count, budget)
end

function Effects.MuzzleFlash(muzzleCf, class, budget)
	local scale = flashScale[class] or 1
	local p = origin("MuzzleBurst", muzzleCf * CFrame.new(0, 0, -0.08), 0.85)
	local a = attachment(p)
	for _, sprite in ipairs({
		{ texture = FLASH_FRONT, size = 0.75, rotation = NumberRange.new(0, 360), speed = 0 },
		{ texture = FLASH_SIDE, size = 1.17, rotation = NumberRange.new(-9, 9), speed = 3.2 },
	}) do
		burst(a, {
			Texture = sprite.texture,
			Size = curve(sprite.size * scale, sprite.size * scale * 0.73),
			Transparency = curve(0.03, 1),
			Lifetime = NumberRange.new(0.037, 0.054),
			Rotation = sprite.rotation,
			Speed = NumberRange.new(sprite.speed),
			EmissionDirection = Enum.NormalId.Front,
			LightEmission = 1,
			LightInfluence = 0,
		}, 1, budget)
	end
	sparks(a, 3, budget)
	smoke(a, Color3.fromRGB(179, 179, 173), 0.62 * scale, 2.8, class == "LMGS" and 0.74 or 0.43, 1, budget)
	local light = Instance.new("PointLight")
	light.Name = "MuzzleLight"
	light.Color = AMBER
	light.Range = 9 * scale
	light.Brightness = 2.7 * scale
	light.Shadows = false
	light.Parent = a
	Debris:AddItem(light, 0.05)
end

function Effects.Tracer(from, to, class, shotNumber)
	if class == "SNIPER RIFLES" then return end
	if shotNumber and shotNumber % (class == "LMGS" and 3 or 5) ~= 0 then return end
	local distance = (to - from).Magnitude
	if distance < 1 then return end
	local p = origin("TracerBeam", CFrame.new(from), 0.06)
	local beam = Instance.new("Beam")
	beam.Attachment0 = attachment(p)
	beam.Attachment1 = attachment(p, to - from)
	beam.FaceCamera = true
	beam.Segments = 6
	beam.Width0 = 0.013
	beam.Width1 = 0.052
	beam.Color = ColorSequence.new(AMBER, WHITE)
	beam.LightEmission = 0.95
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.66, 0.74),
		NumberSequenceKeypoint.new(0.92, 0.19),
		NumberSequenceKeypoint.new(1, 0.09),
	})
	beam.Parent = p
end

local function rememberHole(mark)
	while #holes > 0 and (not holes[1].Parent or #holes >= MAX_HOLES) do
		local old = table.remove(holes, 1)
		if old.Parent then old:Destroy() end
	end
	table.insert(holes, mark)
end

local function markSurface(name, pos, normal, size, texture, life)
	local cf = CFrame.lookAt(pos + normal * 0.013, pos + normal)
		* CFrame.Angles(0, 0, rng:NextNumber(0, math.pi * 2))
	local mark = part(name, Vector3.new(size, size, 0.01), cf, Color3.fromRGB(31, 26, 23), nil, texture and 1 or 0.16)
	if texture then
		local decal = Instance.new("Decal")
		decal.Face = Enum.NormalId.Front
		decal.Texture = texture
		if name == "GrenadeScorch" then decal.Color3 = Color3.fromRGB(61, 53, 45) end
		decal.Parent = mark
	else
		mark.Shape = Enum.PartType.Cylinder
		mark.Size = Vector3.new(0.01, size, size)
		mark.CFrame = cf * CFrame.Angles(0, math.pi / 2, 0)
	end
	rememberHole(mark)
	Debris:AddItem(mark, life)
end

local function chips(pos, normal, color, count, size, reach, budget, material)
	if budget then
		count = math.min(count, budget.remaining)
		budget.remaining -= count
	end
	for _ = 1, count do
		local offset = Vector3.new(rng:NextNumber(-0.8, 0.8), rng:NextNumber(-0.25, 0.9), rng:NextNumber(-0.8, 0.8))
		local dir = (normal + offset).Unit
		local c = part("ImpactChip", Vector3.new(size * 0.58, size, size * 0.71),
			CFrame.new(pos + normal * 0.05) * CFrame.Angles(rng:NextNumber(), rng:NextNumber(), rng:NextNumber()),
			color, material)
		TweenService:Create(c, TweenInfo.new(0.23, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = pos + dir * rng:NextNumber(reach * 0.55, reach), Transparency = 1, Size = Vector3.one * 0.018 }):Play()
		Debris:AddItem(c, 0.25)
	end
end

function Effects.Impact(info, budget)
	if not info or typeof(info.Position) ~= "Vector3" or typeof(info.Normal) ~= "Vector3" then return end
	local pos, normal = info.Position, info.Normal
	if normal.Magnitude < 0.001 then return end
	normal = normal.Unit
	local kind = surfaceKinds[info.Material]
	local color = info.Color or Color3.fromRGB(125, 125, 120)
	if kind ~= "Dirt" and kind ~= "Glass" then
		local texture = kind and asset("Hole" .. kind .. "Texture")
		markSurface("BulletHole", pos, normal, texture and 0.25 or 0.115, texture, HOLE_LIFETIME)
	end
	if budget and budget.remaining <= 0 then return end
	local p = origin("SurfaceImpact", CFrame.lookAt(pos + normal * 0.065, pos + normal), 0.58)
	local a = attachment(p)
	if kind == "Metal" then
		sparks(a, 5, budget)
	elseif kind == "Glass" then
		chips(pos, normal, Color3.fromRGB(224, 234, 238), 4, 0.095, 1.15, budget, Enum.Material.Glass)
	elseif kind == "Dirt" then
		smoke(a, color:Lerp(Color3.fromRGB(144, 116, 81), 0.5), 0.58, 3, 0.42, 3, budget)
	elseif kind == "Wood" then
		smoke(a, color:Lerp(Color3.fromRGB(180, 154, 117), 0.52), 0.37, 1.6, 0.31, 2, budget)
		chips(pos, normal, color, 3, 0.11, 0.83, budget, Enum.Material.Wood)
	elseif kind == "Concrete" then
		smoke(a, color:Lerp(Color3.fromRGB(176, 171, 161), 0.55), 0.54, 2.7, 0.44, 3, budget)
		chips(pos, normal, color, 3, 0.09, 0.92, budget)
	else
		chips(pos, normal, color, 3, 0.10, 1, budget)
		sparks(a, 1, budget)
	end
end

function Effects.BodyHit(pos, budget)
	local p = origin("HitMist", CFrame.lookAt(pos, pos + Vector3.yAxis, Vector3.zAxis), 0.34)
	smoke(attachment(p), Color3.fromRGB(111, 29, 29), 0.32, 1.45, 0.28, 2, budget)
end

function Effects.Shell(ejectCf, caliberSize)
	local shotgun = caliberSize == "Shotgun"
	local size = tonumber(caliberSize) or (shotgun and 1.35 or 1)
	size = math.clamp(size, 0.6, 1.7)
	local p = part("SpentCasing", Vector3.new(0.18, 0.062, 0.062) * size, ejectCf,
		shotgun and Color3.fromRGB(151, 39, 29) or Color3.fromRGB(187, 146, 71),
		shotgun and Enum.Material.SmoothPlastic or Enum.Material.Metal)
	p.Shape = Enum.PartType.Cylinder
	local start = ejectCf.Position
	local velocity = ejectCf.RightVector * rng:NextNumber(3.3, 5.2) + Vector3.yAxis * rng:NextNumber(3.8, 5.1)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { getFolder() }
	local elapsed, previous = 0, start
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if not p.Parent or elapsed >= 1.45 then connection:Disconnect(); return end
		local position = start + velocity * elapsed - Vector3.yAxis * (12 * elapsed * elapsed)
		local hit = workspace:Raycast(previous, position - previous, params)
		if hit then
			p.Position = hit.Position + hit.Normal * 0.04
			connection:Disconnect()
			return
		end
		p.CFrame = CFrame.new(position) * ejectCf.Rotation * CFrame.Angles(elapsed * 9, elapsed * 12, elapsed * 6)
		previous = position
	end)
	Debris:AddItem(p, 1.5)
end

function Effects.Explosion(pos)
	local p = origin("GrenadeBurst", CFrame.lookAt(pos, pos + Vector3.yAxis, Vector3.zAxis), 1.85)
	local a = attachment(p)
	burst(a, {
		Texture = FLASH_FRONT,
		Color = ColorSequence.new(WHITE, AMBER),
		Size = curve(2.1, 5.6),
		Transparency = curve(0.02, 1),
		Lifetime = NumberRange.new(0.13, 0.22),
		LightEmission = 1,
		Rotation = NumberRange.new(0, 360),
		Speed = NumberRange.new(0),
	}, 2)
	smoke(a, Color3.fromRGB(125, 116, 105), 4.1, 5, 1.62, 8)
	for i = 1, 6 do
		local angle = i * math.pi / 3
		local dir = Vector3.new(math.cos(angle), 0.09, math.sin(angle))
		local edge = attachment(p, p.CFrame:VectorToObjectSpace(dir * 0.58))
		edge.CFrame = p.CFrame:ToObjectSpace(CFrame.lookAt(pos + dir * 0.58, pos + dir * 2))
		smoke(edge, Color3.fromRGB(161, 146, 123), 2.2, 7.4, 0.74, 2)
	end
	chips(pos, Vector3.yAxis, Color3.fromRGB(99, 86, 73), 5, 0.16, 3.1)
	local texture = asset("ScorchTexture")
	local hit = texture and workspace:Raycast(pos + Vector3.yAxis * 0.75, -Vector3.yAxis * 5)
	if hit then markSurface("GrenadeScorch", hit.Position, hit.Normal, 3.1, texture, SCORCH_LIFETIME) end
end

function Effects.PlaySound(id, parent, volume, maxDistance)
	if not id or not parent then return end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.6
	s.RollOffMaxDistance = maxDistance or 300
	s.PlaybackSpeed = 0.95 + rng:NextNumber() * 0.1
	s.Parent = parent
	s.Ended:Once(function() s:Destroy() end)
	s:Play()
	Debris:AddItem(s, 3)
end

return Effects
