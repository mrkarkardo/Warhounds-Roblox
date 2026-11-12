-- WARHOUNDS ShotEffects: observer-side rendering of another player's shots.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Effects = require(ReplicatedStorage:WaitForChild("WeaponEffects"))
local Stats = require(ReplicatedStorage:WaitForChild("WeaponStats"))
local ShotFired = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ShotFired")

-- ShotFired sends one result per pellet. Consecutive pellets of the same shot share one
-- muzzle flash, one potential tracer, and one visual budget. Rifle events are one pellet.
local byShooter = setmetatable({}, { __mode = "k" })
local function shotContext(shooter, weapon, stats)
	local now = os.clock()
	local previous = shooter and byShooter[shooter]
	if previous and previous.weapon == weapon and previous.pelletsLeft > 0 and now - previous.at < 0.035 then
		previous.pelletsLeft -= 1
		return previous, false
	end
	local shot = {
		weapon = weapon,
		at = now,
		number = (previous and previous.number or 0) + 1,
		pelletsLeft = math.max((stats and stats.Pellets or 1) - 1, 0),
		budget = Effects.ShotBudget(),
	}
	if shooter then byShooter[shooter] = shot end
	return shot, true
end

ShotFired.OnClientEvent:Connect(function(shooter, muzzlePos, endPos, impacts, hitBody)
	local weapon = shooter and shooter:GetAttribute("Weapon")
	local stats = weapon and Stats[weapon]
	local shot, firstPellet = shotContext(shooter, weapon, stats)
	local class = stats and stats.Class
	if firstPellet then
		local gun = shooter and shooter:FindFirstChild("EquippedWeapon")
		local handle = gun and gun.PrimaryPart
		local muzzle = handle and handle:FindFirstChild("Muzzle")
		if muzzle then
			muzzlePos = muzzle.WorldPosition
			Effects.MuzzleFlash(muzzle.WorldCFrame, class, shot.budget)
			if stats and stats.Sounds then Effects.PlaySound(stats.Sounds.Fire, handle, 0.8, 400) end
		end
		if muzzlePos and endPos then Effects.Tracer(muzzlePos, endPos, class, shot.number) end
	end
	for _, impact in ipairs(impacts or {}) do Effects.Impact(impact, shot.budget) end
	if hitBody then Effects.BodyHit(endPos, shot.budget) end
end)
