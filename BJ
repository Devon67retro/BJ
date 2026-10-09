local table_insert = table.insert

local Maid = {}
Maid.__index = Maid

function Maid.new() 
    return setmetatable({_tasks = {}, _destroyed = false}, Maid) 
end

function Maid:GiveTask(task)
    if self._destroyed then
        self:_cleanupTask(task)
        return
    end
    table_insert(self._tasks, task)
    return task
end

function Maid:GiveTasks(...)
    for _, task in ipairs({...}) do
        self:GiveTask(task)
    end
end

function Maid:_cleanupTask(task)
    local taskType = typeof(task)
    if taskType == "RBXScriptConnection" then
        task:Disconnect()
    elseif taskType == "Instance" then
        task:Destroy()
    elseif taskType == "function" then
        task()
    elseif taskType == "table" and type(task.Destroy) == "function" then
        task:Destroy()
    end
end

function Maid:DoCleaning()
    if self._destroyed then return end
    self._destroyed = true
    for _, task in ipairs(self._tasks) do
        self:_cleanupTask(task)
    end
    self._tasks = {}
end

function Maid:Destroy() 
    self:DoCleaning() 
end

local RootMaid = Maid.new()

local shared = odh_shared_plugins
task.spawn(function()
    shared.load_from_github_url("/aux0on/CrashHandler/refs/heads/main/Prevention.lua")
end)

local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    StarterGui = game:GetService("StarterGui"),
    CoreGui = game:GetService("CoreGui"),
    Workspace = game:GetService("Workspace"),
    TweenService = game:GetService("TweenService"),
    SoundService = game:GetService("SoundService")
}

local LocalPlayer = Services.Players.LocalPlayer

local __PCLR = Color3.new
local __RGB = Color3.fromRGB
local __UD2 = UDim2.new
local __UD = UDim.new
local __V2 = Vector2.new

local function getfserv(s)
    local ok, svc = pcall(function() return game:GetService(s) end)
    if ok and svc then return svc end
    ok, svc = pcall(function() return game:FindService(s) end)
    if ok and svc then return svc end
    return game[s]
end

local __RS   = getfserv("RunService")
local __UIS  = getfserv("UserInputService")
local __PLRS = getfserv("Players")
local __TS   = getfserv("TweenService")

local SAVE_FILE = "BJP_BP.json"

local function savePositions(data)
    pcall(function()
        if writefile then
            writefile(SAVE_FILE, game:GetService("HttpService"):JSONEncode(data))
        end
    end)
end

local function loadPositions()
    local ok, result = pcall(function()
        if readfile and isfile and isfile(SAVE_FILE) then
            return game:GetService("HttpService"):JSONDecode(readfile(SAVE_FILE))
        end
    end)
    if ok and type(result) == "table" then return result end
    return {}
end

local savedPositions = loadPositions()

local BBSystem = {Buttons = {}, Connections = {}}

-- Declared here (before UpdateAllButtonSounds) so the function can see it
local BindableButtons = {Buttons = {}, Maids = {}, Count = 0}

local function bb_safecallback(callback)
    if not callback then return end
    local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
    if not ok then warn("[BB ERROR] " .. tostring(err)) end
end

local function BB_GetStorage()
    local parent = gethui and gethui()
    if not parent or typeof(parent) ~= "Instance" then
        parent = getfserv("CoreGui")
    end
    if not parent or typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui", 5)
    end
    if typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui")
    end

    local sg = parent:FindFirstChild("@BBStorage")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "@BBStorage"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
        sg.Parent = parent
    end
    return sg
end

local __BB_GRAD_SEQ = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    __PCLR(0.0784314, 0.0784314, 0.0784314)),
    ColorSequenceKeypoint.new(0.75, __PCLR(0.0784314, 0.0784314, 0.54902)),
    ColorSequenceKeypoint.new(1,    __PCLR(0.470588,  0.156863,  0.470588))
})

local muteButtonSounds = false
local lockBindableButtons = false
local lockBigButtons = false
local lockTimerWindows = false

