local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets       = ReplicatedStorage:WaitForChild("Assets")
local SwordsFolder = Assets:WaitForChild("Swords")
local ItemsFolder  = Assets:WaitForChild("Items")

local DataBins = ReplicatedStorage:WaitForChild("DataBins")
local ItemData = require(DataBins:WaitForChild("ItemData"))

local IconRenderer = {}

local animCache = {}

local function prepareEffects(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
		elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail")
			or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles")
			or d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
			d.Enabled = true
		end
	end
end

local function clearViewport(viewport)
	for _, c in ipairs(viewport:GetChildren()) do
		if c:IsA("Model") or c:IsA("BasePart") or c:IsA("Camera") then
			c:Destroy()
		end
	end
end

local function getOrCreateCamera(viewport)
	local cam = viewport:FindFirstChildOfClass("Camera")
	if not cam then
		cam = Instance.new("Camera")
		cam.Parent = viewport
	end
	viewport.CurrentCamera = cam
	return cam
end

local function findPrimaryPart(model)
	if model:IsA("BasePart") then return model end
	if model.PrimaryPart then return model.PrimaryPart end
	local sw = model:FindFirstChild("Sword")
	if sw and sw:IsA("BasePart") then return sw end
	local dual = model:FindFirstChild("Dual")
	if dual and dual:IsA("BasePart") then return dual end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function frameFromPart(cam, part, fov, distMul)
	fov = fov or 70
	distMul = distMul or 1.6
	cam.FieldOfView = fov

	local maxDim = math.max(part.Size.X, part.Size.Y, part.Size.Z)
	if maxDim < 0.5 then maxDim = 1 end

	local center = part.Position
	local dist = maxDim * distMul

	cam.CFrame = CFrame.new(
		center + Vector3.new(dist * 0.45, dist * 0.35, dist * 0.95),
		center
	)
end

function IconRenderer.Render3D(viewport, source, opts)
	if not viewport or not source then return nil end
	clearViewport(viewport)

	local model = source:Clone()
	if not model then return nil end
	model.Parent = viewport
	prepareEffects(model)

	local cam = getOrCreateCamera(viewport)
	local primary = findPrimaryPart(model)
	if not primary then return model, cam end

	opts = opts or {}
	frameFromPart(cam, primary, opts.fov or 70, opts.distMul or 1.6)
	return model, cam
end

function IconRenderer.RenderSword(viewport, swordName, opts)
	opts = opts or {}
	if type(swordName) ~= "string" or swordName == "" then return nil end

	local template = SwordsFolder:FindFirstChild(swordName)
	if not template then return nil end

	local model, cam = IconRenderer.Render3D(viewport, template, { fov = 70, distMul = 1.55 })
	if not model then return nil end

	if opts.shiny then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Material = Enum.Material.Neon
				d.Reflectance = math.max(d.Reflectance, 0.3)
			end
		end
	end

	if opts.ascended or opts.vfxColor then
		local Packages = ReplicatedStorage:FindFirstChild("Packages")
		local sv = Packages and Packages:FindFirstChild("SwordVisuals")
		if sv then
			local ok, mod = pcall(require, sv)
			if ok and mod and mod.Apply then
				pcall(function()
					mod.Apply(model, { Ascension = true, VFXColor = opts.vfxColor })
				end)
			end
		end
	end

	return model, cam
end

function IconRenderer.RenderAura(viewport, auraName)
	if type(auraName) ~= "string" or auraName == "" then return nil end
	local template = ItemsFolder:FindFirstChild(auraName)
	if not template then return nil end
	if not (template:IsA("Model") or template:IsA("BasePart")) then return nil end

	local model, cam = IconRenderer.Render3D(viewport, template, { fov = 50, distMul = 1.7 })
	if not model then return nil end

	local hum = model:FindFirstChildOfClass("Humanoid") or model:FindFirstChildWhichIsA("Humanoid", true)
	if hum then
		local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("UpperTorso") or model:FindFirstChildWhichIsA("BasePart", true)
		if hrp and cam then
			frameFromPart(cam, hrp, 50, 2.4)
		end
	end

	return model, cam
end

local function rigTemplate()
	local rig = Assets:FindFirstChild("CharacterRigR15")
	if rig and rig:IsA("Model") then return rig end
	return nil
end

local function getAnimation(animId)
	if animCache[animId] ~= nil then
		return animCache[animId] or nil
	end
	local ok, objs = pcall(game.GetObjects, game, "rbxassetid://" .. tostring(animId))
	if not ok or not objs or not objs[1] then
		animCache[animId] = false
		return nil
	end
	local obj = objs[1]
	if obj:IsA("Animation") then
		animCache[animId] = obj
		return obj
	end
	if obj:IsA("KeyframeSequence") then
		local a = Instance.new("Animation")
		a.AnimationId = "rbxassetid://" .. tostring(animId)
		animCache[animId] = a
		return a
	end
	animCache[animId] = false
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
	if not clone then return nil end
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
				track:Play(0.01)
				track.TimePosition = 0.25
				track:AdjustSpeed(0)
				animator:StepAnimations(0.001)
			end)
		end
	end

	local cam = getOrCreateCamera(viewport)
	cam.FieldOfView = 45

	local hrp = clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChild("UpperTorso") or clone:FindFirstChildWhichIsA("BasePart", true)
	if hrp then
		local maxDim = math.max(hrp.Size.X, hrp.Size.Y, hrp.Size.Z)
		if maxDim < 0.5 then maxDim = 1 end
		local dist = 6.5
		local center = hrp.Position
		cam.CFrame = CFrame.new(
			center + Vector3.new(dist * 0.35, dist * 0.15, dist),
			center
		)
	end

	return clone, cam
end

function IconRenderer.GetEnchantImage(enchName)
	local ok, EnchantData = pcall(function()
		return require(ReplicatedStorage.DataBins:WaitForChild("EnchantData"))
	end)
	if not ok or type(EnchantData) ~= "table" then return nil end
	local data = EnchantData[enchName]
	if type(data) == "table" then
		return data.ImageId or data.Icon or data.IconImage
	end
	return nil
end

function IconRenderer.GetItemImage(itemName)
	local data = ItemData[itemName]
	if type(data) == "table" then
		return data.ImageId or data.Icon or data.IconImage
	end
	return nil
end

return IconRenderer
