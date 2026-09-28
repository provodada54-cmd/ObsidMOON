local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets       = ReplicatedStorage:WaitForChild("Assets")
local SwordsFolder = Assets:WaitForChild("Swords")
local ItemsFolder  = Assets:WaitForChild("Items")

local DataBins = ReplicatedStorage:WaitForChild("DataBins")
local ItemData = require(DataBins:WaitForChild("ItemData"))

local IconRenderer = {}

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

local function computeVisibleBounds(model)
	local minV, maxV = nil, nil
	local function visit(inst)
		if inst:IsA("BasePart") and inst.Transparency < 0.95 then
			local cf = inst.CFrame
			local hs = inst.Size * 0.5
			local corners = {
				cf * CFrame.new( hs.X,  hs.Y,  hs.Z).Position,
				cf * CFrame.new(-hs.X,  hs.Y,  hs.Z).Position,
				cf * CFrame.new( hs.X, -hs.Y,  hs.Z).Position,
				cf * CFrame.new(-hs.X, -hs.Y,  hs.Z).Position,
				cf * CFrame.new( hs.X,  hs.Y, -hs.Z).Position,
				cf * CFrame.new(-hs.X,  hs.Y, -hs.Z).Position,
				cf * CFrame.new( hs.X, -hs.Y, -hs.Z).Position,
				cf * CFrame.new(-hs.X, -hs.Y, -hs.Z).Position,
			}
			for _, p in ipairs(corners) do
				if not minV then
					minV, maxV = p, p
				else
					minV = Vector3.new(math.min(minV.X, p.X), math.min(minV.Y, p.Y), math.min(minV.Z, p.Z))
					maxV = Vector3.new(math.max(maxV.X, p.X), math.max(maxV.Y, p.Y), math.max(maxV.Z, p.Z))
				end
			end
		end
		for _, child in ipairs(inst:GetChildren()) do visit(child) end
	end
	visit(model)
	return minV, maxV
end

local function frameModel(viewport, model, opts)
	opts = opts or {}
	local fov   = opts.fov   or 70
	local pad   = opts.pad   or 0.75
	local yaw   = opts.yaw   or 35
	local pitch = opts.pitch or -20

	local cam = getOrCreateCamera(viewport)
	cam.FieldOfView = fov

	local minV, maxV = computeVisibleBounds(model)
	local center, size
	if minV and maxV then
		center = (minV + maxV) * 0.5
		size = maxV - minV
	else
		local cf, sz = model:GetBoundingBox()
		center = cf.Position
		size = sz
	end

	local maxDim = math.max(size.X, size.Y, size.Z)
	if maxDim < 0.1 then maxDim = 1 end

	local halfAngle = math.rad(fov * 0.5)
	local dist = (maxDim * 0.5) / (math.tan(halfAngle) * pad)
	if dist < 1 then dist = 1 end

	local dir = CFrame.Angles(math.rad(pitch), math.rad(yaw), 0) * Vector3.new(0, 0, dist)
	cam.CFrame = CFrame.lookAt(center + dir, center)
end

function IconRenderer.Render3D(viewport, source, opts)
	if not viewport or not source then return nil end
	clearViewport(viewport)

	local model = source:Clone()
	model.Parent = viewport
	prepareEffects(model)

	frameModel(viewport, model, opts)
	return model, viewport.CurrentCamera
end

function IconRenderer.RenderSword(viewport, swordName, opts)
	opts = opts or {}
	if type(swordName) ~= "string" or swordName == "" then return nil end

	local template = SwordsFolder:FindFirstChild(swordName)
	if not template then return nil end

	local model, cam = IconRenderer.Render3D(viewport, template, {
		fov = 70, pad = 0.72, yaw = 35, pitch = -20,
	})
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
	return IconRenderer.Render3D(viewport, template, {
		fov = 50, pad = 0.78, yaw = 35, pitch = -20,
	})
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

	frameModel(viewport, clone, { fov = 50, pad = 0.8, yaw = 25, pitch = -10 })
	return clone, viewport.CurrentCamera
end

return IconRenderer