-- Big button drag/press handler (no enlargement animation)
local function BB_MakeDraggable(gui, func, ripple, sound)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false

    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            hasMoved  = false
            dragStart = input.Position
            startPos  = gui.Position
            local absPos = gui.AbsolutePosition
            ripple.Position = __UD2(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
            ripple.Size = __UD2(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.5
            ripple.Visible = true
            sound:Play()
            __TS:Create(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = __UD2(0, 300, 0, 300),
                BackgroundTransparency = 1
            }):Play()
            local rel
            rel = __UIS.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == input.UserInputType then
                    dragging = false
                    if not hasMoved then bb_safecallback(func) end
                    
                    if not lockBigButtons then
                        savedPositions[gui.Name] = {
                            xs = gui.Position.X.Scale, xo = gui.Position.X.Offset,
                            ys = gui.Position.Y.Scale, yo = gui.Position.Y.Offset
                        }
                        savePositions(savedPositions)
                    end
                    
                    rel:Disconnect()
                end
            end)
        end
    end)
    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    __UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            if lockBigButtons then return end
            local delta = input.Position - dragStart
            if delta.Magnitude > 7 then hasMoved = true end
            gui.Position = __UD2(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function UpdateAllButtonSounds()
    local volume = muteButtonSounds and 0 or 0.5
    for id, btn in pairs(BBSystem.Buttons) do
        local sound = btn:FindFirstChild("Sound")
        if sound then
            sound.Volume = volume
        end
    end
    for id, btn in pairs(BindableButtons.Buttons) do
        local sound = btn:FindFirstChild("Sound")
        if sound then
            sound.Volume = volume
        end
    end
end

local function AddBigButton(id, text, func, isGold)
    if BBSystem.Buttons[id] then return end
    local storage = BB_GetStorage()
    local bb = Instance.new("TextButton")
    bb.Name = id
    bb.Size = __UD2(0, 200, 0, 75)
    
    local sp = savedPositions[id]
    if sp then
        bb.Position = __UD2(sp.xs, sp.xo, sp.ys, sp.yo)
    else
        bb.Position = __UD2(0.5, 0, 0.5, 0)
    end
    
    bb.AnchorPoint = __V2(0.5, 0.5)
    bb.BackgroundColor3 = __RGB(255, 255, 255)
    bb.BackgroundTransparency = 0.9
    bb.BorderSizePixel = 0
    bb.Font = Enum.Font.Jura
    bb.Text = text
    bb.TextSize = 24
    bb.TextColor3 = __RGB(255, 255, 255)
    bb.TextWrapped = true
    bb.ClipsDescendants = true
    bb.AutoButtonColor = false
    bb.ZIndex = 5
    bb.Parent = storage

    Instance.new("UICorner", bb).CornerRadius = __UD(0, 5)
    local stroke = Instance.new("UIStroke")
    stroke.Color = __RGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = bb
    local gradient = Instance.new("UIGradient")
    
    if isGold then
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    __RGB(255, 215, 0)),
            ColorSequenceKeypoint.new(0.5,  __RGB(255, 140, 0)),
            ColorSequenceKeypoint.new(1,    __RGB(184, 134, 11))
        })
    else
        gradient.Color = __BB_GRAD_SEQ
    end
    gradient.Parent = stroke

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = isGold and __RGB(255, 215, 0) or __RGB(0, 155, 255)
    ripple.BackgroundTransparency = 0.5
    ripple.ZIndex = 4
    ripple.Size = __UD2(0, 0, 0, 0)
    ripple.AnchorPoint = __V2(0.5, 0.5)
    ripple.Visible = false
    ripple.Parent = bb
    Instance.new("UICorner", ripple).CornerRadius = __UD(1, 0)

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://3868133279"
    sound.Volume = muteButtonSounds and 0 or 0.5
    sound.Parent = bb

    BB_MakeDraggable(bb, func, ripple, sound)
    BBSystem.Connections[id] = __RS.RenderStepped:Connect(function()
        gradient.Rotation = (gradient.Rotation + 1) % 360
    end)
    BBSystem.Buttons[id] = bb
    return bb
end

local function DeleteBigButton(id)
    if BBSystem.Buttons[id] then
        if BBSystem.Connections[id] then
            BBSystem.Connections[id]:Disconnect()
            BBSystem.Connections[id] = nil
        end
        BBSystem.Buttons[id]:Destroy()
        BBSystem.Buttons[id] = nil
    end
end

local __SHAPES = {
    [0] = "rbxassetid://86221076925479",
    [1] = "rbxassetid://96242665417546",
    [2] = "rbxassetid://97129189935336",
    [3] = "rbxassetid://76165862027868",
    [4] = "rbxassetid://125868092127496"
}

local __NORMAL_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   __PCLR(0.133333, 0.827451, 0.494118)),
    ColorSequenceKeypoint.new(0.6, __PCLR(0.231373, 0.509804, 0.498039)),
    ColorSequenceKeypoint.new(1,   __PCLR(0.501961, 0.501961, 0.501961))
})

local __WAIT_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   __PCLR(0.827451, 0.133333, 0.133333)),
    ColorSequenceKeypoint.new(0.6, __PCLR(0.509804, 0.231373, 0.231373)),
    ColorSequenceKeypoint.new(1,   __PCLR(0.501961, 0.501961, 0.501961))
})

local __GOLD_NORMAL_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   __RGB(255, 215, 0)),
    ColorSequenceKeypoint.new(0.6, __RGB(255, 140, 0)),
    ColorSequenceKeypoint.new(1,   __RGB(184, 134, 11))
})

