local shared = odh_shared_plugins

if not shared or type(shared.CreateTab) ~= "function" then
	warn("[Bomb Jump+] Load through the current Overdrive H plugin menu.")
	return
end

-- Try your BJ icon first, then the Debug icon that already works, then no icon.
local ok, my_tab = pcall(function()
	return shared.CreateTab("Bomb Jump+", "/Devon67retro/BJ/refs/heads/main/icon.png")
end)
if not ok or not my_tab then
	ok, my_tab = pcall(function()
		return shared.CreateTab("Bomb Jump+", "/Devon67retro/Debug/refs/heads/main/icon")
	end)
end
if not ok or not my_tab then
	ok, my_tab = pcall(function()
		return shared.CreateTab("Bomb Jump+")
	end)
end
if not ok or not my_tab then
	warn("[Bomb Jump+] CreateTab failed: " .. tostring(my_tab))
	return
end

local ok2, section = pcall(function()
	return my_tab:AddSection("Bomb Jump+", "MM2 / MMV")
end)
if not ok2 or not section then return end

local function note(msg)
	pcall(function() shared.Notify(msg, 4) end)
end

local isModded = (shared.game_name == "Murder Mystery Modded")

-- ===== TOGGLES FIRST: nothing above can fail, so they always appear =====
local impl = {
	ready = false,
	desired = {},
}
local replay = {}

local function safeCall(fn, ...)
	if type(fn) ~= "function" then return end
	local okA, errA = pcall(fn, ...)
	if not okA then note("Error: " .. tostring(errA)) end
end

local function addToggle(label, key, handler)
	table.insert(replay, { key = key, handler = handler })
	pcall(function()
		section:AddToggle(label, function(bool)
			bool = bool and true or false
			impl.desired[key] = bool
			if impl.ready then safeCall(impl[handler], bool) end
		end)
	end)
end

addToggle("Enable Auto Bomb Jump", "bj", "setBJ")
addToggle("Auto-Get Fake Bomb", "bjAuto", "setBJAuto")

if isModded then
	addToggle("Enable Auto Gold Bomb Jump", "gbj", "setGBJ")
	addToggle("Auto-Get Gold Bomb", "gbjAuto", "setGBJAuto")
end

addToggle("Move Cooldown Windows", "move", "setMove")

pcall(function()
	-- Saves only on a user flip after load (never from the hub restoring state on join)
	section:AddToggle("Save Cooldown Positions", function(bool)
		if bool and impl.ready then safeCall(impl.savePos) end
	end)
end)

pcall(function()
	section:AddKeybind("Bomb Jump Keybind", "E", function()
		if impl.ready and impl.bj then safeCall(impl.bj.fire) end
	end)
end)

if isModded then
	pcall(function()
		section:AddKeybind("Gold Bomb Jump Keybind", "G", function()
			if impl.ready and impl.gbj then safeCall(impl.gbj.fire) end
		end)
	end)
end

pcall(function() section:AddLabel("Bomb Jump logic by @lzzzx") end)

