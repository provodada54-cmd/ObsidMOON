local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local DataBins = ReplicatedStorage:WaitForChild("DataBins")
local ItemData = require(DataBins:WaitForChild("ItemData"))

local IconRenderer = {}

local SwordTradable, ItemTradable

local function ensureTradables()
	if SwordTradable and ItemTradable then return end
	local ok, TradablesUI = pcall(function()
		return require(ReplicatedFirst.Core.TradablesUI)
	end)
	if not ok or type(TradablesUI) ~= "table" then return end
	pcall(function()
		SwordTradable = TradablesUI.FromRewardType("Sword") or SwordTradable
		ItemTradable  = TradablesUI.FromRewardType("Item") or ItemTradable
	end)
end

local function clearViewport(viewport)
	for _, c in ipairs(viewport:GetChildren()) do
		if c:IsA("Model") or c:IsA("BasePart") or c:IsA("Camera") then
			c:Destroy()
		end
	end
end

function IconRenderer.RenderSword(viewport, swordName, opts)
	if not viewport or type(swordName) ~= "string" or swordName == "" then return nil end
	ensureTradables()
	if not SwordTradable then return nil end

	clearViewport(viewport)

	local ok, model, cam = pcall(function()
		return SwordTradable:SetupViewport(swordName, viewport, true)
	end)
	if not ok or not model then return nil end

	if opts and opts.shiny then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Material = Enum.Material.Neon
				d.Reflectance = math.max(d.Reflectance, 0.3)
			end
		end
	end

	return model, cam
end

function IconRenderer.RenderAura(viewport, auraName)
	if not viewport or type(auraName) ~= "string" or auraName == "" then return nil end
	ensureTradables()
	if not ItemTradable then return nil end

	clearViewport(viewport)

	local ok, model, cam = pcall(function()
		return ItemTradable:SetupViewport(auraName, viewport, true)
	end)
	if not ok or not model then return nil end

	return model, cam
end

local function rigTemplate()
	local rig = Assets:FindFirstChild("CharacterRigR15")
	if rig and rig:IsA("Model") then return rig end
	return nil
end

local function getAnimation(animId)
	local ok, objs = pcall(game.GetObjects, game, "rbxassetid://" .. tostring(animId))
	if not ok or not objs or not objs[1] then return nil end
	local obj = objs[1]
	if obj:IsA("Animation") then return obj end
	if obj:IsA("KeyframeSequence") then
		local a = Instance.new("Animation")
		a.AnimationId = "rbxassetid://" .. tostring(animId)
		return a
	end
	return nil
end

function IconRenderer.RenderPose(viewport, poseName)
	if not viewport or type(poseName) ~= "string" or poseName == "" then return nil end
	local data = ItemData[poseName]
	if type(data) ~= "table" then return nil end
	local usage = data.UsageData
	local animId = type(usage) == "table" and usage[1]
	if not animId then return nil end

	local rig = rigTemplate()
	if not rig then return nil end

	clearViewport(viewport)

	local clone = rig:Clone()
	clone.Parent = viewport

	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
		end
	end

	local hum = clone:FindFirstChildOfClass("Humanoid") or clone:FindFirstChildWhichIsA("Humanoid", true)
	if not hum then return nil end

	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end

	local animObj = getAnimation(animId)
	if animObj then
		local okTrack, track = pcall(function() return animator:LoadAnimation(animObj) end)
		if okTrack and track then
			pcall(function()
				track.Priority = Enum.AnimationPriority.Action4
				track.Looped = true
				track:Play(0)
				track.Playing = false
				animator:StepAnimations(0.15)
			end)
		end
	end

	local cam = viewport:FindFirstChildOfClass("Camera")
	if not cam then
		cam = Instance.new("Camera")
		cam.Parent = viewport
	end
	viewport.CurrentCamera = cam
	cam.FieldOfView = 45

	local cf, size = clone:GetBoundingBox()
	local maxDim = math.max(size.X, size.Y, size.Z)
	if maxDim < 0.01 then maxDim = 1 end
	local dist = (maxDim * 0.5) / (math.tan(math.rad(45) * 0.5) * 0.75)
	local dir = CFrame.Angles(math.rad(-10), math.rad(25), 0) * Vector3.new(0, 0, dist)
	cam.CFrame = CFrame.lookAt(cf.Position + dir, cf.Position)

	return clone, cam
end

return IconRenderer