local __GOLD_WAIT_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   __RGB(255, 69, 0)),
    ColorSequenceKeypoint.new(0.6, __RGB(139, 69, 19)),
    ColorSequenceKeypoint.new(1,   __RGB(160, 82, 45))
})

local function bind_safecallback(callback)
    if not callback then return end
    local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
    if not ok then warn("[BIND ERROR] " .. tostring(err)) end
end

local function Bind_GetStorage()
    local parent = gethui and gethui()
    if not parent or typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui", 5)
    end
    if typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui")
    end

    local sg = parent:FindFirstChild("@bindstorage")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "@bindstorage"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
        sg.Parent = parent
    end
    return sg
end

local function Bind_MakeDraggable(gui, maid, ripple, sound, clickFunc)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false
    
    maid:GiveTask(gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, gui.Position
            hasMoved = false
            sound:Play()
            local absPos = gui.AbsolutePosition
            ripple.Position = __UD2(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
            ripple.Size = __UD2(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.5
            ripple.Visible = true
            __TS:Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = __UD2(0, 45, 0, 45),
                BackgroundTransparency = 1
            }):Play()

            local rel
            rel = __UIS.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == input.UserInputType then
                    dragging = false
                    if not hasMoved then
                        bind_safecallback(clickFunc)
                    end
                    
                    if not lockBindableButtons then
                        savedPositions[gui.Name] = {
                            xs = gui.Position.X.Scale, xo = gui.Position.X.Offset,
                            ys = gui.Position.Y.Scale, yo = gui.Position.Y.Offset
                        }
                        savePositions(savedPositions)
                    end
                    
                    rel:Disconnect()
                end
            end)
        end
    end))
    
    maid:GiveTask(gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))
    
    maid:GiveTask(__UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            if lockBindableButtons then return end
            local delta = input.Position - dragStart
            if delta.Magnitude > 7 then hasMoved = true end
            local screen = gui.Parent.AbsoluteSize
            gui.Position = __UD2(startPos.X.Scale + (delta.X / screen.X), 0, startPos.Y.Scale + (delta.Y / screen.Y), 0)
        end
    end))
end

function BindableButtons.AddBButton(id, text, clickFunc, isGold)
    if BindableButtons.Buttons[id] then return end
    
    local buttonMaid = Maid.new()
    local camera = workspace.CurrentCamera
    local screen = camera.ViewportSize
    local buttonSizeY = 0.11
    local widthScale = buttonSizeY * (screen.Y / screen.X)
    
    local sp = savedPositions[id]
    local xPos, yPos
    if sp then
        xPos = sp.xs
        yPos = sp.ys
    else
        xPos = 0.1 + ((BindableButtons.Count % 8) * (widthScale + 0.005))
        yPos = 0.9 - (math.floor(BindableButtons.Count / 8) * (buttonSizeY + 0.015))
    end

    local ImageButton = Instance.new("ImageButton")
    ImageButton.Name = id
    ImageButton.Size = __UD2(widthScale, 0, buttonSizeY, 0)
    ImageButton.Position = __UD2(xPos, 0, yPos, 0)
    ImageButton.AnchorPoint = __V2(0.5, 0.5)
    ImageButton.Image = __SHAPES[0]
    ImageButton.BackgroundTransparency = 1
    ImageButton.BorderSizePixel = 0
    ImageButton.ClipsDescendants = false
    ImageButton.AutoButtonColor = false
    ImageButton.Parent = Bind_GetStorage()
    buttonMaid:GiveTask(ImageButton)

    local TextLabel = Instance.new("TextLabel", ImageButton)
    TextLabel.Name = "@Text"
    TextLabel.Size = __UD2(0.8, 0, 0.8, 0)
    TextLabel.Position = __UD2(0.5, 0, 0.5, 0)
    TextLabel.AnchorPoint = __V2(0.5, 0.5)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Font = Enum.Font.Jura
    TextLabel.Text = text
    TextLabel.TextColor3 = __PCLR(1, 1, 1)
    TextLabel.TextSize = 10
    TextLabel.TextWrapped = true
    TextLabel.ZIndex = 3

    local Aspect = Instance.new("UIAspectRatioConstraint", ImageButton)
    Aspect.AspectRatio = 1
    Aspect.AspectType = Enum.AspectType.ScaleWithParentSize

    local Stroke = Instance.new("UIGradient", ImageButton)
    Stroke.Name = "@Stroke"
    if isGold then
        Stroke.Color = __GOLD_NORMAL_COLOR
    else
        Stroke.Color = __NORMAL_COLOR
    end

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = isGold and __RGB(255, 215, 0) or __RGB(0, 155, 255)
    ripple.BackgroundTransparency = 0.5
    ripple.Size = __UD2(0, 0, 0, 0)
    ripple.AnchorPoint = __V2(0.5, 0.5)
    ripple.Visible = false
    ripple.ZIndex = 2
    ripple.Parent = ImageButton
    Instance.new("UICorner", ripple).CornerRadius = __UD(1, 0)

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://3868133279"
    sound.Volume = muteButtonSounds and 0 or 0.5
    sound.Parent = ImageButton

    Bind_MakeDraggable(ImageButton, buttonMaid, ripple, sound, clickFunc)
    buttonMaid:GiveTask(__RS.RenderStepped:Connect(function()
        Stroke.Rotation = (Stroke.Rotation + 1) % 360
    end))

    BindableButtons.Buttons[id] = ImageButton
    BindableButtons.Maids[id] = buttonMaid
    BindableButtons.Count = BindableButtons.Count + 1
    return ImageButton