-- ===== Everything else, guarded; errors are shown on screen =====
local function init()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local HttpService = game:GetService("HttpService")
	local SoundService = game:GetService("SoundService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Workspace = game:GetService("Workspace")
	local LocalPlayer = Players.LocalPlayer
	local pg = LocalPlayer:WaitForChild("PlayerGui")

	local BJ_COOLDOWN = 22
	local GBJ_COOLDOWN = 4
	local LAUNCH_POWER = 58
	local TAP_MOVE = 10
	local TAP_TIME = 0.3
	local POS_FILE = "BombJump_CDPos.json"

	local MY_ID = tostring(os.clock()) .. tostring(math.random(1000, 9999))
	pcall(function() LocalPlayer:SetAttribute("BombJumpRunId", MY_ID) end)
	local function isCurrent()
		local okA, v = pcall(function() return LocalPlayer:GetAttribute("BombJumpRunId") end)
		if not okA then return true end
		return v == MY_ID
	end

	local moveMode = false
	local boxGui = nil
	local boxes = {}

	-- ===== Saved cooldown-window positions =====
	local positions = {}
	pcall(function()
		if isfile and readfile and isfile(POS_FILE) then
			local d = HttpService:JSONDecode(readfile(POS_FILE))
			if type(d) == "table" then positions = d end
		end
	end)

	local function savedPosFor(id)
		local p = positions[id]
		if type(p) == "table" and type(p.x) == "number" and type(p.y) == "number" then
			return UDim2.fromScale(math.clamp(p.x, 0, 0.95), math.clamp(p.y, 0, 0.95))
		end
		return nil
	end

	pcall(function()
		local o = pg:FindFirstChild("BombJumpLiteGui")
		if o then o:Destroy() end
	end)

	local function ensureGui()
		if boxGui and boxGui.Parent then return end
		boxGui = Instance.new("ScreenGui")
		boxGui.Name = "BombJumpLiteGui"
		boxGui.ResetOnSpawn = false
		boxGui.IgnoreGuiInset = true
		boxGui.DisplayOrder = 999
		boxGui.Parent = pg
	end

	-- ===== Cooldown window (same style as the Firefly one) =====
	-- Hidden until the first jump, then always visible:
	-- counting during the cooldown, "Active" the rest of the time.
	local function makeBox(id, prefix, defaultPos)
		local B = {}
		local label = nil
		local hasCd = false
		local token = 0
		local cdEnd = 0

		local function refresh()
			if not label then return end
			if moveMode then
				label.Visible = true
				label.Text = prefix .. (hasCd and " Active" or " CD 0.0")
			elseif hasCd then
				label.Visible = true
				label.Text = prefix .. " Active"
			else
				label.Visible = false
			end
		end

		local function ensure()
			ensureGui()
			if label and label.Parent then return end
			label = Instance.new("TextLabel")
			label.Name = id
			label.Position = savedPosFor(id) or defaultPos
			label.Size = UDim2.fromOffset(150, 44)
			label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			label.BackgroundTransparency = 0.5
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.Font = Enum.Font.GothamBold
			label.TextSize = 22
			label.Text = ""
			label.Visible = false
			label.Active = moveMode
			label.Parent = boxGui
			pcall(function() Instance.new("UICorner", label) end)

			local dragging, dragStart, startPos = false, nil, nil
			label.InputBegan:Connect(function(input)
				if not moveMode or not isCurrent() then return end
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
					dragStart = input.Position
					startPos = label.Position
					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then dragging = false end
					end)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if not dragging or not moveMode or not isCurrent() then return end
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
					local d = input.Position - dragStart
					label.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
				end
			end)
		end

		function B.start(duration)
			ensure()
			token = token + 1
			local my = token
			hasCd = true
			local t0 = os.clock()
			cdEnd = t0 + duration
			label.Visible = true
			task.spawn(function()
				while my == token and isCurrent() do
					local e = os.clock() - t0
					if e >= duration then break end
					if label then label.Text = string.format("%s CD %.1f", prefix, e) end
					RunService.Heartbeat:Wait()
				end
				if my == token then refresh() end
			end)
		end

		-- show = true -> box shows "Active"; false -> box hides
		function B.reset(show)
			token = token + 1
			cdEnd = 0
			hasCd = show and true or false
			if show then ensure() end
			refresh()
		end

		function B.hide()
			B.reset(false)
		end

		function B.setMove()
			ensure()
			label.Active = moveMode
			if os.clock() >= cdEnd then refresh() end
		end

		function B.capture()
			if not (label and boxGui) then return false end
			local size = boxGui.AbsoluteSize
			if size.X <= 0 or size.Y <= 0 then return false end
			local lp = label.Position
			positions[id] = {
				x = math.clamp(lp.X.Scale + lp.X.Offset / size.X, 0, 0.95),
				y = math.clamp(lp.Y.Scale + lp.Y.Offset / size.Y, 0, 0.95),
			}
			return true
		end

		table.insert(boxes, B)
		return B
	end

	-- ===== Shared helpers (same logic as the original script) =====
	local clickSound = Instance.new("Sound")
	clickSound.SoundId = "rbxassetid://6895079853"
	clickSound.Volume = 1.0
	local function playClick()
		pcall(function() SoundService:PlayLocalSound(clickSound) end)
	end

	local function invokeToy(name)
		pcall(function()
			ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(name)
		end)
	end

	local function isInAir()
		local character = LocalPlayer.Character
		if not character then return false end
		local humanoid = character:FindFirstChild("Humanoid")
		local root = character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root then return false end
		local state = humanoid:GetState()
		if state == Enum.HumanoidStateType.Jumping
			or state == Enum.HumanoidStateType.FallingDown
			or state == Enum.HumanoidStateType.Freefall then
			return true
		end
		return math.abs(root.AssemblyLinearVelocity.Y) > 0.5
	end

	-- ===== One jumper = one bomb type (Fake Bomb / Gold Bomb) =====
	local function makeJumper(cfg)
		local J = {
			box = cfg.box,
			enabled = false,
			autoGet = false,
			onCooldown = false,
			debounce = false,
			justRespawned = false,
		}
		local cdToken = 0
		local touches = {}

		function J.reset()
			cdToken = cdToken + 1
			J.onCooldown = false
			cfg.box.reset(J.enabled)
		end

		function J.startCooldown()
			cdToken = cdToken + 1
			local my = cdToken
			J.onCooldown = true
			J.debounce = false
			cfg.box.start(cfg.cooldown)
			task.delay(cfg.cooldown, function()
				if my == cdToken and J.onCooldown then J.reset() end
			end)
		end

		local function getTool()
			local character = LocalPlayer.Character
			if not character then return nil end

			local tool = character:FindFirstChild(cfg.tool)
			if tool then return tool end

			local backpack = LocalPlayer:FindFirstChild("Backpack")
			if backpack then
				tool = backpack:FindFirstChild(cfg.tool)
				if tool then
					tool.Parent = character
					return tool
				end
			end

			invokeToy(cfg.tool)

			for _ = 1, 5 do
				tool = character:FindFirstChild(cfg.tool)
				if tool then return tool end
				backpack = LocalPlayer:FindFirstChild("Backpack")
				if backpack then
					tool = backpack:FindFirstChild(cfg.tool)
					if tool then
						tool.Parent = character
						return tool
					end
				end
				task.wait(0.05)
			end
			return nil
		end

		function J.fire()
			if not isCurrent() then return end
			if not isInAir() then return end
			if J.onCooldown or J.debounce or J.justRespawned then return end
			J.debounce = true

			local tool = getTool()
			if tool then
				local char = LocalPlayer.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root then
					local cam = Workspace.CurrentCamera
					local pos = root.Position + (cam.CFrame.LookVector * 5)

					local remote = tool:FindFirstChild("Remote")
					if remote then
						playClick()
						pcall(function()
							remote:FireServer(CFrame.new(pos), 50)
						end)
					end

					local v = root.AssemblyLinearVelocity
					root.AssemblyLinearVelocity = Vector3.new(v.X, LAUNCH_POWER, v.Z)

					local hum = char:FindFirstChild("Humanoid")
					if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end

					-- put the bomb back in the backpack
					task.spawn(function()
						task.wait(0.5)
						local c = LocalPlayer.Character
						local t = c and c:FindFirstChild(cfg.tool)
						if t then t.Parent = LocalPlayer:FindFirstChild("Backpack") or c end
					end)

					task.spawn(function()
						task.wait(0.1)
						J.startCooldown()
					end)
				end
			end

			task.spawn(function()
				task.wait(0.5)
				J.debounce = false
			end)
		end

		-- tap anywhere while holding the bomb in the air
		UserInputService.InputBegan:Connect(function(input, gp)
			if gp or not isCurrent() then return end
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				touches[input] = { pos = input.Position, t = tick(), moved = false }
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			local data = touches[input]
			if data and (input.Position - data.pos).Magnitude > TAP_MOVE then
				data.moved = true
			end
		end)
		UserInputService.InputEnded:Connect(function(input, gp)
			if gp then
				touches[input] = nil
				return
			end
			local data = touches[input]
			if data and isCurrent() and not data.moved and tick() - data.t <= TAP_TIME then
				if J.enabled and not J.onCooldown and not J.debounce then
					local char = LocalPlayer.Character
					if char and char:FindFirstChild(cfg.tool) and isInAir() then
						J.fire()
					end
				end
			end
			touches[input] = nil
		end)

		-- respawn: cancel the cooldown, block jumps for a second, re-grab the bomb
		LocalPlayer.CharacterAdded:Connect(function()
			if not isCurrent() then return end
			J.reset()
			touches = {}
			J.justRespawned = true
			task.wait(1)
			J.justRespawned = false
			if J.autoGet then
				task.wait(0.2)
				invokeToy(cfg.tool)
			end
		end)

		return J
	end

	local bj = makeJumper({
		tool = "FakeBomb",
		cooldown = BJ_COOLDOWN,
		box = makeBox("bj", "BJ", UDim2.new(0, 20, 0.5, 0)),
	})
	impl.bj = bj

	local gbj = nil
	if isModded then
		gbj = makeJumper({
			tool = "GoldBomb",
			cooldown = GBJ_COOLDOWN,
			box = makeBox("gbj", "GBJ", UDim2.new(0, 20, 0.5, 52)),
		})
		impl.gbj = gbj
	end

	-- ===== Toggle handlers =====
	impl.setBJ = function(b)
		if not isCurrent() then return end
		bj.enabled = b
		if not b then bj.box.hide() end
	end

	impl.setBJAuto = function(b)
		if not isCurrent() then return end
		bj.autoGet = b
		if b then invokeToy("FakeBomb") end
	end

	if gbj then
		impl.setGBJ = function(b)
			if not isCurrent() then return end
			gbj.enabled = b
			if not b then gbj.box.hide() end
		end
		impl.setGBJAuto = function(b)
			if not isCurrent() then return end
			gbj.autoGet = b
			if b then invokeToy("GoldBomb") end
		end
	end

	impl.setMove = function(b)
		if not isCurrent() then return end
		moveMode = b
		for _, B in ipairs(boxes) do B.setMove() end
	end

	impl.savePos = function()
		if not isCurrent() then return end
		ensureGui()
		for _, B in ipairs(boxes) do B.setMove() end
		local any = false
		for _, B in ipairs(boxes) do
			if B.capture() then any = true end
		end
		if not any then return end
		local wrote = false
		pcall(function()
			if writefile then
				writefile(POS_FILE, HttpService:JSONEncode(positions))
				wrote = true
			end
		end)
		if wrote then
			note("Cooldown positions saved")
		else
			note("Positions kept for this session (executor can't save files)")
		end
	end
end

local okInit, errInit = xpcall(init, function(e) return tostring(e) end)
if not okInit then
	note("Init error: " .. tostring(errInit))
	warn("[Bomb Jump+] init failed: " .. tostring(errInit))
else
	impl.ready = true
	note("Bomb Jump+ loaded (" .. tostring(shared.game_name) .. ")")
	for _, r in ipairs(replay) do
		if impl.desired[r.key] then safeCall(impl[r.handler], true) end
	end
end