end

function BindableButtons.DeleteBButton(id)
    if BindableButtons.Maids[id] then
        BindableButtons.Maids[id]:Destroy()
        BindableButtons.Maids[id] = nil
        BindableButtons.Buttons[id] = nil
    end
end

function BindableButtons.UpdateBButtonText(id, text, isWaiting, isGold)
    local btn = BindableButtons.Buttons[id]
    if not btn then return end
    
    local textLabel = btn:FindFirstChild("@Text")
    if textLabel then
        textLabel.Text = text
    end
    
    local stroke = btn:FindFirstChild("@Stroke")
    if stroke then
        if isGold then
            stroke.Color = isWaiting and __GOLD_WAIT_COLOR or __GOLD_NORMAL_COLOR
        else
            stroke.Color = isWaiting and __WAIT_COLOR or __NORMAL_COLOR
        end
    end
end

-- Small draggable cooldown window (counts up, shows "Active" when ready)
local function MakeTimerWindow(id, prefix, defaultPos)
    local label = Instance.new("TextLabel")
    label.Name = id
    label.Size = UDim2.fromOffset(110, 36)
    local sp = savedPositions[id]
    label.Position = sp and __UD2(sp.xs, sp.xo, sp.ys, sp.yo) or defaultPos
    label.BackgroundColor3 = __RGB(0, 0, 0)
    label.BackgroundTransparency = 0.5
    label.TextColor3 = __RGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 20
    label.Active = true
    label.Parent = BB_GetStorage()
    Instance.new("UICorner", label).CornerRadius = __UD(0, 6)

    local win, conns = {}, {}
    local token, conn = 0, nil

    local function idle() label.Text = prefix .. " Active" end
    idle()

    local function stopTick()
        token = token + 1
        if conn then conn:Disconnect() conn = nil end
    end

    function win.Start(duration)
        stopTick()
        local my = token
        local startT = os.clock()
        conn = __RS.Heartbeat:Connect(function()
            if my ~= token then return end
            local e = os.clock() - startT
            if e >= duration then
                stopTick()
                idle()
            else
                label.Text = string.format("%s %.1f", prefix, e)
            end
        end)
    end

    function win.Reset() stopTick() idle() end

    function win.ResetPosition()
        savedPositions[id] = nil
        savePositions(savedPositions)
        label.Position = defaultPos
    end

    function win.Destroy()
        stopTick()
        for _, c in ipairs(conns) do c:Disconnect() end
        label:Destroy()
    end

    local dragging, dragStart, startPos = false, nil, nil
    table.insert(conns, label.InputBegan:Connect(function(input)
        if lockTimerWindows then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, label.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    savedPositions[id] = {
                        xs = label.Position.X.Scale, xo = label.Position.X.Offset,
                        ys = label.Position.Y.Scale, yo = label.Position.Y.Offset
                    }
                    savePositions(savedPositions)
                end
            end)
        end
    end))
    table.insert(conns, __UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            label.Position = __UD2(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
    return win
end

local function GetSafeGuiRoot()
    local success, result = pcall(function() 
        return gethui() 
    end)
    if success and result and typeof(result) == "Instance" then
        return result
    end
    return Services.CoreGui
end

local hiddenGui = Instance.new("ScreenGui")
hiddenGui.Name = "HiddenGui"
hiddenGui.ResetOnSpawn = false
hiddenGui.IgnoreGuiInset = true
hiddenGui.Parent = GetSafeGuiRoot()
RootMaid:GiveTask(hiddenGui)

local BombJump = shared.CreateTab("Bomb Jump+", "/Devon67retro/BJ/refs/heads/main/icon.png")

local _game = shared.game_name

if _game == "Murder Mystery 2" or _game == "Murder Mystery Modded" then

local aboutSection = BombJump:AddSection("About", "Information")

aboutSection:AddParagraph("Bomb Jump+", "Plugin Made by @lzzzx")

aboutSection:AddToggle("Mute Button SFX", function(bool)
    muteButtonSounds = bool
    UpdateAllButtonSounds()
end)

aboutSection:AddToggle("Lock Bindable Buttons", function(bool)
    lockBindableButtons = bool
end)

aboutSection:AddToggle("Lock Big Buttons", function(bool)
    lockBigButtons = bool
end)

aboutSection:AddToggle("Lock Timer Windows", function(bool)
    lockTimerWindows = bool
end)

shared.Notify("Bomb Jump+ Successfully Loaded!", 1)

local section = BombJump:AddSection("Bomb Jump+", "MM2/MMV")

local CONFIG = {
    CooldownTime = 22.0,
    LaunchPower = 58,
    MinSize = 50,
    MaxSize = 300,
    DefaultSize = 90
}

local bombJumpEnabled = false
local onCooldown = false
local debounce = false
local autoGetBomb = false
local justRespawned = false
local bigButtonSize = CONFIG.DefaultSize
local bindButtonSize = 0.11
local bjBindButton = nil
local bjTimer = nil
local bigBtnExists = false
local bindBtnExists = false

local BOMB_NAMES = {"FakeBomb"}

local BombJumpMaid = Maid.new()
RootMaid:GiveTask(BombJumpMaid)

local Sounds = {
    Click = Instance.new("Sound"),
    Cooldown = Instance.new("Sound")
}
Sounds.Click.SoundId = "rbxassetid://6895079853"
Sounds.Click.Volume = 1.0

Sounds.Cooldown.SoundId = "rbxassetid://138090596"
Sounds.Cooldown.Volume = 1.0

local function PlaySound(snd)
    pcall(function()
        if snd then
            Services.SoundService:PlayLocalSound(snd)
        end
    end)
end

local function IsPlayerInAir()
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local state = humanoid:GetState()
    if state == Enum.HumanoidStateType.Jumping or 
       state == Enum.HumanoidStateType.FallingDown or
       state == Enum.HumanoidStateType.Freefall then
        return true
    end
    
    local velocityY = rootPart.Velocity.Y
    return math.abs(velocityY) > 0.5
end

local cdToken = 0

local function ResetCooldown()
    cdToken = cdToken + 1
    onCooldown = false
    if bjTimer then bjTimer.Reset() end
    if bjBindButton then
        BindableButtons.UpdateBButtonText("bombjump_bind", "BJ", false, false)
    end
end

local function StartCooldown()
    cdToken = cdToken + 1
    local my = cdToken
    onCooldown = true
    debounce = false
    if bjTimer then bjTimer.Start(CONFIG.CooldownTime) end
    if bjBindButton then
        BindableButtons.UpdateBButtonText("bombjump_bind", "BJ", true, false)
    end
    task.delay(CONFIG.CooldownTime, function()
        if my == cdToken and onCooldown then ResetCooldown() end
    end)
end

local function GetCenterPosition()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local camera = Services.Workspace.CurrentCamera
        local lookDir = camera.CFrame.LookVector
        return character.HumanoidRootPart.Position + (lookDir * 5)
    end
    return nil
end

local function MakeCharacterJump()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end

local function UnequipBomb()
    task.spawn(function()
        task.wait(0.5)
        local character = LocalPlayer.Character
        if character then
            for _, bombName in ipairs(BOMB_NAMES) do
                local bomb = character:FindFirstChild(bombName)
                if bomb then
                    bomb.Parent = LocalPlayer.Backpack or character
                    break
                end
            end
        end
    end)
end

local function GetAnyBomb()
    local character = LocalPlayer.Character
    if not character then return false, nil end
    
    for _, bombName in ipairs(BOMB_NAMES) do
        local bomb = character:FindFirstChild(bombName)
        if bomb then return true, bomb end
    end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, bombName in ipairs(BOMB_NAMES) do
            local bomb = backpack:FindFirstChild(bombName)
            if bomb then
                bomb.Parent = character
                return true, bomb
            end
        end
    end
    
    pcall(function()
        Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("FakeBomb")
    end)
    
    for _ = 1, 5 do
        for _, bombName in ipairs(BOMB_NAMES) do
            local bomb = character:FindFirstChild(bombName)
            if bomb then return true, bomb end
            if backpack then
                bomb = backpack:FindFirstChild(bombName)
                if bomb then
                    bomb.Parent = character
                    return true, bomb
                end
            end
        end
        task.wait(0.05)
    end
    
    return false, nil
end

local function FastBombJump()
    if not IsPlayerInAir() then return end
    if onCooldown or debounce or justRespawned then return end
    debounce = true
    
    local success, bomb = GetAnyBomb()
    
    if success and bomb then
        local position = GetCenterPosition()
        if position then
            local remote = bomb:FindFirstChild("Remote")
            if remote then
                PlaySound(Sounds.Click)
                pcall(function()
                    remote:FireServer(CFrame.new(position), 50)
                end)
            end
            
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local currentVelocity = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(currentVelocity.X, CONFIG.LaunchPower, currentVelocity.Z)
            end
            
            MakeCharacterJump()
            UnequipBomb()
            
            task.spawn(function()
                task.wait(0.1)
                StartCooldown()
            end)
        end
    end
    
    task.spawn(function()
        task.wait(0.5)
        debounce = false
    end)
end

local function IsHoldingBomb()
    local character = LocalPlayer.Character
    if not character then return false end
    
    for _, bombName in ipairs(BOMB_NAMES) do
        if character:FindFirstChild(bombName) then
            return true
        end
    end
    return false
end

local activeTouches = {}
local TAP_MOVEMENT_THRESHOLD = 10
local TAP_TIME_THRESHOLD = 0.3

BombJumpMaid:GiveTasks(
    Services.UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            activeTouches[input] = {startPosition = input.Position, startTime = tick(), moved = false}
        end
    end),
    Services.UserInputService.InputChanged:Connect(function(input)
        local data = activeTouches[input]
        if data and (input.Position - data.startPosition).Magnitude > TAP_MOVEMENT_THRESHOLD then
            data.moved = true
        end
    end),
    Services.UserInputService.InputEnded:Connect(function(input, gp)
        if gp then activeTouches[input] = nil return end
        local data = activeTouches[input]
        if data and not data.moved and tick() - data.startTime <= TAP_TIME_THRESHOLD then
            if bombJumpEnabled and not onCooldown and not debounce then
                if IsHoldingBomb() and IsPlayerInAir() then
                    FastBombJump()
                end
            end
        end
        activeTouches[input] = nil
    end),
    LocalPlayer.CharacterAdded:Connect(function()
        ResetCooldown()
        activeTouches = {}
        justRespawned = true
        task.wait(1)
        justRespawned = false
        if autoGetBomb then
            task.wait(0.2)
            pcall(function() Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("FakeBomb") end)
        end
    end)
)

section:AddLabel("Bomb Jump Options")
section:AddToggle("Enable Auto Bomb Jump", function(bool) bombJumpEnabled = bool end)

section:AddToggle("Auto-Get Fake Bomb", function(bool)
    autoGetBomb = bool
    if bool then
        pcall(function() Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("FakeBomb") end)
    end
end)

section:AddToggle("Enable BJ Big Button", function(e)
    bigBtnExists = e
    if e then
        AddBigButton("bombjump_big", "Bomb Jump", FastBombJump, false)
        local btn = BBSystem.Buttons["bombjump_big"]
        if btn then
            btn.Size = __UD2(0, bigButtonSize, 0, bigButtonSize * 0.375)
        end
    else
        DeleteBigButton("bombjump_big")
    end
end)

section:AddToggle("Enable BJ Timer Window", function(e)
    if e then
        if not bjTimer then
            bjTimer = MakeTimerWindow("bombjump_timer", "BJ", __UD2(0, 20, 0.5, 0))
        end
    elseif bjTimer then
        bjTimer.Destroy()
        bjTimer = nil
    end
end)

section:AddButton("Reset BJ Timer Position", function()
    if bjTimer then bjTimer.ResetPosition() end
    shared.Notify("BJ Timer position reset", 2)
end)

section:AddSlider("BJ Big Button Size", 50, 300, CONFIG.DefaultSize, function(value)
    bigButtonSize = value
    local btn = BBSystem.Buttons["bombjump_big"]
    if btn then
        btn.Size = __UD2(0, bigButtonSize, 0, bigButtonSize * 0.375)
    end
end)

section:AddButton("Reset BJ Big Button Position", function()
    savedPositions["bombjump_big"] = nil
    savePositions(savedPositions)
    local btn = BBSystem.Buttons["bombjump_big"]
    if btn then
        btn.Position = __UD2(0.5, 0, 0.5, 0)
    end
    shared.Notify("BJ Big button position reset", 2)
end)

section:AddToggle("Enable BJ Bind Button", function(e)
    bindBtnExists = e
    if e then
        BindableButtons.AddBButton("bombjump_bind", "BJ", FastBombJump, false)
        bjBindButton = BindableButtons.Buttons["bombjump_bind"]
        if bjBindButton then
            local screen = Services.Workspace.CurrentCamera.ViewportSize
            bjBindButton.Size = __UD2(bindButtonSize * (screen.Y / screen.X), 0, bindButtonSize, 0)
            BindableButtons.UpdateBButtonText("bombjump_bind", "BJ", onCooldown, false)
        end
    else
        BindableButtons.DeleteBButton("bombjump_bind")
        bjBindButton = nil
    end
end)

section:AddSlider("BJ Bind Button Size", 5, 25, 11, function(value)
    bindButtonSize = value / 100
    if bjBindButton then
        local screen = Services.Workspace.CurrentCamera.ViewportSize
        bjBindButton.Size = __UD2(bindButtonSize * (screen.Y / screen.X), 0, bindButtonSize, 0)
    end
end)

section:AddButton("Reset BJ Bind Button Position", function()
    savedPositions["bombjump_bind"] = nil
    savePositions(savedPositions)
    local btn = BindableButtons.Buttons["bombjump_bind"]
    if btn then
        btn.Position = __UD2(0.1, 0, 0.9, 0)
    end
    shared.Notify("BJ Bind button position reset", 2)
end)

section:AddKeybind("Bomb Jump Keybind", "E", FastBombJump)

if _game == "Murder Mystery Modded" then

local gbjSection = BombJump:AddSection("Gold Bomb Jump+", "MMV")

local gbjOnCooldown = false
local goldBombJumpEnabled = false
local gbjDebounce = false
local autoGetGoldBomb = false
local gbjJustRespawned = false
local gbjBigButtonSize = 200
local gbjBindButtonSize = 0.11
local gbjBindButton = nil
local gbjTimer = nil

local GOLD_BOMB_NAME = "GoldBomb"

local GoldBombJumpMaid = Maid.new()
RootMaid:GiveTask(GoldBombJumpMaid)

local gbjCdToken = 0

local function GBJResetCooldown()
    gbjCdToken = gbjCdToken + 1
    gbjOnCooldown = false
    if gbjTimer then gbjTimer.Reset() end
    if gbjBindButton then
        BindableButtons.UpdateBButtonText("goldbombjump_bind", "GBJ", false, true)
    end
end

local function GBJStartCooldown()
    gbjCdToken = gbjCdToken + 1
    local my = gbjCdToken
    gbjOnCooldown = true
    gbjDebounce = false
    if gbjTimer then gbjTimer.Start(4) end
    if gbjBindButton then
        BindableButtons.UpdateBButtonText("goldbombjump_bind", "GBJ", true, true)
    end
    task.delay(4, function()
        if my == gbjCdToken and gbjOnCooldown then GBJResetCooldown() end
    end)
end

local function GBJGetCenterPosition()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local camera = Services.Workspace.CurrentCamera
        local lookDir = camera.CFrame.LookVector
        return character.HumanoidRootPart.Position + (lookDir * 5)
    end
    return nil
end

local function GBJMakeCharacterJump()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end

local function UnequipGoldBomb()
    task.spawn(function()
        task.wait(0.5)
        local character = LocalPlayer.Character
        if character then
            local bomb = character:FindFirstChild(GOLD_BOMB_NAME)
            if bomb then
                bomb.Parent = LocalPlayer.Backpack or character
            end
        end
    end)
end

local function GetAnyGoldBomb()
    local character = LocalPlayer.Character
    if not character then return false, nil end

    local bomb = character:FindFirstChild(GOLD_BOMB_NAME)
    if bomb then return true, bomb end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        bomb = backpack:FindFirstChild(GOLD_BOMB_NAME)
        if bomb then
            bomb.Parent = character
            return true, bomb
        end
    end

    local success = pcall(function()
        Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("GoldBomb")
    end)

    if success then
        for _ = 1, 5 do
            bomb = character:FindFirstChild(GOLD_BOMB_NAME)
            if bomb then return true, bomb end

            if backpack then
                bomb = backpack:FindFirstChild(GOLD_BOMB_NAME)
                if bomb then
                    bomb.Parent = character
                    return true, bomb
                end
            end
            task.wait(0.05)
        end
    end

    return false, nil
end

local function FastGoldBombJump()
    if not IsPlayerInAir() then return end
    if gbjOnCooldown or gbjDebounce or gbjJustRespawned then return end
    gbjDebounce = true

    local success, bomb = GetAnyGoldBomb()

    if success and bomb then
        local position = GBJGetCenterPosition()
        if position then
            local remote = bomb:FindFirstChild("Remote")
            if remote then
                PlaySound(Sounds.Click)
                pcall(function()
                    remote:FireServer(CFrame.new(position), 50)
                end)
            end

            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local currentVelocity = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(currentVelocity.X, CONFIG.LaunchPower, currentVelocity.Z)
            end

            GBJMakeCharacterJump()
            UnequipGoldBomb()

            task.spawn(function()
                task.wait(0.1)
                GBJStartCooldown()
            end)
        end
    end

    task.spawn(function()
        task.wait(0.5)
        gbjDebounce = false
    end)
end

local function IsHoldingGoldBomb()
    local character = LocalPlayer.Character
    if not character then return false end
    return character:FindFirstChild(GOLD_BOMB_NAME) ~= nil
end

local gbjActiveTouches = {}

GoldBombJumpMaid:GiveTasks(
    Services.UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            gbjActiveTouches[input] = {startPosition = input.Position, startTime = tick(), moved = false}
        end
    end),
    Services.UserInputService.InputChanged:Connect(function(input)
        local data = gbjActiveTouches[input]
        if data and (input.Position - data.startPosition).Magnitude > TAP_MOVEMENT_THRESHOLD then
            data.moved = true
        end
    end),
    Services.UserInputService.InputEnded:Connect(function(input, gp)
        if gp then gbjActiveTouches[input] = nil return end
        local data = gbjActiveTouches[input]
        if data and not data.moved and tick() - data.startTime <= TAP_TIME_THRESHOLD then
            if goldBombJumpEnabled and not gbjOnCooldown and not gbjDebounce then
                if IsHoldingGoldBomb() and IsPlayerInAir() then
                    FastGoldBombJump()
                end
            end
        end
        gbjActiveTouches[input] = nil
    end),
    LocalPlayer.CharacterAdded:Connect(function()
        GBJResetCooldown()
        gbjActiveTouches = {}
        gbjJustRespawned = true
        task.wait(1)
        gbjJustRespawned = false
        if autoGetGoldBomb then
            task.wait(0.2)
            pcall(function() Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("GoldBomb") end)
        end
    end)
)

gbjSection:AddLabel("Gold Bomb Jump Options")
gbjSection:AddToggle("Enable Auto Gold Bomb Jump", function(bool) goldBombJumpEnabled = bool end)

gbjSection:AddToggle("Auto-Get Gold Bomb", function(bool)
    autoGetGoldBomb = bool
    if bool then
        pcall(function() Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("GoldBomb") end)
    end
end)

gbjSection:AddToggle("Enable GBJ Big Button", function(e)
    if e then
        AddBigButton("goldbombjump_big", "Gold Bomb Jump", FastGoldBombJump, true)
        local btn = BBSystem.Buttons["goldbombjump_big"]
        if btn then
            btn.Size = __UD2(0, gbjBigButtonSize, 0, gbjBigButtonSize * 0.375)
        end
    else
        DeleteBigButton("goldbombjump_big")
    end
end)

gbjSection:AddToggle("Enable GBJ Timer Window", function(e)
    if e then
        if not gbjTimer then
            gbjTimer = MakeTimerWindow("goldbombjump_timer", "GBJ", __UD2(0, 20, 0.5, 44))
        end
    elseif gbjTimer then
        gbjTimer.Destroy()
        gbjTimer = nil
    end
end)

gbjSection:AddButton("Reset GBJ Timer Position", function()
    if gbjTimer then gbjTimer.ResetPosition() end
    shared.Notify("GBJ Timer position reset", 2)
end)

gbjSection:AddSlider("GBJ Big Button Size", 50, 300, 200, function(value)
    gbjBigButtonSize = value
    local btn = BBSystem.Buttons["goldbombjump_big"]
    if btn then
        btn.Size = __UD2(0, gbjBigButtonSize, 0, gbjBigButtonSize * 0.375)
    end
end)

gbjSection:AddButton("Reset GBJ Big Button Position", function()
    savedPositions["goldbombjump_big"] = nil
    savePositions(savedPositions)
    local btn = BBSystem.Buttons["goldbombjump_big"]
    if btn then
        btn.Position = __UD2(0.5, 0, 0.5, 0)
    end
    shared.Notify("GBJ Big button position reset", 2)
end)

gbjSection:AddToggle("Enable GBJ Bind Button", function(e)
    if e then
        BindableButtons.AddBButton("goldbombjump_bind", "GBJ", FastGoldBombJump, true)
        gbjBindButton = BindableButtons.Buttons["goldbombjump_bind"]
        if gbjBindButton then
            local screen = Services.Workspace.CurrentCamera.ViewportSize
            gbjBindButton.Size = __UD2(gbjBindButtonSize * (screen.Y / screen.X), 0, gbjBindButtonSize, 0)
            BindableButtons.UpdateBButtonText("goldbombjump_bind", "GBJ", gbjOnCooldown, true)
        end
    else
        BindableButtons.DeleteBButton("goldbombjump_bind")
        gbjBindButton = nil
    end
end)

gbjSection:AddSlider("GBJ Bind Button Size", 5, 25, 11, function(value)
    gbjBindButtonSize = value / 100
    if gbjBindButton then
        local screen = Services.Workspace.CurrentCamera.ViewportSize
        gbjBindButton.Size = __UD2(gbjBindButtonSize * (screen.Y / screen.X), 0, gbjBindButtonSize, 0)
    end
end)

gbjSection:AddButton("Reset GBJ Bind Button Position", function()
    savedPositions["goldbombjump_bind"] = nil
    savePositions(savedPositions)
    local btn = BindableButtons.Buttons["goldbombjump_bind"]
    if btn then
        btn.Position = __UD2(0.1, 0, 0.9, 0)
    end
    shared.Notify("GBJ Bind button position reset", 2)
end)

gbjSection:AddKeybind("Gold Bomb Jump Keybind", "G", FastGoldBombJump)

end

end
