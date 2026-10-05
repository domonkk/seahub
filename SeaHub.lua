local Config
do
Config = {}

Config.Version = "20260930-36"

Config.Game = {
    Name = "Blox Fruits",
    QuestTask = "Auto Farm Level",
    EnemyFolder = "Enemies",
    RemoteFolder = "Remotes",
    MainRemote = "CommF_",
    BlockedSea2Action = "TravelDressrosa",
    StatAction = "AddPoint",
    ServerBrowser = "__ServerBrowser",
}

Config.FarmStatus = {
    WaitingMob = "waiting mob",
    AttackingMob = "attacking mob",
    QuestProgress = "quest-progress",
    QuestRestarted = "quest-restarted",
    QuestTargetChanged = "quest-target-changed",
    QuestTargetMissing = "quest-target-missing",
    QuestUnavailable = "quest-unavailable",
    TargetAppeared = "target-appeared",
    TargetCountDecreased = "target-count-decreased",
    TargetHealthDecreased = "target-health-decreased",
    AttackStarted = "attack-started",
    UnmanagedTask = "unmanaged-task",
    NoRecoveryServer = "no-recovery-server",
}

Config.UiNames = {
    Legacy = "SeaHubLegacyUI",
    ScreenGui = "SeaHubUI",
    SeaHubHud = "SeaHubHud",
    VisibilityToggle = "VisibilityToggle",
    BlackScreen = "SeaHubBlackScreen",
}

Config.Interface = {
    BlackScreen = false,
    DisplayOrder = 1000,
}

Config.Performance = {
    FPS = 15,
}

Config.Globals = {
    ApprovedRequest = "__SEAHUB_APPROVED_REQUEST",
    CoreFunctionsReady = "__SEAHUB_CORE_FUNCTIONS_READY",
    FarmWatchdog = "__SEAHUB_FARM_WATCHDOG",
    HttpFacade = "__SEAHUB_H",
    HookSentinelActive = "__SEAHUB_HOOK_SENTINEL_ACTIVE",
    LiveTimeStartedAt = "__SEAHUB_LIVE_STARTED_AT",
    NetworkBlocked = "__SEAHUB_NETWORK_BLOCKED",
    SpyDetected = "__SEAHUB_SPY_DETECTED",
    StatAllocationGuard = "__SEAHUB_STAT_ALLOCATION_GUARD",
    WhitelistPassed = "__SEAHUB_WHITELIST_PASSED",
}

Config.Errors = {
    UnauthorizedHttpHook = "SEAHUB_UNAUTHORIZED_HTTP_HOOK",
    UnauthorizedNamecallHook = "SEAHUB_UNAUTHORIZED_NAMECALL_HOOK",
    UnauthorizedOtherHttpHook = "SEAHUB_UNAUTHORIZED_OTH_HTTP_HOOK",
    Poly1305UnalignedInput = "SEAHUB_POLY1305_UNALIGNED_INPUT",
}

Config.ExecutorHttpAliases = {
    "request",
    "http_request",
    "syn.request",
    "fluxus.request",
    "http.request",
    "krnl.request",
    "secure_request",
}

Config.Colors = {
    White = "#FFFFFF",
    Label = "#AAB6AD",
    Level = "#72E69A",
    Status = "#53D984",
    Time = "#D8C98B",
}
end

local UIState
do
local Players = game:GetService("Players")

UIState = {}

local COLORS = {
    Background = Color3.fromRGB(18, 24, 20),
    Border = Color3.fromRGB(48, 68, 55),
    Divider = Color3.fromRGB(42, 52, 45),
    Green = Color3.fromRGB(72, 214, 126),
    GreenSoft = Color3.fromRGB(142, 226, 168),
    Text = Color3.fromRGB(244, 247, 245),
    Muted = Color3.fromRGB(166, 177, 169),
    Turtle = Color3.fromRGB(187, 207, 83),
    OwnedBackground = Color3.fromRGB(25, 65, 41),
}

local V2_MELEES = {
    { Name = "Death Step", Label = "Death Step" },
    { Name = "Sharkman Karate", Label = "Sharkman" },
    { Name = "Electric Claw", Label = "E. Claw" },
    { Name = "Dragon Talon", Label = "D. Talon" },
}

local function globalEnv()
    return getgenv and getgenv() or _G
end

local function liveStartedAt()
    local environment = globalEnv()
    local now = os.time()
    local key = Config.Globals.LiveTimeStartedAt or "__SEAHUB_LIVE_STARTED_AT"
    local startedAt = tonumber(rawget(environment, key))
    if not startedAt or startedAt <= 0 or startedAt > now + 300 then
        startedAt = now
        rawset(environment, key, startedAt)
    end
    return math.floor(startedAt)
end

local function formatElapsed(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor(seconds % 3600 / 60)
    local remainingSeconds = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, remainingSeconds)
end

local function addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
end

local function addStroke(instance, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = instance
end

local function createText(parent, name, text, position, size, textSize, color)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Position = position
    label.Size = size
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextSize = textSize
    label.TextColor3 = color
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = parent
    return label
end

local function splitStatus(status, runtimeState)
    local parts = {}
    for part in tostring(status or ""):gmatch("[^|]+") do
        local clean = part:match("^%s*(.-)%s*$")
        if clean ~= "" then
            table.insert(parts, clean)
        end
    end

    local mainTask = parts[1]
        or runtimeState and runtimeState.lastTaskName
        or "Waiting"
    if mainTask == "Auto Farm Level" then
        mainTask = "Level Farming"
    end
    local subTask = #parts > 1 and table.concat(parts, " | ", 2) or "n/o"
    return mainTask, subTask
end

local function levelRouteInfo(runtimeState)
    if type(runtimeState) ~= "table" then
        return nil, nil
    end

    local mobName = runtimeState.farmClusterName
        or runtimeState.currentFarmMobName
        or runtimeState.levelRouteMob
    if type(mobName) ~= "string" or mobName == "" then
        return nil, nil
    end

    local mobLevel
    if mobName == runtimeState.levelRouteMob then
        mobLevel = tonumber(runtimeState.levelRouteQuestLevel)
    end
    if not mobLevel then
        for _, quest in runtimeState.questData or {} do
            if quest.mob_name == mobName then
                mobLevel = tonumber(quest.level_req)
                break
            end
        end
    end
    return mobName, mobLevel
end

local function formatMainTask(mainTask, runtimeState)
    if mainTask ~= "Level Farming" then
        return mainTask
    end
    local mobName, mobLevel = levelRouteInfo(runtimeState)
    if not mobName then
        return mainTask
    end
    if mobLevel then
        return string.format("%s | %s [Lv. %d]", mainTask, mobName, mobLevel)
    end
    return string.format("%s | %s", mainTask, mobName)
end

local function meleeToolName(tool)
    if not tool or not tool:IsA("Tool") then
        return nil
    end
    local weaponType = tool:GetAttribute("WeaponType")
    if type(weaponType) ~= "string" or weaponType == "" then
        weaponType = tool.ToolTip
    end
    return weaponType == "Melee" and tool.Name or nil
end

local function currentMeleeInfo(player)
    local character = player and player.Character
    for _, tool in character and character:GetChildren() or {} do
        local name = meleeToolName(tool)
        if name then
            local level = tool:FindFirstChild("Level")
            local mastery = level and tonumber(level.Value)
                or tonumber(tool:GetAttribute("Mastery"))
                or 0
            return name, mastery
        end
    end
    return nil, 0
end

local function hasPhysicalMelee(player, name)
    for _, container in {
        player and player.Character,
        player and player:FindFirstChildOfClass("Backpack"),
    } do
        local tool = container and container:FindFirstChild(name)
        if meleeToolName(tool) then
            return true
        end
    end
    return false
end

local function ownsMelee(context, player, name)
    if context then
        local functions = context.Functions
        if functions and type(functions.Owns) == "function" then
            local success, owned = pcall(functions.Owns, "Moveset", name)
            if success and owned == true then
                return true
            end
        end

        local melee = context.MeleeInventory
            and context.MeleeInventory.Melee
            and context.MeleeInventory.Melee[name]
        if melee == true or type(melee) == "table" and melee.Bought == true then
            return true
        end

        local moveset = context.Inventory
            and context.Inventory.Moveset
            and context.Inventory.Moveset[name]
        if moveset == true or type(moveset) == "table" then
            return true
        end

    end
    return hasPhysicalMelee(player, name)
end

function UIState.destroyOld(parent)
    if not parent then
        return
    end
    for _, name in ipairs({
        Config.UiNames.Legacy,
        Config.UiNames.ScreenGui,
    }) do
        local old = parent:FindFirstChild(name)
        if old then
            old:Destroy()
        end
    end
end

function UIState.install(parent)
    local player = Players.LocalPlayer
    if not player then
        return nil
    end
    local playerGui = player:WaitForChild("PlayerGui")

    if parent and parent ~= playerGui then
        UIState.destroyOld(parent)
    end
    UIState.destroyOld(playerGui)

    local interfaceConfig = Config.Interface or {}
    local blackScreenEnabled = interfaceConfig.BlackScreen == true

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = Config.UiNames.ScreenGui
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = interfaceConfig.DisplayOrder or 1000
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local blackScreen = Instance.new("Frame")
    blackScreen.Name = Config.UiNames.BlackScreen or "SeaHubBlackScreen"
    blackScreen.Position = UDim2.fromScale(0, 0)
    blackScreen.Size = UDim2.fromScale(1, 1)
    blackScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blackScreen.BackgroundTransparency = 0
    blackScreen.BorderSizePixel = 0
    blackScreen.Active = true
    blackScreen.Selectable = false
    blackScreen.ZIndex = 1
    blackScreen.Visible = blackScreenEnabled
    blackScreen.Parent = screenGui

    local root = Instance.new("Frame")
    root.Name = "SeaHubRoot"
    root.AnchorPoint = Vector2.new(0.5, 0.5)
    root.Position = UDim2.fromScale(0.5, 0.5)
    root.Size = UDim2.fromOffset(620, 220)
    root.BackgroundTransparency = 1
    root.ZIndex = 10
    root.Parent = screenGui

    local scaler = Instance.new("UIScale")
    scaler.Name = "ResponsiveScale"
    scaler.Parent = root

    local taskPanel = Instance.new("Frame")
    taskPanel.Name = "TaskPanel"
    taskPanel.Size = UDim2.fromScale(1, 1)
    taskPanel.BackgroundColor3 = COLORS.Background
    taskPanel.BackgroundTransparency = 0.16
    taskPanel.BorderSizePixel = 0
    taskPanel.ClipsDescendants = true
    taskPanel.ZIndex = 10
    taskPanel.Parent = root
    addCorner(taskPanel, 8)
    addStroke(taskPanel, COLORS.Border, 1.5)

    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Position = UDim2.fromOffset(0, 0)
    accent.Size = UDim2.new(0, 6, 1, 0)
    accent.BackgroundColor3 = COLORS.Green
    accent.BackgroundTransparency = 0.04
    accent.BorderSizePixel = 0
    accent.ZIndex = 11
    accent.Parent = taskPanel
    addCorner(accent, 8)

    local brandLabel = createText(
        taskPanel,
        "Brand",
        "SEAHUB",
        UDim2.fromOffset(24, 10),
        UDim2.fromOffset(106, 38),
        20,
        COLORS.GreenSoft
    )
    brandLabel.ZIndex = 11

    local levelLabel = createText(
        taskPanel,
        "Level",
        "LV --",
        UDim2.fromOffset(142, 10),
        UDim2.fromOffset(112, 38),
        18,
        COLORS.Green
    )
    levelLabel.ZIndex = 11

    local meleeLabel = createText(
        taskPanel,
        "CurrentMelee",
        "Melee --",
        UDim2.fromOffset(268, 10),
        UDim2.new(1, -314, 0, 38),
        18,
        COLORS.Text
    )
    meleeLabel.ZIndex = 11

    local activity = Instance.new("Frame")
    activity.Name = "Activity"
    activity.AnchorPoint = Vector2.new(1, 0.5)
    activity.Position = UDim2.new(1, -24, 0, 29)
    activity.Size = UDim2.fromOffset(10, 10)
    activity.BackgroundColor3 = COLORS.Green
    activity.BorderSizePixel = 0
    activity.ZIndex = 11
    activity.Parent = taskPanel
    addCorner(activity, 10)

    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Position = UDim2.fromOffset(24, 52)
    divider.Size = UDim2.new(1, -48, 0, 1)
    divider.BackgroundColor3 = COLORS.Divider
    divider.BorderSizePixel = 0
    divider.ZIndex = 11
    divider.Parent = taskPanel

    local mainTaskLabel = createText(
        taskPanel,
        "MainTask",
        "Waiting",
        UDim2.fromOffset(24, 58),
        UDim2.new(1, -48, 0, 34),
        22,
        COLORS.Text
    )
    mainTaskLabel.ZIndex = 11
    local subTaskLabel = createText(
        taskPanel,
        "SubTask",
        "n/o",
        UDim2.fromOffset(24, 92),
        UDim2.new(1, -48, 0, 24),
        16,
        COLORS.Muted
    )
    subTaskLabel.ZIndex = 11

    local v2Divider = Instance.new("Frame")
    v2Divider.Name = "V2Divider"
    v2Divider.Position = UDim2.fromOffset(24, 123)
    v2Divider.Size = UDim2.new(1, -48, 0, 1)
    v2Divider.BackgroundColor3 = COLORS.Divider
    v2Divider.BorderSizePixel = 0
    v2Divider.ZIndex = 11
    v2Divider.Parent = taskPanel

    local v2Title = createText(
        taskPanel,
        "V2Title",
        "V2",
        UDim2.fromOffset(24, 136),
        UDim2.fromOffset(36, 36),
        16,
        COLORS.Green
    )
    v2Title.ZIndex = 11

    local v2Bar = Instance.new("Frame")
    v2Bar.Name = "OwnedV2Melees"
    v2Bar.Position = UDim2.fromOffset(72, 135)
    v2Bar.Size = UDim2.new(1, -96, 0, 38)
    v2Bar.BackgroundTransparency = 1
    v2Bar.ZIndex = 11
    v2Bar.Parent = taskPanel

    local v2Layout = Instance.new("UIListLayout")
    v2Layout.FillDirection = Enum.FillDirection.Horizontal
    v2Layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    v2Layout.VerticalAlignment = Enum.VerticalAlignment.Center
    v2Layout.Padding = UDim.new(0, 10)
    v2Layout.SortOrder = Enum.SortOrder.LayoutOrder
    v2Layout.Parent = v2Bar

    local v2Badges = {}
    for index, style in ipairs(V2_MELEES) do
        local badge = Instance.new("Frame")
        badge.Name = style.Name:gsub("%s+", "")
        badge.Size = UDim2.fromOffset(119, 36)
        badge.BackgroundColor3 = COLORS.OwnedBackground
        badge.BackgroundTransparency = 0.28
        badge.BorderSizePixel = 0
        badge.LayoutOrder = index
        badge.Visible = false
        badge.ZIndex = 11
        badge.Parent = v2Bar
        addCorner(badge, 6)
        addStroke(badge, COLORS.Border, 1)

        local label = createText(
            badge,
            "Label",
            style.Label,
            UDim2.fromOffset(8, 0),
            UDim2.new(1, -16, 1, 0),
            14,
            COLORS.GreenSoft
        )
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.ZIndex = 12
        v2Badges[index] = badge
    end

    local noV2Label = createText(
        v2Bar,
        "Empty",
        "None",
        UDim2.fromScale(0, 0),
        UDim2.fromOffset(84, 36),
        14,
        COLORS.Muted
    )
    noV2Label.LayoutOrder = #V2_MELEES + 1
    noV2Label.ZIndex = 11

    local liveDivider = Instance.new("Frame")
    liveDivider.Name = "LiveDivider"
    liveDivider.Position = UDim2.fromOffset(24, 181)
    liveDivider.Size = UDim2.new(1, -48, 0, 1)
    liveDivider.BackgroundColor3 = COLORS.Divider
    liveDivider.BorderSizePixel = 0
    liveDivider.ZIndex = 11
    liveDivider.Parent = taskPanel

    local liveTimeLabel = createText(
        taskPanel,
        "LiveTime",
        "LIVE TIME  00:00:00",
        UDim2.fromOffset(24, 184),
        UDim2.new(1, -48, 0, 28),
        15,
        COLORS.GreenSoft
    )
    liveTimeLabel.ZIndex = 11

    local visibilityToggle = Instance.new("ImageButton")
    visibilityToggle.Name = "SeaHubOverlay"
    visibilityToggle.Active = true
    visibilityToggle.AnchorPoint = Vector2.new(0, 0)
    visibilityToggle.Position = UDim2.new(1, -66, 1, -148)
    visibilityToggle.Size = UDim2.fromOffset(48, 48)
    visibilityToggle.BackgroundColor3 = COLORS.Background
    visibilityToggle.BackgroundTransparency = 0.18
    visibilityToggle.BorderSizePixel = 0
    visibilityToggle.AutoButtonColor = false
    visibilityToggle.Image = "rbxassetid://91555154146294"
    visibilityToggle.ImageColor3 = COLORS.Turtle
    visibilityToggle.ScaleType = Enum.ScaleType.Fit
    visibilityToggle.ZIndex = 220
    visibilityToggle.Visible = not blackScreenEnabled
    visibilityToggle.Parent = screenGui
    addCorner(visibilityToggle, 999)
    addStroke(visibilityToggle, COLORS.Green, 1.25)

    local panelVisible = true

    local function getCleanContext()
        local environment = globalEnv()
        local seaHub = environment.SeaHub
        return seaHub and seaHub.CleanContext or environment.__SEAHUB_CLEAN_CONTEXT
    end

    local function getRuntimeState()
        local context = getCleanContext()
        return context and context.State
    end

    local function setPanelVisible(visible)
        panelVisible = visible
        root.Visible = visible
    end

    local function setBlackScreenEnabled(enabled)
        blackScreenEnabled = enabled == true
        blackScreen.Visible = blackScreenEnabled
        visibilityToggle.Visible = not blackScreenEnabled
        if blackScreenEnabled then
            setPanelVisible(true)
        end
    end

    visibilityToggle.MouseButton1Click:Connect(function()
        setPanelVisible(not panelVisible)
    end)

    local alive = true
    local camera
    local viewportConnection
    local currentCameraConnection

    local function disconnect(connection)
        if connection then
            pcall(connection.Disconnect, connection)
        end
    end

    local function updateScale()
        if not alive or not scaler.Parent then
            return
        end
        local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
        local widthScale = (viewport.X - 32) / 620
        local heightScale = (viewport.Y - 32) / 220
        scaler.Scale = math.clamp(math.min(widthScale, heightScale), 0.48, 1.1)
    end

    local function bindCurrentCamera()
        disconnect(viewportConnection)
        viewportConnection = nil
        camera = workspace.CurrentCamera
        if camera then
            viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
        end
        updateScale()
    end

    bindCurrentCamera()
    currentCameraConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCurrentCamera)
    screenGui.Destroying:Connect(function()
        alive = false
        disconnect(viewportConnection)
        disconnect(currentCameraConnection)
        viewportConnection = nil
        currentCameraConnection = nil
    end)

    task.spawn(function()
        local startedAt = liveStartedAt()
        local previousMain
        local previousSub
        local previousActive
        local previousLevel
        local previousMeleeText
        local previousV2Signature
        local previousLiveText
        while alive and screenGui.Parent do
            task.wait(panelVisible and 0.75 or 2)
            if panelVisible then
                local runtimeState = getRuntimeState()
                local context = getCleanContext()
                local status = runtimeState and runtimeState.status or "Waiting"
                local mainTask, subTask = splitStatus(status, runtimeState)
                mainTask = formatMainTask(mainTask, runtimeState)
                local active = runtimeState
                    and not runtimeState.paused and not runtimeState.stopped or false
                if mainTask ~= previousMain then
                    mainTaskLabel.Text = mainTask
                    previousMain = mainTask
                end
                if subTask ~= previousSub then
                    subTaskLabel.Text = subTask
                    previousSub = subTask
                end
                if active ~= previousActive then
                    activity.BackgroundColor3 = active and COLORS.Green or COLORS.Muted
                    previousActive = active
                end

                local liveText = "LIVE TIME  " .. formatElapsed(os.time() - startedAt)
                if liveText ~= previousLiveText then
                    liveTimeLabel.Text = liveText
                    previousLiveText = liveText
                end


                local data = player:FindFirstChild("Data")
                local levelValue = context and context.Level or data and data:FindFirstChild("Level")
                local level = levelValue and tonumber(levelValue.Value) or 0
                if level ~= previousLevel then
                    levelLabel.Text = "LV " .. tostring(level)
                    previousLevel = level
                end

                local equippedMelee, equippedMastery = currentMeleeInfo(player)
                if equippedMelee then
                    local meleeText = string.format(
                        "%s  |  Mastery %d",
                        equippedMelee,
                        equippedMastery
                    )
                    if meleeText ~= previousMeleeText then
                        meleeLabel.Text = meleeText
                        previousMeleeText = meleeText
                    end
                elseif not previousMeleeText then
                    meleeLabel.Text = "Melee --"
                end

                local ownedV2 = {}
                for index, style in ipairs(V2_MELEES) do
                    if ownsMelee(context, player, style.Name) then
                        ownedV2[#ownedV2 + 1] = index
                    end
                end
                local signature = table.concat(ownedV2, ",")
                if signature ~= previousV2Signature then
                    local visible = {}
                    for _, index in ipairs(ownedV2) do
                        visible[index] = true
                    end
                    for index, badge in ipairs(v2Badges) do
                        badge.Visible = visible[index] == true
                    end
                    noV2Label.Visible = #ownedV2 == 0
                    previousV2Signature = signature
                end
            end
        end
    end)

    return {
        ScreenGui = screenGui,
        Root = root,
        TaskPanel = taskPanel,
        MainTaskLabel = mainTaskLabel,
        SubTaskLabel = subTaskLabel,
        LevelLabel = levelLabel,
        MeleeLabel = meleeLabel,
        V2Bar = v2Bar,
        V2Badges = v2Badges,
        LiveTimeLabel = liveTimeLabel,
        VisibilityToggle = visibilityToggle,
        BlackScreen = blackScreen,
        SetBlackScreenEnabled = setBlackScreenEnabled,
        BrandLabel = brandLabel,
    }
end

UIState.create = UIState.install
end

local ControllerOrder
do
ControllerOrder = {}

ControllerOrder.Arya = {
    "Saber",
    "Tushita",
    "Yama",
    "UtillyItemsActivitation",
    "MeleeMaterials",
    "SpecialBossesTask",
    "RaidController",
    "ThirdSeaPuzzle",
    "Trevor",
    "ColosseumPuzzle",
    "Wenlocktoad",
    "SecondSeaPuzzle",
    "CollectDrops",
    "BossesTask",
    "ExpRedeem",
    "LevelFarm",
}

ControllerOrder.Priorities = {
    ["Auto Saber"] = 160,
    ["Auto Tushita"] = 150,
    ["Auto Yama"] = 140,
    ["Utility Items Activation"] = 130,
    ["Melee Materials"] = 120,
    ["Special Boss"] = 110,
    ["Auto Raid"] = 100,
    ["Auto Third Sea"] = 90,
    ["Auto Trevor"] = 80,
    ["Auto Bartilo Quest"] = 70,
    Wenlocktoad = 60,
    ["Auto Second Sea"] = 50,
    ["Get Fruits"] = 40,
    ["Farm Boss"] = 30,
    ["Exp Redeem"] = 20,
    ["Auto Farm Level"] = 10,
}

function ControllerOrder.copyPriorities()
    return table.clone(ControllerOrder.Priorities)
end

function ControllerOrder.precedes(left, right)
    return (ControllerOrder.Priorities[left] or -math.huge)
        > (ControllerOrder.Priorities[right] or -math.huge)
end
end

local PolicyCache
do
PolicyCache = {}

function PolicyCache.prepare(policy, callback, now, retention)
    if policy.cacheCallback ~= callback then
        table.clear(policy.Cache)
        policy.cacheCallback = callback
    end
    for key, entry in policy.Cache do
        local age = now - entry.at
        if age < 0 or age > retention then
            policy.Cache[key] = nil
        end
    end
end

function PolicyCache.put(policy, key, value, now)
    local count, oldestKey, oldestAt = 0, nil, math.huge
    for existingKey, entry in policy.Cache do
        count += 1
        if entry.at < oldestAt then
            oldestKey, oldestAt = existingKey, entry.at
        end
    end
    if policy.Cache[key] == nil and count >= policy.MaxCacheEntries and oldestKey then
        policy.Cache[oldestKey] = nil
    end
    policy.Cache[key] = { at = now, value = value }
end
end

local BoundedCall
do
BoundedCall = {}

local function cancel(thread)
    if type(thread) == "thread" and thread ~= coroutine.running()
        and coroutine.status(thread) ~= "dead" and type(task.cancel) == "function"
    then
        pcall(task.cancel, thread)
    end
end

function BoundedCall.start(context, key, timeout, work, complete)
    local state = context.State
    state.boundedCalls = state.boundedCalls or {}
    state.boundedCallRetryAt = state.boundedCallRetryAt or {}
    local existing = state.boundedCalls[key]
    if existing then return existing, false end
    if state.stopped or os.clock() < (state.boundedCallRetryAt[key] or 0) then
        return nil, false
    end
    local generation = state.runtimeGeneration
    state.boundedCallSequence = (state.boundedCallSequence or 0) + 1
    local slot = { done = false, deadline = os.clock() + timeout, sequence = state.boundedCallSequence }
    state.boundedCalls[key] = slot
    local function finish(ok, result, timedOut)
        if slot.done then return end
        slot.done = true
        local current = state.boundedCalls[key] == slot
            and state.runtimeGeneration == generation and not state.stopped
        cancel(slot.timer)
        if timedOut then
            if current then state.boundedCallRetryAt[key] = os.clock() + 10 end
            cancel(slot.worker)
        end
        local stillWaiting = timedOut and type(slot.worker) == "thread"
            and coroutine.status(slot.worker) ~= "dead"
        if state.boundedCalls[key] == slot and not stillWaiting then
            state.boundedCalls[key] = nil
        end
        if current then
            local applied, value = pcall(complete, ok, result, slot)
            slot.success = ok and applied and value == true
            if not applied then state.lastBoundedCallError = tostring(value) end
        end
    end
    slot.timer = task.delay(timeout, function()
        finish(false, "request-timeout", true)
    end)
    slot.worker = task.spawn(function()
        local ok, result = pcall(work)
        if slot.done then
            if state.boundedCalls and state.boundedCalls[key] == slot then
                state.boundedCalls[key] = nil
            end
            return
        end
        finish(ok, result, false)
    end)
    return slot, true
end

function BoundedCall.await(slot)
    if not slot then return false end
    while not slot.done do task.wait(0.05) end
    return slot.success == true
end

function BoundedCall.stop(context)
    local state = context.State
    local pending = {}
    for key, slot in state.boundedCalls or {} do
        slot.done = true
        cancel(slot.timer)
        cancel(slot.worker)
        if type(slot.worker) == "thread" and coroutine.status(slot.worker) ~= "dead" then
            pending[key] = slot
        end
    end
    state.boundedCalls = next(pending) and pending or nil
    state.boundedCallRetryAt = nil
end
end

local AccessoryPolicy
do
AccessoryPolicy = {}

local function isFinite(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

local function numeric(value)
    if type(value) ~= "number" and type(value) ~= "string" then
        return 0
    end
    local number = tonumber(value)
    return isFinite(number) and number or 0
end

local function sum(first, second)
    return numeric(numeric(first) + numeric(second))
end

local function combined(stats, key)
    local values = rawget(stats, key)
    if type(values) ~= "table" then
        return 0
    end
    return sum(rawget(values, "Melee"), rawget(values, "All"))
end

function AccessoryPolicy.score(stats)
    if type(stats) ~= "table" then
        stats = {}
    end
    return {
        combined(stats, "AllDamage"),
        sum(rawget(stats, "MeleeCooldown"), rawget(stats, "AllCooldown")),
        combined(stats, "PveLeech"),
        combined(stats, "AllResist"),
        numeric(rawget(stats, "Health")),
        numeric(rawget(stats, "Energy")),
        numeric(rawget(stats, "SpeedMultiplier")),
    }
end

local function validCandidate(candidate)
    if type(candidate) ~= "table" then
        return false
    end
    local name = rawget(candidate, "Name")
    local uid = rawget(candidate, "NetworkedUID")
    local score = rawget(candidate, "Score")
    if type(name) ~= "string" or name == "" or type(score) ~= "table" then
        return false
    end
    if uid ~= nil and type(uid) ~= "string" and not isFinite(uid) then
        return false
    end
    for index = 1, 7 do
        if not isFinite(rawget(score, index)) then
            return false
        end
    end
    return true
end

local function better(candidate, current)
    local score, currentScore = rawget(candidate, "Score"), rawget(current, "Score")
    for index = 1, 7 do
        local value, currentValue = rawget(score, index), rawget(currentScore, index)
        if value ~= currentValue then
            return value > currentValue
        end
    end
    local equipped = rawget(candidate, "Equipped") == true
    local currentEquipped = rawget(current, "Equipped") == true
    if equipped ~= currentEquipped then
        return equipped
    end
    return tostring(rawget(candidate, "NetworkedUID") or rawget(candidate, "Name"))
        < tostring(rawget(current, "NetworkedUID") or rawget(current, "Name"))
end

function AccessoryPolicy.choose(candidates)
    if type(candidates) ~= "table" then
        return nil
    end
    local best = nil
    for _, candidate in next, candidates do
        if validCandidate(candidate) and (not best or better(candidate, best)) then
            best = candidate
        end
    end
    return best
end
end

local FruitCollectionPolicy
do
FruitCollectionPolicy = {}

FruitCollectionPolicy.MinimumLevel = 100
FruitCollectionPolicy.BoostValueThreshold = 1000000
FruitCollectionPolicy.BlockingItems = {
    "God's Chalice",
    "Sweet Chalice",
    "Hallow Essence",
}

function FruitCollectionPolicy.moneyValue(item)
    if type(item) ~= "table" then
        return nil
    end
    local quality = item.Quality or item.quality
    return tonumber(item.Value or item.value or item.Price or item.price
        or item.Cost or item.cost
        or type(quality) == "table" and (quality.MoneyPrice or quality.moneyPrice))
end

function FruitCollectionPolicy.shouldCollect(options)
    if (tonumber(options.level) or 0) < FruitCollectionPolicy.MinimumLevel then
        return false, "level"
    end
    if options.blocked then
        return false, "progression-item"
    end
    if options.duplicate then
        return false, "duplicate"
    end
    if (tonumber(options.expBoostRemaining) or 0) > 0 then
        if not options.hasIdentity then
            return false, "boost-unknown-fruit"
        end
        local value = tonumber(options.value)
        if not value or value <= FruitCollectionPolicy.BoostValueThreshold then
            return false, "boost-low-value"
        end
    end
    return true, "eligible"
end
end

local BossTaskPolicy
do
BossTaskPolicy = {}

BossTaskPolicy.BlockingItems = {
    "God's Chalice",
    "Sweet Chalice",
    "Fire Essence",
    "Special Microchip",
    "Hallow Essence",
}

BossTaskPolicy.Order = {
    { name = "Awakened Ice Admiral", level = 1000, sea = 2 },
    { name = "Cake Prince", level = 1500, sea = 3 },
    { name = "Tide Keeper", level = 1000, sea = 2 },
}

BossTaskPolicy.VipBySea = {
    [2] = { "Darkbeard", "Core" },
    [3] = { "rip_indra True Form", "Dough King", "Tyrant of the Skies" },
}

BossTaskPolicy.Levels = {
    ["Awakened Ice Admiral"] = 1000,
    ["Cake Prince"] = 1500,
    ["Tide Keeper"] = 1000,
    Diablo = 1500,
    Deandre = 1500,
    Urban = 1500,
}

function BossTaskPolicy.isBlocked(carries)
    for _, itemName in BossTaskPolicy.BlockingItems do
        if carries(itemName) then
            return true, itemName
        end
    end
    return false
end

function BossTaskPolicy.selectOrdered(level, isSea, bossAlive, firstIndex, lastIndex)
    firstIndex = firstIndex or 1
    lastIndex = lastIndex or #BossTaskPolicy.Order
    for index = firstIndex, lastIndex do
        local entry = BossTaskPolicy.Order[index]
        if level >= entry.level and isSea(entry.sea) and bossAlive(entry.name) then
            return entry.name, index
        end
    end
    return nil
end

function BossTaskPolicy.selectQuest(level, quests, bossAlive, blacklistedQuestIds)
    blacklistedQuestIds = blacklistedQuestIds or {}
    local selected
    for _, quest in pairs(quests or {}) do
        local questId = quest.id or quest.Id
        local bossName = quest.boss_name or quest.bossName
        local levelRequired = quest.level_req or quest.LevelReq or math.huge
        local familyLevel = quest.family_level_req or quest.familyLevelReq or levelRequired
        local nextFamilyLevel = quest.next_family_level_req
            or quest.nextFamilyLevelReq
            or math.huge
        if bossName and level >= levelRequired
            and level >= familyLevel and level < nextFamilyLevel
            and not blacklistedQuestIds[questId]
            and (not selected
                or familyLevel > (selected.family_level_req
                    or selected.familyLevelReq
                    or selected.level_req
                    or selected.LevelReq
                    or -math.huge))
        then
            selected = quest
        end
    end
    local bossName = selected and (selected.boss_name or selected.bossName)
    if bossName and bossAlive(bossName) then
        return bossName, selected
    end
    return nil
end

function BossTaskPolicy.selectVip(sea, bossAlive)
    for _, bossName in BossTaskPolicy.VipBySea[sea] or {} do
        if bossAlive(bossName) then
            return bossName
        end
    end
    return nil
end
end

local BossTelemetry
do
BossTelemetry = {}

local MAX_SIGHTINGS = 96
local MAX_ENGAGEMENTS = 96
local HISTORY_FILE_PREFIX = "seahub_boss_history_"

local function persist(context, row)
    if type(appendfile) ~= "function" then
        return
    end
    pcall(function()
        local player = context.LocalPlayer
        local document = table.clone(row)
        document.userId = player and player.UserId or nil
        document.player = player and player.Name or nil
        document.placeId = game.PlaceId
        document.jobId = game.JobId
        local fileName = HISTORY_FILE_PREFIX
            .. tostring(document.userId or "unknown") .. ".jsonl"
        local encoded = game:GetService("HttpService"):JSONEncode(document)
        appendfile(fileName, encoded .. "\n")
    end)
end

local function appendBounded(rows, row, limit)
    rows[#rows + 1] = row
    while #rows > limit do
        table.remove(rows, 1)
    end
end

local function currentTask(context)
    return context.TaskQueue and context.TaskQueue:top() or nil
end

local function modelSnapshot(model)
    if model == nil then
        return false, nil, nil, nil
    end

    local humanoid
    local root
    pcall(function()
        humanoid = model:FindFirstChildOfClass("Humanoid")
        root = model:FindFirstChild("HumanoidRootPart")
    end)

    local health
    local position
    pcall(function()
        health = humanoid and tonumber(humanoid.Health) or nil
        local value = root and root.Position
        if value then
            position = {
                x = math.round(value.X * 10) / 10,
                y = math.round(value.Y * 10) / 10,
                z = math.round(value.Z * 10) / 10,
            }
        end
    end)

    return health == nil or health > 0, health, position, tostring(model)
end

local function eventBase(context, bossName, event, source)
    return {
        event = event,
        boss = bossName,
        source = source,
        clock = os.clock(),
        unix = os.time(),
        task = currentTask(context),
        schedulerReason = context.State.schedulerReason,
    }
end

function BossTelemetry.observe(context, bossName, model, source)
    local state = context.State
    state.bossPresence = state.bossPresence or {}
    state.bossSightings = state.bossSightings or {}

    local alive, health, position, instanceKey = modelSnapshot(model)
    local previous = state.bossPresence[bossName]
    local now = os.clock()

    if alive and (not previous or not previous.alive
        or previous.instance ~= model)
    then
        local row = eventBase(context, bossName, "spawned", source)
        row.health = health
        row.position = position
        row.instanceKey = instanceKey
        appendBounded(state.bossSightings, row, MAX_SIGHTINGS)
        persist(context, row)
    elseif not alive and previous and previous.alive then
        local row = eventBase(context, bossName, "gone", source)
        row.lastHealth = previous.health
        row.lastPosition = previous.position
        row.firstSeenAt = previous.firstSeenAt
        appendBounded(state.bossSightings, row, MAX_SIGHTINGS)
        persist(context, row)
    end

    if alive then
        state.bossPresence[bossName] = {
            alive = true,
            instance = model,
            instanceKey = instanceKey,
            health = health,
            position = position,
            firstSeenAt = previous and previous.alive
                and previous.instance == model and previous.firstSeenAt or now,
            lastSeenAt = now,
            source = source,
        }
    else
        state.bossPresence[bossName] = {
            alive = false,
            instanceKey = previous and previous.instanceKey or nil,
            health = previous and previous.health or nil,
            position = previous and previous.position or nil,
            firstSeenAt = previous and previous.firstSeenAt or nil,
            lastSeenAt = previous and previous.lastSeenAt or nil,
            goneAt = previous and previous.alive and now
                or previous and previous.goneAt or nil,
            source = source,
        }
    end
    return alive
end

local function appendEngagement(context, bossName, event, source, extra)
    local state = context.State
    state.bossEngagements = state.bossEngagements or {}
    local row = eventBase(context, bossName, event, source)
    for key, value in extra or {} do
        row[key] = value
    end
    appendBounded(state.bossEngagements, row, MAX_ENGAGEMENTS)
    persist(context, row)
    return row
end

function BossTelemetry.select(context, bossName, source, topTask)
    local state = context.State
    local previous = state.bossSelection
    local event = (topTask == "Farm Boss" or topTask == "Special Boss")
        and "selected" or "deferred"
    local signature = bossName and table.concat({
        tostring(bossName),
        tostring(source),
        tostring(topTask),
    }, "|") or nil

    if previous and previous.signature ~= signature then
        appendEngagement(
            context,
            previous.boss,
            "selection-cleared",
            previous.source,
            { nextBoss = bossName, nextTask = topTask }
        )
    end

    if bossName and (not previous or previous.signature ~= signature) then
        appendEngagement(context, bossName, event, source, {
            topTask = topTask,
        })
    end

    state.bossSelection = bossName and {
        boss = bossName,
        source = source,
        topTask = topTask,
        event = event,
        signature = signature,
        at = os.clock(),
    } or nil

    local active = state.activeBossEngagement
    if active and active.taskName == "Farm Boss"
        and (active.boss ~= bossName or topTask ~= "Farm Boss")
    then
        BossTelemetry.finish(
            context,
            active.boss,
            topTask and "preempted:" .. topTask or "selection-cleared"
        )
    end
end

function BossTelemetry.engage(context, bossName, model, taskName, phase)
    local state = context.State
    local _, health, position, instanceKey = modelSnapshot(model)
    local previous = state.activeBossEngagement
    local signature = table.concat({
        tostring(bossName),
        tostring(taskName),
        tostring(phase or "combat"),
        tostring(instanceKey),
    }, "|")

    if not previous or previous.signature ~= signature then
        if previous then
            BossTelemetry.finish(context, previous.boss, "engagement-changed")
        end
        appendEngagement(context, bossName, "engaged", phase or "combat", {
            taskName = taskName,
            health = health,
            position = position,
            instanceKey = instanceKey,
        })
    end

    state.activeBossEngagement = {
        boss = bossName,
        taskName = taskName,
        phase = phase or "combat",
        signature = signature,
        instanceKey = instanceKey,
        health = health,
        position = position,
        startedAt = previous and previous.signature == signature
            and previous.startedAt or os.clock(),
        lastUpdatedAt = os.clock(),
    }
end

function BossTelemetry.finish(context, bossName, reason)
    local state = context.State
    local active = state.activeBossEngagement
    if not active or active.boss ~= bossName then
        return false
    end

    appendEngagement(context, bossName, "released", active.phase, {
        taskName = active.taskName,
        reason = reason,
        startedAt = active.startedAt,
        lastHealth = active.health,
        lastPosition = active.position,
    })
    state.activeBossEngagement = nil
    return true
end
end

local RaidTaskPolicy
do
RaidTaskPolicy = {}
RaidTaskPolicy.MaximumLevel = 2800
RaidTaskPolicy.CacheSeconds = 5
RaidTaskPolicy.Cache = {}
RaidTaskPolicy.MaxCacheEntries = 64

local STYLE_FRAGMENT_COSTS = {
    ["Dragon Claw"] = 1500,
    ["Death Step"] = 5000,
    ["Sharkman Karate"] = 5000,
    ["Electric Claw"] = 5000,
    ["Dragon Talon"] = 5000,
    Godhuman = 5000,
}

local function cacheKey(options)
    return table.concat({
        tostring(tonumber(options.level) or 0),
        tostring(tonumber(options.fragments) or 0),
        tostring(tonumber(options.maximumLevel) or RaidTaskPolicy.MaximumLevel),
        options.ownsDragonClaw == true and "1" or "0",
        options.expBoostActive == true and "1" or "0",
        options.ownsGodhuman == true and "1" or "0",
        options.inRaidSea == true and "1" or "0",
        tostring(options.styleTarget or ""),
        options.styleTargetOwned == true and "1" or "0",
    }, ":")
end

function RaidTaskPolicy.decide(options)
    options = options or {}
    local key = cacheKey(options)
    local now = os.clock()
    PolicyCache.prepare(RaidTaskPolicy, nil, now, RaidTaskPolicy.CacheSeconds)
    local cached = RaidTaskPolicy.Cache[key]
    if cached and now - cached.at <= RaidTaskPolicy.CacheSeconds then
        return cached.value
    end

    local level = tonumber(options.level) or 0
    local fragments = math.max(0, tonumber(options.fragments) or 0)
    local maximumLevel = tonumber(options.maximumLevel) or RaidTaskPolicy.MaximumLevel
    if maximumLevel < 1 then
        maximumLevel = RaidTaskPolicy.MaximumLevel
    end

    local target
    if level >= maximumLevel then
        target = 10000
    elseif level >= 1500 then
        target = 5000
    elseif level >= 1300 then
        target = 2000
    end

    local styleCost = STYLE_FRAGMENT_COSTS[options.styleTarget] or 0
    local decision = {
        autoTarget = target,
        autoDeficit = target and options.expBoostActive ~= true
            and options.ownsGodhuman ~= true
            and math.max(0, target - fragments) or 0,
        initialReserve = target ~= nil and options.ownsDragonClaw ~= true
            and fragments < 2000,
        canStart = target ~= nil and options.inRaidSea == true,
        styleDeficit = math.max(0, styleCost - fragments),
    }
    PolicyCache.put(RaidTaskPolicy, key, decision, now)
    return decision
end
end

local QuestData
do
QuestData = {}

local PLACE_TO_SEA = {
    [2753915549] = 1,
    [4442272183] = 2,
    [7449423635] = 3,
    [85211729168715] = 1,
    [100117331123089] = 3,
    [79091703265657] = 2,
}

local ARYA_BLACKLISTED_FAMILIES = {
    BartiloQuest = true,
    CitizenQuest = true,
    Trainees = true,
    ImpelQuest = true,
    MarineQuest = true,
}

local SEA_LEVEL_RANGES = {
    [1] = { 0, 699 },
    [2] = { 700, 1499 },
    [3] = { 1500, math.huge },
}

local function detectSeaFromMap()
    local map = workspace and workspace:FindFirstChild("Map")
    if not map then
        return nil
    end
    if map:FindFirstChild("Dressrosa") and map:FindFirstChild("GreenBit") then
        return 2
    end
    if map:FindFirstChild("HauntedCastle") or map:FindFirstChild("TikiOutpost")
        or map:FindFirstChild("GreatTree")
    then
        return 3
    end
    return 1
end

local DATA = {
    [1] = {
        {
            mob_pos = CFrame.new(1045.962646484375, 27.00250816345215, 1560.8203125),
            level_req = 0,
            quest_name = "BanditQuest1",
            quest_num = 1,
            mob_name = "Bandit",
            quest_pos = CFrame.new(1058.9927978515625, 16.13587760925293, 1551.7337646484375),
        },
        {
            mob_pos = CFrame.new(-1448.51806640625, 67.85301208496094, 11.46579647064209),
            level_req = 10,
            quest_name = "JungleQuest",
            quest_num = 1,
            mob_name = "Monkey",
            quest_pos = CFrame.new(-1598.089111328125, 35.55011749267578, 153.37783813476562),
        },
        {
            mob_pos = CFrame.new(-1129.8836669921875, 40.46354675292969, -525.4237060546875),
            level_req = 15,
            quest_name = "JungleQuest",
            quest_num = 2,
            mob_name = "Gorilla",
            quest_pos = CFrame.new(-1598.089111328125, 35.55011749267578, 153.37783813476562),
        },
        {
            mob_pos = CFrame.new(-1103.513427734375, 13.752052307128906, 3896.091064453125),
            level_req = 30,
            quest_name = "BuggyQuest1",
            quest_num = 1,
            mob_name = "Pirate",
            quest_pos = CFrame.new(-1141.0751953125, 4.10001277923584, 3831.5498046875),
        },
        {
            mob_pos = CFrame.new(-1140.083740234375, 14.809885025024414, 4322.92138671875),
            level_req = 40,
            quest_name = "BuggyQuest1",
            quest_num = 2,
            mob_name = "Brute",
            quest_pos = CFrame.new(-1141.0751953125, 4.10001277923584, 3831.5498046875),
        },
        {
            mob_pos = CFrame.new(924.7998046875, 6.44867467880249, 4481.5859375),
            level_req = 60,
            quest_name = "DesertQuest",
            quest_num = 1,
            mob_name = "Desert Bandit",
            quest_pos = CFrame.new(894.4886474609375, 5.140007019042969, 4392.43359375),
        },
        {
            mob_pos = CFrame.new(1608.2822265625, 8.614224433898926, 4371.00732421875),
            level_req = 75,
            quest_name = "DesertQuest",
            quest_num = 2,
            mob_name = "Desert Officer",
            quest_pos = CFrame.new(894.4886474609375, 5.140007019042969, 4392.43359375),
        },
        {
            mob_pos = CFrame.new(1354.347900390625, 87.27277374267578, -1393.946533203125),
            level_req = 90,
            quest_name = "SnowQuest",
            quest_num = 1,
            mob_name = "Snow Bandit",
            quest_pos = CFrame.new(1387.1883544921875, 86.6207504272461, -1295.0445556640625),
        },
        {
            mob_pos = CFrame.new(1201.6412353515625, 144.57958984375, -1550.0670166015625),
            level_req = 100,
            quest_name = "SnowQuest",
            quest_num = 2,
            mob_name = "Snowman",
            quest_pos = CFrame.new(1387.1883544921875, 86.6207504272461, -1295.0445556640625),
        },
        {
            mob_pos = CFrame.new(-4881.23095703125, 22.65204429626465, 4273.75244140625),
            level_req = 120,
            quest_name = "MarineQuest2",
            quest_num = 1,
            mob_name = "Chief Petty Officer",
            quest_pos = CFrame.new(-5039.58642578125, 27.350038528442383, 4324.68017578125),
        },
        {
            mob_pos = CFrame.new(-4953.20703125, 295.74420166015625, -2899.22900390625),
            level_req = 150,
            quest_name = "SkyQuest",
            quest_num = 1,
            mob_name = "Sky Bandit",
            quest_pos = CFrame.new(-4839.5302734375, 716.3685913085938, -2619.441650390625),
        },
        {
            mob_pos = CFrame.new(-5259.8447265625, 391.3976745605469, -2229.035400390625),
            level_req = 175,
            quest_name = "SkyQuest",
            quest_num = 2,
            mob_name = "Dark Master",
            quest_pos = CFrame.new(-4839.5302734375, 716.3685913085938, -2619.441650390625),
        },
        {
            mob_pos = CFrame.new(5098.9736328125, -0.3204058110713959, 474.2373352050781),
            level_req = 190,
            quest_name = "PrisonerQuest",
            quest_num = 1,
            mob_name = "Prisoner",
            quest_pos = CFrame.new(5310.60546875, 0.35001492500305176, 474.94659423828125),
        },
        {
            mob_pos = CFrame.new(5654.5634765625, 15.633401870727539, 866.2991943359375),
            level_req = 210,
            quest_name = "PrisonerQuest",
            quest_num = 2,
            mob_name = "Dangerous Prisoner",
            quest_pos = CFrame.new(5310.60546875, 0.35001492500305176, 474.94659423828125),
        },
        {
            mob_pos = CFrame.new(5654.5634765625, 15.633401870727539, 866.2991943359375),
            level_req = 225,
            quest_name = "ImpelQuest",
            quest_num = 1,
            mob_name = "Ruthless Prisoner",
            quest_pos = CFrame.new(5320.666015625, 18.8861141204834, 856.2811889648438),
            arya_blacklisted = true,
        },
        {
            mob_pos = CFrame.new(-1820.21484375, 51.68385696411133, -2740.6650390625),
            level_req = 250,
            quest_name = "ColosseumQuest",
            quest_num = 1,
            mob_name = "Toga Warrior",
            quest_pos = CFrame.new(-1580.046630859375, 6.350002765655518, -2986.475341796875),
        },
        {
            mob_pos = CFrame.new(-1380, 36, -3405),
            level_req = 275,
            quest_name = "ColosseumQuest",
            quest_num = 2,
            mob_name = "Gladiator",
            quest_pos = CFrame.new(-1580.046630859375, 6.350002765655518, -2986.475341796875),
        },
        {
            mob_pos = CFrame.new(-5411.16455078125, 11.081554412841797, 8454.29296875),
            level_req = 300,
            quest_name = "MagmaQuest",
            quest_num = 1,
            mob_name = "Military Soldier",
            quest_pos = CFrame.new(-5313.3701171875, 10.950008392333984, 8515.2939453125),
        },
        {
            mob_pos = CFrame.new(-5802.8681640625, 86.26241302490234, 8828.859375),
            level_req = 325,
            quest_name = "MagmaQuest",
            quest_num = 2,
            mob_name = "Military Spy",
            quest_pos = CFrame.new(-5313.3701171875, 10.950008392333984, 8515.2939453125),
        },
        {
            mob_pos = CFrame.new(60878.30078125, 18.482830047607422, 1543.7574462890625),
            level_req = 375,
            quest_name = "FishmanQuest",
            quest_num = 1,
            mob_name = "Fishman Warrior",
            quest_pos = CFrame.new(61121.109375, 17.953125, 1564.5263671875),
        },
        {
            mob_pos = CFrame.new(61922.6328125, 18.482830047607422, 1493.934326171875),
            level_req = 400,
            quest_name = "FishmanQuest",
            quest_num = 2,
            mob_name = "Fishman Commando",
            quest_pos = CFrame.new(61121.109375, 17.953125, 1564.5263671875),
        },
        {
            mob_pos = CFrame.new(-4710.04296875, 845.2769775390625, -1927.3079833984375),
            level_req = 450,
            quest_name = "SkyExp1Quest",
            quest_num = 1,
            mob_name = "God's Guard",
            quest_pos = CFrame.new(-4721.9521484375, 844.1746826171875, -1949.243408203125),
        },
        {
            mob_pos = CFrame.new(-7678.48974609375, 5566.40380859375, -497.2156066894531),
            level_req = 475,
            quest_name = "SkyExp1Quest",
            quest_num = 2,
            mob_name = "Shanda",
            quest_pos = CFrame.new(-7859.09814453125, 5544.1904296875, -381.4761962890625),
        },
        {
            mob_pos = CFrame.new(-7624.25244140625, 5658.13330078125, -1467.354248046875),
            level_req = 525,
            quest_name = "SkyExp2Quest",
            quest_num = 1,
            mob_name = "Royal Squad",
            quest_pos = CFrame.new(-7904.6845703125, 5634.6611328125, -1409.96728515625),
        },
        {
            mob_pos = CFrame.new(-7806.75341796875, 5645.6640625, -1760.6236572265625),
            level_req = 550,
            quest_name = "SkyExp2Quest",
            quest_num = 2,
            mob_name = "Royal Soldier",
            quest_pos = CFrame.new(-7904.6845703125, 5634.6611328125, -1409.96728515625),
        },
        {
            mob_pos = CFrame.new(5551.02197265625, 78.90135192871094, 3930.412841796875),
            level_req = 625,
            quest_name = "FountainQuest",
            quest_num = 1,
            mob_name = "Galley Pirate",
            quest_pos = CFrame.new(5259.81982421875, 37.35001754760742, 4050.029296875),
        },
        {
            mob_pos = CFrame.new(5441.95166015625, 42.50205993652344, 4950.09375),
            level_req = 650,
            quest_name = "FountainQuest",
            quest_num = 2,
            mob_name = "Galley Captain",
            quest_pos = CFrame.new(5259.81982421875, 37.35001754760742, 4050.029296875),
        },
    },
    [2] = {
        {
            mob_pos = CFrame.new(319.1539611816406, 39.142494201660156, 2380.25830078125),
            level_req = 700,
            quest_name = "Area1Quest",
            quest_num = 1,
            mob_name = "Raider",
            quest_pos = CFrame.new(-429.54351806640625, 71.7699966430664, 1836.181884765625),
        },
        {
            mob_pos = CFrame.new(-1004.3244018554688, 80.15886688232422, 1424.619384765625),
            level_req = 725,
            quest_name = "Area1Quest",
            quest_num = 2,
            mob_name = "Mercenary",
            quest_pos = CFrame.new(-429.54351806640625, 71.7699966430664, 1836.181884765625),
        },
        {
            mob_pos = CFrame.new(1068.664306640625, 137.61428833007812, 1322.1060791015625),
            level_req = 775,
            quest_name = "Area2Quest",
            quest_num = 1,
            mob_name = "Swan Pirate",
            quest_pos = CFrame.new(638.4381103515625, 71.76998901367188, 918.2828979492188),
        },
        {
            mob_pos = CFrame.new(73.07867431640625, 81.86344146728516, -27.470672607421875),
            level_req = 800,
            quest_name = "Area2Quest",
            quest_num = 2,
            mob_name = "Factory Staff",
            quest_pos = CFrame.new(638.4381103515625, 71.76998901367188, 918.2828979492188),
        },
        {
            mob_pos = CFrame.new(-2821.372314453125, 95.89727783203125, -3070.089111328125),
            level_req = 875,
            quest_name = "MarineQuest3",
            quest_num = 1,
            mob_name = "Marine Lieutenant",
            quest_pos = CFrame.new(-2440.79638671875, 71.71407318115234, -3216.068115234375),
        },
        {
            mob_pos = CFrame.new(-1861.2310791015625, 80.17658233642578, -3254.697509765625),
            level_req = 900,
            quest_name = "MarineQuest3",
            quest_num = 2,
            mob_name = "Marine Captain",
            quest_pos = CFrame.new(-2440.79638671875, 71.71407318115234, -3216.068115234375),
        },
        {
            mob_pos = CFrame.new(-5657.77685546875, 78.96973419189453, -928.68701171875),
            level_req = 950,
            quest_name = "ZombieQuest",
            quest_num = 1,
            mob_name = "Zombie",
            quest_pos = CFrame.new(-5497.0615234375, 47.59230041503906, -795.237060546875),
        },
        {
            mob_pos = CFrame.new(-6037.66796875, 32.18463897705078, -1340.6597900390625),
            level_req = 975,
            quest_name = "ZombieQuest",
            quest_num = 2,
            mob_name = "Vampire",
            quest_pos = CFrame.new(-5497.0615234375, 47.59230041503906, -795.237060546875),
        },
        {
            mob_pos = CFrame.new(549.1473388671875, 427.3870544433594, -5563.69873046875),
            level_req = 1000,
            quest_name = "SnowMountainQuest",
            quest_num = 1,
            mob_name = "Snow Trooper",
            quest_pos = CFrame.new(609.8588256835938, 400.1199035644531, -5372.25927734375),
        },
        {
            mob_pos = CFrame.new(1142.7451171875, 475.6398010253906, -5199.41650390625),
            level_req = 1050,
            quest_name = "SnowMountainQuest",
            quest_num = 2,
            mob_name = "Winter Warrior",
            quest_pos = CFrame.new(609.8588256835938, 400.1199035644531, -5372.25927734375),
        },
        {
            mob_pos = CFrame.new(-5707.4716796875, 15.951709747314453, -4513.39208984375),
            level_req = 1100,
            quest_name = "IceSideQuest",
            quest_num = 1,
            mob_name = "Lab Subordinate",
            quest_pos = CFrame.new(-6231.98291015625, 81.80485534667969, -4852.8056640625),
        },
        {
            mob_pos = CFrame.new(-6341.36669921875, 15.951770782470703, -5723.162109375),
            level_req = 1125,
            quest_name = "IceSideQuest",
            quest_num = 2,
            mob_name = "Horned Warrior",
            quest_pos = CFrame.new(-6231.98291015625, 81.80485534667969, -4852.8056640625),
        },
        {
            mob_pos = CFrame.new(-5449.6728515625, 76.65874481201172, -5808.20068359375),
            level_req = 1175,
            quest_name = "FireSideQuest",
            quest_num = 1,
            mob_name = "Magma Ninja",
            quest_pos = CFrame.new(-5406.77783203125, 29.1487979888916, -5371.88671875),
        },
        {
            mob_pos = CFrame.new(-5213.33154296875, 49.73788070678711, -4701.451171875),
            level_req = 1200,
            quest_name = "FireSideQuest",
            quest_num = 2,
            mob_name = "Lava Pirate",
            quest_pos = CFrame.new(-5406.77783203125, 29.1487979888916, -5371.88671875),
        },
        {
            mob_pos = CFrame.new(1212.0111083984375, 150.79205322265625, 33059.24609375),
            level_req = 1250,
            quest_name = "ShipQuest1",
            quest_num = 1,
            mob_name = "Ship Deckhand",
            quest_pos = CFrame.new(1040.5555419921875, 124.94292449951172, 32909.10546875),
        },
        {
            mob_pos = CFrame.new(919.4786376953125, 43.54401397705078, 32779.96875),
            level_req = 1275,
            quest_name = "ShipQuest1",
            quest_num = 2,
            mob_name = "Ship Engineer",
            quest_pos = CFrame.new(1040.5555419921875, 124.94292449951172, 32909.10546875),
        },
        {
            mob_pos = CFrame.new(919.4385375976562, 129.55599975585938, 33436.03515625),
            level_req = 1300,
            quest_name = "ShipQuest2",
            quest_num = 1,
            mob_name = "Ship Steward",
            quest_pos = CFrame.new(974.075439453125, 124.93901824951172, 33253.62109375),
        },
        {
            mob_pos = CFrame.new(1036.0179443359375, 181.4390411376953, 33315.7265625),
            level_req = 1325,
            quest_name = "ShipQuest2",
            quest_num = 2,
            mob_name = "Ship Officer",
            quest_pos = CFrame.new(974.075439453125, 124.93901824951172, 33253.62109375),
        },
        {
            mob_pos = CFrame.new(5966.24609375, 62.97002029418945, -6179.3828125),
            level_req = 1350,
            quest_name = "FrostQuest",
            quest_num = 1,
            mob_name = "Arctic Warrior",
            quest_pos = CFrame.new(5667.658203125, 26.799781799316406, -6486.08984375),
        },
        {
            mob_pos = CFrame.new(5407.07373046875, 69.19437408447266, -6880.88037109375),
            level_req = 1375,
            quest_name = "FrostQuest",
            quest_num = 2,
            mob_name = "Snow Lurker",
            quest_pos = CFrame.new(5667.658203125, 26.799781799316406, -6486.08984375),
        },
        {
            mob_pos = CFrame.new(-3240.3310546875, 27.4530029296875, -9813.9658203125),
            level_req = 1425,
            quest_name = "ForgottenQuest",
            quest_num = 1,
            mob_name = "Sea Soldier",
            quest_pos = CFrame.new(-3054.444580078125, 238.34426879882812, -10142.8193359375),
        },
        {
            mob_pos = CFrame.new(-3352.9013671875, 285.01556396484375, -10534.841796875),
            level_req = 1450,
            quest_name = "ForgottenQuest",
            quest_num = 2,
            mob_name = "Water Fighter",
            quest_pos = CFrame.new(-3054.444580078125, 238.34426879882812, -10142.8193359375),
        },
    },
    [3] = {
        {
            mob_pos = CFrame.new(-245.9963836669922, 47.30615234375, 5584.1005859375),
            level_req = 1500,
            quest_name = "PiratePortQuest",
            quest_num = 1,
            mob_name = "Pirate Millionaire",
            quest_pos = CFrame.new(-290.0746765136719, 42.903465270996094, 5581.58984375),
        },
        {
            mob_pos = CFrame.new(-187.3301544189453, 86.23987579345703, 6013.513671875),
            level_req = 1525,
            quest_name = "PiratePortQuest",
            quest_num = 2,
            mob_name = "Pistol Billionaire",
            quest_pos = CFrame.new(-290.0746765136719, 42.903465270996094, 5581.58984375),
        },
        {
            mob_pos = CFrame.new(6778, 108.53675842285156, -1044.1842041015625),
            level_req = 1575,
            quest_name = "DragonCrewQuest",
            quest_num = 1,
            mob_name = "Dragon Crew Warrior",
            quest_pos = CFrame.new(6735.11083984375, 126.99046325683594, -711.0979614257812),
        },
        {
            mob_pos = CFrame.new(6743.814453125, 536.5570678710938, 345.12908935546875),
            level_req = 1600,
            quest_name = "DragonCrewQuest",
            quest_num = 2,
            mob_name = "Dragon Crew Archer",
            quest_pos = CFrame.new(6735.11083984375, 126.99046325683594, -711.0979614257812),
        },
        {
            mob_pos = CFrame.new(4685.25830078125, 735.8078002929688, 815.3425903320312),
            level_req = 1625,
            quest_name = "VenomCrewQuest",
            quest_num = 1,
            mob_name = "Hydra Enforcer",
            quest_pos = CFrame.new(5214.33935546875, 1003.4676513671875, 759.50732421875),
        },
        {
            mob_pos = CFrame.new(4729.09423828125, 590.436767578125, -36.97627639770508),
            level_req = 1650,
            quest_name = "VenomCrewQuest",
            quest_num = 2,
            mob_name = "Venomous Assailant",
            quest_pos = CFrame.new(5214.33935546875, 1003.4676513671875, 759.50732421875),
        },
        {
            mob_pos = CFrame.new(2286.0078125, 73.13391876220703, -7159.80908203125),
            level_req = 1700,
            quest_name = "MarineTreeIsland",
            quest_num = 1,
            mob_name = "Marine Commodore",
            quest_pos = CFrame.new(2485.7333984375, 73.34599304199219, -6788.62548828125),
        },
        {
            mob_pos = CFrame.new(3656.773681640625, 160.52406311035156, -7001.5986328125),
            level_req = 1725,
            quest_name = "MarineTreeIsland",
            quest_num = 2,
            mob_name = "Marine Rear Admiral",
            quest_pos = CFrame.new(2485.7333984375, 73.34599304199219, -6788.62548828125),
        },
        {
            mob_pos = CFrame.new(-10407.5263671875, 331.76263427734375, -8368.5166015625),
            level_req = 1775,
            quest_name = "DeepForestIsland3",
            quest_num = 1,
            mob_name = "Fishman Raider",
            quest_pos = CFrame.new(-10581.65625, 330.8729553222656, -8761.1865234375),
        },
        {
            mob_pos = CFrame.new(-10994.701171875, 352.38140869140625, -9002.1103515625),
            level_req = 1800,
            quest_name = "DeepForestIsland3",
            quest_num = 2,
            mob_name = "Fishman Captain",
            quest_pos = CFrame.new(-10581.65625, 330.8729553222656, -8761.1865234375),
        },
        {
            mob_pos = CFrame.new(-13274.478515625, 332.3781433105469, -7769.58056640625),
            level_req = 1825,
            quest_name = "DeepForestIsland",
            quest_num = 1,
            mob_name = "Forest Pirate",
            quest_pos = CFrame.new(-13234.0400390625, 331.4884948730469, -7625.4013671875),
        },
        {
            mob_pos = CFrame.new(-13680.607421875, 501.08154296875, -6991.189453125),
            level_req = 1850,
            quest_name = "DeepForestIsland",
            quest_num = 2,
            mob_name = "Mythological Pirate",
            quest_pos = CFrame.new(-13234.0400390625, 331.4884948730469, -7625.4013671875),
        },
        {
            mob_pos = CFrame.new(-12256.16015625, 331.73828125, -10485.8369140625),
            level_req = 1900,
            quest_name = "DeepForestIsland2",
            quest_num = 1,
            mob_name = "Jungle Pirate",
            quest_pos = CFrame.new(-12680.3818359375, 389.9710388183594, -9902.01953125),
        },
        {
            mob_pos = CFrame.new(-13457.904296875, 391.545654296875, -9859.177734375),
            level_req = 1925,
            quest_name = "DeepForestIsland2",
            quest_num = 2,
            mob_name = "Musketeer Pirate",
            quest_pos = CFrame.new(-12680.3818359375, 389.9710388183594, -9902.01953125),
        },
        {
            mob_pos = CFrame.new(-8763.7236328125, 165.72299194335938, 6159.86181640625),
            level_req = 1975,
            quest_name = "HauntedQuest1",
            quest_num = 1,
            mob_name = "Reborn Skeleton",
            quest_pos = CFrame.new(-9479.216796875, 141.215087890625, 5566.0927734375),
        },
        {
            mob_pos = CFrame.new(-10144.1318359375, 138.62667846679688, 5838.0888671875),
            level_req = 2000,
            quest_name = "HauntedQuest1",
            quest_num = 2,
            mob_name = "Living Zombie",
            quest_pos = CFrame.new(-9479.216796875, 141.215087890625, 5566.0927734375),
        },
        {
            mob_pos = CFrame.new(-9505.8720703125, 172.10482788085938, 6158.9931640625),
            level_req = 2025,
            quest_name = "HauntedQuest2",
            quest_num = 1,
            mob_name = "Demonic Soul",
            quest_pos = CFrame.new(-9516.9931640625, 172.01718139648438, 6078.46533203125),
        },
        {
            mob_pos = CFrame.new(-9582.0224609375, 6.251527309417725, 6205.478515625),
            level_req = 2050,
            quest_name = "HauntedQuest2",
            quest_num = 2,
            mob_name = "Posessed Mummy",
            quest_pos = CFrame.new(-9516.9931640625, 172.01718139648438, 6078.46533203125),
        },
        {
            mob_pos = CFrame.new(-2143.241943359375, 47.72198486328125, -10029.9951171875),
            level_req = 2075,
            quest_name = "NutsIslandQuest",
            quest_num = 1,
            mob_name = "Peanut Scout",
            quest_pos = CFrame.new(-2105.531982421875, 37.24959945678711, -10195.5087890625),
        },
        {
            mob_pos = CFrame.new(-1859.35400390625, 38.10316848754883, -10422.4296875),
            level_req = 2100,
            quest_name = "NutsIslandQuest",
            quest_num = 2,
            mob_name = "Peanut President",
            quest_pos = CFrame.new(-2105.531982421875, 37.24959945678711, -10195.5087890625),
        },
        {
            mob_pos = CFrame.new(-872.24658203125, 65.81957244873047, -10919.95703125),
            level_req = 2125,
            quest_name = "IceCreamIslandQuest",
            quest_num = 1,
            mob_name = "Ice Cream Chef",
            quest_pos = CFrame.new(-819.376708984375, 64.92597961425781, -10967.283203125),
        },
        {
            mob_pos = CFrame.new(-558.06103515625, 112.04895782470703, -11290.7744140625),
            level_req = 2150,
            quest_name = "IceCreamIslandQuest",
            quest_num = 2,
            mob_name = "Ice Cream Commander",
            quest_pos = CFrame.new(-819.376708984375, 64.92597961425781, -10967.283203125),
        },
        {
            mob_pos = CFrame.new(-2374.13671875, 37.79826354980469, -12125.30859375),
            level_req = 2200,
            quest_name = "CakeQuest1",
            quest_num = 1,
            mob_name = "Cookie Crafter",
            quest_pos = CFrame.new(-2022.298583984375, 36.927589416503906, -12030.9765625),
        },
        {
            mob_pos = CFrame.new(-1598.3070068359375, 43.773197174072266, -12244.5810546875),
            level_req = 2225,
            quest_name = "CakeQuest1",
            quest_num = 2,
            mob_name = "Cake Guard",
            quest_pos = CFrame.new(-2022.298583984375, 36.927589416503906, -12030.9765625),
        },
        {
            mob_pos = CFrame.new(-1887.8099365234375, 77.6185073852539, -12998.3505859375),
            level_req = 2250,
            quest_name = "CakeQuest2",
            quest_num = 1,
            mob_name = "Baking Staff",
            quest_pos = CFrame.new(-1928.317626953125, 37.72966384887695, -12840.6259765625),
        },
        {
            mob_pos = CFrame.new(-2216.188232421875, 82.884521484375, -12869.2939453125),
            level_req = 2275,
            quest_name = "CakeQuest2",
            quest_num = 2,
            mob_name = "Head Baker",
            quest_pos = CFrame.new(-1928.317626953125, 37.72966384887695, -12840.6259765625),
        },
        {
            mob_pos = CFrame.new(-21.55328369140625, 80.57499694824219, -12352.3876953125),
            level_req = 2300,
            quest_name = "ChocQuest1",
            quest_num = 1,
            mob_name = "Cocoa Warrior",
            quest_pos = CFrame.new(231.75, 23.90030288696289, -12200.2919921875),
        },
        {
            mob_pos = CFrame.new(582.590576171875, 77.18809509277344, -12463.162109375),
            level_req = 2325,
            quest_name = "ChocQuest1",
            quest_num = 2,
            mob_name = "Chocolate Bar Battler",
            quest_pos = CFrame.new(231.75, 23.90030288696289, -12200.2919921875),
        },
        {
            mob_pos = CFrame.new(165.1884765625, 76.05885314941406, -12600.8369140625),
            level_req = 2350,
            quest_name = "ChocQuest2",
            quest_num = 1,
            mob_name = "Sweet Thief",
            quest_pos = CFrame.new(151.1982421875, 23.890714645385742, -12774.6171875),
        },
        {
            mob_pos = CFrame.new(134.86563110351562, 77.2476806640625, -12876.5478515625),
            level_req = 2375,
            quest_name = "ChocQuest2",
            quest_num = 2,
            mob_name = "Candy Rebel",
            quest_pos = CFrame.new(151.1982421875, 23.890714645385742, -12774.6171875),
        },
        {
            mob_pos = CFrame.new(-1310.5003662109375, 26.016523361206055, -14562.404296875),
            level_req = 2400,
            quest_name = "CandyQuest1",
            quest_num = 1,
            mob_name = "Candy Pirate",
            quest_pos = CFrame.new(-1164.498046875, 59.269073486328125, -14492.6181640625),
        },
        {
            mob_pos = CFrame.new(-905.5276489257812, 43.78125762939453, -14683.2177734375),
            level_req = 2425,
            quest_name = "CandyQuest1",
            quest_num = 2,
            mob_name = "Snow Demon",
            quest_pos = CFrame.new(-1164.498046875, 59.269073486328125, -14492.6181640625),
        },
        {
            mob_pos = CFrame.new(-16479.900390625, 226.6117401123047, -300.3114318847656),
            level_req = 2450,
            quest_name = "TikiQuest1",
            quest_num = 1,
            mob_name = "Isle Outlaw",
            quest_pos = CFrame.new(-16548.81640625, 55.60599136352539, -172.8125),
        },
        {
            mob_pos = CFrame.new(-16849.396484375, 192.86505126953125, -150.7853240966797),
            level_req = 2475,
            quest_name = "TikiQuest1",
            quest_num = 2,
            mob_name = "Island Boy",
            quest_pos = CFrame.new(-16548.81640625, 55.60599136352539, -172.8125),
        },
        {
            mob_pos = CFrame.new(-16347, 64, 984),
            level_req = 2500,
            quest_name = "TikiQuest2",
            quest_num = 1,
            mob_name = "Sun-kissed Warrior",
            quest_pos = CFrame.new(-16541.021484375, 54.77081298828125, 1051.461181640625),
        },
        {
            mob_pos = CFrame.new(-16602.1015625, 130.38734436035156, 1087.24560546875),
            level_req = 2525,
            quest_name = "TikiQuest2",
            quest_num = 2,
            mob_name = "Isle Champion",
            quest_pos = CFrame.new(-16541.021484375, 54.77081298828125, 1051.461181640625),
        },
        {
            mob_pos = CFrame.new(-16540.998046875, 148.70091247558594, 1524.616455078125),
            level_req = 2550,
            quest_name = "TikiQuest3",
            quest_num = 1,
            mob_name = "Serpent Hunter",
            quest_pos = CFrame.new(-16665.19140625, 104.59640502929688, 1579.6943359375),
        },
        {
            mob_pos = CFrame.new(-16760.80078125, 111.5384750366211, 1600.358154296875),
            level_req = 2575,
            quest_name = "TikiQuest3",
            quest_num = 2,
            mob_name = "Skull Slayer",
            quest_pos = CFrame.new(-16665.19140625, 104.59640502929688, 1579.6943359375),
        },
        {
            mob_pos = CFrame.new(10883.5478515625, -2160.20458984375, 9075.4833984375),
            level_req = 2601,
            quest_name = "SubmergedQuest1",
            quest_num = 1,
            mob_name = "Reef Bandit",
            quest_pos = CFrame.new(10780.6396484375, -2083.4140625, 9263.453125),
        },
        {
            mob_pos = CFrame.new(10680.076171875, -2056.6748046875, 9933.8896484375),
            level_req = 2651,
            quest_name = "SubmergedQuest2",
            quest_num = 1,
            mob_name = "Sea Chanter",
            quest_pos = CFrame.new(10883.5986328125, -2081.888916015625, 10037.01953125),
        },
        {
            mob_pos = CFrame.new(9854.435546875, -1995.0880126953125, 9963.9375),
            level_req = 2678,
            quest_name = "SubmergedQuest3",
            quest_num = 1,
            mob_name = "High Disciple",
            quest_pos = CFrame.new(9637.2939453125, -1988.1351318359375, 9619.3017578125),
        },
        {
            mob_pos = CFrame.new(9559.1943359375, -1994.3974609375, 9798.6650390625),
            level_req = 2780,
            quest_name = "SubmergedQuest3",
            quest_num = 2,
            mob_name = "Grand Devotee",
            quest_pos = CFrame.new(9637.2939453125, -1988.1351318359375, 9619.3017578125),
        },
    },
}

local function copyTable(source)
    local result = {}
    for key, value in source or {} do
        result[key] = value
    end
    return result
end

local function containsBossTask(quest)
    for _, required in type(quest) == "table" and quest.Task or {} do
        if tonumber(required) == 1 then
            return true
        end
    end
    return false
end

local function taskTarget(quest)
    for name, required in type(quest) == "table" and quest.Task or {} do
        return tostring(name), tonumber(required)
    end
    return nil, nil
end

local function staticTemplates(sea)
    local byFamily = {}
    for _, quest in DATA[sea] or {} do
        local family = byFamily[quest.quest_name]
        if not family then
            family = { first = quest, entries = {} }
            byFamily[quest.quest_name] = family
        end
        family.entries[quest.quest_num] = quest
    end
    return byFamily
end

function QuestData.mergeLive(sea, liveQuests)
    local levelRange = SEA_LEVEL_RANGES[sea]
    if not levelRange or type(liveQuests) ~= "table" then
        return {}
    end

    local templates = staticTemplates(sea)
    local routes = {}

    for familyName, sourceEntries in liveQuests do
        local first = type(sourceEntries) == "table" and sourceEntries[1]
        local firstLevel = first and tonumber(first.LevelReq)
        if firstLevel
            and firstLevel >= levelRange[1]
            and firstLevel <= levelRange[2]
            and not ARYA_BLACKLISTED_FAMILIES[familyName]
        then
            local familyEntries = table.clone(sourceEntries)
            if containsBossTask(familyEntries[#familyEntries]) then
                table.remove(familyEntries, #familyEntries)
            end

            local familyTemplate = templates[familyName]
            for questNumber, sourceQuest in familyEntries do
                local levelRequired = tonumber(sourceQuest.LevelReq)
                local mobName, requiredKills = taskTarget(sourceQuest)
                if levelRequired and mobName and levelRequired <= levelRange[2] then
                    local exactTemplate = familyTemplate
                        and familyTemplate.entries[questNumber]
                    local fallbackTemplate = familyTemplate and familyTemplate.first
                    local route = copyTable(exactTemplate or fallbackTemplate)

                    route.level_req = levelRequired
                    route.quest_name = familyName
                    route.quest_num = questNumber
                    route.mob_name = mobName
                    route.quest_required = requiredKills
                    route.accepted_name = sourceQuest.Name
                    route.live_quest_data = true

                    if not exactTemplate then
                        route.mob_pos = nil
                    end
                    routes[#routes + 1] = route
                end
            end
        end
    end

    table.sort(routes, function(left, right)
        if left.level_req ~= right.level_req then
            return left.level_req < right.level_req
        end
        if left.quest_name ~= right.quest_name then
            return left.quest_name < right.quest_name
        end
        return left.quest_num < right.quest_num
    end)
    return routes
end

local function liveQuestData()
    if not game or type(game.GetService) ~= "function" then
        return nil
    end
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local questModule = replicatedStorage:FindFirstChild("Quests")
    if not questModule then
        return nil
    end
    local loaded, quests = pcall(require, questModule)
    return loaded and type(quests) == "table" and quests or nil
end

function QuestData.forSea(sea)
    return DATA[sea] or {}
end

function QuestData.forPlace(placeId)
    local sea = PLACE_TO_SEA[placeId] or detectSeaFromMap()
    local liveRoutes = QuestData.mergeLive(sea, liveQuestData())
    if #liveRoutes > 0 then
        return liveRoutes
    end
    return QuestData.forSea(sea)
end
end

local QuestNotificationBridge
do
QuestNotificationBridge = {}

local COMPLETION_TEXT = "quest completed"
local COMPLETION_DEDUPE_SECONDS = 2

local function matchesLevelQuestKey(completedKey, levelQuestKey)
    if completedKey == nil or levelQuestKey == nil then
        return false
    end

    completedKey = tostring(completedKey)
    levelQuestKey = tostring(levelQuestKey)
    if completedKey == levelQuestKey then
        return true
    end
    return completedKey:sub(-(#levelQuestKey + 1)) == "\0" .. levelQuestKey
end

local function clearAcceptedQuestState(state)
    state.acceptedQuestKey = nil
    state.acceptedQuestAt = nil
    state.acceptedQuestConfirmed = nil
    state.acceptedQuestKills = nil
    state.acceptedQuestRequired = nil
    state.lastQuestSeenAt = nil
    state.questAcquire = nil
    state.questTarget = nil
    state.farmTarget = nil
    state.farmCluster = nil
    state.farmClusterCount = 0
    state.farmClusterName = nil
    state.currentFarmMobName = nil
    state.attackTarget = nil
    state.attackTargetNames = nil
    state.attackTask = nil
end

function QuestNotificationBridge.isQuestCompleted(message)
    return tostring(message or ""):lower():find(COMPLETION_TEXT, 1, true) ~= nil
end

function QuestNotificationBridge.record(state, message, now, source)
    if type(state) ~= "table" or not QuestNotificationBridge.isQuestCompleted(message) then
        return false
    end

    now = tonumber(now) or os.clock()
    local previousAt = tonumber(state.lastQuestCompletionNotificationAt)
    if previousAt and now - previousAt < COMPLETION_DEDUPE_SECONDS then
        return false
    end

    local completedKey = state.acceptedQuestKey or state.levelQuestKey
    state.completedQuestSequence = (tonumber(state.completedQuestSequence) or 0) + 1
    state.lastCompletedQuestKey = completedKey
    state.lastCompletedQuestAt = now
    if matchesLevelQuestKey(completedKey, state.levelQuestKey) then
        state.completedLevelQuestSequence = (tonumber(state.completedLevelQuestSequence) or 0) + 1
        state.lastCompletedLevelQuestKey = state.levelQuestKey
        state.lastCompletedLevelQuestAt = now
    end
    state.lastQuestCompletionNotificationAt = now
    state.lastQuestCompletionSource = source or "notification"
    state.lastQuestCompletionText = tostring(message or "")
    state.questCompletionPending = true
    clearAcceptedQuestState(state)
    return true
end

local function dispatch(bridge, message)
    local context = bridge and bridge.context
    local state = context and context.State
    if not state or state.stopped then
        return false
    end

    local recorded = QuestNotificationBridge.record(state, message, nil, "notification")
    if not recorded then
        return false
    end

    local functions = context.Functions or {}
    if type(functions.ReleaseBring) == "function" then
        pcall(functions.ReleaseBring)
    end
    if type(functions.CancelTween) == "function" then
        pcall(functions.CancelTween)
    end
    if type(functions.StopAttack) == "function" then
        pcall(functions.StopAttack)
    end
    state.status = "Auto Farm Level | Quest completed"
    return true
end

function QuestNotificationBridge.attach(context)
    if type(context) ~= "table" then
        return false, "context-unavailable"
    end

    local environment = context.Environment or (getgenv and getgenv() or _G)
    local bridge = environment.__SEAHUB_QUEST_NOTIFICATION_BRIDGE
    if type(bridge) ~= "table" then
        bridge = {}
        environment.__SEAHUB_QUEST_NOTIFICATION_BRIDGE = bridge
    end

    bridge.context = context
    bridge.callback = function(message)
        return dispatch(bridge, message)
    end
    environment.NotificationCallBack = bridge.callback

    if bridge.hookInstalled then
        context.State.questNotificationBridgeReady = true
        context.State.questNotificationBridgeError = nil
        return true
    end

    local hook = environment.hookfunction or hookfunction
    if type(hook) ~= "function" then
        context.State.questNotificationBridgeReady = false
        context.State.questNotificationBridgeError = "hookfunction-unavailable"
        return false, context.State.questNotificationBridgeError
    end

    local replicatedStorage = game:GetService("ReplicatedStorage")
    local notificationModule = replicatedStorage:FindFirstChild("Notification")
    if not notificationModule then
        context.State.questNotificationBridgeReady = false
        context.State.questNotificationBridgeError = "notification-module-unavailable"
        return false, context.State.questNotificationBridgeError
    end

    local loaded, notification = pcall(require, notificationModule)
    if not loaded or type(notification) ~= "table" or type(notification.new) ~= "function" then
        context.State.questNotificationBridgeReady = false
        context.State.questNotificationBridgeError = "notification-api-unavailable"
        return false, context.State.questNotificationBridgeError
    end

    local original
    local wrapper = function(message, ...)
        local callback = bridge.callback
        if type(callback) == "function" then
            pcall(callback, message)
        end
        return original(message, ...)
    end
    local wrapClosure = environment.newcclosure or newcclosure
    if type(wrapClosure) == "function" then
        wrapper = wrapClosure(wrapper)
    end

    local hooked, hookResult = pcall(function()
        original = hook(notification.new, wrapper)
    end)
    if not hooked or type(original) ~= "function" then
        context.State.questNotificationBridgeReady = false
        context.State.questNotificationBridgeError = hooked
            and "notification-hook-rejected" or tostring(hookResult)
        return false, context.State.questNotificationBridgeError
    end

    bridge.hookInstalled = true
    bridge.original = original
    context.State.questNotificationBridgeReady = true
    context.State.questNotificationBridgeError = nil
    return true
end

function QuestNotificationBridge.detach(context)
    local environment = context and context.Environment or (getgenv and getgenv() or _G)
    local bridge = environment and environment.__SEAHUB_QUEST_NOTIFICATION_BRIDGE
    if type(bridge) == "table" and bridge.context == context then
        bridge.context = nil
    end
end
end

local QuestRoutePolicy
do
QuestRoutePolicy = {}

local MAX_ROTATING_ENTRIES = 2

local function normalizedWords(value)
    local words = {}
    for word in string.lower(tostring(value or "")):gmatch("[a-z0-9]+") do
        if #word > 3 and word:sub(-1) == "s" then
            word = word:sub(1, -2)
        end
        words[word] = true
    end
    return words
end

local function titleMatchesMob(title, mobName)
    local titleWords = normalizedWords(title)
    local mobWords = normalizedWords(mobName)
    local matched = 0
    for word in mobWords do
        if titleWords[word] then
            matched += 1
        end
    end
    if matched >= 2 then
        return true
    end

    local lastMobWord
    for word in string.lower(tostring(mobName or "")):gmatch("[a-z0-9]+") do
        lastMobWord = word
    end
    if lastMobWord and #lastMobWord > 3 and lastMobWord:sub(-1) == "s" then
        lastMobWord = lastMobWord:sub(1, -2)
    end
    return lastMobWord ~= nil and titleWords[lastMobWord] == true
end

local function isEligible(quest, level)
    return quest.level_req <= level and quest.arya_blacklisted ~= true
end

local function keyMatchesRoute(key, routeKey)
    if key == nil or routeKey == nil then
        return false
    end

    key = tostring(key)
    routeKey = tostring(routeKey)
    if key == routeKey then
        return true
    end
    return key:sub(-(#routeKey + 1)) == "\0" .. routeKey
end

local function selectFamily(questData, level)
    local selected
    for _, quest in questData do
        if quest.level_req > level then
            break
        end
        if isEligible(quest, level) then
            selected = quest
        end
    end
    return selected and selected.quest_name or nil, selected
end

local function unlockedFamilyEntries(questData, familyName, level)
    local entries = {}
    for _, quest in questData do
        if quest.quest_name == familyName and isEligible(quest, level) then
            entries[#entries + 1] = quest
        end
    end
    table.sort(entries, function(left, right)
        if left.quest_num == right.quest_num then
            return left.level_req < right.level_req
        end
        return left.quest_num < right.quest_num
    end)
    while #entries > MAX_ROTATING_ENTRIES do
        table.remove(entries, MAX_ROTATING_ENTRIES + 1)
    end
    return entries
end

function QuestRoutePolicy.select(questData, level, state, activeQuestText)
    state = state or {}
    level = tonumber(level) or 0

    local desiredFamily, levelSelected = selectFamily(questData, level)
    if not desiredFamily then
        return nil
    end

    local completionSequence = tonumber(state.completedLevelQuestSequence) or 0
    local previousFamily = state.levelQuestFamily
    local turn = tonumber(state.levelQuestTurn)
    local lastCompletion = tonumber(state.levelQuestCompletionSequence)
    local completionDelta = lastCompletion and math.max(0, completionSequence - lastCompletion) or 0
    local familyName = previousFamily

    local previousEntries = previousFamily
        and unlockedFamilyEntries(questData, previousFamily, level) or {}
    local previousSelected = previousEntries[turn or 1]
    local previousRouteActive = keyMatchesRoute(state.acceptedQuestKey, state.levelQuestKey)
        or (previousSelected ~= nil
            and activeQuestText ~= nil
            and titleMatchesMob(activeQuestText, previousSelected.mob_name))

    if not familyName
        or completionDelta > 0
        or (familyName ~= desiredFamily and not previousRouteActive)
    then
        familyName = desiredFamily
    end

    local entries = unlockedFamilyEntries(questData, familyName, level)
    if #entries == 0 then
        familyName = desiredFamily
        entries = unlockedFamilyEntries(questData, familyName, level)
    end
    if #entries == 0 then
        return nil
    end

    if previousFamily == nil then
        turn = #entries > 1 and 2 or 1
    elseif previousFamily ~= familyName then
        turn = 1
    elseif completionDelta > 0 and #entries > 1 then
        turn = ((turn or 1) - 1 + completionDelta) % #entries + 1
    elseif not turn or turn < 1 or turn > #entries then
        turn = 1
    elseif #entries == 1 then
        turn = 1
    end

    local selected = entries[turn]
    if not selected then
        selected = levelSelected
        for index, quest in entries do
            if quest.quest_num == selected.quest_num then
                turn = index
                break
            end
        end
    end

    state.levelQuestFamily = familyName
    state.levelQuestTurn = turn
    state.levelQuestCompletionSequence = completionSequence
    state.levelQuestKey = familyName .. "\0" .. tostring(selected.quest_num)
    state.levelQuestActiveMatches = titleMatchesMob(activeQuestText, selected.mob_name)
    state.levelQuestReason = previousFamily == nil and "runtime-enter"
        or previousFamily ~= familyName and "family-enter"
        or completionDelta > 0 and "quest-completed"
        or "quest-in-progress"
    state.questCompletionPending = false

    return table.clone(selected)
end

QuestRoutePolicy.titleMatchesMob = titleMatchesMob
QuestRoutePolicy.unlockedFamilyEntries = unlockedFamilyEntries
end

local LevelFarmRoutePolicy
do
LevelFarmRoutePolicy = {}
LevelFarmRoutePolicy.CacheSeconds = 10
LevelFarmRoutePolicy.Cache = {}
LevelFarmRoutePolicy.MaxCacheEntries = 64

local function cacheKey(options)
    return table.concat({
        tostring(tonumber(options.sea) or 1),
        tostring(tonumber(options.level) or 0),
        options.dragonTalonNeedsEssence == true and "1" or "0",
        (tonumber(options.expBoostRemaining) or 0) > 0 and "1" or "0",
        tostring(tonumber(options.bones) or 0),
        options.rollCooldownReady ~= false and "1" or "0",
        options.hasSweetChalice == true and "1" or "0",
    }, ":")
end

function LevelFarmRoutePolicy.decide(options)
    options = options or {}
    local key = cacheKey(options)
    local now = os.clock()
    PolicyCache.prepare(LevelFarmRoutePolicy, nil, now, LevelFarmRoutePolicy.CacheSeconds)
    local cached = LevelFarmRoutePolicy.Cache[key]
    if cached and now - cached.at <= LevelFarmRoutePolicy.CacheSeconds then
        return cached.value
    end

    local sea = math.clamp(math.floor(tonumber(options.sea) or 1), 1, 3)
    local level = tonumber(options.level) or 0
    local bones = math.max(0, tonumber(options.bones) or 0)
    local expBoostRemaining = math.max(0, tonumber(options.expBoostRemaining) or 0)

    local skipFloor
    if sea == 1 and level <= 70 then
        skipFloor = level <= 19 and 1 or 2
    end

    local boneQuestAvailable = level >= 2025
    local cakeQuestAvailable = level >= 2200 and level < 2800
    local decision = {
        skipFloor = skipFloor,
        farmBones = sea == 3 and level >= 1975
            and options.dragonTalonNeedsEssence == true
            and expBoostRemaining <= 0 and bones < 500
            and options.rollCooldownReady ~= false,
        farmCake = sea == 3 and options.hasSweetChalice == true,
        boneQuestName = boneQuestAvailable and "HauntedQuest2" or nil,
        boneQuestNumber = boneQuestAvailable and 1 or nil,
        cakeQuestName = cakeQuestAvailable and "CakeQuest1" or nil,
        cakeQuestNumber = cakeQuestAvailable and 1 or nil,
    }
    PolicyCache.put(LevelFarmRoutePolicy, key, decision, now)
    return decision
end

function LevelFarmRoutePolicy.skipFloor(sea, level)
    local decision = LevelFarmRoutePolicy.decide({ sea = sea, level = level })
    return decision and decision.skipFloor or nil
end

function LevelFarmRoutePolicy.shouldFarmBones(options)
    local decision = LevelFarmRoutePolicy.decide(options)
    return decision ~= nil and decision.farmBones == true
end

function LevelFarmRoutePolicy.shouldFarmCake(options)
    local decision = LevelFarmRoutePolicy.decide(options)
    return decision ~= nil and decision.farmCake == true
end

function LevelFarmRoutePolicy.boneQuest(level)
    local decision = LevelFarmRoutePolicy.decide({ sea = 3, level = level })
    return decision and decision.boneQuestName or nil,
        decision and decision.boneQuestNumber or nil
end

function LevelFarmRoutePolicy.cakeQuest(level)
    local decision = LevelFarmRoutePolicy.decide({ sea = 3, level = level })
    return decision and decision.cakeQuestName or nil,
        decision and decision.cakeQuestNumber or nil
end
end

local BossQuestData
do
BossQuestData = {}

local PLACE_TO_SEA = {
    [2753915549] = 1,
    [4442272183] = 2,
    [7449423635] = 3,
    [85211729168715] = 1,
    [79091703265657] = 2,
    [100117331123089] = 3,
}

local ARYA_BLACKLISTED_FAMILIES = {
    BartiloQuest = true,
    CitizenQuest = true,
    Trainees = true,
    ImpelQuest = true,
    MarineQuest = true,
}

local SEA_LEVEL_RANGES = {
    [1] = { 0, 699 },
    [2] = { 700, 1499 },
    [3] = { 1500, math.huge },
}

local function detectSeaFromMap()
    local map = workspace and workspace:FindFirstChild("Map")
    if not map then
        return nil
    end
    if map:FindFirstChild("Dressrosa") and map:FindFirstChild("GreenBit") then
        return 2
    end
    if map:FindFirstChild("HauntedCastle") or map:FindFirstChild("TikiOutpost")
        or map:FindFirstChild("GreatTree")
    then
        return 3
    end
    return 1
end

local DATA = {
    [2] = {
        {
            id = "MarineQuest3",
            level_req = 925,
            family_level_req = 875,
            next_family_level_req = 950,
            quest_name = "MarineQuest3",
            quest_num = 3,
            mob_name = "Orbitus",
            boss_name = "Orbitus",
            quest_pos = CFrame.new(-2440.79638671875, 71.71407318115234, -3216.068115234375),
            boss_pos = CFrame.new(-2115.612548828125, 104.06766510009766, -4352.3525390625),
        },
        {
            id = "IceSideQuest",
            level_req = 1150,
            family_level_req = 1100,
            next_family_level_req = 1175,
            quest_name = "IceSideQuest",
            quest_num = 3,
            mob_name = "Smoke Admiral",
            boss_name = "Smoke Admiral",
            quest_pos = CFrame.new(-6231.98291015625, 81.80485534667969, -4852.8056640625),
            boss_pos = CFrame.new(-4857.3583984375, 238.67784118652344, -5583.2431640625),
        },
        {
            id = "FrostQuest",
            level_req = 1400,
            family_level_req = 1350,
            next_family_level_req = 1425,
            quest_name = "FrostQuest",
            quest_num = 3,
            mob_name = "Awakened Ice Admiral",
            boss_name = "Awakened Ice Admiral",
            quest_pos = CFrame.new(5667.658203125, 26.799781799316406, -6486.08984375),
            boss_pos = CFrame.new(6407, 340, -6892),
        },
        {
            id = "ForgottenQuest",
            level_req = 1475,
            family_level_req = 1425,
            quest_name = "ForgottenQuest",
            quest_num = 3,
            mob_name = "Tide Keeper",
            boss_name = "Tide Keeper",
            quest_pos = CFrame.new(-3054.444580078125, 238.34426879882812, -10142.8193359375),
            boss_pos = CFrame.new(-3570, 123, -11555),
        },
    },
    [3] = {
        {
            id = "PiratePortQuest",
            level_req = 1550,
            family_level_req = 1500,
            next_family_level_req = 1575,
            quest_name = "PiratePortQuest",
            quest_num = 3,
            mob_name = "Stone",
            boss_name = "Stone",
            quest_pos = CFrame.new(-290.0746765136719, 42.903465270996094, 5581.58984375),
            boss_pos = CFrame.new(-1109.92626953125, 51.648460388183594, 6811.72607421875),
        },
        {
            id = "VenomCrewQuest",
            level_req = 1675,
            family_level_req = 1625,
            next_family_level_req = 1700,
            quest_name = "VenomCrewQuest",
            quest_num = 3,
            mob_name = "Hydra Leader",
            boss_name = "Hydra Leader",
            quest_pos = CFrame.new(5214.33935546875, 1003.4676513671875, 759.50732421875),
            boss_pos = CFrame.new(5836.02783203125, 1035.16357421875, 6.213329792022705),
        },
        {
            id = "MarineTreeIsland",
            level_req = 1750,
            family_level_req = 1700,
            next_family_level_req = 1775,
            quest_name = "MarineTreeIsland",
            quest_num = 3,
            mob_name = "Kilo Admiral",
            boss_name = "Kilo Admiral",
            quest_pos = CFrame.new(2485.7333984375, 73.34599304199219, -6788.62548828125),
            boss_pos = CFrame.new(2998.294921875, 508.33074951171875, -7344.32177734375),
        },
        {
            id = "DeepForestIsland",
            level_req = 1875,
            family_level_req = 1825,
            next_family_level_req = 1900,
            quest_name = "DeepForestIsland",
            quest_num = 3,
            mob_name = "Captain Elephant",
            boss_name = "Captain Elephant",
            quest_pos = CFrame.new(-13234.0400390625, 331.4884948730469, -7625.4013671875),
            boss_pos = CFrame.new(-13365.5302734375, 318.6407775878906, -8484.98828125),
        },
        {
            id = "DeepForestIsland2",
            level_req = 1950,
            family_level_req = 1900,
            next_family_level_req = 1975,
            quest_name = "DeepForestIsland2",
            quest_num = 3,
            mob_name = "Beautiful Pirate",
            boss_name = "Beautiful Pirate",
            quest_pos = CFrame.new(-12680.3818359375, 389.9710388183594, -9902.01953125),
            boss_pos = CFrame.new(5367.31494140625, 21.144540786743164, -64.69924926757812),
        },
        {
            id = "IceCreamIslandQuest",
            level_req = 2175,
            family_level_req = 2125,
            next_family_level_req = 2200,
            quest_name = "IceCreamIslandQuest",
            quest_num = 3,
            mob_name = "Cake Queen",
            boss_name = "Cake Queen",
            quest_pos = CFrame.new(-819.376708984375, 64.92597961425781, -10967.283203125),
            boss_pos = CFrame.new(-678.47802734375, 381.85699462890625, -11114.345703125),
        },
    },
}

local function copyTable(source)
    local result = {}
    for key, value in source or {} do
        result[key] = value
    end
    return result
end

local function taskTarget(quest)
    for name, required in type(quest) == "table" and quest.Task or {} do
        if tonumber(required) == 1 then
            return tostring(name)
        end
    end
    return nil
end

local function staticTemplates(sea)
    local byFamily = {}
    for _, quest in DATA[sea] or {} do
        byFamily[quest.quest_name] = quest
    end
    return byFamily
end

function BossQuestData.mergeLive(sea, liveQuests)
    local levelRange = SEA_LEVEL_RANGES[sea]
    if not levelRange or type(liveQuests) ~= "table" then
        return {}
    end

    local families = {}
    for familyName, entries in liveQuests do
        local first = type(entries) == "table" and entries[1]
        local firstLevel = first and tonumber(first.LevelReq)
        if firstLevel
            and firstLevel >= levelRange[1]
            and firstLevel <= levelRange[2]
            and not ARYA_BLACKLISTED_FAMILIES[familyName]
        then
            families[#families + 1] = {
                name = familyName,
                entries = entries,
                level = firstLevel,
            }
        end
    end
    table.sort(families, function(left, right)
        if left.level ~= right.level then
            return left.level < right.level
        end
        return left.name < right.name
    end)

    local templates = staticTemplates(sea)
    local routes = {}
    for familyIndex, family in families do
        local nextFamily = families[familyIndex + 1]
        local nextLevel = nextFamily and nextFamily.level or math.huge
        for questNumber, sourceQuest in family.entries do
            local bossName = taskTarget(sourceQuest)
            local levelRequired = tonumber(sourceQuest.LevelReq)
            if bossName and levelRequired and levelRequired <= levelRange[2] then
                local route = copyTable(templates[family.name])
                route.id = family.name
                route.level_req = levelRequired
                route.family_level_req = family.level
                route.next_family_level_req = nextLevel
                route.quest_name = family.name
                route.quest_num = questNumber
                route.mob_name = bossName
                route.boss_name = bossName
                route.quest_required = 1
                route.accepted_name = sourceQuest.Name
                route.live_quest_data = true
                routes[#routes + 1] = route
            end
        end
    end
    return routes
end

local function liveQuestData()
    if not game or type(game.GetService) ~= "function" then
        return nil
    end
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local questModule = replicatedStorage:FindFirstChild("Quests")
    if not questModule then
        return nil
    end
    local loaded, quests = pcall(require, questModule)
    return loaded and type(quests) == "table" and quests or nil
end

function BossQuestData.forSea(sea)
    return DATA[sea] or {}
end

function BossQuestData.forPlace(placeId)
    local sea = PLACE_TO_SEA[placeId] or detectSeaFromMap()
    local liveRoutes = BossQuestData.mergeLive(sea, liveQuestData())
    if #liveRoutes > 0 then
        return liveRoutes
    end
    return BossQuestData.forSea(sea)
end
end

local GetQuest
do
GetQuest = {}

function GetQuest.run(context, level)
    local questData = context.State.questData
    local selectedQuest

    for _, candidate in questData do
        if candidate.level_req > level then
            break
        end
        if candidate.arya_blacklisted ~= true then
            selectedQuest = candidate
        end
    end

    if not selectedQuest then
        return nil
    end

    selectedQuest = table.clone(selectedQuest)

    if level < 10 and context.LocalPlayer.Team and context.LocalPlayer.Team.Name == "Marines" then
        selectedQuest.mob_name = "Trainee"
        selectedQuest.quest_name = "MarineQuest"
        selectedQuest.quest_num = 1
    end

    selectedQuest.mob_pos = context.Functions.ResolveMobCFrame(
        selectedQuest.mob_name,
        selectedQuest.mob_pos
    )

    return selectedQuest
end
end

local NormalizeEnemyName
do
NormalizeEnemyName = {}

function NormalizeEnemyName.run(_, name)
    if type(name) ~= "string" then
        return ""
    end
    return name:gsub("%s*%[.*$", ""):match("^%s*(.-)%s*$") or ""
end
end

local ResolveMobCFrame
do
ResolveMobCFrame = {}

function ResolveMobCFrame.run(context, mobName, fallback)
    local normalizedName = context.Functions.NormalizeEnemyName(mobName)
    local now = os.clock()
    context.MobCFrameCache = context.MobCFrameCache or {}
    local cached = context.MobCFrameCache[normalizedName]
    if cached and now - cached.time < 5 then
        return cached.cframe
    end

    local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local spawnFolders = {
        replicatedStorage:FindFirstChild("FortBuilderReplicatedSpawnPositionsFolder"),
        worldOrigin and worldOrigin:FindFirstChild("EnemySpawns"),
    }
    local character = context.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local referencePosition = typeof(fallback) == "CFrame" and fallback.Position
        or (root and root.Position)
    local bestCFrame
    local bestDistance = math.huge

    for _, folder in spawnFolders do
        for _, spawn in folder and folder:GetChildren() or {} do
            if context.Functions.NormalizeEnemyName(spawn.Name) == normalizedName then
                local success, spawnCFrame = pcall(function()
                    return spawn:IsA("BasePart") and spawn.CFrame or spawn:GetPivot()
                end)
                if success then
                    local distance = referencePosition
                        and (spawnCFrame.Position - referencePosition).Magnitude or 0
                    if distance < bestDistance then
                        bestCFrame = spawnCFrame
                        bestDistance = distance
                    end
                end
            end
        end
    end

    if not bestCFrame then
        return fallback
    end

    local result = CFrame.new(bestCFrame.Position + Vector3.new(0, 30, 0))
    context.MobCFrameCache[normalizedName] = { time = now, cframe = result }
    return result
end
end

local GetBossQuest
do
GetBossQuest = {}

function GetBossQuest.run(context, level, bossName)
    local selected
    for _, quest in context.State.bossQuestData do
        if quest.level_req <= level
            and (not bossName or quest.boss_name == bossName)
            and (not selected or quest.level_req > selected.level_req)
        then
            selected = quest
        end
    end
    return selected
end
end

local GetLiveBoss
do
GetLiveBoss = {}

function GetLiveBoss.run(_, bossName)
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then
        return nil
    end
    for _, enemy in enemies:GetChildren() do
        local humanoid = enemy:FindFirstChildOfClass("Humanoid")
        if enemy.Name == bossName and humanoid and humanoid.Health > 0
            and enemy:FindFirstChild("HumanoidRootPart")
        then
            return enemy
        end
    end
    return nil
end
end

local GetBossCFrame
do
GetBossCFrame = {}

function GetBossCFrame.run(context, bossName)
    local boss = context.Functions.GetLiveBoss(bossName)
    if boss then
        return boss:GetPivot()
    end

    local stored = context.MobSpawns and context.MobSpawns[bossName]
    if typeof(stored) == "CFrame" then
        return stored
    end
    return "undefined"
end
end

local GetFarmWatchdog
do
GetFarmWatchdog = {}

function GetFarmWatchdog.run(context)
    local state = context.State
    local watchdog = state.farmWatchdog
    if watchdog then
        context.FarmWatchdogState = watchdog
        return watchdog
    end

    if context.FarmWatchdogState then
        state.farmWatchdog = context.FarmWatchdogState
        return context.FarmWatchdogState
    end

    watchdog = { LastProgressAt = os.clock(), Config = {} }
    state.farmWatchdog = watchdog
    context.FarmWatchdogState = watchdog
    if context.Environment then
        context.Environment.__SEAHUB_FARM_WATCHDOG = watchdog
    end
    return watchdog
end
end

local GetQuestGiverCFrame
do
GetQuestGiverCFrame = {}

local function usable(cframe)
    if typeof(cframe) ~= "CFrame" then
        return false
    end
    local position = cframe.Position
    return position.X == position.X and position.Y == position.Y and position.Z == position.Z
        and math.abs(position.X) <= 250000 and math.abs(position.Z) <= 250000
        and position.Y >= -5000 and position.Y <= 50000
end

function GetQuestGiverCFrame.run(context, quest)
    if type(quest) ~= "table" then
        return nil, nil, "invalid-quest"
    end

    if context.GetQuestNpcCFrame then
        local liveCFrame, liveName = context.GetQuestNpcCFrame(quest.level_req, quest.quest_pos)
        if usable(liveCFrame) then
            return liveCFrame, liveName, "guide-module"
        end
    end

    local npcName = context.QuestNpcNames and context.QuestNpcNames[quest.quest_name]
    if npcName and context.GetNPCCFrame then
        local npcCFrame = context.GetNPCCFrame(npcName, quest.quest_pos)
        if usable(npcCFrame) then
            if not usable(quest.quest_pos)
                or (npcCFrame.Position - quest.quest_pos.Position).Magnitude <= 3000
            then
                return npcCFrame, npcName, "live-npc"
            end
            if context.DynamicNpcCFrames then
                context.DynamicNpcCFrames[npcName] = nil
            end
        end
    end

    if usable(quest.quest_pos) then
        return quest.quest_pos, npcName, "quest-data"
    end
    return nil, npcName, "missing"
end
end

local EnsureQuest
do
EnsureQuest = {}
local QUEST_INTERACTION_DISTANCE = 8
local QUEST_ACCEPT_UI_GRACE = 1.5
local QUEST_DISAPPEAR_GRACE = 0.5
local QUEST_COMPLETION_UI_GRACE = 0.75
local QUEST_RUNTIME_LEASE = 300
local QUEST_INITIAL_REQUEST_DELAY = 2
local QUEST_ROUTE_SPEED = 300
local QUEST_ROUTE_STEP_DISTANCE = 75

local function resetCombat(context)
    local functions = context.Functions
    if type(functions.StopAttack) == "function" then
        pcall(functions.StopAttack)
    else
        table.clear(context.NearbyTargets)
        table.clear(context.NearbyTargetParts)
    end
    if type(functions.ReleaseBring) == "function" then
        pcall(functions.ReleaseBring)
    end
end

local function normalizedWords(value)
    local words = {}
    for word in string.lower(tostring(value or "")):gmatch("[a-z0-9]+") do
        if #word > 3 and word:sub(-1) == "s" then
            word = word:sub(1, -2)
        end
        words[word] = true
    end
    return words
end

local function titleMatchesMob(title, mobName)
    local titleWords = normalizedWords(title)
    local mobWords = normalizedWords(mobName)
    local matched = 0
    for word in mobWords do
        if titleWords[word] then
            matched += 1
        end
    end
    if matched >= 2 then
        return true
    end

    local lastMobWord
    for word in string.lower(tostring(mobName or "")):gmatch("[a-z0-9]+") do
        lastMobWord = word
    end
    if lastMobWord and #lastMobWord > 3 and lastMobWord:sub(-1) == "s" then
        lastMobWord = lastMobWord:sub(1, -2)
    end
    return lastMobWord ~= nil and titleWords[lastMobWord] == true
end

local function setRemoteResult(record, success, result, successField)
    if success then
        record[successField] = result
        record.lastError = nil
    else
        record[successField] = nil
        record.lastError = tostring(result)
    end
end

function EnsureQuest.run(context, quest, taskName)
    local functions = context.Functions
    local state = context.State

    if context.TaskQueue:top() ~= taskName then
        return false
    end

    local questVisible, questTitle = context.ReadQuest()
    questTitle = tostring(questTitle or "")
    local acquireKey = taskName .. "\0" .. tostring(quest.quest_name) .. "\0" .. tostring(quest.quest_num)
    local now = os.clock()

    local completionNoticeAt = tonumber(state.lastQuestCompletionNotificationAt)
    if questVisible and completionNoticeAt and now - completionNoticeAt < QUEST_COMPLETION_UI_GRACE then
        state.status = taskName .. " | Waiting quest completion"
        return false
    end

    if questVisible and titleMatchesMob(questTitle, quest.mob_name) then
        local isNewAcceptedQuest = state.acceptedQuestKey ~= acquireKey
        state.questAcquire = nil
        state.questTarget = quest.mob_name
        state.acceptedQuestKey = acquireKey
        state.acceptedQuestAt = state.acceptedQuestAt or now
        state.acceptedQuestConfirmed = true
        if isNewAcceptedQuest then
            state.acceptedQuestKills = 0
            state.acceptedQuestRequired = tonumber(quest.quest_required) or 8
        end
        state.acceptedQuestRequired = state.acceptedQuestRequired
            or tonumber(quest.quest_required) or 8
        local completed, required = questTitle:match("(%d+)%s*/%s*(%d+)")
        if completed and required then
            state.acceptedQuestKills = tonumber(completed) or state.acceptedQuestKills
            state.acceptedQuestRequired = tonumber(required) or state.acceptedQuestRequired
        end
        state.lastQuestSeenAt = now
        return true
    end

    local acquire = state.questAcquire

    if not questVisible and state.acceptedQuestKey == acquireKey then
        local acceptedRecently = now - (state.acceptedQuestAt or 0) < QUEST_ACCEPT_UI_GRACE
        local seenRecently = now - (state.lastQuestSeenAt or 0) < QUEST_DISAPPEAR_GRACE
        local runtimeLeaseActive = not state.acceptedQuestConfirmed
            and now - (state.acceptedQuestAt or 0) < QUEST_RUNTIME_LEASE
            and (state.acceptedQuestKills or 0) < (state.acceptedQuestRequired or math.huge)
        if acceptedRecently or seenRecently or runtimeLeaseActive then
            state.questTarget = quest.mob_name
            return true
        end

        local completionRecorded = false
        if state.acceptedQuestConfirmed
            and (state.acceptedQuestKills or 0) >= (state.acceptedQuestRequired or 8)
        then
            completionRecorded = QuestNotificationBridge.record(
                state,
                "quest completed",
                now,
                "quest-ui"
            )
        end
        if state.movement then
            functions.CancelTween()
        end
        resetCombat(context)
        state.acceptedQuestKey = nil
        state.acceptedQuestAt = nil
        state.acceptedQuestConfirmed = nil
        state.lastQuestSeenAt = nil
        state.questAcquire = nil
        state.farmTarget = nil
        acquire = nil
        if completionRecorded then
            if type(functions.ReleaseBring) == "function" then
                pcall(functions.ReleaseBring)
            end
            state.status = taskName .. " | Quest completed"
            return false
        end
    end

    if not acquire or acquire.key ~= acquireKey then
        acquire = {
            key = acquireKey,
            startedAt = now,
            attempts = 0,
            nextRequestAt = now + QUEST_INITIAL_REQUEST_DELAY,
            nextAbandonAt = 0,
        }
        state.questAcquire = acquire
    end

    state.questTarget = quest.mob_name

    if questVisible then
        state.acceptedQuestKey = nil
        state.acceptedQuestAt = nil
        state.acceptedQuestConfirmed = nil
        state.lastQuestSeenAt = nil
        acquire.acceptedAt = nil

        if acquire.nextAbandonAt <= now then
            acquire.nextAbandonAt = now + 3
            local success, result = pcall(function()
                return context.QuestRemote:InvokeServer("AbandonQuest")
            end)
            setRemoteResult(acquire, success, result, "lastAbandonResult")
            state.lastQuestAbandon = { At = now, Result = result, Ok = success, Title = questTitle }
        end

        if state.movement then
            functions.CancelTween()
        end
        resetCombat(context)

        state.status = taskName .. " | Abandoning wrong quest"
        return false
    end

    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local characterRoot = character and character:FindFirstChild("HumanoidRootPart")

    if not characterRoot or not humanoid or humanoid.Health <= 0 then
        state.status = taskName .. " | Waiting character"
        return false
    end

    local questGiverCFrame, npcName, positionSource = functions.GetQuestGiverCFrame(quest)
    acquire.npcName = npcName
    acquire.positionSource = positionSource

    if typeof(questGiverCFrame) ~= "CFrame" then
        acquire.lastError = "quest-giver-unavailable"
        state.status = taskName .. " | Quest giver unavailable"
        return false
    end

    local distance = (characterRoot.Position - questGiverCFrame.Position).Magnitude
    acquire.distance = distance

    if distance > QUEST_INTERACTION_DISTANCE then
        state.status = taskName .. " | Moving to quest giver"
        functions.TP(
            questGiverCFrame + Vector3.new(0, 3, 0),
            taskName,
            nil,
            nil,
            nil,
            nil,
            QUEST_ROUTE_SPEED,
            QUEST_ROUTE_STEP_DISTANCE
        )
        return false
    elseif state.movement then
        functions.CancelTween()
    end

    if acquire.lockedUntilLevel and context.Level.Value < acquire.lockedUntilLevel then
        state.status = taskName .. " | Quest locked until level " .. tostring(acquire.lockedUntilLevel)
        return false
    elseif acquire.lockedUntilLevel then
        acquire.lockedUntilLevel = nil
        acquire.nextRequestAt = 0
    end

    if acquire.acceptedAt and now - acquire.acceptedAt < 4 then
        state.status = taskName .. " | Waiting quest confirmation"
        return false
    end

    if now < acquire.nextRequestAt then
        if distance <= QUEST_INTERACTION_DISTANCE then
            state.status = taskName .. (acquire.lastResult == 1
                and " | Quest request rejected"
                or " | Waiting quest confirmation")
        end
        return false
    end

    if context.TaskQueue:top() ~= taskName then
        return false
    end

    acquire.attempts = acquire.attempts + 1
    acquire.requestedAt = now
    state.lastQuestRequestAt = now

    local success, result = pcall(function()
        return context.QuestRemote:InvokeServer("StartQuest", quest.quest_name, quest.quest_num)
    end)
    setRemoteResult(acquire, success, result, "lastResult")
    state.lastQuestRequest = {
        At = now,
        Quest = quest.quest_name,
        Number = quest.quest_num,
        Result = result,
        Ok = success,
        NPC = npcName,
        Distance = distance,
    }

    if context.TaskQueue:top() ~= taskName then
        return false
    end

    if not success then
        acquire.nextRequestAt = now + 5
        state.status = taskName .. " | Quest request failed"
        return false
    end

    local confirmed, confirmedTitle = context.ReadQuest()
    if confirmed and titleMatchesMob(confirmedTitle, quest.mob_name) then
        state.questAcquire = nil
        state.acceptedQuestKey = acquireKey
        state.acceptedQuestAt = now
        state.acceptedQuestConfirmed = true
        state.lastQuestSeenAt = now
        return true
    end

    local resultCode = tonumber(result)
    if resultCode and context.Level.Value < resultCode then
        acquire.lockedUntilLevel = resultCode
        acquire.nextRequestAt = math.huge
        state.status = taskName .. " | Quest locked until level " .. tostring(resultCode)
    elseif resultCode == 0 then
        state.acceptedQuestKey = acquireKey
        state.acceptedQuestAt = now
        state.acceptedQuestConfirmed = false
        state.acceptedQuestKills = 0
        state.acceptedQuestRequired = tonumber(quest.quest_required) or 8
        state.questAcquire = nil
        state.status = taskName .. " | Quest accepted"
        return true
    elseif resultCode == 1 then
        acquire.nextRequestAt = now + 3
        state.status = taskName .. " | Quest request rejected"
    elseif resultCode == 2 then
        acquire.nextRequestAt = now + 30
        state.status = taskName .. " | Quest already completed"
    else
        acquire.nextRequestAt = now + 3
        state.status = taskName .. " | Waiting quest confirmation"
    end

    return false
end
end

local LoadTools
do
LoadTools = {}

function LoadTools.run(context)
    for weaponType in context.ToolsByType do
        context.ToolsByType[weaponType] = false
    end

    local player = context.LocalPlayer
    for _, root in { player:FindFirstChildOfClass("Backpack"), player.Character } do
        for _, tool in root and root:GetChildren() or {} do
            if tool:IsA("Tool") then
                local weaponType = tool:GetAttribute("WeaponType")
                if type(weaponType) ~= "string" or weaponType == "" then
                    weaponType = tool.ToolTip
                end
                if context.ToolsByType[weaponType] ~= nil then
                    context.ToolsByType[weaponType] = tool
                end
            end
        end
    end

    return context.ToolsByType
end
end

local EquipWeapon
do
EquipWeapon = {}

function EquipWeapon.run(context, weaponType)
    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    local tool = context.ToolsByType[weaponType]
    if typeof(tool) ~= "Instance" or not tool.Parent then
        context.Functions.LoadTools()
        tool = context.ToolsByType[weaponType]
    end

    if typeof(tool) ~= "Instance" or not tool:IsA("Tool") then
        return false
    end

    context.SetCurrentWeaponType(weaponType)
    context.State.selectedWeaponType = weaponType

    if tool.Parent == context.LocalPlayer.Backpack then
        humanoid:EquipTool(tool)
    end

    return tool.Parent == character
end
end

local Attack
do
Attack = {}

local DEFAULT_ATTACK_INTERVAL = 0.05

function Attack.buildHitPayload(validTargets)
    local primaryTarget = table.remove(validTargets, 1)
    return primaryTarget, validTargets
end

local function prepareCombatAnimation(context, humanoid, tool)
    local state = context.State
    local combatUtil = state.combatUtil
    if combatUtil == nil or combatUtil == false
        and os.clock() >= (state.nextCombatUtilLoadAt or 0)
    then
        local modules = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
        local module = modules and modules:FindFirstChild("CombatUtil")
        local ok, loaded = false, nil
        if module then
            ok, loaded = pcall(require, module)
        end
        combatUtil = ok and loaded or false
        state.combatUtil = combatUtil
        state.nextCombatUtilLoadAt = os.clock() + 5
    end
    if type(combatUtil) ~= "table" then
        return
    end

    pcall(function()
        local cache = combatUtil:GetMovesetAnimCache(humanoid)
        local weaponName = combatUtil:GetWeaponName(tool)
        local weaponData = weaponName and combatUtil:GetWeaponData(weaponName)
        if weaponData then
            weaponData.HitboxMagnitude = 60
        end
        if cache and weaponName then
            local pureName = combatUtil:GetPureWeaponName(weaponName)
            local animation = cache[pureName .. "-basic1"]
            if animation then
                animation:Play()
                animation:AdjustSpeed(0)
            end
        end
    end)
end

function Attack.run(context)
    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
    local equippedTool = character and character:FindFirstChildOfClass("Tool")
    if not humanoid or humanoid.Health <= 0 or not characterRoot or not equippedTool then
        return
    end

    local now = os.clock()
    local attackInterval = tonumber(context.State.attackInterval)
        or tonumber(context.Environment.Configs["Attack Interval"])
        or DEFAULT_ATTACK_INTERVAL
    attackInterval = math.clamp(attackInterval, 0.05, 0.25)
    if now - (context.State.lastAttackAt or 0) < attackInterval then
        return
    end

    local validTargets = {}
    for _, entry in context.NearbyTargets do
        local enemy = entry[1]
        local hitPart = entry[2]
        local enemyHumanoid = enemy and enemy:FindFirstChildOfClass("Humanoid")
        local enemyRoot = enemy and enemy:FindFirstChild("HumanoidRootPart")
        if enemyHumanoid and enemyHumanoid.Health > 0
            and enemyRoot and hitPart and hitPart.Parent
            and (enemyRoot.Position - characterRoot.Position).Magnitude <= 60
        then
            validTargets[#validTargets + 1] = { enemy, hitPart }
        end
    end

    if #validTargets == 0 then
        return
    end

    prepareCombatAnimation(context, humanoid, equippedTool)
    local targetCount = #validTargets
    local primaryTarget, hitTargets = Attack.buildHitPayload(validTargets)
    local sent = pcall(function()
        context.RegisterAttackRemote:FireServer(0.4)
        context.RegisterHitRemote:FireServer(primaryTarget[2], hitTargets)
    end)
    context.State.lastAttackTargetCount = targetCount
    context.State.lastAttackSecondaryCount = #hitTargets
    context.State.lastAttackSent = sent
    if sent then
        context.State.lastAttackAt = now
    end
end

function Attack.stop(context)
    table.clear(context.NearbyTargets)
    table.clear(context.NearbyTargetParts)
    local state = context.State
    state.attackTarget = nil
    state.attackTargetNames = nil
    state.attackTask = nil
    state.currentFarmMobName = nil
    state.attackPulseExpiresAt = 0
end
end

local SendKey
do
SendKey = {}

function SendKey.run(_, keyName, duration)
    local keyCode = Enum.KeyCode[tostring(keyName)]
    if not keyCode then return false end
    local input = game:GetService("VirtualInputManager")
    input:SendKeyEvent(true, keyCode, false, game)
    task.wait(tonumber(duration) or 0.1)
    input:SendKeyEvent(false, keyCode, false, game)
    return true
end
end

local AddVelocity
do
AddVelocity = {}

function AddVelocity.run(context)
    local character = context.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local oldLinear = root:FindFirstChild("SeaHubVelocity")
    if oldLinear and not oldLinear:IsA("BodyVelocity") then
        oldLinear:Destroy()
    end
    local oldProbe = root:FindFirstChild("SeaHubLinearVelocity")
    if oldProbe then
        oldProbe:Destroy()
    end
    if context.VelocityAttachment then
        context.VelocityAttachment:Destroy()
        context.VelocityAttachment = nil
    end

    local velocity = root:FindFirstChild("BananaBV") or context.Velocity
    if velocity and (not velocity.Parent or not velocity:IsA("BodyVelocity")) then
        pcall(velocity.Destroy, velocity)
        velocity = nil
    end
    if not velocity then
        velocity = Instance.new("BodyVelocity")
    end
    velocity.Name = "BananaBV"
    velocity.MaxForce = Vector3.new(0, math.huge, 0)
    velocity.Velocity = Vector3.zero
    velocity.Parent = root
    context.Velocity = velocity

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end
end

local RemoveVelocity
do
RemoveVelocity = {}

function RemoveVelocity.run(context)
    if context.Velocity then
        context.Velocity.Parent = game
    end
    if context.VelocityAttachment then
        context.VelocityAttachment:Destroy()
        context.VelocityAttachment = nil
    end
    context.Functions.NoClip("off")
end
end

local ShouldCancelTP
do
ShouldCancelTP = {}

local function usable(cframe)
    if typeof(cframe) ~= "CFrame" then
        return false
    end
    local position = cframe.Position
    return position.X == position.X and position.Y == position.Y and position.Z == position.Z
        and math.abs(position.X) <= 250000 and math.abs(position.Z) <= 250000
        and position.Y >= -5000 and position.Y <= 50000
end

function ShouldCancelTP.run(context, goal, owner, boss, movingTarget)
    local state = context.State
    if not state.stopTweenRequested and usable(goal) then
        if owner and context.TaskQueue:top() ~= owner then
            return true
        end
        if boss and context.Functions.GetBossCFrame(boss) == "undefined" then
            return true
        end
        if typeof(movingTarget) == "Instance" and not movingTarget:IsDescendantOf(workspace) then
            return true
        end
        return false
    end

    state.lastRejectedMovement = {
        at = os.clock(),
        owner = owner,
        target = goal,
    }
    return true
end
end

local ShouldNotBypassTP
do
ShouldNotBypassTP = {}

local BLOCKING_TOOLS = {
    "God's Chalice",
    "Sweet Chalice",
    "Special Microchip",
    "Hallow Essence",
    "Fire Essence",
}

local function carries(player, itemName)
    for _, container in { player.Character, player:FindFirstChildOfClass("Backpack") } do
        if container and container:FindFirstChild(itemName) then
            return true
        end
    end
    return false
end

function ShouldNotBypassTP.run(context)
    local state = context.State
    local taskName = context.TaskQueue and context.TaskQueue:top() or nil

    if os.clock() < (state.bypassBlockedUntil or 0)
        or taskName == "SoulGuitar"
        or taskName == "RaidController"
        or taskName == "Auto Raid"
        or context.LocalPlayer:GetAttribute("IslandRaiding")
    then
        return true
    end

    for _, itemName in BLOCKING_TOOLS do
        if carries(context.LocalPlayer, itemName) then
            return true
        end
    end
    return false
end
end

local TryFastTravel
do
TryFastTravel = {}

local function isTaskCurrent(context, owner)
    local state = context.State or {}
    if state.stopped or state.paused then return false end
    local functions = context.Functions
    if functions and type(functions.IsTaskCurrent) == "function" then
        return functions.IsTaskCurrent(owner)
    end
    return not state.stopped
        and not state.paused
        and context.TaskQueue:top() == owner
end

local FIRST_SEA_DESTINATIONS = {
    fishman = CFrame.new(61163.8515625, 11.68000793457, 1819.7840576172),
    whirlPool = CFrame.new(3864.6879882812, 5.7169952392578, -1926.2139892578),
    skyArea1 = CFrame.new(-4166.6098632812, 1093.6979980469, -347.16226196289),
    skyArea2 = CFrame.new(-6023.5766601562, 5469.7197265625, 2203.3083496094),
}

local FIRST_SEA_FALLBACKS = {
    fishmanEntrance = CFrame.new(4050.31103515625, -1.6880035400390625, -1814.1240234375),
    fishmanExit = CFrame.new(61170.046875, -2, 1952.833984375),
}

local SECOND_SEA_ROUTES = {
    cursedShip = Vector3.new(923.2125244140625, 126.97600555419922, 32852.83203125),
    surface = Vector3.new(-6508.55810546875, 89.03499603271484, -132.83953857421875),
    mansion = CFrame.new(-288.4624938964844, 306.130615234375, 597.9988403320312),
    swanRoom = CFrame.new(2284.912109375, 15.152046203613281, 905.48291015625),
}

local SUBMERGED_CENTER = Vector3.new(11256, -2138, 9888)
local SUBMARINE_WORKER_FALLBACK = CFrame.new(-16269, 23, 1371)
local SUBMERGED_ENTER_SETTLE_SECONDS = 1
local SUBMERGED_SPAWN_EXIT_SETTLE_SECONDS = 6
local SUBMERGED_WORKER_EXIT_SETTLE_SECONDS = 0.5

local CURSED_SHIP_ENTRY_APPROACH = CFrame.new(SECOND_SEA_ROUTES.surface + Vector3.new(0, 5, 0))
local REQUEST_TIMEOUT_SECONDS = 6
local DISCOVERY_RETRY_SECONDS = 5

local function cancelThread(thread)
    if type(thread) ~= "thread" or coroutine.status(thread) == "dead" then return true end
    if thread ~= coroutine.running() and type(task.cancel) == "function" then
        pcall(task.cancel, thread)
    end
    return coroutine.status(thread) == "dead"
end

local function cancelTravelTween(state, ownedTween)
    local tween = state.fastTravelTween
    if ownedTween and tween ~= ownedTween then
        pcall(function() ownedTween:Cancel() end)
        return
    end
    state.fastTravelTween = nil
    if tween then
        pcall(function() tween:Cancel() end)
    end
end

local function restoreWhirlPoolTouch(state)
    local restore = state.whirlPoolTouchRestore
    state.whirlPoolTouchRestore = nil
    if restore then
        cancelThread(restore.thread)
        pcall(function()
            if restore.part.Parent then
                restore.part.CanTouch = restore.canTouch
            end
        end)
    end
end

function TryFastTravel.stop(context)
    local state = context.State
    local request = state.fastTravelRequest
    state.fastTravelGeneration = (state.fastTravelGeneration or 0) + 1
    state.cursedShipTransitionToken = nil
    state.cursedShipTransitionActive = nil
    state.cursedShipTransitionDeadline = nil
    if request then
        request.cancelled = true
        if cancelThread(request.thread) then state.fastTravelRequest = nil end
    end
    cancelThread(state.cursedShipTransitionThread)
    state.cursedShipTransitionThread = nil
    cancelTravelTween(state)
    restoreWhirlPoolTouch(state)
    state.submergedSettleUntil = nil
    state.submergedSettleDirection = nil
    state.skyCombatController = nil
    state.skyCannonMouseTool = nil
    state.skyCannonMouseState = nil
end

local function boundedCall(context, owner, callback, isCurrent)
    local state = context.State
    if state.fastTravelRequest or os.clock() < (state.nextFastTravelRequestAt or 0) then
        return false, "travel-request-busy"
    end
    local character = context.LocalPlayer.Character
    local generation = state.fastTravelGeneration
    local request = {}
    local function current()
        return state.fastTravelRequest == request
            and not request.cancelled
            and state.fastTravelGeneration == generation
            and context.LocalPlayer.Character == character
            and not state.stopped and not state.paused
            and isTaskCurrent(context, owner)
            and (not isCurrent or isCurrent())
    end
    state.fastTravelRequest = request
    if not current() then
        state.fastTravelRequest = nil
        return false, "travel-request-cancelled"
    end
    local deadline = os.clock() + REQUEST_TIMEOUT_SECONDS
    request.thread = task.spawn(function()
        request.results = table.pack(pcall(callback, current))
        if request.cancelled and state.fastTravelRequest == request then
            state.fastTravelRequest = nil
        end
    end)
    while not request.results and current() and os.clock() < deadline do
        task.wait(0.05)
    end
    local valid = current()
    if not request.results then request.cancelled = true end
    local terminated = cancelThread(request.thread)
    if state.fastTravelRequest == request and (terminated or request.results) then
        state.fastTravelRequest = nil
    end
    if not valid then
        return false, "travel-request-cancelled"
    end
    if not request.results then
        state.nextFastTravelRequestAt = os.clock() + 3
        return false, "travel-request-timeout"
    end
    return table.unpack(request.results, 1, request.results.n)
end

local function routeTP(context, ...)
    local state = context.State
    local previous = state.fastTravelResolving
    state.fastTravelResolving = true
    local results = table.pack(pcall(context.Functions.TP, ...))
    state.fastTravelResolving = previous
    if not results[1] then
        error(results[2], 0)
    end
    return table.unpack(results, 2, results.n)
end

local function findCursedShipExit()
    local map = workspace:FindFirstChild("Map")
    local interior = map and map:FindFirstChild("GhostShipInterior")
    local teleporter = interior and interior:FindFirstChild("Teleport")
    return teleporter and teleporter:IsA("BasePart") and teleporter or nil
end

local function findCursedShipEntrance()
    local map = workspace:FindFirstChild("Map")
    local ship = map and map:FindFirstChild("GhostShip")
    local teleporter = ship and ship:FindFirstChild("Teleport")
    return teleporter and teleporter:IsA("BasePart") and teleporter or nil
end

local function isInsideCursedShip(position)
    return position.Z > 30000
end

local function isSubmerged(position)
    return position.Y < -500 and (position - SUBMERGED_CENTER).Magnitude <= 4200
end

local function npcCFrame(name, fallback)
    local npcs = workspace:FindFirstChild("NPCs")
    local npc = npcs and npcs:FindFirstChild(name)
    local root = npc and (npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart)
    return root and root.CFrame or fallback
end

local function submarineRemote(isCurrent)
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local modules = replicatedStorage:FindFirstChild("Modules")
    local netModule = modules and modules:FindFirstChild("Net")
    if not netModule then
        return nil
    end
    local ok, net = pcall(require, netModule)
    if not ok or type(net) ~= "table" or type(net.RemoteFunction) ~= "function" then
        return nil
    end
    if isCurrent and not isCurrent() then return nil end
    local success, remote = pcall(function()
        return net:RemoteFunction("SubmarineWorkerSpeak")
    end)
    return success and remote or nil
end

local function handleSubmergedTransition(context, root, goal, owner)
    if not context.IsSea(3) then
        return false
    end

    local state = context.State
    local now = os.clock()
    local entering = isSubmerged(goal.Position)
    local inside = isSubmerged(root.Position)
        or context.LocalPlayer:GetAttribute("ExactLocation") == "Submerged Island"

    if now < (state.submergedSettleUntil or 0) then
        local direction = state.submergedSettleDirection or "transition"
        state.status = direction == "enter"
            and "Auto Farm Level | Stabilizing Submerged Island"
            or "Auto Farm Level | Stabilizing surface return"
        context.Functions.AddVelocity()
        context.Functions.NoClip("on")
        return true
    elseif state.submergedSettleUntil then
        state.submergedSettleUntil = nil
        state.submergedSettleDirection = nil
    end

    if entering == inside then
        return false
    end

    if now < (state.nextSubmergedTransitionAt or 0) then
        return true
    end

    if entering then
        local worker = npcCFrame("Submarine Worker", SUBMARINE_WORKER_FALLBACK)
        if (root.Position - worker.Position).Magnitude > 60 then
            state.status = "Auto Farm Level | Entering Submerged Island"
            routeTP(context, worker + Vector3.new(0, 5, 3), owner, true)
            return true
        end
        state.nextSubmergedTransitionAt = os.clock() + 4
        local success, result = boundedCall(context, owner, function(isCurrent)
            local remote = submarineRemote(isCurrent)
            if not isCurrent() then return false end
            return remote and remote:InvokeServer("TravelToSubmergedIsland") or false
        end)
        if result == "travel-request-cancelled" or not isTaskCurrent(context, owner) then return true end
        state.lastSubmergedTransition = {
            direction = "enter",
            success = success and result ~= false,
            result = tostring(result),
            at = os.clock(),
        }
        if success and result then
            state.submergedSettleDirection = "enter"
            state.submergedSettleUntil = os.clock() + SUBMERGED_ENTER_SETTLE_SECONDS
        end
        state.status = "Auto Farm Level | Entering Submerged Island"
        return true
    end

    if context.LocalPlayer:GetAttribute("InCombat") == true then
        state.status = "Auto Farm Level | Waiting for combat before leaving Submerged Island"
        state.nextSubmergedTransitionAt = os.clock() + 1
        return true
    end

    local exactLocation = context.LocalPlayer:GetAttribute("ExactLocation")
    if exactLocation == "Submerged Island" then
        state.nextSubmergedTransitionAt = os.clock() + 6
        local success, result = boundedCall(context, owner, function()
            return context.CommandRemote:InvokeServer("TeleportToSpawn")
        end)
        if result == "travel-request-cancelled" or not isTaskCurrent(context, owner) then return true end
        state.lastSubmergedTransition = {
            direction = "leave", success = success and result ~= false,
            result = tostring(result), at = os.clock(),
        }
        if success and result ~= false then
            state.submergedSettleDirection = "leave"
            state.submergedSettleUntil = os.clock() + SUBMERGED_SPAWN_EXIT_SETTLE_SECONDS
        end
        state.status = "Auto Farm Level | Leaving Submerged Island"
        return true
    end

    local worker = npcCFrame("Submarine Worker2")
    if not worker then
        state.status = "Auto Farm Level | Locating Submarine Worker"
        return true
    end
    if (root.Position - worker.Position).Magnitude > 60 then
        routeTP(context, worker + Vector3.new(0, 5, 3), owner, true)
        return true
    end
    state.nextSubmergedTransitionAt = os.clock() + 4
    local success, result = boundedCall(context, owner, function(isCurrent)
        local remote = submarineRemote(isCurrent)
        if not isCurrent() then return false end
        return remote and remote:InvokeServer("TravelToSurface") or false
    end)
    if result == "travel-request-cancelled" or not isTaskCurrent(context, owner) then return true end
    state.lastSubmergedTransition = {
        direction = "leave",
        success = success and result ~= false,
        result = tostring(result),
        at = os.clock(),
    }
    if success and result then
        state.submergedSettleDirection = "leave"
        state.submergedSettleUntil = os.clock() + SUBMERGED_WORKER_EXIT_SETTLE_SECONDS
    end
    state.status = "Auto Farm Level | Leaving Submerged Island"
    return true
end

local function tweenSegment(context, root, destination, speed, maxStep, isCurrent)
    local deadline = os.clock() + 45
    while root.Parent
        and (not isCurrent or isCurrent())
        and (destination - root.Position).Magnitude > 8
        and os.clock() < deadline
    do
        context.Functions.AddVelocity()
        context.Functions.NoClip("on")
        local delta = destination - root.Position
        local step = math.min(delta.Magnitude, maxStep)
        local waypoint = root.Position + delta.Unit * step
        local tween = context.TweenService:Create(
            root,
            TweenInfo.new(step / speed, Enum.EasingStyle.Linear),
            { CFrame = CFrame.lookAt(waypoint, destination) }
        )
        context.State.fastTravelTween = tween
        tween:Play()
        local segmentDeadline = math.min(deadline, os.clock() + step / speed + 2)
        while root.Parent and (not isCurrent or isCurrent())
            and tween.PlaybackState ~= Enum.PlaybackState.Completed
            and tween.PlaybackState ~= Enum.PlaybackState.Cancelled
            and os.clock() < segmentDeadline
        do
            task.wait(0.05)
        end
        local completed = tween.PlaybackState == Enum.PlaybackState.Completed
        cancelTravelTween(context.State, tween)
        if not completed or not root.Parent or isCurrent and not isCurrent() then
            return false
        end
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.1)
    end
    return root.Parent
        and (not isCurrent or isCurrent())
        and (destination - root.Position).Magnitude <= 15
end

local function crossCursedShipPortal(context, root, portal, expectInterior, isCurrent)
    local axis = portal.CFrame.LookVector
    local side = (root.Position - portal.Position):Dot(axis) >= 0 and 1 or -1
    local portalDepth = portal.Size.Z
    local stage = portal.Position + axis * side * (portalDepth / 2 + 5)

    if not tweenSegment(context, root, stage, 200, 240, isCurrent) then
        return false
    end
    task.wait(0.3)
    if isCurrent and not isCurrent() then
        return false
    end

    local finish = portal.Position - axis * side * (portalDepth / 2 + 7)
    local distance = (finish - root.Position).Magnitude
    local tween = context.TweenService:Create(
        root,
        TweenInfo.new(math.max(distance / 18, 0.8), Enum.EasingStyle.Linear),
        { CFrame = CFrame.lookAt(finish, finish - axis * side) }
    )
    context.State.fastTravelTween = tween
    tween:Play()
    local deadline = os.clock() + 7
    local success = false
    repeat
        task.wait(0.05)
        success = isInsideCursedShip(root.Position) == expectInterior
    until success or os.clock() >= deadline or not root.Parent
        or isCurrent and not isCurrent()
    cancelTravelTween(context.State, tween)
    return success and (not isCurrent or isCurrent())
end

local function beginCursedShipTransition(context, routeName, entrance, goal, owner)
    local state = context.State
    if state.cursedShipTransitionActive then
        return true
    end
    if os.clock() < (state.nextCursedShipTransitionAt or 0) then
        return true
    end

    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 then
        return true
    end

    state.cursedShipTransitionActive = true
    local token = {}
    state.cursedShipTransitionToken = token
    state.cursedShipTransitionDeadline = os.clock() + 60
    state.nextCursedShipTransitionAt = os.clock() + 8
    state.lastTravelDecision = {
        mode = "cursed-ship-transition",
        reason = routeName,
        destination = entrance,
        owner = owner,
        at = os.clock(),
        goal = goal.Position,
        phase = "starting",
    }
    local decision = state.lastTravelDecision

    local function isCurrent()
        return state.cursedShipTransitionToken == token
            and not state.stopped
            and not state.paused
            and os.clock() < (state.cursedShipTransitionDeadline or 0)
            and context.LocalPlayer.Character == character
            and root.Parent ~= nil
            and humanoid.Health > 0
            and isTaskCurrent(context, owner)
    end

    local thread = task.spawn(function()
        local success = false
        local completed, failure = pcall(function()
            if not isCurrent() then return end
            context.Functions.CancelTween()
            context.Functions.NoClip("on")
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero

            if routeName == "cursed-ship" then
                decision.phase = "requesting-entry"
                local ok, result = boundedCall(context, owner, function()
                    return context.CommandRemote:InvokeServer("requestEntrance", entrance)
                end, isCurrent)
                decision.result = ok and result or tostring(result)
                if not ok or not isCurrent() then return end
                root.CFrame = root.CFrame + Vector3.new(0, 50, 0)
                local deadline = os.clock() + 6
                repeat
                    task.wait(0.05)
                    success = root.Parent and isInsideCursedShip(root.Position) or false
                until success or os.clock() >= deadline or not isCurrent()
                success = success and isCurrent()
            else
                local portal = findCursedShipExit()
                decision.phase = "crossing-exit"
                if portal then
                    success = crossCursedShipPortal(context, root, portal, false, isCurrent)
                end
            end
        end)
        if state.cursedShipTransitionToken == token then
            state.cursedShipTransitionThread = nil
            state.cursedShipTransitionToken = nil
            state.cursedShipTransitionActive = nil
            state.cursedShipTransitionDeadline = nil
            state.nextCursedShipTransitionAt = os.clock() + (success and 2 or 8)
            cancelTravelTween(state)
            decision.phase = success and "verified" or "failed"
            decision.success = success
            decision.completedAt = os.clock()
            if not completed then decision.error = tostring(failure) end
            state.lastCursedShipTransition = decision
            pcall(context.Functions.NoClip, "off")
        end
    end)
    if state.cursedShipTransitionToken == token then
        state.cursedShipTransitionThread = thread
    end
    return true
end

local function partCFrame(instance, fallback)
    return instance and instance:IsA("BasePart") and instance.CFrame or fallback
end

local function firstSeaPortalPairs()
    local map = workspace:FindFirstChild("Map")
    local teleportSpawn = map and map:FindFirstChild("TeleportSpawn")
    local entrance = partCFrame(
        teleportSpawn and teleportSpawn:FindFirstChild("Entrance"),
        FIRST_SEA_FALLBACKS.fishmanEntrance
    )
    local exit = partCFrame(
        teleportSpawn and teleportSpawn:FindFirstChild("Exit"),
        FIRST_SEA_FALLBACKS.fishmanExit
    )
    local sky = map and map:FindFirstChild("Sky")
    local skyEntrance = partCFrame(sky and sky:FindFirstChild("Entrance"))
    local portals = {
        {
            From = entrance,
            To = FIRST_SEA_DESTINATIONS.fishman,
            Name = "Fish Man",
        },
        {
            From = exit,
            To = FIRST_SEA_DESTINATIONS.whirlPool,
            Name = "Whirl Pool",
        },
    }

    if skyEntrance then
        table.insert(portals, {
            From = skyEntrance,
            To = FIRST_SEA_DESTINATIONS.skyArea2,
            Name = "Sky Area 2",
        })
    end
    table.insert(portals, {
        From = FIRST_SEA_DESTINATIONS.skyArea2,
        To = FIRST_SEA_DESTINATIONS.skyArea1,
        Name = "Sky Area 1",
    })
    return portals
end

local function selectFirstSeaPortal(current, goal)
    local directDistance = (goal - current).Magnitude
    if directDistance < 1000 then
        return nil
    end

    local best
    local bestSavings = 1500
    for _, portal in ipairs(firstSeaPortalPairs()) do
        local destinationDistance = (portal.To.Position - goal).Magnitude
        local routeDistance = (portal.From.Position - current).Magnitude + destinationDistance
        local savings = directDistance - routeDistance
        if savings > bestSavings and destinationDistance < directDistance then
            best = portal
            bestSavings = savings
        end
    end
    if best then
        best.Savings = bestSavings
    end
    return best
end

local function disableWhirlPoolTouch(context)
    local map = workspace:FindFirstChild("Map")
    local teleportSpawn = map and map:FindFirstChild("TeleportSpawn")
    local entrance = teleportSpawn and teleportSpawn:FindFirstChild("Entrance")
    if not entrance or not entrance:IsA("BasePart") then
        return
    end

    local state = context.State
    local restore = state.whirlPoolTouchRestore
    if restore and restore.part ~= entrance then
        restoreWhirlPoolTouch(state)
        restore = nil
    end
    if not restore then
        restore = { part = entrance, canTouch = entrance.CanTouch }
        state.whirlPoolTouchRestore = restore
    end
    cancelThread(restore.thread)
    local timerToken = {}
    restore.timerToken = timerToken
    entrance.CanTouch = false
    restore.thread = task.delay(8, function()
        if state.whirlPoolTouchRestore == restore and restore.timerToken == timerToken then
            restoreWhirlPoolTouch(state)
        end
    end)
end

local function carriedTool(context, name)
    local character = context.LocalPlayer.Character
    local backpack = context.LocalPlayer:FindFirstChildOfClass("Backpack")
    return character and character:FindFirstChild(name)
        or backpack and backpack:FindFirstChild(name)
end

local function loadOrBuyCannon(context, owner)
    local state = context.State
    local cannon = carriedTool(context, "Cannon")
    if cannon then
        return cannon
    end

    local loaded, loadResult = boundedCall(context, owner, function()
        context.CommandRemote:InvokeServer("LoadItem", "Cannon")
    end)
    if not loaded and (loadResult == "travel-request-cancelled"
        or loadResult == "travel-request-timeout" or loadResult == "travel-request-busy")
    then
        return nil
    end
    task.wait(0.15)
    if not isTaskCurrent(context, owner) then
        return nil
    end
    cannon = carriedTool(context, "Cannon")
    if cannon then
        return cannon
    end

    if context.Beli.Value < 100000 or os.clock() < (state.nextSkyCannonBuyAt or 0) then
        return nil
    end

    state.nextSkyCannonBuyAt = os.clock() + 5
    local bought, result = boundedCall(context, owner, function()
        return context.CommandRemote:InvokeServer("BuyItem", "Cannon")
    end)
    state.lastSkyCannonBuy = {
        success = bought,
        result = tostring(result),
        at = os.clock(),
    }
    if not bought then
        return nil
    end
    if not isTaskCurrent(context, owner) then
        return nil
    end

    local reloaded, reloadResult = boundedCall(context, owner, function()
        context.CommandRemote:InvokeServer("LoadItem", "Cannon")
    end)
    if not reloaded and reloadResult == "travel-request-cancelled" then return nil end
    task.wait(0.2)
    if not isTaskCurrent(context, owner) then
        return nil
    end
    return carriedTool(context, "Cannon")
end

local function nearestSkyGateCloud(portalCFrame)
    local map = workspace:FindFirstChild("Map")
    local sky = map and map:FindFirstChild("Sky")
    if not sky then
        return nil
    end

    local nearest
    local nearestDistance
    for _, descendant in sky:GetDescendants() do
        if descendant:IsA("BasePart")
            and descendant.Name == "cloud"
            and descendant.Transparency < 1
        then
            local distance = (descendant.Position - portalCFrame.Position).Magnitude
            if distance < 50 and (not nearestDistance or distance < nearestDistance) then
                nearest = descendant
                nearestDistance = distance
            end
        end
    end
    return nearest, nearestDistance
end

local function functionSource(callback)
    if type(callback) ~= "function" or type(debug) ~= "table" or type(debug.info) ~= "function" then
        return ""
    end
    local success, source = pcall(debug.info, callback, "s")
    return success and tostring(source) or ""
end

local function loadedCombatController(state)
    local cached = state.skyCombatController
    if type(cached) == "table" and type(cached.Attack) == "function" then
        return cached
    end
    if os.clock() < (state.nextSkyCombatDiscoveryAt or 0) then
        return nil
    end
    state.nextSkyCombatDiscoveryAt = os.clock() + DISCOVERY_RETRY_SECONDS
    if type(getgc) ~= "function" then return nil end
    local success, objects = pcall(getgc, true)
    if not success or type(objects) ~= "table" then return nil end
    for _, value in ipairs(objects) do
        if type(value) == "table" and type(rawget(value, "Attack")) == "function"
            and functionSource(rawget(value, "Attack")):find("CombatController", 1, true)
        then
            state.skyCombatController = value
            return value
        end
    end
    return nil
end

local function findMouseState(callback, remainingDepth, visited)
    if type(callback) ~= "function" or remainingDepth < 0 or type(getupvalues) ~= "function" then
        return nil
    end
    visited = visited or {}
    if visited[callback] then
        return nil
    end
    visited[callback] = true

    local success, upvalues = pcall(getupvalues, callback)
    if not success or type(upvalues) ~= "table" then
        return nil
    end
    for _, value in pairs(upvalues) do
        if type(value) == "table"
            and rawget(value, "Hit") ~= nil
            and rawget(value, "X") ~= nil
            and rawget(value, "Y") ~= nil
        then
            return value
        end
    end
    for _, value in pairs(upvalues) do
        if type(value) == "function" then
            local mouse = findMouseState(value, remainingDepth - 1, visited)
            if mouse then
                return mouse
            end
        end
    end
    return nil
end

local function cannonMouseState(state, cannon)
    if state.skyCannonMouseTool == cannon and type(state.skyCannonMouseState) == "table" then
        return state.skyCannonMouseState
    end
    if os.clock() < (state.nextSkyMouseDiscoveryAt or 0) then
        return nil
    end
    state.nextSkyMouseDiscoveryAt = os.clock() + DISCOVERY_RETRY_SECONDS
    if type(getconnections) ~= "function" then return nil end

    local success, connections = pcall(getconnections, cannon.Activated)
    if not success or type(connections) ~= "table" then
        return nil
    end
    for _, connection in ipairs(connections) do
        local mouse = findMouseState(connection.Function, 3)
        if mouse then
            state.skyCannonMouseTool = cannon
            state.skyCannonMouseState = mouse
            return mouse
        end
    end
    return nil
end

local function shootSkyGateCloud(context, cannon, cloud, owner)
    local state = context.State
    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or not cannon or not cloud or not cloud.Parent then
        return false
    end

    if cannon.Parent ~= character then
        humanoid:EquipTool(cannon)
        task.wait(0.1)
        if not isTaskCurrent(context, owner) then
            return false
        end
    end
    if cannon.Parent ~= character
        or not cannon.Enabled
        or cannon:GetAttribute("IsReloading_Client")
        or os.clock() < (state.nextSkyCannonShotAt or 0)
    then
        return true
    end

    local combatController = loadedCombatController(state)
    local mouse = cannonMouseState(state, cannon)
    if not combatController or not mouse then
        state.lastSkyCannonShot = {
            success = false,
            result = not combatController and "combat-controller-unavailable"
                or "mouse-state-unavailable",
            cloud = cloud:GetFullName(),
            at = os.clock(),
        }
        return true
    end

    state.nextSkyCannonShotAt = os.clock() + 0.35
    mouse.Hit = cloud.CFrame
    mouse.Target = cloud

    local previousIdentity
    if type(getthreadidentity) == "function" then
        local ok, identity = pcall(getthreadidentity)
        if ok then previousIdentity = identity end
    end
    if type(setthreadidentity) == "function" then
        pcall(setthreadidentity, 2)
    end
    local success, result = pcall(function()
        return combatController:Attack(cannon, {
            UserInputType = Enum.UserInputType.MouseButton1,
        })
    end)
    if previousIdentity and type(setthreadidentity) == "function" then
        pcall(setthreadidentity, previousIdentity)
    end
    state.lastSkyCannonShot = {
        success = success,
        result = tostring(result),
        cloud = cloud:GetFullName(),
        at = os.clock(),
    }
    return true
end

local function clearSkyGate(context, root, portal, owner)
    local state = context.State
    local cannon = loadOrBuyCannon(context, owner)
    if not isTaskCurrent(context, owner) then
        return true
    end
    if not cannon then
        state.status = context.Beli.Value >= 100000
            and "Auto Farm Level | Loading Cannon"
            or "Auto Farm Level | Need 100000 Beli for Cannon"
        state.lastTravelDecision.mode = "sky-cannon-required"
        return true
    end

    local cloud, cloudDistance = nearestSkyGateCloud(portal.From)
    if not cloud then
        return false
    end

    local firingCFrame = portal.From * CFrame.new(0, -5, 30)
    state.lastTravelDecision.mode = "sky-cloud"
    state.lastTravelDecision.cloud = cloud:GetFullName()
    state.lastTravelDecision.cloudDistance = cloudDistance
    state.status = "Auto Farm Level | Breaking Sky clouds"
    if (root.Position - firingCFrame.Position).Magnitude > 3 then
        routeTP(context, firingCFrame, owner, true)
        return true
    end

    context.Functions.CancelTween()
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    shootSkyGateCloud(context, cannon, cloud, owner)
    return true
end

local function useFirstSeaPortal(context, root, goal, owner, boss, fruit)
    local state = context.State
    local portal = selectFirstSeaPortal(root.Position, goal.Position)
    if not portal then
        return false
    end

    local now = os.clock()
    local distanceToPortal = (portal.From.Position - root.Position).Magnitude
    state.lastTravelDecision = {
        mode = distanceToPortal > 50 and "portal-approach" or "portal-request",
        reason = portal.Name,
        destination = portal.To.Position,
        portalFrom = portal.From.Position,
        owner = owner,
        at = now,
        distance = distanceToPortal,
        savings = portal.Savings,
        goal = goal.Position,
    }

    if portal.Name == "Sky Area 2" and clearSkyGate(context, root, portal, owner) then
        return true
    end

    if distanceToPortal > 50 then
        state.status = "Auto Farm Level | Moving to " .. portal.Name .. " portal"
        routeTP(
            context,
            portal.From + Vector3.new(0, 5, 0),
            owner,
            true,
            boss,
            fruit,
            nil,
            350,
            220
        )
        return true
    end

    context.Functions.CancelTween()
    root.CFrame = portal.From + Vector3.new(0, 2, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    state.status = "Auto Farm Level | Entering " .. portal.Name

    if now < (state.nextEntranceRequestAt or 0) then
        state.lastTravelDecision.mode = "portal-cooldown"
        return true
    end

    state.nextEntranceRequestAt = now + 2
    local success, result = boundedCall(context, owner, function()
        return context.CommandRemote:InvokeServer("requestEntrance", portal.To.Position)
    end)
    if result == "travel-request-cancelled" then return true end
    state.lastTravelDecision.success = success
    state.lastTravelDecision.result = result
    if portal.Name == "Whirl Pool" then
        disableWhirlPoolTouch(context)
    end
    return true
end

local function selectSecondSeaEntrance(current, goal)
    local currentInCursedShip = current.Z > 30000
    local goalInCursedShip = goal.Z > 30000
    if goalInCursedShip and not currentInCursedShip then
        return SECOND_SEA_ROUTES.cursedShip, "cursed-ship"
    end
    if currentInCursedShip and not goalInCursedShip then
        return SECOND_SEA_ROUTES.surface, "cursed-ship-to-surface"
    end
    return nil, nil
end

local function selectSwanRoomPortal(current, goal)
    local swanRoom = SECOND_SEA_ROUTES.swanRoom
    local currentInside = (current - swanRoom.Position).Magnitude <= 300
    local goalInside = (goal - swanRoom.Position).Magnitude <= 300
    if currentInside == goalInside then
        return nil
    end
    if goalInside then
        return {
            from = SECOND_SEA_ROUTES.mansion,
            to = swanRoom,
            name = "Swan's room",
        }
    end
    return {
        from = swanRoom,
        to = SECOND_SEA_ROUTES.mansion,
        name = "Mansion",
    }
end

local function useSwanRoomPortal(context, root, goal, owner, boss, fruit)
    local route = selectSwanRoomPortal(root.Position, goal.Position)
    if not route then
        return false
    end

    local state = context.State
    local now = os.clock()
    local distance = (root.Position - route.from.Position).Magnitude
    state.lastTravelDecision = {
        mode = distance > 50 and "swan-portal-approach" or "swan-portal",
        reason = route.name,
        destination = route.to.Position,
        owner = owner,
        at = now,
        distance = distance,
        goal = goal.Position,
    }
    state.status = "Auto Farm Level | Entering " .. route.name

    if distance > 50 then
        routeTP(
            context,
            route.from + Vector3.new(0, 5, 0),
            owner,
            true,
            boss,
            fruit,
            nil,
            350,
            220
        )
        return true
    end

    context.Functions.CancelTween()
    root.CFrame = route.from + Vector3.new(0, 2, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    if now < (state.nextEntranceRequestAt or 0) then
        return true
    end

    state.nextEntranceRequestAt = now + 2
    local success, result = boundedCall(context, owner, function()
        return context.CommandRemote:InvokeServer("requestEntrance", route.to.Position)
    end)
    if result == "travel-request-cancelled" then return true end
    state.lastTravelDecision.success = success
    state.lastTravelDecision.result = result
    return true
end

function TryFastTravel.run(context, goal, owner, boss, fruit)
    local state = context.State
    local root = state.humanoidRootPart
    if state.travel or not root or context.Functions.ShouldCancelTP(goal, owner) then
        return false
    end

    if context.Functions.ShouldNotBypassTP and context.Functions.ShouldNotBypassTP() then
        state.lastTravelDecision = {
            mode = "tween",
            reason = "bypass-blocked",
            owner = owner,
            at = os.clock(),
            goal = goal.Position,
        }
        return false
    end

    if handleSubmergedTransition(context, root, goal, owner) then
        return true
    end

    if context.IsSea(2)
        and useSwanRoomPortal(context, root, goal, owner, boss, fruit)
    then
        return true
    end

    local distance = (goal.Position - root.Position).Magnitude
    if context.IsSea(1) and useFirstSeaPortal(context, root, goal, owner, boss, fruit) then
        return true
    end

    local entrance
    local routeName
    if context.IsSea(2) and distance > 4000 then
        entrance, routeName = selectSecondSeaEntrance(root.Position, goal.Position)
    end

    local now = os.clock()
    if entrance then
        if routeName == "cursed-ship-to-surface" then
            local shipExit = findCursedShipExit()
            if shipExit then
                local exitDistance = (shipExit.Position - root.Position).Magnitude
                state.lastTravelDecision = {
                    mode = "physical-exit",
                    reason = routeName,
                    destination = shipExit.Position,
                    owner = owner,
                    at = now,
                    distance = exitDistance,
                    goal = goal.Position,
                }
                if exitDistance > 12 then
                    routeTP(context, shipExit.CFrame, owner, true, boss, fruit)
                else
                    beginCursedShipTransition(context, routeName, entrance, goal, owner)
                end
                return true
            end
        end

        if routeName == "cursed-ship" then
            local approachDistance = (CURSED_SHIP_ENTRY_APPROACH.Position - root.Position).Magnitude
            if approachDistance > 12 then
                state.lastTravelDecision = {
                    mode = "cursed-ship-entry-approach",
                    reason = routeName,
                    destination = CURSED_SHIP_ENTRY_APPROACH.Position,
                    owner = owner,
                    at = now,
                    distance = approachDistance,
                    goal = goal.Position,
                }
                routeTP(
                    context,
                    CURSED_SHIP_ENTRY_APPROACH,
                    owner,
                    nil,
                    boss,
                    fruit,
                    nil,
                    350,
                    220
                )
                return true
            end
            return beginCursedShipTransition(context, routeName, entrance, goal, owner)
        end

        if now < (state.nextEntranceRequestAt or 0) then
            state.lastTravelDecision = {
                mode = "entrance-cooldown",
                reason = routeName,
                destination = entrance,
                owner = owner,
                at = now,
                distance = distance,
                goal = goal.Position,
            }
            return true
        end

        state.nextEntranceRequestAt = now + 3
        local success, result = boundedCall(context, owner, function()
            return context.CommandRemote:InvokeServer("requestEntrance", entrance)
        end)
        if result == "travel-request-cancelled" then return true end
        if success and routeName ~= "cursed-ship-to-surface" then
            root.CFrame = root.CFrame + Vector3.new(0, 50, 0)
        end
        state.lastTravelDecision = {
            mode = "entrance",
            reason = routeName,
            destination = entrance,
            owner = owner,
            at = now,
            distance = distance,
            goal = goal.Position,
            success = success,
            result = result,
        }
        return true
    end

    state.lastTravelDecision = {
        mode = "tween",
        reason = distance <= 4000 and "distance-at-most-4000" or "no-clean-entrance-route",
        destination = nil,
        owner = owner,
        at = os.clock(),
        distance = distance,
        goal = goal.Position,
    }
    return false
end
end

local CancelTween
do
CancelTween = {}

function CancelTween.run(context)
    local state = context.State
    local movement = state.movement
    state.movement = nil
    state.movementPhase = "stopped"

    local tween = movement and movement.tween or state.activeTween2 or state.activeTween
    state.activeTween = nil
    state.activeTween2 = nil
    state.activeTweenGoal = nil
    state.activeTweenRoot = nil
    state.tpWaypoint = nil

    if tween then
        local playbackState = tween.PlaybackState
        if playbackState == Enum.PlaybackState.Playing or playbackState == Enum.PlaybackState.Paused then
            tween:Cancel()
        end
    end
end
end

local NoClip
do
NoClip = {}

local function restore(state)
    local noclip = state.noclip
    state.noclip = nil
    state.noClipActive = false

    if not noclip then
        return
    end

    for _, connection in noclip.connections do
        connection:Disconnect()
    end
    for part, canCollide in noclip.parts do
        if part.Parent then
            part.CanCollide = canCollide
        end
    end
    table.clear(noclip.parts)
end

function NoClip.run(context, mode)
    local state = context.State
    if mode ~= "on" then
        restore(state)
        return
    end

    local character = context.LocalPlayer.Character
    if not character or state.paused or state.stopped then
        return
    end
    if state.noclip and state.noclip.character == character then
        return
    end

    restore(state)
    local session = { character = character, parts = {}, connections = {} }
    state.noclip = session
    state.noClipActive = true

    local function disableCollision(part)
        if part:IsA("BasePart") then
            if session.parts[part] == nil then
                session.parts[part] = part.CanCollide
            end
            part.CanCollide = false
        end
    end

    for _, descendant in character:GetDescendants() do
        disableCollision(descendant)
    end

    session.connections[1] = character.DescendantAdded:Connect(disableCollision)
    session.connections[2] = character.DescendantRemoving:Connect(function(part)
        local originalCollision = session.parts[part]
        if originalCollision ~= nil then
            part.CanCollide = originalCollision
            session.parts[part] = nil
        end
    end)
    session.connections[3] = context.RunService.PreSimulation:Connect(function()
        if state.noclip ~= session then
            return
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if context.LocalPlayer.Character == character
            and not state.paused and not state.stopped
            and humanoid and humanoid.Health > 0
        then
            for part in session.parts do
                if part.Parent and part.CanCollide then
                    part.CanCollide = false
                end
            end
        else
            restore(state)
        end
    end)
end
end

local RunMovement
do
RunMovement = {}

local function arrivalThreshold(movement, deltaTime)
    local speed = movement.speed or 350
    local frameStep = speed * math.min(deltaTime or 0.05, 0.05)
    return math.max(100 + frameStep, movement.minimumDistance or 7)
end

local function prepareSubmergedMovement(context, goal)
    if not context.IsSea(3) or goal.Position.Y > -1000 then
        return
    end

    pcall(function()
        context.RunService:UnbindFromRenderStep("GlitchCheck")
    end)
    context.State.submergedGlitchCheckDisabled = true
end

function RunMovement.run(context, movement)
    local state = context.State
    local functions = context.Functions

    local function getDestination()
        if state.movement ~= movement
            or state.paused or state.stopped or state.stopTweenRequested
            or context.LocalPlayer.Character ~= movement.character
            or not movement.root.Parent or movement.humanoid.Health <= 0
            or context.TaskQueue:top() ~= movement.owner
        then
            return nil
        end

        local goal = movement.goal
        if movement.target then
            local targetRoot = movement.target.Parent
                and movement.target:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = movement.target:FindFirstChildOfClass("Humanoid")
            if not targetRoot or (targetHumanoid and targetHumanoid.Health <= 0) then
                return nil
            end
            goal = targetRoot.CFrame + Vector3.new(0, 30, 0)
        end

        if functions.ShouldCancelTP(goal, movement.taskName, movement.boss, movement.fruit) then
            return nil
        end
        return goal
    end

    local success, failure = xpcall(function()
        while true do
            local deltaTime = context.RunService.Heartbeat:Wait()
            local goal = state.movement == movement and getDestination()
            if not goal then
                break
            end

            prepareSubmergedMovement(context, goal)

            local current = movement.root.CFrame
            local distance = (goal.Position - current.Position).Magnitude
            movement.arrival = arrivalThreshold(movement, deltaTime)
            if distance <= movement.arrival then
                movement.root.CFrame = goal
                movement.arrived = true
                return
            end

            functions.AddVelocity()
            functions.NoClip("on")
            local speed = movement.speed or 350
            local stepDistance = math.min(distance, speed * math.min(deltaTime, 0.05))
            local waypointPosition = current.Position
                + (goal.Position - current.Position).Unit * stepDistance
            local waypoint = CFrame.new(waypointPosition, goal.Position)

            movement.tween = nil
            movement.phase = "direct"
            movement.phaseStartedAt = os.clock()
            state.movementPhase = "direct"
            state.activeTween = nil
            state.activeTween2 = nil
            state.activeTweenGoal = waypoint
            state.activeTweenRoot = movement.root
            movement.root.CFrame = waypoint
            movement.pulses = movement.pulses + 1
        end
    end, debug.traceback)

    if state.movement == movement then
        local arrived = success and movement.arrived
        functions.CancelTween()
        state.movementPhase = arrived and "arrived" or "stopped"
        if arrived then
            functions.AddVelocity()
            functions.NoClip("on")
        else
            functions.RemoveVelocity()
            functions.NoClip("off")
        end
        if not arrived and functions.ReleaseBring then
            functions.ReleaseBring()
        end
    end

    if not success then
        state.lastError = tostring(failure)
        warn("[SeaHub][Movement] " .. tostring(failure))
    end
end
end

local TP
do
TP = {}

local function arrivalThreshold(movement)
    local speed = movement.speed or 350
    return math.max(100 + speed * 0.05, movement.minimumDistance or 7)
end

local function movementProfile(state, goal, root, movingTarget)
    local distance = (goal.Position - root.Position).Magnitude
    local farmTarget = movingTarget or state.farmTarget
    local targetRoot = farmTarget and farmTarget.Parent
        and farmTarget:FindFirstChild("HumanoidRootPart")
    local chasingTarget = targetRoot
        and (goal.Position - targetRoot.Position).Magnitude <= 45

    if chasingTarget then
        return 350, 300, "combat-chase"
    end
    if distance > 1500 then
        return 350, 220, "long-route"
    end
    return 350, 300, "farm-route"
end

function TP.run(context, goal, taskName, preserveBring, boss, fruit, movingTarget, speedOverride, stepDistanceOverride)
    local state = context.State
    local functions = context.Functions
    if state.travel then
        return false
    end

    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 or state.paused or state.stopped then
        functions.StopTween()
        return false
    end

    local environment = context.Environment or {}
    local configs = environment.Configs or {}
    local targetFps = math.clamp(math.floor(tonumber(configs.FPS) or 15), 5, 60)
    local applyCap = rawget(environment, "setfpscap")
    if type(applyCap) == "function" then
        pcall(applyCap, targetFps)
    end
    state.performanceFps = targetFps

    if movingTarget then
        local targetRoot = movingTarget.Parent and movingTarget:FindFirstChild("HumanoidRootPart")
        if not targetRoot then
            functions.StopTween()
            return false
        end
        goal = targetRoot.CFrame + Vector3.new(0, 30, 0)
    end

    if functions.ShouldCancelTP(goal, taskName, boss, fruit) then
        return false
    end

    state.humanoid = humanoid
    state.humanoidRootPart = root
    local owner = taskName or context.TaskQueue:top()
    local minimumDistance = fruit and 3 or 7

    if not preserveBring and state.bring and type(functions.ReleaseBring) == "function" then
        pcall(functions.ReleaseBring)
    end

    if not state.fastTravelResolving
        and functions.TryFastTravel(goal, owner, boss, fruit)
    then
        return false
    end

    local movement = state.movement
    if movement and movement.root == root and movement.owner == owner then
        local speed, stepDistance, profile = movementProfile(state, goal, root, movingTarget)
        speed = tonumber(speedOverride) or speed
        stepDistance = tonumber(stepDistanceOverride) or stepDistance
        movement.goal = goal
        movement.taskName = taskName
        movement.boss = boss
        movement.fruit = fruit
        movement.target = movingTarget
        movement.minimumDistance = minimumDistance
        movement.speed = speed
        movement.arrival = arrivalThreshold(movement)
        movement.stepDistance = stepDistance
        movement.profile = profile
        state.movementProfile = profile
        state.movementSpeed = speed
        return false
    end

    local initialSpeed = select(1, movementProfile(state, goal, root, movingTarget))
    initialSpeed = tonumber(speedOverride) or initialSpeed
    local arrivalDistance = math.max(100 + initialSpeed * 0.05, minimumDistance)
    if (goal.Position - root.Position).Magnitude <= arrivalDistance then
        root.CFrame = goal
        local speed, _, profile = movementProfile(state, goal, root, movingTarget)
        functions.CancelTween()
        functions.AddVelocity()
        functions.NoClip("on")
        state.movementPhase = "arrived"
        state.movementProfile = profile
        state.movementSpeed = speed
        return true
    end

    functions.CancelTween()
    functions.AddVelocity()
    functions.NoClip("on")
    if humanoid.Sit then
        humanoid.Sit = false
        humanoid.Jump = true
    end

    local speed, stepDistance, profile = movementProfile(state, goal, root, movingTarget)
    speed = tonumber(speedOverride) or speed
    stepDistance = tonumber(stepDistanceOverride) or stepDistance
    movement = {
        root = root,
        humanoid = humanoid,
        character = character,
        owner = owner,
        goal = goal,
        taskName = taskName,
        boss = boss,
        fruit = fruit,
        target = movingTarget,
        arrival = arrivalDistance,
        minimumDistance = minimumDistance,
        speed = speed,
        stepDistance = stepDistance,
        profile = profile,
        pulses = 0,
        phase = "starting",
        phaseStartedAt = os.clock(),
    }
    state.movement = movement
    state.movementPhase = "starting"
    state.movementProfile = profile
    state.movementSpeed = speed
    movement.thread = task.spawn(functions.RunMovement, movement)
    return false
end
end

local StopTween
do
StopTween = {}

function StopTween.run(context, options)
    local state = context.State
    local functions = context.Functions
    state.stopTweenRequested = true
    state.teleportInProgress = false
    state.travel = nil
    if type(functions.StopFastTravel) == "function" then
        functions.StopFastTravel()
    end
    state.cursedShipTransitionToken = nil
    if type(state.cursedShipTransitionThread) == "thread"
        and type(task.cancel) == "function"
    then
        pcall(task.cancel, state.cursedShipTransitionThread)
    end
    state.cursedShipTransitionThread = nil
    state.cursedShipTransitionActive = nil
    functions.CancelTween()
    local preserveAltitude = type(options) == "table" and options.preserveAltitude == true
        and not state.paused and not state.stopped and context.TaskQueue:top() ~= nil
    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if preserveAltitude and humanoid and humanoid.Health > 0 then
        functions.AddVelocity()
        functions.NoClip("on")
    else
        functions.RemoveVelocity()
    end
    if functions.ReleaseBring then
        functions.ReleaseBring()
    end
    if functions.ReleaseBossCombat then
        functions.ReleaseBossCombat()
    end
    state.namecallTarget = nil
    state.stopTweenRequested = false
end
end

local BringMob
do
BringMob = {}

local REBRING_INTERVAL = 60
local REBRING_RELEASE_TIME = 0.35
local GRAB_INTERVAL = 0.35
local STALLED_MEMBER_SECONDS = 10
local STALLED_MEMBER_RETRY_SECONDS = 5

local function recoveryReady(state, enemy, now)
    local cooldowns = state.bringRecoveryUntil
    local untilTime = cooldowns and cooldowns[enemy]
    if not untilTime then
        return true
    end
    if now < untilTime then
        return false
    end
    cooldowns[enemy] = nil
    return true
end

local function acceptedNames(value)
    local names = {}
    if type(value) == "table" then
        for _, name in value do
            if type(name) == "string" and name ~= "" then
                names[name] = true
            end
        end
    elseif type(value) == "string" and value ~= "" then
        names[value] = true
    end
    return names
end

local function namesKey(names)
    local ordered = {}
    for name in names do ordered[#ordered + 1] = name end
    table.sort(ordered)
    return table.concat(ordered, "\0")
end

local function nameList(names)
    local ordered = {}
    for name in names do
        ordered[#ordered + 1] = name
    end
    table.sort(ordered)
    return ordered
end

local function nextBringSlot(session)
    local used = {}
    for enemy in session.members do
        local slot = enemy:GetAttribute("BringSlot")
        if type(slot) == "number" then
            used[slot] = true
        end
    end
    local slot = 1
    while used[slot] do slot += 1 end
    return slot
end

local function isOnRaidIsland(enemy, root, raidIsland)
    if not raidIsland or not root then
        return raidIsland == nil
    end
    local originalPosition = enemy:GetAttribute("OldPosition")
    if typeof(originalPosition) ~= "Vector3" then
        originalPosition = root.Position
    end

    local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
    local locations = worldOrigin and worldOrigin:FindFirstChild("Locations")
    local nearest
    local nearestDistance = math.huge
    for _, location in locations and locations:GetChildren() or {} do
        if location:IsA("BasePart")
            and location.Name:match("^Island %d+$")
            and location.Position.Magnitude > 7000
        then
            local offset = originalPosition - location.Position
            local distance = Vector3.new(offset.X, 0, offset.Z).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearest = location
            end
        end
    end
    return nearest == raidIsland
        and nearestDistance <= 650
        and math.abs(originalPosition.Y - raidIsland.Position.Y) <= 500
end

local function isBoss(enemy, humanoid)
    return enemy:GetAttribute("IsBoss") == true
        or humanoid and string.find(
            string.lower(tostring(humanoid.DisplayName or "")),
            "boss",
            1,
            true
        ) ~= nil
end

local function captureMember(session, enemy, humanoid, root, allowActions)
    local member = {
        root = root,
        humanoid = humanoid,
        walkSpeed = humanoid.WalkSpeed,
        autoRotate = humanoid.AutoRotate,
        anchored = root.Anchored,
        collisions = {},
        lastOwnedAt = os.clock(),
        reacquires = 0,
    }
    if enemy:GetAttribute("OldPosition") == nil then
        enemy:SetAttribute("OldPosition", root.Position)
    end
    enemy:SetAttribute("IsGrabbed", true)
    enemy:SetAttribute("BringSlot", nextBringSlot(session))
    if not allowActions then
        member.collisions[root] = root.CanCollide
        humanoid.WalkSpeed = 0
        humanoid.AutoRotate = false
        root.Anchored = false
        root.CanCollide = false
        local freezeVelocity = root:FindFirstChild("FreezeVelocity")
            or Instance.new("BodyVelocity")
        freezeVelocity.Name = "FreezeVelocity"
        freezeVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        freezeVelocity.Velocity = Vector3.zero
        freezeVelocity.Parent = root
        member.freezeVelocity = freezeVelocity
    end
    return member
end

local function restoreMember(member, allowActions)
    local humanoid = member.humanoid
    if humanoid and humanoid.Parent then
        if not allowActions then
            humanoid.WalkSpeed = member.walkSpeed
            humanoid.AutoRotate = member.autoRotate
        end
    end
    for part, canCollide in member.collisions do
        if part.Parent then
            part.CanCollide = canCollide
        end
    end
    if member.freezeVelocity and member.freezeVelocity.Parent then
        member.freezeVelocity:Destroy()
    end
    if member.root and member.root.Parent then
        member.root.Anchored = member.anchored
    end
    local enemy = humanoid and humanoid.Parent
    if enemy then
        enemy:SetAttribute("IsGrabbed", nil)
        enemy:SetAttribute("BringSlot", nil)
    end
end

function BringMob.release(context)
    local state = context.State
    local session = state.bring
    state.bring = nil
    state.bringReacquireToken = nil
    state.bringOwnedCount = 0
    state.bringPendingOwnershipCount = 0
    if not session then
        return
    end
    if session.connection then
        session.connection:Disconnect()
    end
    for _, member in session.members do
        restoreMember(member, session.allowActions)
    end
end

function BringMob.run(context, targetCFrame, targetName, options, primaryTarget)
    local state = context.State
    local functions = context.Functions
    if typeof(targetCFrame) ~= "CFrame" or state.paused or state.stopped then
        return nil
    end

    local character = context.LocalPlayer.Character
    local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
    local characterHumanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not characterRoot or not characterHumanoid or characterHumanoid.Health <= 0 then
        return nil
    end

    local owner = context.TaskQueue:top()
    local now = os.clock()
    local session = state.bring
    local allowActions = type(options) == "table" and options.allowActions == true
    local scanRadius = type(options) == "table"
        and tonumber(options.scanRadius) or 320
    local maxMembers = type(options) == "table"
        and tonumber(options.maxMembers) or 10
    local raidIsland = type(options) == "table" and options.raidIsland or nil
    local accepted = acceptedNames(targetName)
    local targetKey = namesKey(accepted)
    if targetKey == "" then
        if session then
            functions.ReleaseBring()
        end
        return nil
    end

    if now < (state.bringPausedUntil or 0) then
        return session and session.anchor or nil
    end

    if primaryTarget and (not accepted[primaryTarget.Name]
        or not functions.IsActiveEnemyModel(primaryTarget, primaryTarget.Name))
    then
        primaryTarget = nil
    end

    functions.RefreshSimulationRadius()
    if session and (session.task ~= owner
        or (not raidIsland and session.nameKey ~= targetKey)
        or session.allowActions ~= allowActions
        or session.scanRadius ~= scanRadius
        or session.maxMembers ~= maxMembers
        or session.raidIsland ~= raidIsland)
    then
        functions.ReleaseBring()
        session = nil
    end

    if not session then
        if (characterRoot.Position - targetCFrame.Position).Magnitude > 80 then
            return nil
        end

        local anchor = CFrame.new(targetCFrame.Position) * targetCFrame.Rotation
        state.bringReacquireToken = nil

        session = {
            task = owner,
            name = primaryTarget and primaryTarget.Name or targetName,
            names = accepted,
            nameKey = targetKey,
            target = primaryTarget,
            anchor = anchor,
            members = {},
            candidates = {},
            updatedAt = now,
            scannedAt = -1,
            allowActions = allowActions,
            scanRadius = scanRadius,
            maxMembers = maxMembers,
            raidIsland = raidIsland,
            heldSince = now,
            lastCleanupAt = now,
        }
        state.bring = session
        session.connection = context.RunService.Heartbeat:Connect(function()
            if state.bring ~= session then
                return
            end
            local humanoid = context.LocalPlayer.Character
                and context.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if state.paused or state.stopped or context.TaskQueue:top() ~= session.task
                or not humanoid or humanoid.Health <= 0
            then
                functions.ReleaseBring()
                return
            end


            if not session.raidIsland
                and not session.allowActions
                and os.clock() - session.heldSince >= REBRING_INTERVAL
            then
                local reacquireAnchor = session.anchor
                local reacquireNames = nameList(session.names)
                local reacquireTask = session.task
                local reacquireOptions = {
                    allowActions = session.allowActions,
                    scanRadius = session.scanRadius,
                    maxMembers = session.maxMembers,
                    raidIsland = session.raidIsland,
                }
                state.bringPausedUntil = os.clock() + REBRING_RELEASE_TIME
                state.lastBringReacquireAt = os.clock()
                state.bringReacquireCycles = (state.bringReacquireCycles or 0) + 1
                functions.ReleaseBring()
                local reacquireToken = {}
                state.bringReacquireToken = reacquireToken
                task.delay(REBRING_RELEASE_TIME, function()
                    if state.bringReacquireToken ~= reacquireToken then
                        return
                    end
                    state.bringReacquireToken = nil
                    if not state.stopped and not state.paused
                        and context.TaskQueue:top() == reacquireTask
                        and not state.bring
                    then
                        functions.BringMob(
                            reacquireAnchor,
                            reacquireNames,
                            reacquireOptions,
                            nil
                        )
                    end
                end)
                return
            end

            local ownedCount = 0
            local pendingOwnershipCount = 0
            local cleanupDue = os.clock() - session.lastCleanupAt >= 3
            if cleanupDue then
                session.lastCleanupAt = os.clock()
            end
            for enemy, member in session.members do
                local root = member.root
                local enemyHumanoid = member.humanoid
                if session.names[enemy.Name]
                    and functions.IsActiveEnemyModel(enemy, enemy.Name)
                    and root.Parent and enemyHumanoid.Parent and enemyHumanoid.Health > 0
                then
                    if not session.raidIsland
                        and (enemy:GetAttribute("FailureCount") or 0) > 5
                    then
                        restoreMember(member, session.allowActions)
                        session.members[enemy] = nil
                        continue
                    end
                    local playerRoot = context.LocalPlayer.Character
                        and context.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if cleanupDue and playerRoot
                        and (root.Position - playerRoot.Position).Magnitude
                            > session.scanRadius + 250
                    then
                        restoreMember(member, session.allowActions)
                        session.members[enemy] = nil
                        continue
                    end
                    local offset = playerRoot and root.Position - playerRoot.Position
                    local nearPlayer = offset
                        and Vector3.new(offset.X, 0, offset.Z).Magnitude <= 30
                    local ownsRoot = functions.IsNetworkOwner(root)
                    local ghostEligible = not session.raidIsland
                        and not session.allowActions
                        and not context.LocalPlayer:GetAttribute("IslandRaiding")
                        and enemy.Name ~= "Core"
                        and nearPlayer
                        and ownsRoot
                        and state.lastAttackSent == true
                        and os.clock() - (state.lastAttackAt or -math.huge) <= 1
                    if ghostEligible then
                        if member.ghostHealth ~= enemyHumanoid.Health then
                            member.ghostHealth = enemyHumanoid.Health
                            member.ghostSince = os.clock()
                        elseif os.clock() - (member.ghostSince or os.clock()) >= STALLED_MEMBER_SECONDS then
                            restoreMember(member, session.allowActions)
                            session.members[enemy] = nil
                            state.bringRecoveryUntil = state.bringRecoveryUntil
                                or setmetatable({}, { __mode = "k" })
                            state.bringRecoveryUntil[enemy] = os.clock() + STALLED_MEMBER_RETRY_SECONDS
                            state.lastBringRecovery = "stalled-member-released"
                            continue
                        end
                    else
                        member.ghostHealth = nil
                        member.ghostSince = nil
                    end

                    if ownsRoot then
                        if member.waitingForOwnership then
                            member.reacquires += 1
                            state.bringReacquireCount = (state.bringReacquireCount or 0) + 1
                        end
                        member.waitingForOwnership = nil
                        member.lastOwnedAt = os.clock()
                        ownedCount += 1
                    else
                        member.waitingForOwnership = true
                        pendingOwnershipCount += 1
                    end

                    if not session.allowActions then
                        enemyHumanoid.WalkSpeed = 0
                        enemyHumanoid.AutoRotate = false
                        root.Anchored = false
                        root.CanCollide = false
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                    end

                    local escapedDistance = (root.Position - session.anchor.Position).Magnitude
                    if session.raidIsland or escapedDistance > 0.05 then
                        if escapedDistance > 20 then
                            state.lastBringReacquireDistance = escapedDistance
                        end
                        local holdCFrame = session.raidIsland
                            and context.LocalPlayer.Character
                            and context.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        holdCFrame = holdCFrame
                            and CFrame.new(holdCFrame.Position - Vector3.new(0, 30, 0))
                            or session.anchor
                        pcall(function()
                            root.CFrame = holdCFrame
                            root.AssemblyLinearVelocity = Vector3.zero
                            root.AssemblyAngularVelocity = Vector3.zero
                        end)
                    end
                else
                    restoreMember(member, session.allowActions)
                    session.members[enemy] = nil
                end
            end
            state.bringOwnedCount = ownedCount
            state.bringPendingOwnershipCount = pendingOwnershipCount
        end)

        if primaryTarget then
            local active, humanoid, root = functions.IsActiveEnemyModel(primaryTarget, primaryTarget.Name)
            local allowedOrdinaryMob = raidIsland
                or (not isBoss(primaryTarget, humanoid)
                    and not primaryTarget:GetAttribute("IgnoreGrab")
                    and (primaryTarget:GetAttribute("FailureCount") or 0) <= 7)
            if active and allowedOrdinaryMob
                and (raidIsland or recoveryReady(state, primaryTarget, now))
                and (raidIsland or functions.IsNetworkOwner(root))
            then
                session.members[primaryTarget] = captureMember(
                    session,
                    primaryTarget,
                    humanoid,
                    root,
                    allowActions
                )
            end
        end
    end

    if raidIsland then
        for name in accepted do
            session.names[name] = true
        end
        session.nameKey = namesKey(session.names)
    end
    session.updatedAt = now
    if now - session.scannedAt >= GRAB_INTERVAL then
        session.scannedAt = now
        local memberCount = 0
        for _ in session.members do
            memberCount = memberCount + 1
        end

        for _, enemy in workspace.Enemies:GetChildren() do
            if memberCount >= session.maxMembers then
                break
            end
            local active, humanoid, root = functions.IsActiveEnemyModel(enemy, enemy.Name)
            local onRaidIsland = not raidIsland or isOnRaidIsland(enemy, root, raidIsland)
            local allowedOrdinaryMob = raidIsland
                or (not isBoss(enemy, humanoid)
                    and not enemy:GetAttribute("IgnoreGrab")
                    and (enemy:GetAttribute("FailureCount") or 0) <= 7)
            if session.names[enemy.Name] and active and allowedOrdinaryMob
                and not session.members[enemy]
                and (raidIsland or recoveryReady(state, enemy, now))
                and (raidIsland or functions.IsNetworkOwner(root))
                and onRaidIsland
                and (raidIsland or (root.Position - session.anchor.Position).Magnitude <= session.scanRadius)
            then
                local member = captureMember(session, enemy, humanoid, root, session.allowActions)
                session.members[enemy] = member
                session.candidates[enemy] = nil
                memberCount += 1
            elseif not session.members[enemy] then
                session.candidates[enemy] = nil
            end
        end
    end

    return next(session.members) and session.anchor or nil
end
end

local AutoBuso
do
AutoBuso = {}

function AutoBuso.run(context)
    local state = context.State
    if state.paused or state.stopped then
        return false
    end

    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    if character:FindFirstChild("HasBuso") then
        state.busoEnabled = true
        state.busoState = "enabled"
        return true
    end

    state.busoEnabled = false
    local now = os.clock()
    if now - (state.lastBusoAt or -2) < 2 then
        return false
    end

    state.lastBusoAt = now
    state.busoState = "requested"
    context.CommandRemote:InvokeServer("Buso")
    return character:FindFirstChild("HasBuso") ~= nil
end
end

local EnsureTeam
do
EnsureTeam = {}

local function isVisible(gui)
    local current = gui
    while current and current:IsA("GuiObject") do
        if not current.Visible then
            return false
        end
        current = current.Parent
    end
    return true
end

local function findTeamButton(player, desiredTeam)
    local playerGui = player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        return nil
    end

    local needle = tostring(desiredTeam):lower()
    local best, bestScore
    for _, gui in playerGui:GetDescendants() do
        if gui:IsA("GuiButton") and isVisible(gui) then
            local text = gui:IsA("TextButton") and gui.Text:lower() or ""
            local name = gui.Name:lower()
            local path = gui:GetFullName():lower()
            local score = 0
            if text == needle or name == needle then
                score += 100
            end
            if text:find(needle, 1, true) then
                score += 40
            end
            if name:find(needle, 1, true) then
                score += 30
            end
            if path:find("chooseteam", 1, true) or path:find("choose team", 1, true)
                or path:find("pick", 1, true)
            then
                score += 20
            end
            if score > 0 and (not bestScore or score > bestScore) then
                best, bestScore = gui, score
            end
        end
    end
    return best
end

local function activateButton(button)
    if type(firesignal) == "function" then
        local ok = pcall(firesignal, button.Activated)
        if ok then
            return true, "firesignal"
        end
    end
    if type(getconnections) == "function" then
        local ok = pcall(function()
            for _, connection in getconnections(button.Activated) do
                if type(connection.Fire) == "function" then
                    connection:Fire()
                end
            end
        end)
        if ok then
            return true, "connections"
        end
    end

    local position = button.AbsolutePosition
    local size = button.AbsoluteSize
    local input = game:GetService("VirtualInputManager")
    local x = position.X + size.X / 2
    local y = position.Y + size.Y / 2
    local ok, failure = pcall(function()
        input:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.05)
        input:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
    return ok, ok and "virtual-input" or tostring(failure)
end

local function playerDataReady(player)
    if player:GetAttribute("DataLoaded") == false then
        return false
    end
    local data = player:FindFirstChild("Data")
    return data ~= nil and data:FindFirstChild("Level") ~= nil
end

function EnsureTeam.run(context)
    local player = context.LocalPlayer
    if player.Team then
        context.State.teamState = "ready"
        return true
    end

    local now = os.clock()
    if not playerDataReady(player) then
        context.State.teamState = "waiting-player-data"
        return false
    end
    if now - (context.State.lastTeamRequestAt or -3) < 3 then
        return false
    end
    context.State.lastTeamRequestAt = now

    local desiredTeam = context.DesiredTeam or "Pirates"
    local success, result = pcall(function()
        return context.CommandRemote:InvokeServer("SetTeam2", desiredTeam)
    end)
    if not success then
        success, result = pcall(function()
            return context.CommandRemote:InvokeServer("SetTeam", desiredTeam)
        end)
    end
    context.State.lastTeamRequest = {
        At = now,
        Team = desiredTeam,
        Ok = success,
        Result = result,
    }
    context.State.teamState = success and "requested" or "failed"
    context.State.lastTeamError = success and nil or tostring(result)

    if not player.Team and now >= (context.State.nextTeamGuiAttemptAt or 0) then
        context.State.nextTeamGuiAttemptAt = now + 2.5
        local button = findTeamButton(player, desiredTeam)
        if button then
            local clicked, method = activateButton(button)
            context.State.lastTeamGuiAttempt = {
                At = now,
                Team = desiredTeam,
                Button = button:GetFullName(),
                Ok = clicked,
                Method = method,
            }
            if clicked then
                context.State.teamState = "gui-requested"
            end
        else
            context.State.lastTeamGuiAttempt = {
                At = now,
                Team = desiredTeam,
                Ok = false,
                Method = "button-not-found",
            }
        end
    end
    return player.Team ~= nil
end

EnsureTeam.findTeamButton = findTeamButton
EnsureTeam.playerDataReady = playerDataReady
end

local UpStats
do
UpStats = {}

function UpStats.run(context)
    local state = context.State
    if state.paused or state.stopped or state.autoStatsEnabled == false then
        return false
    end

    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    local data = context.LocalPlayer:FindFirstChild("Data")
    local pointsValue = data and data:FindFirstChild("Points")
    local stats = data and data:FindFirstChild("Stats")
    local points = pointsValue and math.max(0, math.floor(tonumber(pointsValue.Value) or 0)) or 0
    if points == 0 then
        state.lastStatError = nil
        return false
    end
    if not stats then
        return false
    end

    local now = os.clock()
    if now - (state.lastStatAllocationAt or 0) < 0.5 then
        return false
    end
    state.lastStatAllocationAt = now

    local melee = stats:FindFirstChild("Melee")
    local defense = stats:FindFirstChild("Defense")
    local sword = stats:FindFirstChild("Sword")
    local meleeLevel = melee and melee:FindFirstChild("Level")
    local defenseLevel = defense and defense:FindFirstChild("Level")
    local swordLevel = sword and sword:FindFirstChild("Level")
    if not meleeLevel or not defenseLevel or not swordLevel then
        state.lastStatError = "stat-values-unavailable"
        return false
    end

    local cap = tonumber(context.Environment.Configs["Stat Cap"]) or 2800
    local playerLevel = tonumber(context.Level and context.Level.Value) or 0
    local statName
    if defenseLevel.Value < cap
        and (defenseLevel.Value < playerLevel / 80 or cap - meleeLevel.Value < 100)
    then
        statName = "Defense"
    elseif meleeLevel.Value < cap then
        statName = "Melee"
    else
        statName = "Sword"
    end

    local amount = 999

    local pointsBefore = pointsValue.Value
    local levelBefore = statName == "Melee" and meleeLevel.Value
        or statName == "Defense" and defenseLevel.Value
        or swordLevel.Value
    local success, result = pcall(function()
        return context.CommandRemote:InvokeServer("AddPoint", statName, amount)
    end)
    task.wait()
    local levelAfter = statName == "Melee" and meleeLevel.Value
        or statName == "Defense" and defenseLevel.Value
        or swordLevel.Value
    local accepted = success and (
        pointsValue.Value < pointsBefore
        or levelAfter > levelBefore
    )
    state.lastStatAllocation = {
        At = now,
        Stat = statName,
        Amount = amount,
        Ok = success,
        Accepted = accepted,
        Result = result,
        PointsBefore = pointsBefore,
        PointsAfter = pointsValue.Value,
        LevelBefore = levelBefore,
        LevelAfter = levelAfter,
    }
    state.lastStatError = accepted and nil
        or success and "stat-allocation-rejected"
        or tostring(result)
    return accepted
end
end

local IsNetworkOwner
do
IsNetworkOwner = {}

function IsNetworkOwner.run(_, part)
    if typeof(part) ~= "Instance" or not part:IsA("BasePart") or part.Anchored then
        return false
    end
    if type(isnetworkowner) == "function" then
        local success, result = pcall(isnetworkowner, part)
        if success then
            return result == true
        end
    end
    return part.ReceiveAge == 0
end
end

local RefreshSimulationRadius
do
RefreshSimulationRadius = {}

function RefreshSimulationRadius.run(context)
    local state = context.State
    local now = os.clock()
    if now < (state.nextSimulationRadiusRefreshAt or 0) then
        return
    end
    state.nextSimulationRadiusRefreshAt = now + 1

    if type(setsimulationradius) == "function" then
        pcall(setsimulationradius, 9e9, math.huge)
    end
    if type(setscriptable) == "function" then
        pcall(setscriptable, context.LocalPlayer, "SimulationRadius", true)
    end

    local setProperty = context.SetHiddenProperty or sethiddenproperty
    if type(setProperty) == "function" then
        pcall(setProperty, context.LocalPlayer, "MaximumSimulationRadius", math.huge)
        pcall(setProperty, context.LocalPlayer, "SimulationRadius", 9e9)
    end
end
end

local SelectFarmWaitCFrame
do
SelectFarmWaitCFrame = {}

local LAST_TARGET_GRACE = 15
local ROTATE_AFTER = 3
local ROTATE_EVERY = 5
local SPAWN_CLUSTER_RADIUS = 350

local function spawnCandidates(context, mobName, referencePosition)
    local normalizedName = context.Functions.NormalizeEnemyName(mobName)
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
    local spawnFolders = {
        replicatedStorage:FindFirstChild("FortBuilderReplicatedSpawnPositionsFolder"),
        worldOrigin and worldOrigin:FindFirstChild("EnemySpawns"),
    }
    local candidates = {}
    local seen = {}

    for _, folder in spawnFolders do
        for _, spawn in folder and folder:GetChildren() or {} do
            if context.Functions.NormalizeEnemyName(spawn.Name) == normalizedName then
                local success, spawnCFrame = pcall(function()
                    return spawn:IsA("BasePart") and spawn.CFrame or spawn:GetPivot()
                end)
                local key = success and tostring(spawnCFrame) or nil
                if key and typeof(spawnCFrame) == "CFrame" and not seen[key] then
                    seen[key] = true
                    candidates[#candidates + 1] = {
                        cframe = CFrame.new(spawnCFrame.Position + Vector3.new(0, 30, 0)),
                        distance = referencePosition
                            and (spawnCFrame.Position - referencePosition).Magnitude or 0,
                    }
                end
            end
        end
    end

    table.sort(candidates, function(left, right)
        return left.distance < right.distance
    end)
    return candidates
end

local function clusterCandidates(candidates, referencePosition)
    local clusters = {}
    local assigned = {}

    for index in candidates do
        if not assigned[index] then
            local queue = { index }
            local members = {}
            assigned[index] = true

            while #queue > 0 do
                local candidateIndex = table.remove(queue)
                local candidate = candidates[candidateIndex]
                members[#members + 1] = candidate

                for otherIndex, other in candidates do
                    if not assigned[otherIndex]
                        and (candidate.cframe.Position - other.cframe.Position).Magnitude
                            <= SPAWN_CLUSTER_RADIUS
                    then
                        assigned[otherIndex] = true
                        queue[#queue + 1] = otherIndex
                    end
                end
            end

            local center = Vector3.zero
            for _, member in members do
                center += member.cframe.Position
            end
            center /= #members

            local representative = members[1]
            local representativeDistance = math.huge
            for _, member in members do
                local distance = (member.cframe.Position - center).Magnitude
                if distance < representativeDistance then
                    representative = member
                    representativeDistance = distance
                end
            end

            clusters[#clusters + 1] = {
                cframe = representative.cframe,
                center = center,
                count = #members,
                distance = referencePosition
                    and (center - referencePosition).Magnitude or 0,
            }
        end
    end

    table.sort(clusters, function(left, right)
        return left.distance < right.distance
    end)
    return clusters
end

function SelectFarmWaitCFrame.run(context, taskName, mobName, fallback)
    local state = context.State
    local anchor = state.farmAnchors and state.farmAnchors[mobName]
    if anchor and anchor.task == taskName and os.clock() - anchor.at <= LAST_TARGET_GRACE
        and typeof(anchor.cframe) == "CFrame"
    then
        state.lastFarmWaitSource = "last-target"
        return anchor.cframe
    end

    local missing = state.missingMobState
    local missingSeconds = missing and missing.task == taskName and missing.mob == mobName
        and math.max(0, os.clock() - missing.since) or 0
    if missingSeconds >= ROTATE_AFTER then
        local character = context.LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local referencePosition = typeof(fallback) == "CFrame" and fallback.Position
            or root and root.Position
        local candidates = spawnCandidates(context, mobName, referencePosition)
        local clusters = clusterCandidates(candidates, referencePosition)
        if #clusters > 1 then
            local index = math.floor((missingSeconds - ROTATE_AFTER) / ROTATE_EVERY) % #clusters + 1
            state.lastFarmWaitSource = "rotating-enemy-cluster"
            state.lastFarmWaitSpawnIndex = index
            state.lastFarmWaitSpawnCount = #candidates
            state.lastFarmWaitClusterCount = #clusters
            state.lastFarmWaitClusterSize = clusters[index].count
            return clusters[index].cframe
        end
    end

    state.lastFarmWaitClusterCount = nil
    state.lastFarmWaitClusterSize = nil
    state.lastFarmWaitSource = "enemy-spawn"
    return context.Functions.ResolveMobCFrame(mobName, fallback)
end
end

local IsActiveEnemyModel
do
IsActiveEnemyModel = {}

function IsActiveEnemyModel.run(_, enemy, expectedName)
    local enemies = workspace:FindFirstChild("Enemies")
    if typeof(enemy) ~= "Instance"
        or not enemies
        or enemy.Parent ~= enemies
        or expectedName and enemy.Name ~= expectedName
    then
        return false
    end

    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    local root = enemy:FindFirstChild("HumanoidRootPart")
    if humanoid and root and humanoid.Health > 0
        and humanoid:GetState() ~= Enum.HumanoidStateType.Dead
    then
        return true, humanoid, root
    end
    return false
end
end

local ObserveFarmTarget
do
ObserveFarmTarget = {}

function ObserveFarmTarget.run(context, taskName, mobName, found)
    local state = context.State
    local now = os.clock()
    local missing = state.missingMobState

    if missing and missing.task == taskName and missing.mob == mobName then
        if found then
            missing.since = now
        end
    else
        missing = { task = taskName, mob = mobName, since = now }
        state.missingMobState = missing
    end

    state.currentFarmMobName = mobName
    return now - missing.since
end
end

local RecordFarmRecovery
do
RecordFarmRecovery = {}

function RecordFarmRecovery.run(context, action, actionError)
    local watchdog = context.FarmWatchdogState
    watchdog.LastAction = tostring(action or "none")
    watchdog.LastActionAt = os.clock()
    watchdog.LastError = actionError and tostring(actionError) or "none"
    if action == "hop" then
        watchdog.Hops += 1
    end
end
end

local ResetFarmWatchdog
do
ResetFarmWatchdog = {}

function ResetFarmWatchdog.run(context, taskName, mode)
    local watchdog = context.FarmWatchdogState
    local now = os.clock()
    watchdog.Mode = mode or "active"
    watchdog.Task = taskName
    watchdog.Status = context.State.status or ""
    watchdog.Target = nil
    watchdog.QuestText = ""
    watchdog.QuestCurrent = nil
    watchdog.QuestTotal = nil
    watchdog.TargetCount = 0
    watchdog.TargetHealth = 0
    watchdog.LastProgressAt = now
    watchdog.LastProgressKind = mode or "task-changed"
    watchdog.MissingSince = 0
    watchdog.MissingSeconds = 0
    watchdog.StalledSeconds = 0
    watchdog.ObservedIssue = "none"
    watchdog.LastCheckAt = now
    watchdog.nextPollAt = now
    return watchdog
end
end

local UpdateFarmWatchdog
do
UpdateFarmWatchdog = {}

function UpdateFarmWatchdog.run(context, taskName, mode, targetName)
    local watchdog = context.FarmWatchdogState
    local now = os.clock()
    if watchdog.Enabled == false then
        return watchdog
    end
    if watchdog.Task ~= taskName then
        context.Functions.ResetFarmWatchdog(taskName, mode)
    end
    if now < (watchdog.nextPollAt or 0)
        and watchdog.Mode == mode and watchdog.Target == targetName
    then
        return watchdog
    end

    local config = watchdog.Config or {}
    watchdog.nextPollAt = now + (config.PollSeconds or 2)
    watchdog.LastCheckAt = now
    watchdog.Status = context.State.status or ""

    local visible, questText = context.ReadQuest()
    local current, total
    if visible and type(questText) == "string" then
        local currentText, totalText = questText:match("%((%d+)%s*/%s*(%d+)%)")
        if not currentText then
            currentText, totalText = questText:match("(%d+)%s*/%s*(%d+)")
        end
        current, total = tonumber(currentText), tonumber(totalText)
    else
        questText = ""
    end

    local targetCount, targetHealth = 0, 0
    local enemies = workspace:FindFirstChild("Enemies")
    for _, enemy in enemies and enemies:GetChildren() or {} do
        if enemy.Name == targetName then
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            local root = enemy:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and root then
                targetCount += 1
                targetHealth += humanoid.Health
            end
        end
    end

    local progressKind
    if watchdog.Target ~= targetName or watchdog.QuestTotal ~= total then
        progressKind = "quest-target-changed"
    elseif current and watchdog.QuestCurrent and watchdog.QuestCurrent < current then
        progressKind = "quest-progress"
    elseif current and watchdog.QuestCurrent and current < watchdog.QuestCurrent then
        progressKind = "quest-restarted"
    elseif targetCount > 0 and watchdog.TargetCount == 0 then
        progressKind = "target-appeared"
    elseif targetCount < watchdog.TargetCount then
        progressKind = "target-count-decreased"
    elseif targetHealth + 0.5 < watchdog.TargetHealth then
        progressKind = "target-health-decreased"
    elseif watchdog.Mode == "waiting" and mode == "attacking" then
        progressKind = "attack-started"
    end

    if progressKind then
        watchdog.LastProgressAt = now
        watchdog.LastProgressKind = progressKind
        if targetCount > 0 then
            watchdog.MissingSince = 0
        end
    end

    watchdog.Mode = mode
    watchdog.Task = taskName
    watchdog.Target = targetName
    watchdog.QuestText = questText
    watchdog.QuestCurrent = current
    watchdog.QuestTotal = total
    watchdog.TargetCount = targetCount
    watchdog.TargetHealth = targetHealth
    watchdog.StalledSeconds = math.max(0, now - watchdog.LastProgressAt)
    watchdog.ObservedIssue = "none"

    if mode == "waiting" and targetCount == 0 then
        if watchdog.MissingSince == 0 then
            watchdog.MissingSince = now
        end
        watchdog.MissingSeconds = math.max(0, now - watchdog.MissingSince)
        watchdog.ObservedIssue = "quest-target-missing"
        return watchdog
    end

    watchdog.MissingSince = 0
    watchdog.MissingSeconds = 0
    if mode == "attacking" and watchdog.StalledSeconds >= 30 then
        watchdog.ObservedIssue = "attacking-without-progress"
    elseif mode == "waiting" and targetCount > 0 and watchdog.StalledSeconds >= 30 then
        watchdog.ObservedIssue = "waiting-while-target-exists"
    end
    return watchdog
end
end

local IsTaskCurrent
do
IsTaskCurrent = {}

function IsTaskCurrent.run(context, taskName)
    return not context.State.stopped
        and not context.State.paused
        and context.TaskQueue:top() == taskName
end
end

local ReadTaskProgress
do
ReadTaskProgress = {}

function ReadTaskProgress.run(context, taskName, cacheKey, cacheSeconds, ...)
    local functions = context.Functions
    local state = context.State
    if not functions.IsTaskCurrent(taskName) then
        return nil
    end

    state.taskProgressCache = state.taskProgressCache or {}
    local cached = state.taskProgressCache[cacheKey]
    local now = os.clock()
    if cached and now - cached.checkedAt < cacheSeconds then
        return cached.value
    end

    local value = context.CommandRemote:InvokeServer(...)
    state.taskProgressCache[cacheKey] = { value = value, checkedAt = now }
    if value ~= nil then
        state[cacheKey] = value
    end
    return functions.IsTaskCurrent(taskName) and value or nil
end
end

local TaskRequest
do
TaskRequest = {}

function TaskRequest.run(context, taskName, requestKey, cooldown, ...)
    if not context.Functions.IsTaskCurrent(taskName) then
        return false
    end

    local state = context.State
    state.taskRequestTimes = state.taskRequestTimes or {}
    local now = os.clock()
    local key = taskName .. "/" .. requestKey
    local lastRequestAt = state.taskRequestTimes[key]
    if lastRequestAt and now - lastRequestAt < cooldown then
        return false
    end

    state.taskRequestTimes[key] = now
    return true, context.CommandRemote:InvokeServer(...)
end
end

local ProgressionProbe
do
ProgressionProbe = {}
local POLL_SECONDS = 30

local function requestsForSea(context)
    if context.IsSea(1) then
        return {
            { key = "proQuestProgress", args = { "ProQuestProgress" } },
        }
    end
    if context.IsSea(2) then
        return {
            { key = "secondSeaProgress", args = { "DressrosaQuestProgress" } },
            { key = "alchemistProgress", args = { "Alchemist", "1" } },
            { key = "raceEvolutionProgress", args = { "Wenlocktoad", "1" } },
        }
    end
    if context.IsSea(3) then
        return {
            { key = "zQuestProgress", args = { "ZQuestProgress" } },
            { key = "eliteProgress", args = { "EliteHunter", "Progress" } },
        }
    end
    return {}
end

function ProgressionProbe.run(context)
    local state = context.State
    local now = os.clock()
    if now < (state.nextProgressProbeAt or 0) then
        return false
    end

    local requests = requestsForSea(context)
    if #requests == 0 then
        state.nextProgressProbeAt = now + POLL_SECONDS
        return false
    end

    local index = (state.progressProbeIndex or 0) % #requests + 1
    state.progressProbeIndex = index
    state.nextProgressProbeAt = now + POLL_SECONDS / #requests
    local request = requests[index]
    local _, started = BoundedCall.start(context, "progression", 8, function()
        return context.CommandRemote:InvokeServer(table.unpack(request.args))
    end, function(success, result)
        state.lastProgressProbe = {
            key = request.key,
            success = success,
            result = result,
            at = os.clock(),
        }
        if success and result ~= nil then
            state[request.key] = result
            state[request.key .. "At"] = os.clock()
            state.lastProgressProbeError = nil
        elseif not success then
            state.lastProgressProbeError = tostring(result)
        end
        return success
    end)
    return started
end
end

local RefreshInventory
do
RefreshInventory = {}
local POLL_SECONDS = 3
local MELEE_ALIASES = {
    ["Dark Step"] = "Black Leg",
    ["Electric"] = "Electro",
    ["Water Kung Fu"] = "Fishman Karate",
    ["Dragon Breath"] = "Dragon Claw",
}

local function positiveCount(item)
    return tonumber(item.Count or item.count or item.Amount or item.amount
        or item.Value or item.value) or 1
end

local function itemName(item)
    return item.StorageKey or item.storageKey or item.Name or item.name
        or item.ItemId or item.itemId
end

local function itemType(item)
    local value = item.Type or item.type or item.IdType or item.idType or "Other"
    if value == "Sword" or value == "Gun" or value == "Melee"
        or value == "Fighting Style"
    then
        return "Moveset"
    end
    return value
end

local function mastery(item)
    return tonumber(item.Mastery or item.mastery or item.Level or item.level) or 0
end

local function replicationInventory()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local success, result = pcall(function()
        local serviceModule = replicatedStorage:FindFirstChild("ItemReplicationService")
        if not serviceModule then return nil end
        local keysModule = serviceModule:FindFirstChild("KEYS")
        local configModule = replicatedStorage:FindFirstChild("ItemConfig")
        if not keysModule or not configModule then return nil end
        local service = require(serviceModule)
        local keys = require(keysModule)
        local itemConfig = require(configModule)
        if service.IsInitialized ~= true then return nil end

        local masteryByItem = {}
        for _, item in service:GetItems(keys.MASTERY) or {} do
            local key = tostring(item.ItemId) .. ":" .. tostring(item.NetworkedUID or "")
            masteryByItem[key] = tonumber(item.Value) or 0
        end

        local items = {}
        for _, item in service:GetItems(keys.QUANTITY) or {} do
            local count = tonumber(item.Value) or 0
            if count > 0 then
                local config = itemConfig.match(item.ItemId):unwrap()
                local index = config.Index or {}
                local display = config.Display or {}
                local label = tostring(index.DebugLabel or "")
                local parsedName, parsedCategory = label:match("^(.-) %[(.-)%-%d+%]$")
                local name = display.Name or parsedName or index.StorageKey
                local category = display.Category or parsedCategory
                if category == "Blox Fruit" then
                    category = "PhysicalMoveset"
                end
                if name and category then
                    local key = tostring(item.ItemId) .. ":" .. tostring(item.NetworkedUID or "")
                    items[#items + 1] = {
                        StorageKey = index.StorageKey or name,
                        Name = name,
                        Type = category,
                        Count = count,
                        Mastery = masteryByItem[key] or 0,
                        ItemId = item.ItemId,
                        NetworkedUID = item.NetworkedUID,
                        Value = FruitCollectionPolicy.moneyValue(config),
                    }
                end
            end
        end
        return items
    end)
    return success and type(result) == "table" and result or nil
end

local function indexInventory(context, items)
    local indexed = {}
    for _, item in items do
        if type(item) == "table" and positiveCount(item) > 0 then
            local name = itemName(item)
            local category = itemType(item)
            if type(name) == "string" and name ~= "" then
                item.Count = positiveCount(item)
                item.Mastery = mastery(item)
                indexed[category] = indexed[category] or {}
                indexed[category][name] = item
                local displayName = item.Name or item.name
                if type(displayName) == "string" and displayName ~= "" then
                    indexed[category][displayName] = item
                end
            end
        end
    end
    context.Inventory = indexed
end

local function syncMelee(context)
    context.MeleeProgress = context.MeleeProgress or {}
    context.MeleeInventory = context.MeleeInventory or {}
    context.MeleeInventory.Melee = context.MeleeInventory.Melee or {}

    local movesets = context.Inventory.Moveset or {}
    for key, item in movesets do
        if type(key) == "string" and type(item) == "table" then
            local displayName = item.Name or item.name or key
            local canonical = MELEE_ALIASES[displayName] or MELEE_ALIASES[key]
                or displayName
            local level = mastery(item)
            context.MeleeProgress[canonical] = context.MeleeProgress[canonical] or {}
            context.MeleeProgress[canonical].Level = math.max(
                tonumber(context.MeleeProgress[canonical].Level) or 0,
                level
            )
            context.MeleeProgress[canonical].Done = true
            context.MeleeInventory.Melee[canonical] = {
                Bought = true,
                Level = level,
            }
        end
    end

    local character = context.LocalPlayer.Character
    local equipped = character and character:FindFirstChildOfClass("Tool")
    if equipped then
        local weaponType = equipped:GetAttribute("WeaponType") or equipped.ToolTip
        if weaponType == "Melee" then
            local canonical = MELEE_ALIASES[equipped.Name] or equipped.Name
            local levelValue = equipped:FindFirstChild("Level")
            local level = levelValue and tonumber(levelValue.Value) or 0
            context.MeleeProgress[canonical] = context.MeleeProgress[canonical] or {}
            context.MeleeProgress[canonical].Level = math.max(
                tonumber(context.MeleeProgress[canonical].Level) or 0,
                level
            )
            context.MeleeProgress[canonical].Done = true
            context.MeleeInventory.Melee[canonical] = {
                Bought = true,
                Level = level,
            }
        end
    end
end

function RefreshInventory.run(context, force)
    local state = context.State
    local now = os.clock()
    local pending = state.boundedCalls and state.boundedCalls.inventory
    if pending then
        if not force then return false end
        local generation = state.runtimeGeneration
        if not BoundedCall.await(pending) or state.stopped
            or state.runtimeGeneration ~= generation
        then return false end
        local followup = state.boundedCalls and state.boundedCalls.inventory
        if followup then return BoundedCall.await(followup) end
        if (state.inventoryRefreshSequence or 0) > pending.sequence then
            return state.lastInventoryRefreshError == nil
        end
        now = os.clock()
    end
    if not force and now < (state.nextInventoryRefreshAt or 0) then
        return false
    end
    state.nextInventoryRefreshAt = now + POLL_SECONDS

    local source = "replication"
    local slot = BoundedCall.start(context, "inventory", 8, function()
        local result = replicationInventory()
        if type(result) ~= "table" then
            source = "remote-fallback"
            return context.CommandRemote:InvokeServer("getInventory")
        end
        return result
    end, function(success, result, completed)
        state.inventoryRefreshSequence = completed.sequence
        state.lastInventoryRefreshAt = os.clock()
        state.lastInventoryRefreshSource = source
        if not success or type(result) ~= "table" then
            state.lastInventoryRefreshError = success and "invalid-result" or tostring(result)
            state.nextInventoryRefreshAt = os.clock() + 10
            return false
        end
        indexInventory(context, result)
        syncMelee(context)
        state.lastInventoryRefreshError = nil
        state.inventoryReady = true
        state.inventoryItemCount = #result
        return true
    end)
    if force then return BoundedCall.await(slot) end
    return slot ~= nil and slot.success == true
end

function RefreshInventory.owns(context, category, name)
    if category == "Sword" or category == "Gun" or category == "Melee" then
        category = "Moveset"
    end
    local item = context.Inventory[category] and context.Inventory[category][name]
    return type(item) == "table" and positiveCount(item) > 0 or item == true
end

function RefreshInventory.carries(context, name)
    local player = context.LocalPlayer
    return player.Character and player.Character:FindFirstChild(name)
        or player:FindFirstChildOfClass("Backpack")
            and player.Backpack:FindFirstChild(name)
        or false
end

function RefreshInventory.findPhysicalMoveset(context, preferred)
    local inventory = context.Inventory.PhysicalMoveset or {}
    if preferred and inventory[preferred] then
        return inventory[preferred]
    end
    for _, item in inventory do
        if type(item) == "table" and positiveCount(item) > 0 then
            return item
        end
    end
    return nil
end
end

local AutoAccessory
do
AutoAccessory = {}
local POLL_SECONDS = 5
local REQUEST_TIMEOUT = 8
local SAME_ITEM_RETRY = 30
local MAX_ITEMS = 2048

local function available(context, character)
    local state = context.State
    local environment = context.Environment or {}
    local configs = environment.Configs or {}
    if state.stopped or state.paused or state.inventoryStartupPending
        or configs["Auto Equip Accessory"] == false or environment.Stop or _G.Stop
        or state.resetting or state.hopBusy or state.fastTravelRequest
        or state.cursedShipTransitionActive or state.fruitStoreInFlight
        or os.clock() < (state.raidChipPurchasePendingUntil or 0)
        or state.worldTravelIssuedAt and os.clock() - state.worldTravelIssuedAt < 15
    then
        return false
    end
    if not character or context.LocalPlayer.Character ~= character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid ~= nil and humanoid.Health > 0
end

local function dependencies(context, current)
    local storage = game:GetService("ReplicatedStorage")
    local serviceModule = storage:FindFirstChild("ItemReplicationService")
    local keysModule = serviceModule and serviceModule:FindFirstChild("KEYS")
    local configModule = storage:FindFirstChild("ItemConfig")
    local modules = storage:FindFirstChild("Modules")
    local assets = modules and modules:FindFirstChild("Asset")
    local data = assets and assets:FindFirstChild("ItemData")
    local statsModule = data and data:FindFirstChild("ItemStats")
    if not serviceModule or not keysModule or not configModule or not statsModule then
        return nil
    end
    local handles = { serviceModule, keysModule, configModule, statsModule }
    local cached = context.State.accessoryDependencies
    if cached then
        local same = true
        for i, handle in handles do
            if cached.handles[i] ~= handle then same = false; break end
        end
        if same then return cached.values end
    end
    local values = {}
    for i, handle in handles do
        if not current() then return nil end
        values[i] = require(handle)
    end
    if not current() then return nil end
    context.State.accessoryDependencies = { handles = handles, values = values }
    return values
end

local function validId(id)
    return type(id) == "string" and id ~= ""
        or type(id) == "number" and id == id and id > -math.huge and id < math.huge
end

local function collect(values, current)
    local service, keys, config, stats = table.unpack(values)
    if type(service) ~= "table" or service.IsInitialized ~= true
        or type(keys) ~= "table" or keys.QUANTITY == nil
        or keys.IS_EQUIPPED == nil or keys.UPGRADE_COUNT == nil
        or type(config) ~= "table" or type(stats) ~= "table"
    then
        return nil, "replication-unavailable"
    end
    local items = service:GetItems(keys.QUANTITY)
    if type(items) ~= "table" then return nil, "inventory-unavailable" end
    local candidates, count, invalid = {}, 0, 0
    for _, item in items do
        count += 1
        if count > MAX_ITEMS then return nil, "inventory-scan-limit" end
        if not current() then return nil, "deferred" end
        local ok, candidate = pcall(function()
            if type(item) ~= "table" then return nil end
            local quantity = tonumber(item.Value) or 0
            if quantity ~= quantity or quantity <= 0 or quantity == math.huge
                or not validId(item.ItemId)
                or item.NetworkedUID ~= nil and not validId(item.NetworkedUID)
            then return nil end
            local matched = config.match(item.ItemId):unwrap()
            if matched.Display.Category ~= "Accessory" then return nil end
            local name = matched.Index.StorageKey
            if type(name) ~= "string" or name == "" then return nil end
            local itemStats = stats[name]
            if type(itemStats) ~= "table" or not itemStats.Accessory then return nil end
            local upgrade = tonumber(service:ReadItem(keys.UPGRADE_COUNT, item.ItemId, item.NetworkedUID)) or 0
            local tier = itemStats[upgrade] or itemStats[0]
            if type(tier) ~= "table" or type(tier[2]) ~= "table" then return nil end
            local equipped = service:ReadItem(keys.IS_EQUIPPED, item.ItemId, item.NetworkedUID)
            if equipped ~= nil and type(equipped) ~= "boolean" then return nil end
            return {
                Name = name, ItemId = item.ItemId, NetworkedUID = item.NetworkedUID,
                Score = AccessoryPolicy.score(tier[2]), Equipped = equipped == true,
            }
        end)
        if ok and candidate then
            candidates[#candidates + 1] = candidate
        elseif not ok then
            invalid += 1
        end
    end
    return AccessoryPolicy.choose(candidates), nil, invalid
end

function AutoAccessory.run(context)
    local state = context.State
    local now = os.clock()
    if now < (state.nextAccessoryCheckAt or 0)
        or state.boundedCalls and state.boundedCalls.accessory
    then return false end
    local character = context.LocalPlayer.Character
    if not available(context, character) then return false end
    state.nextAccessoryCheckAt = now + POLL_SECONDS
    local generation = state.runtimeGeneration
    local slot, started = BoundedCall.start(context, "accessory", REQUEST_TIMEOUT, function()
        local ownedSlot = state.boundedCalls.accessory
        local function current()
            return state.boundedCalls and state.boundedCalls.accessory == ownedSlot
                and not ownedSlot.done and os.clock() < ownedSlot.deadline
                and state.runtimeGeneration == generation and available(context, character)
        end
        if not current() then return { status = "deferred" } end
        local values = dependencies(context, current)
        if not values then return { status = "dependencies-unavailable" } end
        local best, reason, invalid = collect(values, current)
        if not current() then return { status = "deferred" } end
        if not best then return { status = reason or "no-accessory", invalid = invalid } end
        if best.Equipped then
            state.accessoryLastRequestedId = nil
            return { status = "equipped", name = best.Name, invalid = invalid }
        end
        local id = best.NetworkedUID or best.ItemId
        if not validId(id) then return { status = "invalid-item-id" } end
        if id == state.accessoryLastRequestedId and os.clock() < (state.accessoryRetryAt or 0) then
            return { status = "awaiting-replication", name = best.Name, invalid = invalid }
        end
        if not current() then return { status = "deferred" } end
        state.accessoryLastRequestedId = id
        state.accessoryRetryAt = os.clock() + SAME_ITEM_RETRY
        state.lastAccessoryRequestAt = os.clock()
        local result = context.CommandRemote:InvokeServer("LoadItem", id)
        return { status = result == false and "load-rejected" or "equip-requested", name = best.Name, invalid = invalid }
    end, function(success, result)
        state.lastAccessoryCheckAt = os.clock()
        if not success or type(result) ~= "table" then
            state.lastAccessoryError = success and "invalid-result" or tostring(result)
            state.nextAccessoryCheckAt = os.clock() + 10
            return false
        end
        state.lastAccessoryError = nil
        state.accessoryStatus = result.status
        state.accessoryCandidate = result.name
        state.accessoryInvalidItems = result.invalid or 0
        if result.status == "dependencies-unavailable" or result.status == "replication-unavailable"
            or result.status == "inventory-unavailable" or result.status == "inventory-scan-limit"
        then state.nextAccessoryCheckAt = os.clock() + 10 end
        return true
    end)
    return slot ~= nil and started == true
end
end

local ProgressionPlanner
do
ProgressionPlanner = {}

local function materialCount(context, name)
    local material = context.Inventory.Material and context.Inventory.Material[name]
    return material and tonumber(material.Count or material.Value) or 0
end

function ProgressionPlanner.run(context)
    local state = context.State
    local level = context.Level.Value
    local phase = "level-farm"
    local reason = "level-progress"

    if level >= 1500 and context.IsSea(2) then
        phase = "transition-third-sea"
        reason = "third-sea-unlocked"
    elseif level >= 700 and context.IsSea(1) then
        phase = "transition-second-sea"
        reason = "second-sea-unlocked"
    elseif state.meleeMissingMaterial then
        phase = "godhuman-material"
        reason = state.meleeMissingMaterial
    elseif state.needFragments then
        phase = "fragment-farm"
        reason = "required-purchase"
    elseif state.meleeTarget and state.meleeTarget ~= "Godhuman"
        and (tonumber(state.meleeCurrentMastery) or 0) < (tonumber(state.meleeTargetMastery) or 400)
    then
        phase = "melee-mastery"
        reason = state.meleeTarget
    elseif state.meleeTarget == "Godhuman" and not state.godhumanOwned then
        phase = "godhuman-purchase"
        for _, requirement in {
            { "Fish Tail", 20 },
            { "Dragon Scale", 10 },
            { "Mystic Droplet", 10 },
            { "Magma Ore", 20 },
        } do
            if materialCount(context, requirement[1]) < requirement[2] then
                phase = "godhuman-material"
                reason = requirement[1]
                break
            end
        end
    end

    state.progressionPhase = phase
    state.progressionReason = reason
    state.progressionPlanAt = os.clock()
    return phase
end
end

local RejoinPersistence
do
RejoinPersistence = {}

function RejoinPersistence.run(context)
    local state = context.State
    if state.rejoinPersistenceCleared then
        return false
    end
    local environment = context.Environment
    local clearQueue = environment.clear_teleport_queue
        or environment.clearteleportqueue
        or environment.clearqueueonteleport
    if type(clearQueue) == "function" then
        local success, result = pcall(clearQueue)
        state.rejoinPersistenceError = success and nil or tostring(result)
    else
        state.rejoinPersistenceError = "clear-teleport-queue-unavailable"
    end
    state.rejoinPersistenceRegistered = false
    state.rejoinPersistenceCleared = true
    return false
end
end

local HopServer
do
HopServer = {}

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local function normalizedMaximum(value)
    local maximum = tonumber(value)
    return maximum and maximum > 0 and maximum or nil
end

local function ensureFailureRecovery(context)
    local state = context.State
    if state.teleportFailureConnection then
        return
    end

    state.teleportFailureConnection = TeleportService.TeleportInitFailed:Connect(function(
        player,
        result,
        message,
        placeId,
        teleportOptions
    )
        if player ~= context.LocalPlayer then
            return
        end

        state.hopBusy = false
        state.hopRetryAt = 0
        state.lastHopError = string.format("%s: %s", tostring(result), tostring(message))
        state.lastHopFailure = {
            job = teleportOptions and teleportOptions.ServerInstanceId,
            place = placeId,
            at = os.time(),
        }
        state.status = "Server hop failed | Trying another"

        task.delay(1.5, function()
            if not state.stopped then
                HopServer.run(context, state.lastHopMaximumPlayers, state.lastHopReason)
            end
        end)
    end)
end

local function publicServerCandidates(maximumPlayers)
    local url = string.format(
        "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true",
        tostring(game.PlaceId)
    )
    local body = game:HttpGet(url)
    local response = HttpService:JSONDecode(body)
    local candidates = {}

    for _, server in ipairs(type(response.data) == "table" and response.data or {}) do
        local playing = tonumber(server.playing)
        local capacity = tonumber(server.maxPlayers)
        if type(server.id) == "string" and server.id ~= game.JobId
            and playing and capacity
            and playing > 0
            and playing < capacity
            and (not maximumPlayers or playing < maximumPlayers)
        then
            candidates[#candidates + 1] = {
                id = server.id,
                count = playing,
                source = "public",
            }
        end
    end
    return candidates
end

local function browserServerCandidates(serverBrowser, state, maximumPlayers)
    local candidates = {}
    if not serverBrowser or not serverBrowser:IsA("RemoteFunction") then
        return candidates
    end

    local now = os.time()
    local servers = state.cachedServerBrowser
    if not servers or now - (state.cachedServerBrowserAt or 0) >= 60 then
        servers = nil
        for page = 1, 100 do
            local result = serverBrowser:InvokeServer(page)
            if type(result) == "table" and next(result) ~= nil then
                servers = result
                state.cachedServerBrowser = result
                state.cachedServerBrowserAt = now
                break
            end
        end
    end

    for jobId, details in type(servers) == "table" and servers or {} do
        local count = type(details) == "table" and tonumber(details.Count)
        if type(jobId) == "string" and jobId ~= game.JobId and count
            and (not maximumPlayers or count < maximumPlayers)
        then
            candidates[#candidates + 1] = {
                id = jobId,
                count = count,
                source = "browser",
            }
        end
    end
    return candidates
end

function HopServer.run(context, maximumPlayers, reason)
    local state = context.State
    maximumPlayers = normalizedMaximum(maximumPlayers)
    reason = type(reason) == "string" and reason or nil
    ensureFailureRecovery(context)

    local now = os.clock()
    if state.hopBusy or now < (state.hopRetryAt or 0) then
        return false
    end

    local serverBrowser = game:GetService("ReplicatedStorage"):FindFirstChild("__ServerBrowser")
    state.hopBusy = true
    state.hopRetryAt = now + 5
    state.lastHopMaximumPlayers = maximumPlayers
    state.lastHopReason = reason

    local success, result = xpcall(function()
        local candidates = {}
        local publicOk, publicResult = pcall(publicServerCandidates, maximumPlayers)
        if publicOk then
            candidates = publicResult
        else
            state.lastPublicServerError = tostring(publicResult)
        end

        if #candidates == 0 then
            local browserOk, browserResult = pcall(
                browserServerCandidates,
                serverBrowser,
                state,
                maximumPlayers
            )
            if browserOk then
                candidates = browserResult
            else
                state.lastServerBrowserError = tostring(browserResult)
            end
        end

        if #candidates == 0 then
            state.lastHopError = "no-low-player-server"
            return false
        end

        local candidate = candidates[math.random(1, #candidates)]
        state.lastHop = {
            job = candidate.id,
            count = candidate.count,
            source = candidate.source,
            maximumPlayers = maximumPlayers,
            reason = reason,
            at = os.time(),
        }
        context.Functions.StopTween()

        if serverBrowser and serverBrowser:IsA("RemoteFunction") then
            serverBrowser:InvokeServer("teleport", candidate.id)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, candidate.id, context.LocalPlayer)
        end
        return true
    end, debug.traceback)

    state.hopBusy = false
    if not success then
        state.lastHopError = tostring(result)
        return false
    end
    return result == true
end
end

local RecoveryWatchdog
do
RecoveryWatchdog = {}

local CHECK_INTERVAL = 0.5
local NEARBY_RADIUS = 50
local NEARBY_MOVE_DISTANCE = 20
local NEARBY_RETRY_SECONDS = 10
local IDLE_MOVE_DISTANCE = 2
local IDLE_HOP_SECONDS = 120

local function configurationEnabled(context, name)
    local configs = context.Environment.Configs or {}
    local configuration = configs.Configuration
    if type(configuration) == "table" and configuration[name] ~= nil then
        return configuration[name] == true
    end
    if configs[name] ~= nil then
        return configs[name] == true
    end
    return true
end

local function validCharacter(context)
    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not humanoid or humanoid.Health <= 0 or not root then
        return nil, nil
    end
    return character, root
end

local function updateMovementProgress(state, character, root, now)
    if state.idleCharacter ~= character then
        state.idleCharacter = character
        state.idleOldPosition = root.Position
        state.lastIdleMovementCheck = now
        state.lastIdlingAt = os.time()
        return
    end
    if now < (state.lastIdleMovementCheck or 0) + 1 then
        return
    end

    state.lastIdleMovementCheck = now
    local oldPosition = state.idleOldPosition
    if oldPosition and (root.Position - oldPosition).Magnitude < IDLE_MOVE_DISTANCE then
        return
    end
    state.idleOldPosition = root.Position
    state.lastIdlingAt = os.time()
    state.lastIdleProgressKind = "movement"
end

local function isClaimingQuest(state)
    if state.questAcquire then
        return true
    end
    local status = tostring(state.status or "")
    return status:find("Claiming Quest", 1, true) ~= nil
        or status:find("Moving to quest giver", 1, true) ~= nil
        or status:find("Waiting quest confirmation", 1, true) ~= nil
end

local function isStationary(root)
    return root.AssemblyLinearVelocity == Vector3.zero
end

local function handleNearbyPlayer(context, character, root, now)
    local state = context.State
    if not configurationEnabled(context, "HopNear")
        or context.TaskQueue:top() ~= "Auto Farm Level"
        or state.factoryActive
        or isClaimingQuest(state)
        or state.isResetting
        or state.resetting
        or state.hopBusy
        or now < (state.nearbyHopRetryAt or 0)
    then
        return false
    end

    local characters = workspace:FindFirstChild("Characters")
    state.nearbyPlayerSamples = state.nearbyPlayerSamples or {}

    for _, other in characters and characters:GetChildren() or {} do
        if other ~= character then
            local humanoid = other:FindFirstChildOfClass("Humanoid")
            local otherRoot = other:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and otherRoot
                and isStationary(otherRoot)
                and (otherRoot.Position - root.Position).Magnitude <= NEARBY_RADIUS
            then
                local sampleKey = other.Name
                local firstPosition = state.nearbyPlayerSamples[sampleKey]
                if firstPosition then
                    if (otherRoot.Position - firstPosition).Magnitude > NEARBY_MOVE_DISTANCE then
                        state.nearbyHopRetryAt = now + NEARBY_RETRY_SECONDS
                        state.nearbyPlayerSamples = {}
                        state.status = "Auto Farm Level | Hopping from nearby player"
                        context.Functions.StopTween()
                        local hopped = context.Functions.HopServer(
                            5,
                            "Nearby player: " .. other.Name
                        )
                        state.lastNearbyPlayerHop = {
                            name = other.Name,
                            success = hopped,
                            at = os.time(),
                        }
                        return hopped == true
                    end
                    state.nearbyPlayerSamples[sampleKey] = nil
                else
                    state.nearbyPlayerSamples[sampleKey] = otherRoot.Position
                end
            end
        end
    end
    return false
end

local function handleIdle(context, now)
    local state = context.State
    if not configurationEnabled(context, "HopWhenIdle")
        or state.factoryActive
        or state.hopBusy
        or now < (state.idleHopRetryAt or 0)
    then
        return false
    end

    state.lastIdlingAt = state.lastIdlingAt or os.time()
    local idleSeconds = os.time() - state.lastIdlingAt
    state.idleSeconds = idleSeconds
    if idleSeconds <= IDLE_HOP_SECONDS then
        return false
    end

    state.idleHopRetryAt = now + NEARBY_RETRY_SECONDS
    state.status = "Recovery | Hopping after 120 seconds idle"
    context.Functions.StopTween()
    local hopped = context.Functions.HopServer(nil, "idle-120-seconds")
    state.lastIdleHop = {
        success = hopped,
        idleSeconds = idleSeconds,
        at = os.time(),
    }
    return hopped == true
end

function RecoveryWatchdog.run(context)
    local state = context.State
    local now = os.clock()
    if now < (state.nextRecoveryWatchdogAt or 0) then
        return false
    end
    state.nextRecoveryWatchdogAt = now + CHECK_INTERVAL

    local character, root = validCharacter(context)
    if state.paused or state.stopped or not character then
        return false
    end

    updateMovementProgress(state, character, root, now)
    if handleNearbyPlayer(context, character, root, now) then
        return true
    end
    return handleIdle(context, now)
end
end

local TaskExecutorLoop
do
TaskExecutorLoop = {}

local FRUIT_GACHA_MIN_PULSE_SECONDS = 5
local FRUIT_STORE_PULSE_SECONDS = 2
local QUEST_NOTIFICATION_RETRY_SECONDS = 10

function TaskExecutorLoop.startFruitStoreBackground(context)
    local state = context.State
    if state.stopped or state.paused or state.inventoryStartupPending or state.fruitStoreBackgroundToken
        or type(context.Functions.StoreCarriedFruits) ~= "function"
    then
        return false
    end
    local token = {}
    state.fruitStoreBackgroundToken = token
    local thread = task.spawn(function()
        while state.fruitStoreBackgroundToken == token and not state.stopped do
            if not state.paused then
                state.lastFruitStorePulseAt = os.clock()
                local ok, failure = pcall(context.Functions.StoreCarriedFruits)
                if state.fruitStoreBackgroundToken ~= token then
                    return
                end
                state.lastFruitStoreBackgroundError = not ok and tostring(failure) or nil
            end
            task.wait(FRUIT_STORE_PULSE_SECONDS)
        end
        if state.fruitStoreBackgroundToken == token then
            state.fruitStoreBackgroundToken = nil
            state.fruitStoreBackgroundThread = nil
        end
    end)
    if state.fruitStoreBackgroundToken == token then
        state.fruitStoreBackgroundThread = thread
    end
    return true
end

function TaskExecutorLoop.ensureQuestNotification(context)
    local state = context.State
    local now = os.clock()
    if state.stopped
        or state.questNotificationBridgeReady == true
        or type(context.AttachQuestNotification) ~= "function"
        or now < (state.nextQuestNotificationAttachAt or 0)
    then
        return false
    end

    state.nextQuestNotificationAttachAt = now + QUEST_NOTIFICATION_RETRY_SECONDS
    local called, attached, failure = pcall(context.AttachQuestNotification)
    if not called then
        state.questNotificationBridgeReady = false
        state.questNotificationBridgeError = tostring(attached)
        return false
    end
    if attached ~= true then
        state.questNotificationBridgeReady = false
        state.questNotificationBridgeError = state.questNotificationBridgeError
            or tostring(failure or "notification-hook-unavailable")
        return false
    end

    state.questNotificationBridgeReady = true
    state.questNotificationBridgeError = nil
    return true
end

function TaskExecutorLoop.startMeleeBackground(context)
    local state = context.State
    local runBackground = context.Functions.RunMeleeBackground
    if state.stopped or state.inventoryStartupPending
        or type(runBackground) ~= "function" or state.meleeBackgroundRunning
    then
        return false
    end

    local token = {}
    state.meleeBackgroundToken = token
    state.meleeBackgroundRunning = true
    state.meleeBackgroundStartedAt = os.clock()
    local thread = task.spawn(function()
        local startedAt = os.clock()
        local success, failure = pcall(runBackground)
        if state.meleeBackgroundToken ~= token then
            return
        end
        state.lastMeleeBackgroundDuration = os.clock() - startedAt
        state.lastMeleeBackgroundCompletedAt = os.clock()
        state.meleeBackgroundThread = nil
        state.meleeBackgroundToken = nil
        state.meleeBackgroundRunning = false
        if not success then
            state.lastMeleeBackgroundError = tostring(failure)
        else
            state.lastMeleeBackgroundError = nil
        end
    end)
    if state.meleeBackgroundToken == token then
        state.meleeBackgroundThread = thread
    end
    return true
end

function TaskExecutorLoop.startFruitGachaBackground(context)
    local state = context.State
    local runGacha = context.Functions.AutoFruitGacha
    local now = os.clock()
    if state.stopped
        or state.inventoryStartupPending
        or type(runGacha) ~= "function"
        or state.fruitGachaBackgroundRunning
        or now < (state.nextFruitGachaAt or 0)
        or now < (state.nextFruitGachaBackgroundPulseAt or 0)
    then
        return false
    end

    local token = {}
    state.fruitGachaBackgroundToken = token
    state.nextFruitGachaBackgroundPulseAt = now + FRUIT_GACHA_MIN_PULSE_SECONDS
    state.fruitGachaBackgroundRunning = true
    state.fruitGachaBackgroundStartedAt = now
    local thread = task.spawn(function()
        local startedAt = os.clock()
        local success, result = pcall(runGacha)
        if state.fruitGachaBackgroundToken ~= token then
            return
        end
        state.lastFruitGachaBackgroundDuration = os.clock() - startedAt
        state.lastFruitGachaBackgroundCompletedAt = os.clock()
        state.lastFruitGachaBackgroundResult = success and tostring(result) or nil
        state.fruitGachaBackgroundThread = nil
        state.fruitGachaBackgroundToken = nil
        state.fruitGachaBackgroundRunning = false
        if success then
            state.lastFruitGachaBackgroundError = nil
        else
            state.lastFruitGachaBackgroundError = tostring(result)
            state.nextFruitGachaBackgroundPulseAt = os.clock() + 60
        end
    end)
    if state.fruitGachaBackgroundToken == token then
        state.fruitGachaBackgroundThread = thread
    end
    return true
end

function TaskExecutorLoop.run(context, currentGeneration)
    local state = context.State
    local functions = context.Functions
    local function isCurrent()
        return not state.stopped
            and (type(currentGeneration) ~= "function" or currentGeneration())
    end
    if not isCurrent() then
        return
    end
    state.taskErrors = {}

    while isCurrent() do
        local taskName
        while true do
            repeat
                if not isCurrent() then
                    return
                end
                task.wait(0.15)
            until not state.paused
            if not isCurrent() then
                return
            end

            if state.inventoryStartupPending then
                local inventorySuccess, inventoryError = pcall(functions.RefreshInventory)
                if not isCurrent() then return end
                if not inventorySuccess then
                    state.lastInventoryRefreshError = tostring(inventoryError)
                end
                if state.inventoryReady == true then
                    state.inventoryStartupPending = false
                    state.inventoryStartupReadyAt = os.clock()
                    TaskExecutorLoop.startFruitStoreBackground(context)
                    if not isCurrent() then return end
                else
                    state.status = "Waiting initial inventory | Retrying read"
                    if type(functions.RecoveryWatchdog) == "function" then
                        local recoverySuccess, recoveryError = pcall(functions.RecoveryWatchdog)
                        if not isCurrent() then return end
                        if not recoverySuccess then
                            state.lastRecoveryError = tostring(recoveryError)
                        end
                    end
                    continue
                end
            end

            taskName = context.TaskQueue:top()
            if taskName ~= state.lastTaskName then
                local fruitHandoff = state.lastTaskName == "Get Fruits" and taskName ~= nil
                functions.StopTween({ preserveAltitude = fruitHandoff })
                if not isCurrent() then return end
                if fruitHandoff then
                    local character = context.LocalPlayer.Character
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    state.lastFruitMovementHandoff = {
                        at = os.clock(),
                        nextTask = taskName,
                        position = root and tostring(root.Position),
                        fruit = state.droppedFruitTarget and state.droppedFruitTarget.Name,
                    }
                end
                if type(functions.StopAttack) == "function" then
                    functions.StopAttack()
                    if not isCurrent() then return end
                end
                table.clear(context.NearbyTargets)
                table.clear(context.NearbyTargetParts)
                state.farmTarget = nil
                state.attackTarget = nil
                state.attackTargetNames = nil
                state.attackTask = nil
                state.missingMobState = nil
                state.lastTaskName = taskName
                if taskName then
                    state.status = taskName
                    functions.ResetFarmWatchdog(taskName, "active")
                else
                    functions.ResetFarmWatchdog(nil, "idle")
                end
                if not isCurrent() then return end
            end

            if not state.travel then
                break
            end
            if os.clock() - state.travel.startedAt > 45 then
                state.lastTravelError = "Travel deadline exceeded"
                state.travelCooldownUntil = os.clock() + 60
                functions.StopTween()
                if not isCurrent() then return end
                break
            end
        end

        local definition = taskName and context.TaskDefinitions[taskName]
        local previousError = taskName and state.taskErrors[taskName]
        TaskExecutorLoop.ensureQuestNotification(context)
        if not isCurrent() then return end
        if type(functions.EnsureTeam) == "function" then
            local teamSuccess, teamError = pcall(functions.EnsureTeam)
            if not isCurrent() then return end
            if not teamSuccess then
                state.lastTeamError = tostring(teamError)
            end
        end
        if type(functions.UpStats) == "function" then
            local statSuccess, statError = pcall(functions.UpStats)
            if not isCurrent() then return end
            if not statSuccess then
                state.lastStatError = tostring(statError)
            end
        end
        if type(functions.RejoinPersistence) == "function" then
            functions.RejoinPersistence()
            if not isCurrent() then return end
        end
        if type(functions.ProgressionProbe) == "function" then
            local probeSuccess, probeError = pcall(functions.ProgressionProbe)
            if not isCurrent() then return end
            if not probeSuccess then
                state.lastProgressProbeError = tostring(probeError)
            end
        end
        if type(functions.RefreshInventory) == "function" then
            local inventorySuccess, inventoryError = pcall(functions.RefreshInventory)
            if not isCurrent() then return end
            if not inventorySuccess then
                state.lastInventoryRefreshError = tostring(inventoryError)
            end
        end
        TaskExecutorLoop.startMeleeBackground(context)
        if not isCurrent() then return end
        TaskExecutorLoop.startFruitGachaBackground(context)
        if not isCurrent() then return end
        if type(functions.ProgressionPlanner) == "function" then
            local planSuccess, planError = pcall(functions.ProgressionPlanner)
            if not isCurrent() then return end
            if not planSuccess then
                state.lastProgressionPlanError = tostring(planError)
            end
        end
        if type(functions.RecoveryWatchdog) == "function" then
            local recoverySuccess, recoveryError = pcall(functions.RecoveryWatchdog)
            if not isCurrent() then return end
            if not recoverySuccess then
                state.lastRecoveryError = tostring(recoveryError)
            end
        end
        if definition
            and context.TaskQueue:top() == taskName
            and (not previousError or os.clock() >= previousError.retryAt)
        then
            local success, failure = xpcall(function()
                definition.func(table.unpack(definition.args or {}))
            end, debug.traceback)
            if not isCurrent() then return end

            if success then
                state.taskErrors[taskName] = nil
            else
                functions.StopTween()
                if not isCurrent() then return end
                local failureCount = previousError and previousError.count + 1 or 1
                state.taskErrors[taskName] = {
                    count = failureCount,
                    message = tostring(failure),
                    retryAt = os.clock() + math.min(10, failureCount),
                }
                state.lastError = tostring(failure)
                functions.RecordFarmRecovery("task-error", failure)
                warn("[SeaHub][" .. taskName .. "] " .. tostring(failure))
            end
        end
    end
end
end

local ScheduleGoalTasks
do
ScheduleGoalTasks = {}
local function currentSea(context)
    for sea = 1, 3 do
        if context.IsSea(sea) then
            return sea
        end
    end
    return 0
end

function ScheduleGoalTasks.run(context)
    local state = context.State
    local functions = context.Functions
    local level = context.Level.Value
    local sea = currentSea(context)

    local function setTask(name, enabled, priority)
        if enabled then
            context.TaskQueue:push(
                name,
                priority or context.TaskPriorities[name] or ControllerOrder.Priorities[name]
            )
        else
            context.TaskQueue:pop(name)
        end
    end

    setTask("Auto Farm Level", true)

    local raidLocked = state.raidActive == true
        or state.raidStartRequestedAt ~= nil
        or os.clock() < (state.raidStartPendingUntil or 0)
        or functions.IsRaidActive and functions.IsRaidActive()
    local raidScheduled = raidLocked
        or functions.ShouldAutoRaid and functions.ShouldAutoRaid()
    context.TaskDefinitions["Auto Raid"].args = {}
    setTask("Auto Raid", raidScheduled)

    setTask("Melee Materials", functions.NeedsMeleeMaterialTask
        and functions.NeedsMeleeMaterialTask())

    setTask("Auto Trevor", sea == 2 and level >= 1100
        and functions.ShouldAutoTrevor and functions.ShouldAutoTrevor())
    setTask("Auto Third Sea", sea == 2 and level >= 1500
        and functions.CanAutoThirdSea and functions.CanAutoThirdSea())
    setTask("Auto Second Sea", sea == 1 and level >= 700)

    if context.Environment.Configs["Get Fruits"] ~= false
        and functions.HasDroppedFruit()
    then
        setTask("Get Fruits", true)
    else
        setTask("Get Fruits", false)
    end

    local observedBosses = {}
    for _, entry in BossTaskPolicy.Order do
        if context.IsSea(entry.sea) then
            local model = functions.GetLiveBoss(entry.name)
            observedBosses[entry.name] = model or false
            BossTelemetry.observe(
                context,
                entry.name,
                model,
                "ordered-scan"
            )
        end
    end

    local function bossAlive(name)
        if functions.ShouldTargetOrderedBoss
            and not functions.ShouldTargetOrderedBoss(name)
        then
            return false
        end
        local model = observedBosses[name]
        if model == nil then
            model = functions.GetLiveBoss(name)
            observedBosses[name] = model or false
            BossTelemetry.observe(context, name, model, "scheduler-scan")
        elseif model == false then
            model = nil
        end
        local alive = model ~= nil
        if name == "Cake Prince" then
            if not alive then
                state.cakePrincePortalStartedAt = nil
                state.cakePrincePortalBlockedUntil = nil
            elseif os.clock() < (state.cakePrincePortalBlockedUntil or 0) then
                return false
            end
        end
        return alive
    end

    local needsBartilo = sea == 2 and level >= 850
        and state.bartiloCompleted ~= true
        and not functions.Owns("Accessory", "Warrior Helmet")
    if needsBartilo then
        setTask("Auto Bartilo Quest", true)
    else
        setTask("Auto Bartilo Quest", false)
    end

    local saberBossAlive = functions.GetLiveBoss("Saber Expert") ~= nil
    if saberBossAlive then
        state.saberAwaitingFinalBoss = nil
    end
    setTask("Auto Saber", context.Environment.Configs.Saber ~= false
        and sea == 1 and level >= 200
        and not functions.Owns("Moveset", "Saber")
        and (not state.saberAwaitingFinalBoss or saberBossAlive))

    local eliteProgress = tonumber(state.eliteProgress) or 0
    setTask("Auto Yama", functions.ShouldAutoYama
        and functions.ShouldAutoYama()
        or sea == 3 and level >= 2800
            and eliteProgress >= 30 and not functions.Owns("Moveset", "Yama"))

    local indraAlive = sea == 3 and functions.GetLiveBoss("rip_indra True Form") ~= nil
    local longmaAlive = sea == 3 and functions.GetLiveBoss("Longma") ~= nil
    setTask("Auto Tushita", functions.ShouldAutoTushita
        and functions.ShouldAutoTushita()
        or sea == 3 and level >= 2000
            and not functions.Owns("Moveset", "Tushita")
            and (indraAlive or state.tushitaDoorOpened and longmaAlive))

    setTask("Utility Items Activation", functions.ShouldActivateUtilityItem
        and functions.ShouldActivateUtilityItem())

    for _, name in { "Pirate Raid", "Tyrant Boss", "Auto Soul Guitar" } do
        context.TaskQueue:pop(name)
    end

    local specialBlocked = functions.Carries("God's Chalice")
        or functions.Carries("Sweet Chalice")
        or functions.Carries("Hallow Essence")
    local darkbeard = not specialBlocked and level >= 700 and level < 2600
        and functions.GetLiveBoss("Darkbeard") or nil
    if darkbeard then
        context.TaskDefinitions["Special Boss"].args = {
            "Darkbeard",
            "Special Boss",
            false,
        }
    end
    setTask("Special Boss", darkbeard ~= nil)

    local blocked = BossTaskPolicy.isBlocked(functions.Carries)
    local selectedBoss, selectedQuest
    if not blocked then
        selectedBoss = BossTaskPolicy.selectOrdered(level, context.IsSea, bossAlive)
        if not selectedBoss and level > 900 then
            selectedBoss, selectedQuest = BossTaskPolicy.selectQuest(
                level,
                state.bossQuestData,
                bossAlive,
                state.blacklistedBossQuestIds
            )
        end
    end

    if selectedBoss then
        context.TaskDefinitions["Farm Boss"].args = {
            selectedBoss,
            "Farm Boss",
            selectedQuest ~= nil,
            selectedQuest,
        }
        setTask("Farm Boss", true)
        state.schedulerReason = selectedQuest and "boss-quest:" .. selectedBoss
            or "boss-order:" .. selectedBoss
    else
        setTask("Farm Boss", false)
    end

    setTask("Exp Redeem", functions.ShouldRedeemExpCode
        and functions.ShouldRedeemExpCode())

    if not selectedBoss and state.schedulerReason
        and state.schedulerReason:find("boss-", 1, true) == 1
    then
        state.schedulerReason = "level-progress"
    end
    if raidLocked then
        state.schedulerReason = "raid-active"
    elseif darkbeard then
        state.schedulerReason = "special-boss:Darkbeard"
    end
    local topTask = context.TaskQueue:top()
    BossTelemetry.select(
        context,
        selectedBoss,
        selectedQuest and "boss-quest" or selectedBoss and "boss-order" or nil,
        topTask
    )
    return topTask
end
end

local CollectDroppedFruit
do
CollectDroppedFruit = {}
local TASK_NAME = "Get Fruits"
local PICKUP_TIMEOUT_SECONDS = 10
local COLLECT_DISTANCE = 15
local ItemConfig
local FruitConfigIndex

local function copyMetadata(metadata)
    if type(metadata) ~= "table" then
        return nil
    end
    return {
        storageKey = metadata.storageKey,
        itemId = metadata.itemId,
        value = metadata.value,
        name = metadata.name,
        raw = metadata.raw,
    }
end

local function buildFruitConfigIndex(items)
    local index = {
        byItemId = {},
        byStorageKey = {},
        byName = {},
    }
    for _, item in items or {} do
        local itemIndex = type(item) == "table" and item.Index or nil
        local display = type(item) == "table" and item.Display or nil
        if type(itemIndex) == "table"
            and type(display) == "table"
            and type(itemIndex.StorageKey) == "string"
            and itemIndex.IdType == "PhysicalMoveset"
            and display.Category == "Blox Fruit"
        then
            local name = display.Name or itemIndex.StorageKey
            local displayName = name:match("%sFruit$") and name or name .. " Fruit"
            local metadata = {
                storageKey = itemIndex.StorageKey,
                itemId = itemIndex.ItemId,
                value = FruitCollectionPolicy.moneyValue(item),
                name = displayName,
                raw = item,
            }
            index.byStorageKey[itemIndex.StorageKey] = metadata
            index.byName[name] = metadata
            index.byName[displayName] = metadata
            if itemIndex.ItemId ~= nil then
                index.byItemId[tostring(itemIndex.ItemId)] = metadata
            end
        end
    end
    return index
end

local function resolveIndexedMetadata(index, descriptor)
    descriptor = descriptor or {}
    if descriptor.itemId ~= nil then
        local metadata = index.byItemId[tostring(descriptor.itemId)]
        return copyMetadata(metadata) or { itemId = descriptor.itemId }
    end
    local metadata = index.byStorageKey[descriptor.originalName]
        or index.byStorageKey[descriptor.storageKey]
        or index.byName[descriptor.name]
        or index.byStorageKey[descriptor.name]
    return copyMetadata(metadata)
end

local function isDroppedFruit(instance)
    return typeof(instance) == "Instance"
        and instance:IsA("Tool")
        and instance.Name:find("Fruit", 1, true) ~= nil
        and instance.Parent == workspace
end

local function getHandle(tool)
    return tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart", true)
end

local function isSuppressed(state, tool)
    local untilAt = state.failedDroppedFruits and state.failedDroppedFruits[tool]
    return untilAt and os.clock() < untilAt
end

local function appendFruitTrace(context, event)
    local environment = context.Environment or {}
    local globalEnvironment = type(getgenv) == "function" and getgenv() or nil
    local appender = rawget(environment, "appendfile")
    local writer = rawget(environment, "writefile")
    local checker = rawget(environment, "isfile")
    if type(globalEnvironment) == "table" then
        if type(appender) ~= "function" then
            appender = rawget(globalEnvironment, "appendfile")
        end
        if type(writer) ~= "function" then
            writer = rawget(globalEnvironment, "writefile")
        end
        if type(checker) ~= "function" then
            checker = rawget(globalEnvironment, "isfile")
        end
    end
    local state = context.State
    local path = "seahub_fruit_trace_" .. tostring(context.LocalPlayer.UserId) .. ".jsonl"
    local function recordTrace(success, method, failure)
        local errorMessage
        if not success and failure ~= nil then
            errorMessage = tostring(failure)
        end
        state.lastDroppedFruitTrace = {
            kind = event.kind,
            success = success,
            method = method,
            error = errorMessage,
            path = path,
            at = os.clock(),
        }
        return success
    end

    if type(appender) ~= "function" and type(writer) ~= "function" then
        return recordTrace(false, "unavailable", "file writer unavailable")
    end

    local encoded
    local encodedSuccessfully, encodeFailure = pcall(function()
        local record = table.clone(event)
        record.unix = os.time()
        record.clock = os.clock()
        record.placeId = game.PlaceId
        record.jobId = game.JobId
        record.userId = context.LocalPlayer.UserId
        record.level = context.Level.Value
        encoded = game:GetService("HttpService"):JSONEncode(record) .. "\n"
    end)
    if not encodedSuccessfully then
        return recordTrace(false, "encode", encodeFailure)
    end

    local exists
    if type(checker) == "function" then
        local checked, result = pcall(checker, path)
        if checked then
            exists = result == true
        end
    end

    local method
    local fileFunction
    if exists == false and type(writer) == "function" then
        method = "writefile"
        fileFunction = writer
    elseif type(appender) == "function" then
        method = "appendfile"
        fileFunction = appender
    elseif type(writer) == "function" then
        method = "writefile"
        fileFunction = writer
    else
        return recordTrace(false, "unavailable", "file writer unavailable")
    end

    local wrote, writeFailure = pcall(fileFunction, path, encoded)
    if not wrote and method == "appendfile" and exists ~= true and type(writer) == "function" then
        method = "writefile"
        wrote, writeFailure = pcall(writer, path, encoded)
    end
    if wrote then
        return recordTrace(true, method)
    end
    return recordTrace(false, method, writeFailure)
end

local function configMetadata(tool)
    local ok, matched = pcall(function()
        ItemConfig = ItemConfig or require(game:GetService("ReplicatedStorage"):WaitForChild("ItemConfig"))
        FruitConfigIndex = FruitConfigIndex
            or buildFruitConfigIndex(ItemConfig.dumpItems())
        return resolveIndexedMetadata(FruitConfigIndex, {
            itemId = tool:GetAttribute("ItemId"),
            originalName = tool:GetAttribute("OriginalName"),
            storageKey = tool:GetAttribute("StorageKey") or tool:GetAttribute("FruitId"),
            name = tool.Name,
        })
    end)
    if not ok or type(matched) ~= "table" then
        return nil
    end
    return matched
end

local function fruitMetadata(context, tool)
    local inventory = context.Inventory.PhysicalMoveset or {}
    local itemId = tool:GetAttribute("ItemId")
    local originalName = tool:GetAttribute("OriginalName")
    local storageKey = tool:GetAttribute("StorageKey") or tool:GetAttribute("FruitId")
    local prefix = tool.Name:match("^%s*(%S+)%s+Fruit$")
    storageKey = storageKey or prefix and (prefix .. "-" .. prefix)

    local direct = storageKey and inventory[storageKey]
    if type(direct) == "table" then
        return {
            storageKey = storageKey,
            itemId = direct.ItemId or itemId,
            value = FruitCollectionPolicy.moneyValue(direct),
            stored = direct,
        }
    end
    for key, item in pairs(inventory) do
        if type(item) == "table" then
            local same = itemId and item.ItemId
                    and tostring(item.ItemId) == tostring(itemId)
                or originalName and (item.StorageKey == originalName or item.Name == originalName)
                or storageKey and (item.StorageKey == storageKey or item.Name == storageKey)
            if same then
                return {
                    storageKey = item.StorageKey or item.Name or key,
                    itemId = item.ItemId or itemId,
                    value = FruitCollectionPolicy.moneyValue(item),
                    stored = item,
                }
            end
        end
    end

    local matched = configMetadata(tool)
    if matched then
        matched.storageKey = matched.storageKey or storageKey
        matched.itemId = matched.itemId or itemId
        local stored = matched.storageKey and inventory[matched.storageKey]
        if type(stored) ~= "table" and matched.itemId then
            for _, candidate in pairs(inventory) do
                if type(candidate) == "table" and candidate.ItemId
                    and tostring(candidate.ItemId) == tostring(matched.itemId)
                then
                    stored = candidate
                    break
                end
            end
        end
        matched.stored = stored
        return matched
    end
    return {
        storageKey = storageKey,
        itemId = itemId,
        value = nil,
    }
end

local function boostRemaining(context)
    local startedAt = tonumber(context.LocalPlayer:GetAttribute("ExpBoostTick")) or 0
    local duration = tonumber(context.LocalPlayer:GetAttribute("ExpBoost"))
    if duration and duration > 0 and startedAt > 0 then
        return math.max(0, duration - math.max(0, tick() - startedAt))
    end
    return math.max(tonumber(context.State.expBoostRemaining) or 0, startedAt - tick(), 0)
end

local function hasProgressionItem(context)
    for _, itemName in FruitCollectionPolicy.BlockingItems do
        if context.Functions.Carries(itemName) then
            return true, itemName
        end
    end
    return false
end

local function isDuplicate(context, tool, metadata)
    local stored = metadata.stored
    if type(stored) == "table" and (tonumber(stored.Count) or 0) > 0 then
        return true
    end
    for _, container in {
        context.LocalPlayer.Character,
        context.LocalPlayer:FindFirstChildOfClass("Backpack"),
    } do
        for _, carried in container and container:GetChildren() or {} do
            if carried:IsA("Tool") and carried ~= tool then
                local carriedMetadata = fruitMetadata(context, carried)
                if metadata.storageKey and carriedMetadata.storageKey == metadata.storageKey
                    or metadata.itemId and carriedMetadata.itemId
                        and tostring(carriedMetadata.itemId) == tostring(metadata.itemId)
                then
                    return true
                end
            end
        end
    end
    return false
end

local function shouldCollect(context, tool)
    local metadata = fruitMetadata(context, tool)
    local blocked, blockedBy = hasProgressionItem(context)
    local eligible, reason = FruitCollectionPolicy.shouldCollect({
        level = context.Level.Value,
        blocked = blocked,
        hasIdentity = metadata.storageKey ~= nil or metadata.itemId ~= nil,
        duplicate = isDuplicate(context, tool, metadata),
        expBoostRemaining = boostRemaining(context),
        value = metadata.value,
    })
    local finalReason = blockedBy or reason
    context.State.lastFruitEligibility = {
        name = tool.Name,
        storageKey = metadata.storageKey,
        itemId = metadata.itemId,
        value = metadata.value,
        eligible = eligible,
        reason = finalReason,
        at = os.clock(),
    }

    local state = context.State
    state.seenDroppedFruits = state.seenDroppedFruits
        or setmetatable({}, { __mode = "k" })
    if not state.seenDroppedFruits[tool] then
        state.seenDroppedFruits[tool] = true
        state.droppedFruitSightings = state.droppedFruitSightings or {}
        local sighting = {
            kind = "sighting",
            name = tool.Name,
            storageKey = metadata.storageKey,
            itemId = metadata.itemId,
            value = metadata.value,
            eligible = eligible,
            reason = finalReason,
            at = os.clock(),
        }
        table.insert(state.droppedFruitSightings, sighting)
        appendFruitTrace(context, sighting)
        while #state.droppedFruitSightings > 20 do
            table.remove(state.droppedFruitSightings, 1)
        end
    end
    return eligible
end

function CollectDroppedFruit.findNearest(context)
    local state = context.State
    local now = os.clock()
    state.lastDroppedFruitScanAt = now
    state.droppedFruitScanCount = (state.droppedFruitScanCount or 0) + 1
    if now >= (state.nextDroppedFruitTraceHeartbeatAt or 0) then
        state.nextDroppedFruitTraceHeartbeatAt = now + 900
        appendFruitTrace(context, {
            kind = "scan-heartbeat",
            scans = state.droppedFruitScanCount,
            task = context.TaskQueue:top(),
            status = state.status,
        })
    end
    if context.Level.Value < FruitCollectionPolicy.MinimumLevel then
        return nil
    end
    if type(context.Functions.RefreshInventory) == "function" then
        local refreshed, failure = pcall(context.Functions.RefreshInventory, false)
        if refreshed then
            state.lastDroppedFruitInventoryError = nil
        else
            state.lastDroppedFruitInventoryError = tostring(failure)
        end
    end
    local blocked = hasProgressionItem(context)
    if blocked then
        return nil
    end
    local character = context.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil
    end

    local nearestTool, nearestHandle, nearestDistance
    for _, child in workspace:GetChildren() do
        if isDroppedFruit(child)
            and not game:GetService("Players"):FindFirstChild(child.Name)
            and not isSuppressed(context.State, child)
            and shouldCollect(context, child)
        then
            local handle = getHandle(child)
            if handle then
                local distance = (handle.Position - root.Position).Magnitude
                if not nearestDistance or distance < nearestDistance then
                    nearestTool, nearestHandle, nearestDistance = child, handle, distance
                end
            end
        end
    end
    return nearestTool, nearestHandle, nearestDistance
end

function CollectDroppedFruit.hasTarget(context)
    return CollectDroppedFruit.findNearest(context) ~= nil
end

local function finish(context, reason, tool)
    local state = context.State
    local ownsTask = context.TaskQueue:top() == TASK_NAME
    context.TaskQueue:pop(TASK_NAME)
    if ownsTask then
        context.Functions.StopTween({ preserveAltitude = true })
    end
    state.droppedFruitStartedAt = nil
    state.droppedFruitNearAt = nil
    state.nextDroppedFruitTouchAt = nil
    state.droppedFruitTarget = nil
    state.lastDroppedFruitResult = {
        reason = reason,
        name = tool and tool.Name or nil,
        at = os.clock(),
    }
    appendFruitTrace(context, {
        kind = "result",
        reason = reason,
        name = tool and tool.Name or nil,
    })
end

function CollectDroppedFruit.run(context)
    if context.TaskQueue:top() ~= TASK_NAME then
        return false
    end

    local state = context.State
    local tool = state.droppedFruitTarget
    if tool and tool.Parent ~= workspace then
        local backpack = context.LocalPlayer:FindFirstChildOfClass("Backpack")
        local collected = tool.Parent == context.LocalPlayer.Character
            or tool.Parent == backpack
        if collected then
            local stored = context.Functions.StoreFruit(tool)
            if stored then
                context.Functions.RefreshInventory(true)
            end
        end
        finish(context, collected and "collected" or "target-gone", tool)
        return collected
    end

    local handle
    local distance
    if tool then
        if not isDroppedFruit(tool)
            or isSuppressed(state, tool)
            or not shouldCollect(context, tool)
        then
            finish(context, "target-ineligible", tool)
            return false
        end
        handle = getHandle(tool)
        local character = context.LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not handle or not root then
            finish(context, "target-invalid", tool)
            return false
        end
        distance = (handle.Position - root.Position).Magnitude
    else
        tool, handle, distance = CollectDroppedFruit.findNearest(context)
    end
    if not tool then
        finish(context, "no-target")
        return false
    end

    state.droppedFruitTarget = tool
    state.droppedFruitStartedAt = state.droppedFruitStartedAt or os.clock()

    state.status = TASK_NAME .. " | " .. tool.Name
    if distance > COLLECT_DISTANCE then
        context.Functions.TP(handle.CFrame, TASK_NAME, false, nil, tool)
        return true
    end

    if type(context.Functions.CancelTween) == "function" then
        context.Functions.CancelTween()
    else
        context.Functions.StopTween()
    end

    local now = os.clock()
    state.droppedFruitNearAt = state.droppedFruitNearAt or now
    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Jump = true
        pcall(humanoid.ChangeState, humanoid, Enum.HumanoidStateType.Jumping)
    end

    if now >= (state.nextDroppedFruitTouchAt or 0) then
        state.nextDroppedFruitTouchAt = now + 0.15
        local prompt = tool:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and type(fireproximityprompt) == "function" then
            pcall(fireproximityprompt, prompt)
        elseif type(firetouchinterest) == "function" then
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root then
                pcall(firetouchinterest, root, handle, 0)
                pcall(firetouchinterest, root, handle, 1)
            end
        end
    end

    if tool.Parent ~= workspace then
        if tool.Parent == context.LocalPlayer.Character
            or tool.Parent == context.LocalPlayer:FindFirstChildOfClass("Backpack")
        then
            local stored = context.Functions.StoreFruit(tool)
            if stored then
                context.Functions.RefreshInventory(true)
            end
        end
        finish(context, "collected", tool)
    elseif now - state.droppedFruitNearAt >= PICKUP_TIMEOUT_SECONDS then
        state.failedDroppedFruits = state.failedDroppedFruits or setmetatable({}, { __mode = "k" })
        state.failedDroppedFruits[tool] = now + 60
        pcall(tool.Destroy, tool)
        finish(context, "pickup-timeout", tool)
        return false
    end
    return true
end

CollectDroppedFruit.TASK_NAME = TASK_NAME
CollectDroppedFruit.TIMEOUT_SECONDS = PICKUP_TIMEOUT_SECONDS
CollectDroppedFruit.MINIMUM_LEVEL = FruitCollectionPolicy.MinimumLevel
CollectDroppedFruit.BOOST_VALUE_THRESHOLD = FruitCollectionPolicy.BoostValueThreshold
CollectDroppedFruit.buildFruitConfigIndex = buildFruitConfigIndex
CollectDroppedFruit.resolveIndexedMetadata = resolveIndexedMetadata
CollectDroppedFruit.appendTrace = appendFruitTrace
end

local RuntimeContext
do
RuntimeContext = {}
local SEA_PLACE_IDS = {
    [1] = 2753915549,
    [2] = 4442272183,
    [3] = 7449423635,
}

local PLACE_TO_SEA = {
    [2753915549] = 1,
    [4442272183] = 2,
    [7449423635] = 3,
    [85211729168715] = 1,
    [79091703265657] = 2,
    [100117331123089] = 3,
}

local function currentSea()
    local known = PLACE_TO_SEA[game.PlaceId]
    if known then
        return known
    end
    local map = workspace:FindFirstChild("Map")
    if not map then
        return nil
    end
    if map:FindFirstChild("Dressrosa") and map:FindFirstChild("GreenBit") then
        return 2
    end
    if map:FindFirstChild("HauntedCastle") or map:FindFirstChild("TikiOutpost")
        or map:FindFirstChild("GreatTree")
    then
        return 3
    end
    return 1
end

local function ensureHopConfiguration(environment)
    environment.Configs = environment.Configs or {}
    environment.Configs.Configuration = environment.Configs.Configuration or {}
    local configuration = environment.Configs.Configuration
    if configuration.HopNear == nil then
        configuration.HopNear = true
    end
    if configuration.HopWhenIdle == nil then
        configuration.HopWhenIdle = true
    end
end

local function ensurePerformanceConfiguration(environment)
    environment.Configs = environment.Configs or {}
    local targetFps = math.clamp(math.floor(tonumber(environment.Configs.FPS) or 15), 5, 60)
    environment.Configs.FPS = targetFps

    local applyCap = rawget(environment, "setfpscap")
    if type(applyCap) == "function" then
        pcall(applyCap, targetFps)
    end
    return targetFps
end

local function guardCommandRemote(remote, state)
    if not remote then
        return nil
    end
    return setmetatable({}, {
        __index = function(_, key)
            if key == "BindState" then
                return function(_, nextState)
                    assert(type(nextState) == "table", "world travel state is required")
                    return guardCommandRemote(remote, nextState)
                end
            end
            if key == "InvokeServer" then
                return function(_, action, ...)
                    if currentSea() == 3
                        and (action == "TravelMain" or action == "TravelDressrosa")
                    then
                        local destinationSea = action == "TravelMain" and 1 or 2
                        local issuedAt = tonumber(state.worldTravelIssuedAt)
                        local owned = state.worldTravelDestination == destinationSea
                            and issuedAt ~= nil
                            and os.clock() - issuedAt <= 8
                        if not owned then
                            state.blockedWorldDowngrades = (state.blockedWorldDowngrades or 0) + 1
                            state.lastBlockedWorldAction = action
                            state.status = "Blocked stale world travel: " .. action
                            warn("[SEAHUB_WORLD_GUARD] blocked " .. action .. " from Third Sea")
                            return nil
                        end
                    end
                    return remote:InvokeServer(action, ...)
                end
            end
            return remote[key]
        end,
    })
end

local QUEST_NPC_NAMES = {
    ImpelQuest = "Head Jailer",
    SkyExp1Quest = "Mole",
    SkyExp2Quest = "Sky Quest Giver 2",
    Area1Quest = "Area 1 Quest Giver",
    Area2Quest = "Area 2 Quest Giver",
    SnowMountainQuest = "Snow Quest Giver",
    IceSideQuest = "Ice Quest Giver",
    ShipQuest1 = "Rear Crew Quest Giver",
    ShipQuest2 = "Front Crew Quest Giver",
    FrostQuest = "Frost Quest Giver",
    ForgottenQuest = "Forgotten Quest Giver",
    HauntedQuest1 = "Haunted Castle Quest Giver 1",
    HauntedQuest2 = "Haunted Castle Quest Giver 2",
    CakeQuest1 = "Cake Quest Giver 1",
    CakeQuest2 = "Cake Quest Giver 2",
}

local function findNpcCFrame(name, fallback)
    local best
    local bestDistance = math.huge
    for _, root in {
        workspace:FindFirstChild("NPCs"),
        game:GetService("ReplicatedStorage"):FindFirstChild("NPCs"),
    } do
        for _, npc in root and root:GetChildren() or {} do
            if npc.Name == name and npc:IsA("PVInstance") then
                local pivot = npc:GetPivot()
                local distance = typeof(fallback) == "CFrame"
                    and (pivot.Position - fallback.Position).Magnitude or 0
                if distance < bestDistance then
                    best = pivot
                    bestDistance = distance
                end
            end
        end
    end

    local npcManagerModule = game:GetService("ReplicatedStorage"):FindFirstChild("NPCManager")
    if npcManagerModule then
        local loaded, manager = pcall(require, npcManagerModule)
        if loaded and type(manager) == "table" and type(manager.getNPCsByName) == "function" then
            local found, npcs = pcall(manager.getNPCsByName, name)
            if found and type(npcs) == "table" then
                for _, npc in npcs do
                    local modelState = type(npc) == "table" and npc._modelState
                    local rootPart = type(modelState) == "table" and modelState._rootPart
                    local targetLocation = type(modelState) == "table" and modelState._targetLocation
                    if typeof(rootPart) == "Instance" and rootPart:IsA("BasePart") then
                        return rootPart.CFrame
                    end
                    if typeof(targetLocation) == "CFrame" then
                        return targetLocation
                    end
                end
            end
        end
    end

    if best and (typeof(fallback) ~= "CFrame" or bestDistance <= 3000) then
        return best
    end
    return fallback
end

local function findQuestNpcCFrame(level, fallback)
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local guideModule = replicatedStorage:FindFirstChild("GuideModule")
    if not guideModule then
        return fallback, nil
    end

    local loaded, guide = pcall(require, guideModule)
    local npcList = loaded and type(guide) == "table"
        and type(guide.Data) == "table" and guide.Data.NPCList
    if type(npcList) ~= "table" then
        return fallback, nil
    end

    for npc, metadata in npcList do
        local levels = type(metadata) == "table" and metadata.Levels
        if type(levels) == "table" then
            for _, questLevel in levels do
                if tonumber(questLevel) == tonumber(level) then
                    local success, cframe = pcall(function()
                        if typeof(npc) == "Instance" then
                            if npc:IsA("BasePart") then
                                return npc.CFrame
                            end
                            if npc:IsA("PVInstance") then
                                return npc:GetPivot()
                            end
                        elseif type(npc) == "table" then
                            return npc.CFrame
                        end
                    end)
                    if success and typeof(cframe) == "CFrame" then
                        return cframe, typeof(npc) == "Instance" and npc.Name or nil
                    end
                end
            end
        end
    end
    return fallback, nil
end

local function readQuestFromPlayer(player)
    local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
    local trackedQuest = playerGui and playerGui:FindFirstChild("TrackedQuestFrame")
    local trackedFrame = trackedQuest and trackedQuest:FindFirstChild("Frame")
    local trackedEnabled = not trackedQuest
        or not trackedQuest:IsA("LayerCollector")
        or trackedQuest.Enabled
    local trackedVisible = not trackedFrame
        or not trackedFrame:IsA("GuiObject")
        or trackedFrame.Visible
    local description = trackedFrame and trackedFrame:FindFirstChild("description")
    if trackedEnabled and trackedVisible
        and description and description:IsA("TextLabel") and description.Text ~= ""
    then
        local header = trackedFrame:FindFirstChild("header")
        local titleLabel = header and header:FindFirstChild("textLabel", true)
        local progressLabel = trackedFrame:FindFirstChild("progress")
        local title = titleLabel and titleLabel:IsA("TextLabel") and tostring(titleLabel.Text) or ""
        local target = tostring(description.Text)
        local progress = progressLabel and progressLabel:IsA("TextLabel")
            and tostring(progressLabel.Text) or ""
        local combined = table.concat({ title, target, progress }, " "):gsub("^%s+", ""):gsub("%s+$", "")
        return true, combined, {
            source = "TrackedQuestFrame",
            title = title,
            description = target,
            progress = progress,
        }
    end

    local main = playerGui and playerGui:FindFirstChild("Main")
    local quest = main and main:FindFirstChild("Quest")
    if not quest or not quest.Visible then
        return false, ""
    end
    local container = quest:FindFirstChild("Container")
    local questTitle = container and container:FindFirstChild("QuestTitle")
    local title = questTitle and questTitle:FindFirstChild("Title")
    local text = title and tostring(title.Text) or ""
    return true, text, {
        source = "Main.Quest",
        title = text,
        description = "",
        progress = "",
    }
end

local function findRemote(root, path)
    local current = root
    for _, name in path do
        current = current and current:FindFirstChild(name)
    end
    return current
end

local function getCapturedUpvalues(capturedFunction)
    if type(getupvalues) ~= "function" or type(capturedFunction) ~= "function" then
        return {}
    end
    local success, upvalues = pcall(getupvalues, capturedFunction)
    return success and upvalues or {}
end

function RuntimeContext.fromCapturedRuntime(options)
    options = options or {}
    local environment = options.Environment or (getgenv and getgenv() or _G)
    ensureHopConfiguration(environment)
    local targetFps = ensurePerformanceConfiguration(environment)
    local capturedFunctions = options.CapturedFunctions or environment.__SEAHUB_FUNCTIONS
    local state = options.State or environment.__SEAHUB_SCRIPT_STATE
    assert(type(capturedFunctions) == "table", "captured SeaHub functions are unavailable")
    assert(type(state) == "table", "captured SeaHub state is unavailable")
    state.performanceFps = targetFps
    if type(state.bossQuestData) ~= "table" or #state.bossQuestData == 0 then
        state.bossQuestData = BossQuestData.forPlace(game.PlaceId)
    end

    local players = game:GetService("Players")
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local localPlayer = players.LocalPlayer
    local playerData = localPlayer:FindFirstChild("Data") or localPlayer:WaitForChild("Data")
    local schedulerUpvalues = getCapturedUpvalues(capturedFunctions.ScheduleGameplay)
    local taskCheckUpvalues = getCapturedUpvalues(capturedFunctions.IsTaskCurrent)
    local combatUpvalues = getCapturedUpvalues(capturedFunctions.Attack)
    local equipUpvalues = getCapturedUpvalues(capturedFunctions.EquipWeapon)

    local remotes = replicatedStorage:FindFirstChild("Remotes")
    local modules = replicatedStorage:FindFirstChild("Modules")
    local net = modules and modules:FindFirstChild("Net")

    local context = {
        Environment = environment,
        State = state,
        CapturedFunctions = capturedFunctions,
        Functions = setmetatable({}, { __index = capturedFunctions }),
        LocalPlayer = localPlayer,
        Level = playerData:FindFirstChild("Level"),
        Beli = playerData:FindFirstChild("Beli"),
        Fragments = playerData:FindFirstChild("Fragments"),
        Race = playerData:FindFirstChild("Race"),
        TweenService = game:GetService("TweenService"),
        RunService = game:GetService("RunService"),
        TaskQueue = options.TaskQueue or taskCheckUpvalues[2] or schedulerUpvalues[6],
        TaskDefinitions = options.TaskDefinitions or schedulerUpvalues[5] or {},
        FruitTracker = options.FruitTracker or schedulerUpvalues[10] or { objects = {}, count = 0 },
        Inventory = options.Inventory or schedulerUpvalues[13] or {},
        ConfiguredFruitName = options.ConfiguredFruitName or schedulerUpvalues[12] or "",
        Islands = options.Islands or schedulerUpvalues[16] or {},
        Crafting = options.Crafting or schedulerUpvalues[17] or {},
        CraftingCosts = options.CraftingCosts or schedulerUpvalues[18] or {},
        MeleeProgress = options.MeleeProgress or schedulerUpvalues[20] or {},
        MeleeInventory = options.MeleeInventory or schedulerUpvalues[21] or {},
        FruitAwakening = options.FruitAwakening or schedulerUpvalues[22],
        SkullGuitar = options.SkullGuitar or schedulerUpvalues[23] or {},
        DropCatalog = options.DropCatalog or schedulerUpvalues[24] or {},
        TaskPriorities = options.TaskPriorities or schedulerUpvalues[7] or {},
        MobSpawns = options.MobSpawns or {},
        ToolsByType = options.ToolsByType or equipUpvalues[2] or {},
        NearbyTargets = options.NearbyTargets or combatUpvalues[3] or {},
        NearbyTargetParts = options.NearbyTargetParts or {},
        CommandRemote = options.CommandRemote or (remotes and remotes:FindFirstChild("CommF_")),
        QuestRemote = options.QuestRemote or (remotes and remotes:FindFirstChild("CommF_")),
        RegisterAttackRemote = options.RegisterAttackRemote
            or combatUpvalues[4]
            or findRemote(net, { "RE", "RegisterAttack" }),
        RegisterHitRemote = options.RegisterHitRemote
            or combatUpvalues[5]
            or findRemote(net, { "RE", "RegisterHit" }),
        SeaName = options.SeaName,
        QuestNpcNames = options.QuestNpcNames or QUEST_NPC_NAMES,
        DynamicNpcCFrames = options.DynamicNpcCFrames or state.dynamicNpcCFrames or {},
        GetNPCCFrame = options.GetNPCCFrame or findNpcCFrame,
        GetQuestNpcCFrame = options.GetQuestNpcCFrame or findQuestNpcCFrame,
        SetHiddenProperty = options.SetHiddenProperty,
        FarmWatchdogState = options.FarmWatchdogState or {
            Enabled = true,
            Config = { PollSeconds = 2 },
            Hops = 0,
            MissingSince = 0,
            LastProgressAt = os.clock(),
            TargetCount = 0,
            TargetHealth = 0,
        },
    }

    context.IsSea = options.IsSea or function(sea)
        return currentSea() == sea
    end
    context.CommandRemote = guardCommandRemote(context.CommandRemote, state)
    context.ReadQuest = options.ReadQuest or function()
        return readQuestFromPlayer(localPlayer)
    end
    context.SetCurrentWeaponType = options.SetCurrentWeaponType or function(weaponType)
        state.currentWeaponType = weaponType
    end
    context.SetNeedsMasteryFragments = options.SetNeedsMasteryFragments or function(value)
        state.needMasteryFragments = value
    end
    context.UsePreviousQuest = options.UsePreviousQuest == true
    context.FarmMasteryActive = options.FarmMasteryActive == true
    context.MasteryWeaponType = options.MasteryWeaponType

    return context
end

function RuntimeContext.fromStandalone(options)
    options = options or {}
    local environment = options.Environment or (getgenv and getgenv() or _G)
    local targetFps = ensurePerformanceConfiguration(environment)
    local players = game:GetService("Players")
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local localPlayer = players.LocalPlayer
    local playerData = localPlayer:FindFirstChild("Data") or localPlayer:WaitForChild("Data")
    local remotes = replicatedStorage:WaitForChild("Remotes")
    local netModule = replicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
    local net = require(netModule)
    local questData = QuestData.forPlace(game.PlaceId)
    local bossQuestData = BossQuestData.forPlace(game.PlaceId)
    assert(#questData > 0, "standalone quest data is unavailable for this place")

    ensureHopConfiguration(environment)
    environment.Configs.Team = environment.Configs.Team or "Pirates"
    environment.Configs["Farm Config"] = environment.Configs["Farm Config"] or {
        ["First Farm At Sky"] = true,
        ["Skip Mode Hop"] = true,
        ["Skip Mode Hop Seconds"] = 35,
        ["Farm Bone Get x2 Exp"] = { Enable = true, Level = 1975 },
    }
    environment.Configs["Farm Config"]["First Farm At Sky"] = true
    if environment.Configs["Farm Config"]["Skip Mode Hop"] == nil then
        environment.Configs["Farm Config"]["Skip Mode Hop"] = true
    end
    environment.Configs["Farm Config"]["Skip Mode Hop Seconds"] =
        environment.Configs["Farm Config"]["Skip Mode Hop Seconds"] or 35
    environment.Configs["Farm Config"]["Farm Bone Get x2 Exp"] =
        environment.Configs["Farm Config"]["Farm Bone Get x2 Exp"] or {
            Enable = true,
            Level = 1975,
        }
    local boneFarm = environment.Configs["Farm Config"]["Farm Bone Get x2 Exp"]
    if boneFarm.Enable == nil then
        boneFarm.Enable = true
    end
    boneFarm.Level = math.max(1975, tonumber(boneFarm.Level) or 1975)
    environment.Configs["Farm Mastery"] = environment.Configs["Farm Mastery"] or {
        Enable = false,
        ["Mastery Health (%)"] = 40,
    }
    if environment.Configs["Switch Melee"] == nil then
        environment.Configs["Switch Melee"] = true
    end
    if environment.Configs["Buy Stuffs"] == nil then
        environment.Configs["Buy Stuffs"] = true
    end
    if environment.Configs["Auto Random Fruit"] == nil then
        environment.Configs["Auto Random Fruit"] = true
    end
    if environment.Configs["Auto 2x Exp Codes"] == nil then
        environment.Configs["Auto 2x Exp Codes"] = true
    end
    if environment.Configs["Auto Use Grinding Fruit"] == nil then
        environment.Configs["Auto Use Grinding Fruit"] = true
    end
    if environment.Configs["Attack Interval"] == nil then
        environment.Configs["Attack Interval"] = 0.05
    end
    if environment.Configs["Auto Set Spawn"] == nil then
        environment.Configs["Auto Set Spawn"] = true
    end
    if environment.Configs.Saber == nil then
        environment.Configs.Saber = true
    end
    environment.Configs["Raid Test"] = environment.Configs["Raid Test"] or {
        Enable = environment.SEAHUB_RAID_TEST == true,
        FragmentDeficit = 1000,
        MaxFruits = 1,
    }

    local state = options.State or {
        paused = true,
        stopped = false,
        status = "Standalone runtime ready",
        autoStatsEnabled = true,
        questData = questData,
        bossQuestData = bossQuestData,
        expBoostRemaining = 0,
        dynamicNpcCFrames = {},
        farmAnchors = {},
    }
    state.performanceFps = targetFps
    state.questData = state.questData or questData
    state.bossQuestData = state.bossQuestData or bossQuestData

    local mobSpawns = {}
    for _, quest in questData do
        mobSpawns[quest.mob_name] = quest.mob_pos
    end

    local context = {
        Environment = environment,
        State = state,
        CapturedFunctions = nil,
        Functions = {},
        LocalPlayer = localPlayer,
        Level = playerData:WaitForChild("Level"),
        Beli = playerData:WaitForChild("Beli"),
        Fragments = playerData:WaitForChild("Fragments"),
        Race = playerData:WaitForChild("Race"),
        TweenService = game:GetService("TweenService"),
        RunService = game:GetService("RunService"),
        TaskQueue = options.TaskQueue,
        TaskDefinitions = options.TaskDefinitions or {},
        FruitTracker = { objects = {}, count = 0 },
        Inventory = options.Inventory or { Material = {}, Moveset = {} },
        ConfiguredFruitName = "",
        Islands = {},
        Crafting = {},
        CraftingCosts = {},
        MeleeProgress = options.MeleeProgress or {},
        MeleeInventory = { Melee = {} },
        SkullGuitar = {},
        DropCatalog = {},
        TaskPriorities = ControllerOrder.copyPriorities(),
        MobSpawns = mobSpawns,
        ToolsByType = {
            Melee = false,
            Sword = false,
            Gun = false,
            ["Blox Fruit"] = false,
            Wear = false,
        },
        NearbyTargets = {},
        NearbyTargetParts = {},
        CommandRemote = remotes:WaitForChild("CommF_"),
        QuestRemote = remotes:WaitForChild("CommF_"),
        RegisterAttackRemote = net:RemoteEvent("RegisterAttack", true),
        RegisterHitRemote = net:RemoteEvent("RegisterHit", true),
        DynamicNpcCFrames = state.dynamicNpcCFrames,
        QuestNpcNames = options.QuestNpcNames or QUEST_NPC_NAMES,
        GetNPCCFrame = options.GetNPCCFrame or findNpcCFrame,
        GetQuestNpcCFrame = options.GetQuestNpcCFrame or findQuestNpcCFrame,
        DesiredTeam = environment.Configs.Team,
        SetHiddenProperty = options.SetHiddenProperty or rawget(environment, "sethiddenproperty"),
        FarmWatchdogState = options.FarmWatchdogState or {
            Enabled = true,
            Config = { PollSeconds = 2, MissingMobHopSeconds = 200, HopRetrySeconds = 120 },
            Hops = 0,
            MissingSince = 0,
            LastProgressAt = os.clock(),
            TargetCount = 0,
            TargetHealth = 0,
        },
    }

    context.IsSea = function(sea)
        return currentSea() == sea
    end
    context.CommandRemote = guardCommandRemote(context.CommandRemote, state)
    context.ReadQuest = function()
        return readQuestFromPlayer(localPlayer)
    end
    context.SetCurrentWeaponType = function(weaponType)
        state.currentWeaponType = weaponType
    end
    context.SetNeedsMasteryFragments = function(value)
        state.needMasteryFragments = value
    end
    context.UsePreviousQuest = options.UsePreviousQuest == true
    context.FarmMasteryActive = false

    return context
end

function RuntimeContext.bindCleanFunctions(context, cleanModules)
    for name, module in cleanModules do
        if type(module) == "table" and type(module.run) == "function" then
            context.Functions[name] = function(...)
                return module.run(context, ...)
            end
        end
    end

    if cleanModules.BringMob and type(cleanModules.BringMob.release) == "function" then
        context.Functions.ReleaseBring = function()
            return cleanModules.BringMob.release(context)
        end
    end
    if cleanModules.Attack and type(cleanModules.Attack.stop) == "function" then
        context.Functions.StopAttack = function()
            return cleanModules.Attack.stop(context)
        end
    end
    if cleanModules.AutoFruitGacha and type(cleanModules.AutoFruitGacha.storeFruit) == "function" then
        context.Functions.StoreFruit = function(tool, options)
            return cleanModules.AutoFruitGacha.storeFruit(context, tool, options)
        end
    end
    if cleanModules.AutoFruitPolicy and type(cleanModules.AutoFruitPolicy.reservedFruit) == "function" then
        context.Functions.ReservedGrindingFruit = function()
            return cleanModules.AutoFruitPolicy.reservedFruit(context)
        end
    end
    if cleanModules.AutoFruitGacha and type(cleanModules.AutoFruitGacha.storeCarriedFruits) == "function" then
        context.Functions.StoreCarriedFruits = function()
            return cleanModules.AutoFruitGacha.storeCarriedFruits(context)
        end
    end
    if cleanModules.AutoRaid and type(cleanModules.AutoRaid.isActive) == "function" then
        context.Functions.IsRaidActive = function()
            return cleanModules.AutoRaid.isActive(context)
        end
        context.Functions.ShouldAutoRaid = function()
            return cleanModules.AutoRaid.shouldSchedule(context)
        end
    end
    if cleanModules.AutoUtilityItems
        and type(cleanModules.AutoUtilityItems.shouldSchedule) == "function"
    then
        context.Functions.ShouldActivateUtilityItem = function()
            return cleanModules.AutoUtilityItems.shouldSchedule(context)
        end
    end
    if cleanModules.AutoTushita
        and type(cleanModules.AutoTushita.shouldSchedule) == "function"
    then
        context.Functions.ShouldAutoTushita = function()
            return cleanModules.AutoTushita.shouldSchedule(context)
        end
    end
    if cleanModules.AutoYama
        and type(cleanModules.AutoYama.shouldSchedule) == "function"
    then
        context.Functions.ShouldAutoYama = function()
            return cleanModules.AutoYama.shouldSchedule(context)
        end
    end
    if cleanModules.AutoExpCodes
        and type(cleanModules.AutoExpCodes.shouldSchedule) == "function"
    then
        context.Functions.ShouldRedeemExpCode = function()
            return cleanModules.AutoExpCodes.shouldSchedule(context)
        end
    end
    if cleanModules.AutoThirdSea then
        if type(cleanModules.AutoThirdSea.shouldTrevor) == "function" then
            context.Functions.ShouldAutoTrevor = function()
                return cleanModules.AutoThirdSea.shouldTrevor(context)
            end
        end
        if type(cleanModules.AutoThirdSea.runTrevor) == "function" then
            context.Functions.AutoTrevor = function(...)
                return cleanModules.AutoThirdSea.runTrevor(context, ...)
            end
        end
        if type(cleanModules.AutoThirdSea.canSchedule) == "function" then
            context.Functions.CanAutoThirdSea = function()
                return cleanModules.AutoThirdSea.canSchedule(context)
            end
        end
    end
    if cleanModules.AutoMeleeProgress then
        if type(cleanModules.AutoMeleeProgress.runBackground) == "function" then
            context.Functions.RunMeleeBackground = function()
                return cleanModules.AutoMeleeProgress.runBackground(context)
            end
        end
        if type(cleanModules.AutoMeleeProgress.runPurchaseMovement) == "function" then
            context.Functions.AutoMeleePurchaseMovement = function()
                return cleanModules.AutoMeleeProgress.runPurchaseMovement(context)
            end
        end
        if type(cleanModules.AutoMeleeProgress.shouldTargetOrderedBoss) == "function" then
            context.Functions.ShouldTargetOrderedBoss = function(bossName)
                return cleanModules.AutoMeleeProgress.shouldTargetOrderedBoss(
                    context,
                    bossName
                )
            end
        end
        if type(cleanModules.AutoMeleeProgress.needsDragonTalonEssence) == "function" then
            context.Functions.NeedsDragonTalonEssence = function()
                return cleanModules.AutoMeleeProgress.needsDragonTalonEssence(context)
            end
        end
        if type(cleanModules.AutoMeleeProgress.needsMaterialTask) == "function" then
            context.Functions.NeedsMeleeMaterialTask = function()
                return cleanModules.AutoMeleeProgress.needsMaterialTask(context)
            end
        end
        if type(cleanModules.AutoMeleeProgress.runMaterial) == "function" then
            context.Functions.AutoMeleeMaterial = function()
                return cleanModules.AutoMeleeProgress.runMaterial(context)
            end
        end
    end
    if cleanModules.AutoElectricUnlock then
        if type(cleanModules.AutoElectricUnlock.shouldPrefetch) == "function" then
            context.Functions.ShouldPrefetchElectric = function()
                return cleanModules.AutoElectricUnlock.shouldPrefetch(context)
            end
        end
        if type(cleanModules.AutoElectricUnlock.runPrefetch) == "function" then
            context.Functions.AutoElectricPrefetch = function(...)
                return cleanModules.AutoElectricUnlock.runPrefetch(context, ...)
            end
        end
    end
    if cleanModules.RefreshInventory then
        context.Functions.CancelPendingReads = function()
            BoundedCall.stop(context)
        end
        context.Functions.Owns = function(category, name)
            return cleanModules.RefreshInventory.owns(context, category, name)
        end
        context.Functions.Carries = function(name)
            return cleanModules.RefreshInventory.carries(context, name)
        end
        context.Functions.FindPhysicalMoveset = function(preferred)
            return cleanModules.RefreshInventory.findPhysicalMoveset(context, preferred)
        end
    end
    if cleanModules.CollectDroppedFruit then
        context.Functions.HasDroppedFruit = function()
            return cleanModules.CollectDroppedFruit.hasTarget(context)
        end
    end
    if cleanModules.TryFastTravel and type(cleanModules.TryFastTravel.stop) == "function" then
        context.Functions.StopFastTravel = function()
            cleanModules.TryFastTravel.stop(context)
        end
    end
    if cleanModules.QuestNotificationBridge then
        local bridge = cleanModules.QuestNotificationBridge
        context.AttachQuestNotification = function()
            return bridge.attach(context)
        end
        context.DetachQuestNotification = function()
            return bridge.detach(context)
        end
        bridge.attach(context)
    end
    return context.Functions
end
end

local CombatTarget
do
CombatTarget = {}

local FULL_HEALTH_STUCK_SECONDS = 60
local FULL_HEALTH_HOP_RETRY_SECONDS = 10

local function observeDamageProgress(state, target, health)
    if state.idleObservedTarget == target
        and type(state.idleObservedTargetHealth) == "number"
        and health < state.idleObservedTargetHealth
    then
        state.lastIdlingAt = os.time()
        state.lastIdleProgressKind = "target-damage"
    end
    state.idleObservedTarget = target
    state.idleObservedTargetHealth = health
end

local function resetFullHealthMonitor(state)
    state.fullHealthStuckTarget = nil
    state.fullHealthStuckSince = nil
    state.fullHealthStuckSeconds = 0
end

local function monitorFullHealthTarget(context, target, targetHumanoid, taskName, options, settled)
    local state = context.State
    local now = os.clock()
    local attackIsRecent = state.lastAttackSent == true
        and now - (state.lastAttackAt or -math.huge) <= 1
    local isRaid = options.raidIsland ~= nil
        or context.LocalPlayer:GetAttribute("IslandRaiding") == true
        or taskName == "Auto Raid"
    local eligible = taskName == "Auto Farm Level"
        and context.Level.Value > 100
        and target.Name ~= "Core"
        and not isRaid
        and settled
        and attackIsRecent
        and targetHumanoid.Health == targetHumanoid.MaxHealth

    if not eligible then
        resetFullHealthMonitor(state)
        return false
    end

    if state.fullHealthStuckTarget ~= target then
        state.fullHealthStuckTarget = target
        state.fullHealthStuckSince = now
        state.fullHealthStuckSeconds = 0
        return false
    end

    state.fullHealthStuckSince = state.fullHealthStuckSince or now
    state.fullHealthStuckSeconds = now - state.fullHealthStuckSince
    if state.fullHealthStuckSeconds <= FULL_HEALTH_STUCK_SECONDS
        or now < (state.nextFullHealthHopAt or 0)
    then
        return false
    end

    state.nextFullHealthHopAt = now + FULL_HEALTH_HOP_RETRY_SECONDS
    state.status = "Auto Farm Level | Hopping from invulnerable mob"
    context.Functions.StopTween()
    local hopped = context.Functions.HopServer(nil, "mob-health-unchanged")
    state.lastFullHealthHop = {
        target = target.Name,
        success = hopped,
        seconds = state.fullHealthStuckSeconds,
        at = os.time(),
    }
    if not hopped then
        state.fullHealthStuckSince = now - (
            FULL_HEALTH_STUCK_SECONDS - FULL_HEALTH_HOP_RETRY_SECONDS
        )
    end
    return hopped == true
end

function CombatTarget.run(context, target, taskName, options)
    options = options or {}
    local functions = context.Functions
    local state = context.State

    if context.TaskQueue:top() ~= taskName then
        return false
    end

    local character = context.LocalPlayer.Character
    local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local active, targetHumanoid, targetRoot = functions.IsActiveEnemyModel(target)

    if not characterRoot or not humanoid or humanoid.Health <= 0 or not active then
        if state.farmTarget == target then
            state.farmTarget = nil
        end
        if state.idleObservedTarget == target then
            state.idleObservedTarget = nil
            state.idleObservedTargetHealth = nil
        end
        resetFullHealthMonitor(state)
        return false
    end

    observeDamageProgress(state, target, targetHumanoid.Health)

    state.farmTarget = target
    state.status = options.status or (taskName .. " | Attacking mob")
    functions.UpdateFarmWatchdog(taskName, "attacking", target.Name)

    local bringNames = options.targetNames or target.Name
    local bringOptions = {
        raidIsland = options.raidIsland,
        scanRadius = options.bringRadius,
        maxMembers = options.maxBringMembers,
    }
    local bringAnchor = options.bringAnchor or targetRoot.CFrame
    local groupedCFrame = not options.boss
        and functions.BringMob(bringAnchor, bringNames, bringOptions, target)
    local destination = options.destination or (groupedCFrame or targetRoot.CFrame) + Vector3.new(0, 30, 0)
    local preserveBring = options.preserveBring
    if preserveBring == nil then
        preserveBring = options.noRespawn
    end
    if preserveBring == nil then
        preserveBring = true
    end
    functions.TP(destination, taskName, preserveBring)

    local attackRadius = tonumber(options.attackRadius) or 60
    local distanceToDestination = (destination.Position - characterRoot.Position).Magnitude
    if distanceToDestination > attackRadius then
        resetFullHealthMonitor(state)
        return true
    end

    functions.AutoBuso()
    table.clear(context.NearbyTargets)
    table.clear(context.NearbyTargetParts)

    for _, enemy in workspace.Enemies:GetChildren() do
        local enemyHumanoid = enemy:FindFirstChildOfClass("Humanoid")
        local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
        local hitPart = enemy:FindFirstChild("Head") or enemyRoot
        if enemyHumanoid and enemyHumanoid.Health > 0
            and enemyRoot and hitPart
            and (enemyRoot.Position - characterRoot.Position).Magnitude <= 60
        then
            context.NearbyTargets[#context.NearbyTargets + 1] = { enemy, hitPart }
            context.NearbyTargetParts[#context.NearbyTargetParts + 1] = hitPart
        end
    end

    local weaponType = options.weaponType or state.selectedWeaponType or "Melee"
    local masteryConfig = context.Environment.Configs["Farm Mastery"]
    state.namecallTarget = nil

    if context.FarmMasteryActive then
        local healthPercent = targetHumanoid.Health / math.max(1, targetHumanoid.MaxHealth) * 100
        if healthPercent <= masteryConfig["Mastery Health (%)"] then
            weaponType = context.MasteryWeaponType or "Sword"
        end
    end

    if functions.EquipWeapon(weaponType) then
        if context.FarmMasteryActive and weaponType == context.MasteryWeaponType then
            functions.FarmMastery(target, targetRoot.CFrame, weaponType)
        elseif weaponType == "Gun" then
            functions.ShootGun(target, weaponType)
        else
            state.attackPulseTask = taskName
            state.attackPulseExpiresAt = os.clock() + 0.35
            functions.Attack()
            if not state.attackPulseRunning then
                state.attackPulseRunning = true
                task.spawn(function()
                    while not state.stopped
                        and not state.paused
                        and context.TaskQueue:top() == state.attackPulseTask
                        and os.clock() <= (state.attackPulseExpiresAt or 0)
                    do
                        functions.Attack()
                        task.wait(0.05)
                    end
                    state.attackPulseRunning = false
                end)
            end
        end
    end

    monitorFullHealthTarget(
        context,
        target,
        targetHumanoid,
        taskName,
        options,
        distanceToDestination <= 15
    )

    return true
end
end

local FarmBoss
do
FarmBoss = {}
local CAKE_PRINCE = "Cake Prince"
local MIRROR_PORTAL_CFRAME = CFrame.new(-2154.778564453125, 70.29520416259766, -12405.072265625)
local MIRROR_DIMENSION_MIN_Y = 3000
local MIRROR_PORTAL_TIMEOUT = 176
local MIRROR_PORTAL_RETRY_COOLDOWN = 300

local function activateMirrorPortal(context, root)
    local map = workspace:FindFirstChild("Map")
    local cake = map and map:FindFirstChild("CakeLoaf")
    local mirror = cake and cake:FindFirstChild("BigMirror")
    if not mirror then return false end

    local detector = mirror:FindFirstChildWhichIsA("ClickDetector", true)
    if detector and type(fireclickdetector) == "function" then
        pcall(fireclickdetector, detector)
    end

    local touchPart = mirror:FindFirstChildWhichIsA("BasePart", true)
    if touchPart and type(firetouchinterest) == "function" then
        pcall(firetouchinterest, root, touchPart, 0)
        task.wait()
        pcall(firetouchinterest, root, touchPart, 1)
    end
    context.State.lastMirrorPortalActivationAt = os.clock()
    return detector ~= nil or touchPart ~= nil
end

local function enterMirrorPortal(context, bossName, taskName)
    if bossName ~= CAKE_PRINCE then
        return false
    end

    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 then
        return true
    end
    if root.Position.Y >= MIRROR_DIMENSION_MIN_Y then
        context.State.cakePrincePortalStartedAt = nil
        return false
    end

    local now = os.clock()
    context.State.cakePrincePortalStartedAt = context.State.cakePrincePortalStartedAt or now
    if now - context.State.cakePrincePortalStartedAt >= MIRROR_PORTAL_TIMEOUT then
        context.State.cakePrincePortalStartedAt = nil
        context.State.cakePrincePortalBlockedUntil = now + MIRROR_PORTAL_RETRY_COOLDOWN
        context.State.status = "Auto Farm Level | Cake Prince portal timeout"
        if context.Functions.ReleaseBossCombat then
            context.Functions.ReleaseBossCombat()
        end
        if context.Functions.StopTween then
            context.Functions.StopTween(taskName)
        end
        context.TaskQueue:pop(taskName)
        return true
    end

    context.State.status = "Auto Farm Boss - Entering Mirror Portal"
    if (root.Position - MIRROR_PORTAL_CFRAME.Position).Magnitude > 30 then
        context.Functions.TP(MIRROR_PORTAL_CFRAME, taskName, true, bossName)
    elseif now >= (context.State.nextMirrorPortalActivationAt or 0) then
        context.State.nextMirrorPortalActivationAt = now + 0.4
        context.Functions.CancelTween()
        activateMirrorPortal(context, root)
    end
    return true
end

function FarmBoss.run(context, bossName, taskName, requiresQuest, quest)
    taskName = taskName or "Auto Farm Level"
    if context.TaskQueue:top() ~= taskName then
        return false
    end

    local functions = context.Functions
    if taskName == "Special Boss"
        and functions.IsRaidActive and functions.IsRaidActive()
    then
        context.State.status = "Special Boss | Leaving active raid"
        local character = context.LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            pcall(function()
                humanoid.Health = 0
            end)
        end
        return true
    end
    local boss = functions.GetLiveBoss(bossName)
    BossTelemetry.observe(context, bossName, boss, "farm-boss")
    if not boss then
        if bossName == CAKE_PRINCE then
            context.State.cakePrincePortalStartedAt = nil
        end
        context.State.farmTarget = nil
        context.State.status = taskName .. " | Boss unavailable"
        if functions.ReleaseBossCombat then
            functions.ReleaseBossCombat()
        end
        if functions.StopTween then
            functions.StopTween(taskName)
        end
        BossTelemetry.finish(context, bossName, "unavailable")
        return false
    end

    if enterMirrorPortal(context, bossName, taskName) then
        BossTelemetry.engage(context, bossName, boss, taskName, "portal")
        return true
    end

    context.State.status = taskName .. " | " .. bossName
    if requiresQuest ~= false then
        quest = quest or functions.GetBossQuest(context.Level.Value, bossName)
        if not quest or quest.boss_name ~= bossName then
            BossTelemetry.finish(context, bossName, "quest-unavailable")
            return false
        end
        if not functions.EnsureQuest(quest, taskName) then
            BossTelemetry.engage(context, bossName, boss, taskName, "quest")
            return true
        end
    end

    BossTelemetry.engage(context, bossName, boss, taskName, "combat")
    return functions.CombatTarget(boss, taskName, {
        boss = true,
        preserveBring = true,
        destination = boss.HumanoidRootPart.CFrame + Vector3.new(0, 30, 0),
    })
end
end

local FarmMob
do
FarmMob = {}

local GRAB_DISTANCE = 320
local MOB_CACHE_RESYNC_SECONDS = 5
local SPAWN_REGION_CACHE_SECONDS = 5
local APPROACH_TIMEOUT = 45
local APPROACH_PROGRESS = 10
local WAIT_FOR_SPAWN_SECONDS = 15
local REGION_REACHED_DISTANCE = 10
local BRING_STUCK_TIMEOUT = 8

local function acceptedNameList(acceptedNames)
    local names = {}
    for name in acceptedNames do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

local function namesKey(names)
    return table.concat(acceptedNameList(names), "\0")
end

local function resetTargetState(state, reason)
    state.farmTarget = nil
    state.farmTargetHealth = nil
    state.farmTargetProgressAt = nil
    state.farmTargetLastPosition = nil
    state.farmTargetOldPosition = nil
    state.farmApproachDistance = nil
    state.farmApproachProgressAt = nil
    state.farmTargetRecovery = reason
end

local function resetPack(context, reason)
    local state = context.State
    resetTargetState(state, reason)
    state.farmCluster = nil
    state.farmClusterCount = 0
    state.farmClusterName = nil
    table.clear(context.NearbyTargets)
    table.clear(context.NearbyTargetParts)
    if context.Functions.ReleaseBring then
        pcall(context.Functions.ReleaseBring)
    end
end

local function cacheEnemy(state, enemy)
    if not enemy:IsA("Model") then
        return
    end
    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        return
    end
    state.farmMobCache[enemy.Name] = state.farmMobCache[enemy.Name] or {}
    state.farmMobCache[enemy.Name][enemy] = true
end

local function uncacheEnemy(state, enemy)
    local cache = enemy and state.farmMobCache[enemy.Name]
    if not cache then
        return
    end
    cache[enemy] = nil
    if not next(cache) then
        state.farmMobCache[enemy.Name] = nil
    end
end

local function ensureMobCache(context)
    local state = context.State
    local enemies = workspace:FindFirstChild("Enemies")
    state.farmMobCache = state.farmMobCache or {}
    local watching = state.farmMobCacheFolder == enemies
        and state.farmEnemyAddedConnection
        and state.farmEnemyRemovedConnection
    if watching then
        if os.clock() >= (state.nextFarmMobCacheResyncAt or 0) then
            state.farmMobCache = {}
            for _, enemy in enemies:GetChildren() do
                cacheEnemy(state, enemy)
            end
            state.nextFarmMobCacheResyncAt = os.clock() + MOB_CACHE_RESYNC_SECONDS
        end
        return
    end

    if state.farmEnemyAddedConnection then
        state.farmEnemyAddedConnection:Disconnect()
    end
    if state.farmEnemyRemovedConnection then
        state.farmEnemyRemovedConnection:Disconnect()
    end
    state.farmEnemyAddedConnection = nil
    state.farmEnemyRemovedConnection = nil
    state.farmMobCache = {}
    state.farmMobCacheFolder = enemies
    state.farmDeadRegions = state.farmDeadRegions or {}
    local token = {}
    state.farmMobCacheToken = token
    if not enemies then
        return
    end
    for _, enemy in enemies:GetChildren() do
        cacheEnemy(state, enemy)
    end
    state.nextFarmMobCacheResyncAt = os.clock() + MOB_CACHE_RESYNC_SECONDS

    state.farmEnemyAddedConnection = enemies.ChildAdded:Connect(function(enemy)
        if state.stopped or state.farmMobCacheToken ~= token
            or state.farmMobCacheFolder ~= enemies or enemy.Parent ~= enemies
        then
            return
        end
        cacheEnemy(state, enemy)
        task.spawn(function()
            local root = enemy:WaitForChild("HumanoidRootPart", 5)
            if not root or state.stopped or state.farmMobCacheToken ~= token
                or state.farmMobCacheFolder ~= enemies or enemy.Parent ~= enemies
            then
                return
            end
            state.farmDeadRegions[enemy.Name] = nil
            local regionState = state.farmRegionState
            if regionState and regionState.acceptedNames[enemy.Name] then
                table.clear(regionState.scanned)
                regionState.spawnCandidate = enemy
                regionState.lastSpawnAt = os.clock()
            end
        end)
    end)
    state.farmEnemyRemovedConnection = enemies.ChildRemoved:Connect(function(enemy)
        if state.stopped or state.farmMobCacheToken ~= token
            or state.farmMobCacheFolder ~= enemies
        then
            return
        end
        uncacheEnemy(state, enemy)
    end)
end

function FarmMob.mergeTargetCandidates(cachedTargets, heldTargets)
    local targets = {}
    local seen = {}
    local recovered = 0

    for _, candidate in cachedTargets do
        if candidate.enemy and not seen[candidate.enemy] then
            seen[candidate.enemy] = true
            targets[#targets + 1] = candidate
        end
    end
    for _, candidate in heldTargets do
        if candidate.enemy and not seen[candidate.enemy] then
            seen[candidate.enemy] = true
            targets[#targets + 1] = candidate
            recovered += 1
        end
    end

    return targets, recovered
end

local function activeTargetRecord(context, enemy)
    local observedHumanoid = enemy and enemy:FindFirstChildOfClass("Humanoid")
    local active, humanoid, root = context.Functions.IsActiveEnemyModel(
        enemy,
        enemy and enemy.Name
    )
    if not active or (enemy:GetAttribute("FailureCount") or 0) >= 3 then
        return nil, humanoid or observedHumanoid
    end
    return {
        enemy = enemy,
        humanoid = humanoid,
        root = root,
        grabbed = enemy:GetAttribute("IsGrabbed") == true,
    }, humanoid
end

local function collectActiveTargets(context, acceptedNames)
    local state = context.State
    local cachedTargets = {}
    local heldTargets = {}
    local enemies = workspace:FindFirstChild("Enemies")

    for name in acceptedNames do
        local cache = state.farmMobCache[name]
        for enemy in cache or {} do
            local candidate, humanoid = activeTargetRecord(context, enemy)
            if candidate then
                cachedTargets[#cachedTargets + 1] = candidate
            elseif enemy.Parent ~= enemies or (humanoid and humanoid.Health <= 0) then
                cache[enemy] = nil
            end
        end
    end

    local session = state.bring
    for enemy in session and session.members or {} do
        if acceptedNames[enemy.Name] then
            local candidate = activeTargetRecord(context, enemy)
            if candidate then
                heldTargets[#heldTargets + 1] = candidate
            end
        end
    end

    return FarmMob.mergeTargetCandidates(cachedTargets, heldTargets)
end

local function activeBringCount(context, acceptedNames)
    local session = context.State.bring
    local count = 0
    if not session or not session.members then
        return count
    end
    for enemy in session.members do
        if acceptedNames[enemy.Name]
            and enemy:GetAttribute("IsGrabbed")
            and context.Functions.IsActiveEnemyModel(enemy, enemy.Name)
        then
            count += 1
        end
    end
    return count
end

local function spawnFolders()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
    return {
        replicatedStorage:FindFirstChild("FortBuilderReplicatedSpawnPositionsFolder"),
        worldOrigin and worldOrigin:FindFirstChild("EnemySpawns"),
    }
end

local function clusterSpawnRegions(entries)
    local regions = {}
    local assigned = {}

    for index, entry in entries do
        if not assigned[index] then
            local queue = { index }
            local members = {}
            assigned[index] = true

            while #queue > 0 do
                local memberIndex = table.remove(queue)
                local member = entries[memberIndex]
                members[#members + 1] = member

                for otherIndex, other in entries do
                    if not assigned[otherIndex]
                        and other.name == entry.name
                        and (member.cframe.Position - other.cframe.Position).Magnitude
                            <= GRAB_DISTANCE
                    then
                        assigned[otherIndex] = true
                        queue[#queue + 1] = otherIndex
                    end
                end
            end

            local center = Vector3.zero
            for _, member in members do
                center += member.cframe.Position
            end
            center /= #members

            local representative = members[1]
            local representativeDistance = math.huge
            for _, member in members do
                local distance = (member.cframe.Position - center).Magnitude
                if distance < representativeDistance then
                    representative = member
                    representativeDistance = distance
                end
            end

            regions[#regions + 1] = {
                name = entry.name,
                cframe = representative.cframe,
                key = entry.name .. "\0" .. tostring(representative.cframe),
                count = #members,
            }
        end
    end

    return regions
end

local function spawnRegions(context, acceptedNames)
    local folders = spawnFolders()
    local key = namesKey(acceptedNames)
    local cached = context.State.farmSpawnRegionsCache
    local now = os.clock()
    if cached and cached.key == key and now < cached.expiresAt
        and cached.firstFolder == folders[1] and cached.secondFolder == folders[2]
    then
        return cached.regions
    end
    local entries = {}
    local seen = {}
    local normalized = {}
    for name in acceptedNames do
        normalized[context.Functions.NormalizeEnemyName(name)] = name
    end

    for _, folder in folders do
        for _, spawn in folder and folder:GetChildren() or {} do
            local name = normalized[context.Functions.NormalizeEnemyName(spawn.Name)]
            if name then
                local success, cframe = pcall(function()
                    return spawn:IsA("BasePart") and spawn.CFrame or spawn:GetPivot()
                end)
                local key = success and name .. "\0" .. tostring(cframe) or nil
                if key and typeof(cframe) == "CFrame" and not seen[key] then
                    seen[key] = true
                    entries[#entries + 1] = {
                        name = name,
                        cframe = cframe,
                    }
                end
            end
        end
    end
    local regions = clusterSpawnRegions(entries)
    context.State.farmSpawnRegionsCache = {
        key = key, firstFolder = folders[1], secondFolder = folders[2],
        expiresAt = now + SPAWN_REGION_CACHE_SECONDS, regions = regions,
    }
    return regions
end

local function nearestRegion(regions, name, position)
    local selected
    local selectedDistance = math.huge
    for _, region in regions do
        if region.name == name then
            local distance = (region.cframe.Position - position).Magnitude
            if distance < selectedDistance then
                selected = region
                selectedDistance = distance
            end
        end
    end
    return selected
end

local function markDeadRegion(context, name, position, regions)
    if type(name) ~= "string" or typeof(position) ~= "Vector3" then
        return
    end
    local region = nearestRegion(regions, name, position)
    if not region then
        return
    end
    local deadRegions = context.State.farmDeadRegions
    deadRegions[name] = deadRegions[name] or {}
    deadRegions[name][region.key] = true
end

local function completeFarmRegion(context, regionState, acceptedNames, regions)
    local session = context.State.bring
    local anchor = session and session.anchor
    if anchor then
        regionState.lastAnchor = anchor
        local farmAnchors = context.State.farmAnchors or {}
        context.State.farmAnchors = farmAnchors
        for name in acceptedNames do
            farmAnchors[name] = {
                task = regionState.task,
                cframe = anchor + Vector3.new(0, 30, 0),
                at = os.clock(),
            }
            local region = nearestRegion(regions, name, anchor.Position)
            if region then
                regionState.scanned[region.key] = true
            end
        end
    end
    regionState.currentIndex = 1
    context.State.farmCluster = nil
    context.State.farmClusterCount = 0
    context.State.farmClusterName = nil
    if context.Functions.ReleaseBring then
        pcall(context.Functions.ReleaseBring)
    end
end

function FarmMob.shouldPreemptTarget(currentName, preferredName, preferredAvailable)
    return preferredAvailable == true
        and preferredName ~= nil
        and currentName ~= preferredName
end

function FarmMob.chooseCandidate(candidates, finishPack, preferredName)
    local selected
    local selectedGrabRank = math.huge
    local selectedPreferredRank = math.huge
    local selectedDistance = math.huge
    for _, candidate in candidates do
        local grabRank = finishPack and (candidate.grabbed and 0 or 1) or 0
        local preferredRank = not finishPack and preferredName
            and (candidate.enemy.Name == preferredName and 0 or 1) or 0
        local distance = candidate.distance or 0
        if grabRank < selectedGrabRank
            or grabRank == selectedGrabRank and preferredRank < selectedPreferredRank
            or grabRank == selectedGrabRank and preferredRank == selectedPreferredRank
                and distance < selectedDistance
        then
            selected = candidate
            selectedGrabRank = grabRank
            selectedPreferredRank = preferredRank
            selectedDistance = distance
        end
    end
    return selected and selected.enemy or nil
end

local function updateTargetHealth(context, target, targetHumanoid, targetRoot)
    local state = context.State
    local now = os.clock()
    local health = targetHumanoid.Health
    local characterRoot = context.LocalPlayer.Character
        and context.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    state.farmTargetLastPosition = targetRoot.Position
    state.farmTargetOldPosition = target:GetAttribute("OldPosition") or state.farmTargetOldPosition
    if state.farmTarget ~= target
        or state.farmTargetHealth == nil
        or health < state.farmTargetHealth - 0.5
    then
        state.farmTargetHealth = health
        state.farmTargetProgressAt = now
    end


    if characterRoot then
        local distance = (targetRoot.Position - characterRoot.Position).Magnitude
        if distance <= 150
            or state.farmApproachDistance == nil
            or distance + APPROACH_PROGRESS < state.farmApproachDistance
        then
            state.farmApproachDistance = distance
            state.farmApproachProgressAt = now
        elseif now - (state.farmApproachProgressAt or now) >= APPROACH_TIMEOUT then
            target:SetAttribute("FailureCount", (target:GetAttribute("FailureCount") or 0) + 1)
            resetPack(context, "approach-timeout")
            return false
        end
    end
    return true
end

local function ensureRegionState(context, taskName, acceptedNames)
    local state = context.State
    local key = namesKey(acceptedNames)
    local regionState = state.farmRegionState
    if not regionState or regionState.task ~= taskName or regionState.key ~= key then
        resetPack(context, "pack-changed")
        regionState = {
            task = taskName,
            key = key,
            acceptedNames = acceptedNames,
            scanned = {},
            currentIndex = 1,
        }
        state.farmRegionState = regionState
        state.farmPackKey = key
    else
        regionState.acceptedNames = acceptedNames
    end
    return regionState
end

function FarmMob.run(
    context,
    targetNames,
    taskName,
    requireQuest,
    maximumQuestLevel,
    cancelPredicate,
    retainAuxiliaryTargets,
    preferredTargetName
)
    local functions = context.Functions
    local state = context.State

    if context.TaskQueue:top() ~= taskName
        or (type(cancelPredicate) == "function" and cancelPredicate())
    then
        functions.StopTween()
        return
    end

    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not characterRoot or not humanoid or humanoid.Health <= 0 or #targetNames == 0 then
        return
    end

    local acceptedNames = {}
    for _, name in targetNames do
        acceptedNames[name] = true
    end

    if requireQuest then
        local questLevel = math.min(context.Level.Value, maximumQuestLevel or context.Level.Value)
        local quest = functions.GetQuest(questLevel)
        if quest and acceptedNames[quest.mob_name] then
            if not functions.EnsureQuest(quest, taskName) then
                return
            end
            preferredTargetName = quest.mob_name
            if not retainAuxiliaryTargets then
                acceptedNames = { [quest.mob_name] = true }
            end
        end
    end

    ensureMobCache(context)
    local regionState = ensureRegionState(context, taskName, acceptedNames)
    local regions = spawnRegions(context, acceptedNames)
    local activeTargets, recoveredTargetCount = collectActiveTargets(context, acceptedNames)
    state.farmRecoveredTargetCount = recoveredTargetCount
    if recoveredTargetCount > 0 then
        state.lastFarmTargetReacquireAt = os.clock()
    end
    local grabbedCount = activeBringCount(context, acceptedNames)
    local finishPack = grabbedCount > 0
    local preferredAvailable = false
    for _, candidate in activeTargets do
        candidate.distance = (candidate.root.Position - characterRoot.Position).Magnitude
        if candidate.enemy.Name == preferredTargetName then
            preferredAvailable = true
        end
    end
    state.farmPreferredName = preferredTargetName

    local target = state.farmTarget
    local targetActive, targetHumanoid, targetRoot
    if target then
        targetActive, targetHumanoid, targetRoot = functions.IsActiveEnemyModel(target, target.Name)
    end
    if target and not targetActive then
        local enemies = workspace:FindFirstChild("Enemies")
        local targetHumanoidNow = target:FindFirstChildOfClass("Humanoid")
        local targetStillAlive = target.Parent == enemies
            and targetHumanoidNow
            and targetHumanoidNow.Health > 0
        if not targetStillAlive then
            markDeadRegion(
                context,
                target.Name,
                target:GetAttribute("OldPosition")
                    or state.farmTargetOldPosition
                    or state.farmTargetLastPosition,
                regions
            )
        end
        resetTargetState(
            state,
            targetStillAlive and "target-root-refresh" or "target-finished"
        )
        target = nil
    elseif targetActive then
        local targetGrabbed = target:GetAttribute("IsGrabbed") == true
        if finishPack and not targetGrabbed then
            resetTargetState(state, "finish-grabbed-pack")
            target = nil
        elseif not finishPack and FarmMob.shouldPreemptTarget(
            target.Name,
            preferredTargetName,
            preferredAvailable
        ) then
            resetPack(context, "preferred-target-available")
            target = nil
            finishPack = false
        elseif not updateTargetHealth(context, target, targetHumanoid, targetRoot) then
            target = nil
        end
    end

    if not target then
        local spawnCandidate = not finishPack and regionState.spawnCandidate
        if spawnCandidate and acceptedNames[spawnCandidate.Name]
            and functions.IsActiveEnemyModel(spawnCandidate, spawnCandidate.Name)
        then
            target = spawnCandidate
        else
            target = FarmMob.chooseCandidate(activeTargets, finishPack, preferredTargetName)
        end
        local session = state.bring
        local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
        if targetRoot and session and grabbedCount == 0 then
            local anchorRegion = nearestRegion(regions, target.Name, session.anchor.Position)
            local targetPosition = target:GetAttribute("OldPosition") or targetRoot.Position
            local targetRegion = nearestRegion(regions, target.Name, targetPosition)
            local changedRegion = anchorRegion and targetRegion
                and anchorRegion.key ~= targetRegion.key
            local leftAnchor = (targetRoot.Position - session.anchor.Position).Magnitude
                > GRAB_DISTANCE
            if changedRegion or leftAnchor then
                completeFarmRegion(context, regionState, acceptedNames, regions)
                state.status = taskName .. " | Moving to next mob region"
                functions.TP(targetRoot.CFrame + Vector3.new(0, 30, 0), taskName)
                return
            end

            local stuckKey = regionState.key .. tostring(session.anchor)
            if regionState.bringStuckKey ~= stuckKey then
                regionState.bringStuckKey = stuckKey
                regionState.bringStuckAt = os.clock()
            elseif os.clock() - regionState.bringStuckAt >= BRING_STUCK_TIMEOUT then
                completeFarmRegion(context, regionState, acceptedNames, regions)
                regionState.bringStuckKey = nil
                regionState.bringStuckAt = nil
                return
            end
            regionState.waitingSince = regionState.waitingSince or os.clock()
            state.status = taskName .. " | Waiting for gathered mob"
            return
        end
    end

    if target then
        local selectedHumanoid = target:FindFirstChildOfClass("Humanoid")
        local selectedRoot = target:FindFirstChild("HumanoidRootPart")
        if state.farmTarget ~= target then
            state.farmTarget = target
            state.farmTargetHealth = selectedHumanoid and selectedHumanoid.Health or nil
            state.farmTargetProgressAt = os.clock()
            state.farmTargetLastPosition = selectedRoot and selectedRoot.Position or nil
            state.farmTargetOldPosition = target:GetAttribute("OldPosition")
                or state.farmTargetLastPosition
            state.farmApproachDistance = selectedRoot
                and (selectedRoot.Position - characterRoot.Position).Magnitude or nil
            state.farmApproachProgressAt = os.clock()
        end

        regionState.waitingSince = nil
        regionState.spawnCandidate = nil
        state.missingMobState = nil
        functions.ObserveFarmTarget(taskName, target.Name, true)
        functions.CombatTarget(target, taskName, {
            targetNames = acceptedNameList(acceptedNames),
            bringRadius = GRAB_DISTANCE,
            maxBringMembers = 10,
        })

        local session = state.bring
        if session and session.anchor then
            local count = activeBringCount(context, acceptedNames)
            state.farmCluster = {
                task = taskName,
                key = regionState.key,
                position = session.anchor.Position,
                count = count,
                selectedAt = os.clock(),
            }
            state.farmClusterCount = count
            state.farmClusterName = target.Name
        end
        return
    end

    resetTargetState(state, state.farmTargetRecovery or "searching")
    table.clear(context.NearbyTargets)
    table.clear(context.NearbyTargetParts)
    if type(functions.StopAttack) == "function" then
        functions.StopAttack()
    end

    if state.bring then
        if activeBringCount(context, acceptedNames) > 0 then
            functions.BringMob(
                state.bring.anchor,
                acceptedNameList(acceptedNames),
                { scanRadius = GRAB_DISTANCE, maxMembers = 10 },
                nil
            )
            regionState.waitingSince = regionState.waitingSince or os.clock()
            state.status = taskName .. " | Holding gathered pack"
            return
        end
        completeFarmRegion(context, regionState, acceptedNames, regions)
    end

    local firstName = acceptedNameList(acceptedNames)[1]
    local missingSeconds = functions.ObserveFarmTarget(taskName, firstName, false)
    local submergedRoute = context.IsSea(3) and context.Level.Value >= 2600
    if not submergedRoute
        and missingSeconds >= 200
        and os.clock() - (state.lastMissingHopAt or -120) >= 120
    then
        state.lastMissingHopAt = os.clock()
        functions.RecordFarmRecovery("hop")
        functions.HopServer(nil, true)
        return
    end

    local availableRegions = {}
    for _, region in regions do
        local dead = state.farmDeadRegions[region.name]
        if not regionState.scanned[region.key] and not (dead and dead[region.key]) then
            availableRegions[#availableRegions + 1] = region
        end
    end

    if #availableRegions > 0 then
        regionState.waitingSince = nil
        regionState.spawnCandidate = nil
        if not availableRegions[regionState.currentIndex] then
            regionState.currentIndex = 1
        end
        local region = availableRegions[regionState.currentIndex]
        local destination = region.cframe + Vector3.new(0, 30, 30)
        state.status = taskName .. " | Scanning mob region"
        state.lastFarmWaitSource = "arya-region-scan"
        state.lastFarmWaitSpawnIndex = regionState.currentIndex
        state.lastFarmWaitSpawnCount = #availableRegions
        functions.UpdateFarmWatchdog(taskName, "scanning", region.name)
        functions.TP(destination, taskName)
        if (destination.Position - characterRoot.Position).Magnitude <= REGION_REACHED_DISTANCE then
            regionState.scanned[region.key] = true
            regionState.currentIndex += 1
        end
        return
    end

    if #regions == 0 then
        local fallbackName = acceptedNameList(acceptedNames)[1]
        local fallback = fallbackName
            and functions.SelectFarmWaitCFrame(taskName, fallbackName, context.MobSpawns[fallbackName])
        if typeof(fallback) == "CFrame" then
            state.status = taskName .. " | Waiting mob data"
            functions.TP(fallback, taskName)
        else
            state.status = taskName .. " | Spawn unavailable"
        end
    else
        regionState.waitingSince = regionState.waitingSince or os.clock()
        state.status = taskName .. " | Waiting mob spawn"
        state.lastFarmWaitSource = "arya-spawn-wait"
        if os.clock() - regionState.waitingSince >= WAIT_FOR_SPAWN_SECONDS then
            table.clear(regionState.scanned)
            regionState.currentIndex = 1
            regionState.waitingSince = os.clock()
        end
    end

    functions.UpdateFarmWatchdog(taskName, "waiting", firstName)
end
end

local SkipMode
do
SkipMode = {}
local TASK_NAME = "Auto Farm Level"
local FLOOR_ONE_BELI_TARGET = 150000
local DEFAULT_HOP_SECONDS = 35
local FLOORS = {
    {
        maximumLevel = 19,
        targets = { "Sky Bandit", "Dark Master" },
    },
    {
        maximumLevel = math.huge,
        targets = { "God's Guard" },
    },
}

local function resolveFloor(sea, level)
    local decision = LevelFarmRoutePolicy.decide({ sea = sea, level = level })
    local index = decision and decision.skipFloor or nil
    return index, index and FLOORS[index] or nil
end

local function hasLiveTarget(context, targetNames)
    local accepted = {}
    for _, name in targetNames do
        accepted[name] = true
    end

    local world = context.Workspace or workspace
    local enemies = world:FindFirstChild("Enemies")
    for _, enemy in enemies and enemies:GetChildren() or {} do
        if accepted[enemy.Name] then
            local active = context.Functions.IsActiveEnemyModel(enemy, enemy.Name)
            if active then
                return true, enemy.Name
            end
        end
    end
    return false, nil
end

local function hopEnabled(context)
    local configs = context.Environment.Configs or {}
    local farmConfig = configs["Farm Config"] or {}
    if farmConfig["Skip Mode Hop"] ~= nil then
        return farmConfig["Skip Mode Hop"] == true
    end
    if configs.HopWhenIdle ~= nil then
        return configs.HopWhenIdle == true
    end
    return true
end

function SkipMode.shouldRun(context)
    local configs = context.Environment.Configs or {}
    local farmConfig = configs["Farm Config"] or {}
    if farmConfig["First Farm At Sky"] ~= true or not context.IsSea(1) then
        return false
    end

    local level = tonumber(context.Level.Value) or 0
    local floorNumber = resolveFloor(1, level)
    return floorNumber ~= nil
end

function SkipMode.run(context)
    if not SkipMode.shouldRun(context) then
        context.State.skipMode = nil
        return false
    end

    local state = context.State
    local now = os.clock()
    local level = tonumber(context.Level.Value) or 0
    local floorNumber, floor = resolveFloor(1, level)
    if not floor then
        state.skipMode = nil
        return false
    end
    state.levelRouteMode = "skip-" .. tostring(floorNumber)
    state.levelRouteLevel = level
    state.levelRouteQuestKey = nil
    state.levelRouteMob = table.concat(floor.targets, " | ")
    local live, targetName = hasLiveTarget(context, floor.targets)
    local skip = state.skipMode
    if not skip then
        skip = {
            floor = floorNumber,
            startedAt = now,
            lastTargetAt = live and now or nil,
            noTargetSince = live and nil or now,
            hops = 0,
        }
        state.skipMode = skip
    end

    if skip.floor ~= floorNumber then
        skip.floor = floorNumber
        skip.lastTargetAt = live and now or nil
        skip.noTargetSince = live and nil or now
    end
    skip.beli = context.Beli and tonumber(context.Beli.Value) or 0
    skip.beliTarget = FLOOR_ONE_BELI_TARGET
    skip.target = targetName

    if live then
        skip.lastTargetAt = now
        skip.noTargetSince = nil
    else
        skip.noTargetSince = skip.noTargetSince or now
    end

    context.Functions.FarmMob(floor.targets, TASK_NAME)

    if live then
        state.status = string.format(
            "Level Farming | Skip Mode | Floor %d | %s | Beli %d/%d",
            floorNumber,
            targetName,
            skip.beli,
            FLOOR_ONE_BELI_TARGET
        )
        return true
    end

    local farmConfig = context.Environment.Configs["Farm Config"] or {}
    local timeout = tonumber(farmConfig["Skip Mode Hop Seconds"]) or DEFAULT_HOP_SECONDS
    timeout = math.max(20, timeout)
    local missingSeconds = now - skip.noTargetSince
    state.status = string.format(
        "Level Farming | Skip Mode | Floor %d | Waiting %.0fs/%ds",
        floorNumber,
        missingSeconds,
        timeout
    )

    if missingSeconds >= timeout and hopEnabled(context)
        and now - (skip.lastHopAt or -120) >= 30
    then
        skip.lastHopAt = now
        skip.hops += 1
        skip.noTargetSince = now
        state.status = string.format(
            "Level Farming | Skip Mode | Floor %d | Hopping for mobs",
            floorNumber
        )
        context.Functions.StopTween()
        context.Functions.HopServer()
    end

    return true
end
end

local FarmMaterial
do
FarmMaterial = {}

local MATERIAL_MOBS = {
    [1] = {
        ["Fish Tail"] = { "Fishman Warrior", "Fishman Commando" },
        ["Magma Ore"] = { "Military Soldier", "Military Spy" },
    },
    [2] = {
        ["Magma Ore"] = { "Magma Ninja" },
        ["Mystic Droplet"] = { "Water Fighter", "Sea Soldier" },
    },
    [3] = {
        ["Fish Tail"] = { "Fishman Raider", "Fishman Captain" },
        ["Dragon Scale"] = { "Dragon Crew Warrior", "Dragon Crew Archer" },
    },
}

local MATERIAL_QUESTS = {
    [2] = {
        ["Magma Ore"] = { name = "FireSideQuest", slot = 1 },
        ["Mystic Droplet"] = { name = "ForgottenQuest", slot = 2 },
    },
    [3] = {
        ["Fish Tail"] = { name = "DeepForestIsland3", slot = 1 },
        ["Dragon Scale"] = { name = "DragonCrewQuest", slot = 1 },
    },
}

local SEA_LEVELS = { 0, 700, 1500 }

local function currentSea(context)
    for sea = 1, 3 do
        if context.IsSea(sea) then
            return sea
        end
    end
end

local function materialSeaOrder(context, materialName)
    local order = {}
    local here = currentSea(context)
    for sea = 1, 3 do
        if MATERIAL_MOBS[sea][materialName] then
            order[#order + 1] = sea
        end
    end
    table.sort(order, function(left, right)
        local leftDistance = math.abs(left - (here or left))
        local rightDistance = math.abs(right - (here or right))
        if leftDistance == rightDistance then
            return left > right
        end
        return leftDistance < rightDistance
    end)
    return order
end

local function travelCommand(current, destination)
    if current == destination then return nil end
    if current == 3 then return "TravelDressrosa" end
    if current == 2 then
        return destination == 1 and "TravelMain" or "TravelZou"
    end
    return "TravelDressrosa"
end

local function selectMaterialQuest(context, mobNames, fixedQuest)
    local accepted = {}
    for _, name in mobNames do
        accepted[name] = true
    end

    local level = context.Level.Value
    if fixedQuest then
        for _, quest in context.State.questData or {} do
            if quest.quest_name == fixedQuest.name
                and tonumber(quest.quest_num) == fixedQuest.slot
                and tonumber(quest.level_req)
                and quest.level_req <= level
            then
                return quest
            end
        end
    end

    local liveCounts = {}
    local enemies = workspace:FindFirstChild("Enemies")
    for _, enemy in enemies and enemies:GetChildren() or {} do
        if accepted[enemy.Name] and context.Functions.IsActiveEnemyModel(enemy, enemy.Name) then
            liveCounts[enemy.Name] = (liveCounts[enemy.Name] or 0) + 1
        end
    end

    local selected
    local selectedCount = -1
    for _, quest in context.State.questData or {} do
        if accepted[quest.mob_name]
            and tonumber(quest.level_req)
            and quest.level_req <= level
        then
            local liveCount = liveCounts[quest.mob_name] or 0
            local isSticky = context.State.materialQuestMob == quest.mob_name
            local selectedSticky = selected
                and context.State.materialQuestMob == selected.mob_name
            if not selected
                or (isSticky and not selectedSticky)
                or (isSticky == selectedSticky and liveCount > selectedCount)
                or (isSticky == selectedSticky and liveCount == selectedCount
                    and quest.level_req > selected.level_req)
            then
                selected = quest
                selectedCount = liveCount
            end
        end
    end
    return selected
end

function FarmMaterial.run(context, materialName, taskName, targetCount, preferredSea)
    local state = context.State
    taskName = taskName or "Auto Farm Level"
    local activeTask = context.TaskQueue and context.TaskQueue:top() or taskName

    local seaOrder = preferredSea
        and MATERIAL_MOBS[preferredSea]
        and MATERIAL_MOBS[preferredSea][materialName]
        and { preferredSea }
        or materialSeaOrder(context, materialName)
    for _, sea in seaOrder do
        local mobs = MATERIAL_MOBS[sea][materialName]
        if mobs then
            if context.IsSea(sea) then
                local quest = selectMaterialQuest(
                    context,
                    mobs,
                    MATERIAL_QUESTS[sea] and MATERIAL_QUESTS[sea][materialName]
                )
                if quest then
                    state.materialQuestName = quest.quest_name
                    state.materialQuestLevel = quest.level_req
                    state.materialQuestMob = quest.mob_name
                    state.status = string.format(
                        "%s | %s | Quest %s",
                        taskName,
                        materialName,
                        quest.mob_name
                    )
                    if not context.Functions.EnsureQuest(quest, activeTask) then
                        return true
                    end
                    context.Functions.FarmMob(
                        mobs,
                        activeTask,
                        false,
                        nil,
                        targetCount
                    )
                else
                    state.materialQuestName = nil
                    state.materialQuestLevel = nil
                    state.materialQuestMob = nil
                    state.status = taskName .. " | " .. materialName .. " | No matching quest"
                    context.Functions.FarmMob(mobs, activeTask, false, nil, targetCount)
                end
                return true
            end
            if context.Level.Value >= SEA_LEVELS[sea] then
                state.status = taskName .. " | Traveling for " .. materialName
                if os.clock() >= (state.nextMaterialTravelAt or 0) then
                    state.nextMaterialTravelAt = os.clock() + 5
                    state.worldTravelOwner = "FarmMaterial:" .. materialName
                    state.worldTravelDestination = sea
                    state.worldTravelIssuedAt = os.clock()
                    local command = travelCommand(currentSea(context), sea)
                    if command then
                        context.CommandRemote:InvokeServer(command)
                    end
                end
                return true
            end
        end
    end

    state.status = taskName .. " | Unknown material: " .. tostring(materialName)
    return false
end

FarmMaterial.Mobs = MATERIAL_MOBS
FarmMaterial.Quests = MATERIAL_QUESTS
FarmMaterial.selectQuest = selectMaterialQuest
FarmMaterial.materialSeaOrder = materialSeaOrder
FarmMaterial.travelCommand = travelCommand
end

local AutoBoneBoost
do
AutoBoneBoost = {}

local BATCH_BONES = 500
local ROLL_COST = 50
local MAX_ROLLS = 10

local function cooldownSeconds(value)
    local minutes, seconds = tostring(value or ""):match("^(%d+):(%d+)$")
    if not minutes then return 60 end
    return tonumber(minutes) * 60 + tonumber(seconds)
end

local function checkDeathKing(context, inventoryBones)
    local values = table.pack(pcall(function()
        return context.CommandRemote:InvokeServer("Bones", "Check")
    end))
    if not values[1] then return nil end
    return {
        availableBones = tonumber(inventoryBones) or 0,
        checkValue = values[2],
        rewards = values[3],
        rollsRemaining = tonumber(values[4]) or 0,
        cooldown = tostring(values[5] or ""),
        maxRolls = tonumber(values[6]) or MAX_ROLLS,
    }
end

local function boneCount(context)
    local item = context.Inventory.Material and context.Inventory.Material.Bones
    return tonumber(item and (item.Count or item.count or item.Amount or item.amount)) or 0
end

local function boostRemaining(context)
    local startedAt = tonumber(context.LocalPlayer:GetAttribute("ExpBoostTick")) or 0
    local duration = tonumber(context.LocalPlayer:GetAttribute("ExpBoost"))
    if duration and duration > 0 and startedAt > 0 then
        return math.max(0, duration - math.max(0, tick() - startedAt))
    end
    return math.max(0, startedAt - tick())
end

function AutoBoneBoost.run(context)
    local state = context.State
    local remaining = boostRemaining(context)
    state.expBoostRemaining = remaining

    if not context.IsSea(3) then
        state.boneRollBatchActive = false
        state.boneRollArmed = false
        state.dragonTalonBoneCyclePhase = nil
        return false
    end

    local functions = context.Functions or {}
    local carries = functions.Carries
    if state.fireEssenceDelivered == true
        or type(carries) == "function" and carries("Fire Essence")
    then
        state.boneRollBatchActive = false
        state.boneRollArmed = false
        state.boneRollSuppressedReason = "fire-essence-carried"
        state.dragonTalonBoneCyclePhase = "complete"
        return false
    end

    local owns = functions.Owns
    if type(owns) == "function"
        and (owns("Melee", "Dragon Talon")
            or owns("Moveset", "Dragon Talon"))
    then
        state.boneRollBatchActive = false
        state.boneRollArmed = false
        state.boneRollSuppressedReason = "dragon-talon-owned"
        state.dragonTalonBoneCyclePhase = "complete"
        return false
    end
    state.boneRollSuppressedReason = nil

    local bones = boneCount(context)
    state.dragonTalonBoneReserve = bones
    if bones >= BATCH_BONES then
        if not state.boneRollArmed then
            state.boneRollBatchAttempts = 0
        end
        state.boneRollArmed = true
    elseif bones < ROLL_COST then
        state.boneRollArmed = false
    end

    state.boneRollBatchActive = state.boneRollArmed == true
    if not state.boneRollArmed or bones < ROLL_COST then
        state.dragonTalonBoneCyclePhase = os.clock() < (state.boneRollCooldownUntil or 0)
            and "level-cooldown" or "gather"
        return false
    end
    if os.clock() < (state.nextBoneRollAt or 0) then
        state.dragonTalonBoneCyclePhase = "rolling"
        return false
    end
    if os.clock() < (state.nextBoneBatchProbeAt or 0) then
        state.dragonTalonBoneCyclePhase = "level-cooldown"
        return false
    end

    local deathKing = checkDeathKing(context, bones)
    state.lastDeathKingCheck = deathKing
    if not deathKing then
        state.nextBoneBatchProbeAt = os.clock() + 10
        state.dragonTalonBoneCyclePhase = "probe-retry"
        return false
    end
    if deathKing.rollsRemaining <= 0 then
        state.boneRollBatchAttempts = 0
        state.boneRollCooldownObserved = deathKing.cooldown
        local waitSeconds = math.max(5, cooldownSeconds(deathKing.cooldown) + 2)
        state.boneRollCooldownUntil = os.clock() + waitSeconds
        state.nextBoneBatchProbeAt = state.boneRollCooldownUntil
        state.dragonTalonBoneCyclePhase = "level-cooldown"
        return false
    end
    state.boneRollCooldownUntil = nil

    if deathKing.availableBones < ROLL_COST
        or deathKing.rollsRemaining <= 0
    then
        state.nextBoneBatchProbeAt = os.clock() + 30
        state.dragonTalonBoneCyclePhase = "gather"
        return false
    end
    if os.clock() < (state.nextBoneRollAt or 0) then return false end

    state.nextBoneRollAt = os.clock() + 0.7
    local before = deathKing.availableBones
    local success, result = pcall(function()
        return context.CommandRemote:InvokeServer("Bones", "Buy", 1, 1)
    end)
    local accepted = success and tonumber(result) == 1

    state.lastBoneRoll = {
        success = success,
        result = tostring(result),
        before = before,
        rollsBefore = deathKing.rollsRemaining,
        cooldown = deathKing.cooldown,
        accepted = accepted,
        at = os.clock(),
    }

    if accepted then
        state.boneRollBatchAttempts = (state.boneRollBatchAttempts or 0) + 1
        state.status = string.format(
            "Auto Farm Level | Bones roll %d/%d",
            state.boneRollBatchAttempts,
            MAX_ROLLS
        )
        state.nextBoneRollAt = os.clock() + 0.7
        state.dragonTalonBoneCyclePhase = "rolling"
        return false
    end

    state.boneRollCooldownObserved = tostring(result)
    state.boneRollCooldownUntil = os.clock() + 60
    state.nextBoneBatchProbeAt = state.boneRollCooldownUntil
    state.dragonTalonBoneCyclePhase = "level-cooldown"
    return false
end

AutoBoneBoost.cooldownSeconds = cooldownSeconds
end

local AutoFarmLevel
do
AutoFarmLevel = {}
local function pulseCakeSpawner(context)
    local state = context.State
    if os.clock() < (state.nextCakePrinceSpawnerAt or 0) then return end
    state.nextCakePrinceSpawnerAt = os.clock() + 5
    pcall(function()
        context.CommandRemote:InvokeServer("CakePrinceSpawner")
    end)
end

local function materialCount(context, name)
    local item = context.Inventory.Material and context.Inventory.Material[name]
    return tonumber(item and (item.Count or item.count or item.Amount or item.amount)) or 0
end

local function fixedQuest(context, questName, questNumber)
    for _, quest in context.State.questData or {} do
        if quest.quest_name == questName and quest.quest_num == questNumber then
            local selected = table.clone(quest)
            selected.mob_pos = context.Functions.ResolveMobCFrame(
                selected.mob_name,
                selected.mob_pos
            )
            return selected
        end
    end
    return nil
end

local function farmResourceRoute(context, mobs, questName, questNumber)
    local functions = context.Functions
    local state = context.State
    local preferredTargetName
    if questName then
        local quest = fixedQuest(context, questName, questNumber)
        if not quest then
            context.State.status = "Auto Farm Level | Resource quest unavailable"
            return false
        end
        preferredTargetName = quest.mob_name
        state.levelRouteMob = quest.mob_name
        state.levelRouteQuestLevel = quest.level_req
        if not functions.EnsureQuest(quest, "Auto Farm Level") then
            return false
        end
    else
        state.levelRouteMob = mobs[1]
        state.levelRouteQuestLevel = nil
    end
    functions.FarmMob(
        mobs,
        "Auto Farm Level",
        false,
        nil,
        nil,
        true,
        preferredTargetName
    )
    return true
end

local function needsMeleeFragments(context)
    local target = context.State.meleeTarget
    if not target then
        return false
    end
    local owned = context.Functions.Owns("Melee", target)
        or context.Functions.Owns("Moveset", target)
    local decision = RaidTaskPolicy.decide({
        level = context.Level.Value,
        fragments = context.Fragments.Value,
        maximumLevel = RaidTaskPolicy.MaximumLevel,
        inRaidSea = context.IsSea(2) or context.IsSea(3),
        styleTarget = target,
        styleTargetOwned = owned == true,
    })
    return decision ~= nil and decision.styleDeficit > 0
end

local function resetLevelRouteTarget(context, routeKey)
    local state = context.State
    if state.appliedLevelQuestKey == routeKey then
        return
    end

    if type(context.Functions.StopAttack) == "function" then
        pcall(context.Functions.StopAttack)
    end
    if type(context.Functions.ReleaseBring) == "function" then
        pcall(context.Functions.ReleaseBring)
    end
    if type(context.Functions.CancelTween) == "function" then
        pcall(context.Functions.CancelTween)
    end

    state.farmTarget = nil
    state.farmTargetHealth = nil
    state.farmTargetProgressAt = nil
    state.farmCluster = nil
    state.farmClusterCount = 0
    state.farmClusterName = nil
    state.currentFarmMobName = nil
    state.attackTarget = nil
    state.attackTargetNames = nil
    state.attackTask = nil
    state.appliedLevelQuestKey = routeKey
    state.levelRouteTargetResetReason = "quest-route-changed"
end

function AutoFarmLevel.run(context)
    local functions = context.Functions
    local runtimeState = context.State
    local level = context.Level.Value

    if context.TaskQueue:top() ~= "Auto Farm Level" then
        return
    end

    if functions.AutoFruitSniper() then
        return
    end
    if functions.AutoBoneBoost() then
        return
    end
    functions.AutoFruitPolicy()
    functions.AutoSetSpawn()
    if functions.AutoProgressionItems() then
        return
    end
    if functions.AutoFactory() then
        return
    end

    if type(functions.AutoMeleePurchaseMovement) == "function"
        and functions.AutoMeleePurchaseMovement() == "busy"
    then
        return
    end
    functions.AutoAbilities()

    local inThirdSea = context.IsSea(3)
    runtimeState.levelRouteSea = inThirdSea and 3 or context.IsSea(2) and 2 or 1

    if functions.SkipMode() then
        return
    end

    local boneCount = materialCount(context, "Bones")
    local hasSweetChalice = not not functions.Carries("Sweet Chalice")
    local hasGodsChalice = not not functions.Carries("God's Chalice")
    local ownsMirrorFractal = functions.Owns("Material", "Mirror Fractal") == true
    local cocoaCount = materialCount(context, "Conjured Cocoa")
	local levelRouteDecision = LevelFarmRoutePolicy.decide({
		sea = runtimeState.levelRouteSea,
		level = level,
		bones = boneCount,
		dragonTalonNeedsEssence = functions.NeedsDragonTalonEssence
			and functions.NeedsDragonTalonEssence(),
		expBoostRemaining = runtimeState.expBoostRemaining,
		rollCooldownReady = os.clock() >= (runtimeState.boneRollCooldownUntil or 0),
		hasSweetChalice = hasSweetChalice,
	})
    if inThirdSea and hasGodsChalice and not ownsMirrorFractal and cocoaCount < 10 then
        runtimeState.levelRouteMode = "cocoa"
        runtimeState.levelRouteMob = "Cocoa Warrior"
        runtimeState.levelRouteQuestLevel = 2300
        runtimeState.status = "Material Farming | Conjured Cocoa | Need 10x"
        functions.FarmMob({ "Cocoa Warrior", "Chocolate Bar Battler" }, "Auto Farm Level", false)
        return
    end
    if inThirdSea and hasGodsChalice and not ownsMirrorFractal then
        runtimeState.levelRouteMode = "sweet-chalice"
        runtimeState.status = "Material Farming | Sweet Chalice | Waiting for craft"
        return
    end

    if levelRouteDecision.farmCake == true then
        runtimeState.levelRouteMode = "cake-special"
        if hasSweetChalice then
            pulseCakeSpawner(context)
        end
        local questName, questNumber = levelRouteDecision.cakeQuestName,
			levelRouteDecision.cakeQuestNumber
        farmResourceRoute(context, {
            "Cookie Crafter",
            "Cake Guard",
            "Baking Staff",
            "Head Baker",
        }, questName, questNumber)
        return
    end

    if levelRouteDecision.farmBones == true then
        context.SetNeedsMasteryFragments(needsMeleeFragments(context))
        runtimeState.shouldFarmBones = true
        runtimeState.boneFarmReason = "arya-exp-expired"
        runtimeState.levelRouteMode = "bones-special"
        local boneQuestName, boneQuestNumber = levelRouteDecision.boneQuestName,
			levelRouteDecision.boneQuestNumber
        farmResourceRoute(context, {
            "Reborn Skeleton",
            "Living Zombie",
            "Demonic Soul",
            "Posessed Mummy",
        }, boneQuestName, boneQuestNumber)
        return
    end

    context.SetNeedsMasteryFragments(false)
    runtimeState.shouldFarmBones = false
    runtimeState.boneFarmReason = nil

    local questVisible, questText = context.ReadQuest()
    local selectedQuest = QuestRoutePolicy.select(
        runtimeState.questData,
        level,
        runtimeState,
        questVisible and questText or nil
    )
    if not selectedQuest then
        runtimeState.levelRouteMode = "ordinary-unavailable"
        runtimeState.levelRouteMob = nil
        runtimeState.levelRouteQuestLevel = nil
        runtimeState.status = "Auto Farm Level | Quest unavailable"
        return
    end

    if level < 10 and context.LocalPlayer.Team and context.LocalPlayer.Team.Name == "Marines" then
        selectedQuest.mob_name = "Trainee"
        selectedQuest.quest_name = "MarineQuest"
        selectedQuest.quest_num = 1
    end
    selectedQuest.mob_pos = functions.ResolveMobCFrame(
        selectedQuest.mob_name,
        selectedQuest.mob_pos
    )
    local selectedQuestKey = selectedQuest.quest_name
        .. "\0" .. tostring(selectedQuest.quest_num)
    resetLevelRouteTarget(context, selectedQuestKey)
    runtimeState.levelRouteMode = "ordinary"
    runtimeState.levelRouteLevel = level
    runtimeState.levelRouteQuestKey = selectedQuestKey
    runtimeState.levelRouteMob = selectedQuest.mob_name
    runtimeState.levelRouteQuestLevel = selectedQuest.level_req

    if functions.EnsureQuest(selectedQuest, "Auto Farm Level") then
        functions.FarmMob(
            { selectedQuest.mob_name },
            "Auto Farm Level",
            false
        )
    end
end
end

local AutoSecondSea
do
AutoSecondSea = {}

local ICE_ADMIRAL_CFRAME = CFrame.new(1266.08923, 56.8099976, -1399.58081)

local function isTaskCurrent(context, owner)
    local functions = context.Functions
    if functions and type(functions.IsTaskCurrent) == "function" then
        return functions.IsTaskCurrent(owner)
    end
    local state = context.State or {}
    return not state.stopped
        and not state.paused
        and context.TaskQueue:top() == owner
end

local function invoke(context, ...)
    local args = table.pack(...)
    return pcall(function()
        return context.CommandRemote:InvokeServer(table.unpack(args, 1, args.n))
    end)
end

local function refreshProgress(context, now, force)
    local state = context.State
    if not force and state.secondSeaProgress ~= nil
        and now - (state.secondSeaProgressAt or 0) < 1
    then
        return state.secondSeaProgress
    end

    local success, progress = invoke(context, "DressrosaQuestProgress")
    state.secondSeaProgressAt = now
    if success then
        state.secondSeaProgress = progress
        state.lastSecondSeaProgressType = type(progress)
        state.lastSecondSeaError = nil
    else
        state.lastSecondSeaError = tostring(progress)
    end
    return state.secondSeaProgress
end

local function detectiveHandshake(context, now, phase, owner)
    local state = context.State
    if now < (state.nextSecondSeaHandshakeAt or 0) then
        return false
    end
    state.nextSecondSeaHandshakeAt = now + 3

    local detective1Ok, detective1 = invoke(context, "DressrosaQuestProgress", "Detective")
    local detective2Ok, detective2 = invoke(context, "DressrosaQuestProgress", "Detective")
    task.wait(1)
    if not isTaskCurrent(context, owner) then
        state.lastSecondSeaHandshake = {
            At = now,
            Phase = phase,
            Detective1Ok = detective1Ok,
            Detective1 = tostring(detective1),
            Detective2Ok = detective2Ok,
            Detective2 = tostring(detective2),
            Interrupted = true,
        }
        return false
    end
    local useKeyOk, useKey = invoke(context, "DressrosaQuestProgress", "UseKey")
    state.secondSeaProgressAt = 0
    state.lastSecondSeaHandshake = {
        At = now,
        Phase = phase,
        Detective1Ok = detective1Ok,
        Detective1 = tostring(detective1),
        Detective2Ok = detective2Ok,
        Detective2 = tostring(detective2),
        UseKeyOk = useKeyOk,
        UseKey = tostring(useKey),
    }
    return true
end

function AutoSecondSea.run(context, taskName)
    local state = context.State
    local functions = context.Functions
    local owner = taskName or "Auto Second Sea"
    if context.TaskQueue:top() ~= owner then
        return false
    end

    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return true
    end

    local now = os.clock()
    local progress = refreshProgress(context, now)
    if not isTaskCurrent(context, owner) then
        return false
    end
    if type(progress) ~= "table" then
        state.status = "Auto Second Sea | Reading quest progress"
        return true
    end

    if not progress.TalkedDetective then
        state.status = "Auto Second Sea | Talk To Detective"
        detectiveHandshake(context, now, "detective", owner)
        return true
    end

    if not progress.KilledIceBoss then
        state.status = "Auto Second Sea | Defeating Ice Admiral"
        detectiveHandshake(context, now, "ice-admiral", owner)
        if not isTaskCurrent(context, owner) then
            return false
        end

        local boss = functions.GetLiveBoss("Ice Admiral")
        if boss then
            state.secondSeaSawBoss = true
            return functions.CombatTarget(boss, owner, {
                boss = true,
                preserveBring = true,
                destination = boss.HumanoidRootPart.CFrame + Vector3.new(0, 30, 0),
            })
        end

        functions.TP(ICE_ADMIRAL_CFRAME, owner, true)
        return true
    end

    state.secondSeaBossDefeated = true
    state.status = "Auto Second Sea | Travelling"
    if now >= (state.nextSecondSeaTravelAt or 0) then
        state.nextSecondSeaTravelAt = now + 8
        local success, result = invoke(context, "TravelDressrosa")
        state.lastSecondSeaTravel = {
            At = now,
            Ok = success,
            Result = tostring(result),
        }
        if not success then
            state.lastSecondSeaError = tostring(result)
        end
    end
    return true
end

AutoSecondSea.detectiveHandshake = detectiveHandshake
end

local AutoBartiloQuest
do
AutoBartiloQuest = {}

local TASK_NAME = "Auto Bartilo Quest"
local BARTILO_CFRAME = CFrame.new(-456.28952, 73.0200958, 299.895966)
local JEREMY_CFRAME = CFrame.new(2099.88159, 448.931, 648.997375)
local SWAN_PIRATE_CFRAME = CFrame.new(970.369446, 142.653198, 1217.3667)
local PUZZLE_APPROACH = CFrame.new(-1837.46155, 44.2921753, 1656.1987)
local PUZZLE_ENTRY = CFrame.new(-1836, 11, 1714)
local PUZZLE_POINTS = {
    CFrame.new(-1850.49329, 13.1789551, 1750.89685),
    CFrame.new(-1858.87305, 19.3777466, 1712.01807),
    CFrame.new(-1803.94324, 16.5789185, 1750.89685),
    CFrame.new(-1858.55835, 16.8604317, 1724.79541),
    CFrame.new(-1869.54224, 15.987854, 1681.00659),
    CFrame.new(-1800.0979, 16.4978027, 1684.52368),
    CFrame.new(-1819.26343, 14.795166, 1717.90625),
    CFrame.new(-1813.51843, 14.8604736, 1724.79541),
}

local BARTILO_QUEST = {
    level_req = 850,
    quest_name = "BartiloQuest",
    quest_num = 1,
    mob_name = "Swan Pirate",
    quest_pos = BARTILO_CFRAME,
    mob_pos = SWAN_PIRATE_CFRAME,
}

local function progressStage(progress)
    if type(progress) == "number" then
        return progress
    end
    if type(progress) ~= "table" then
        return nil
    end
    if progress.KilledBandits ~= true then
        return 0
    end
    if progress.KilledSpring ~= true then
        return 1
    end
    if progress.DidPlates ~= true then
        return 2
    end
    return 3
end

local function refreshProgress(context, force)
    local state = context.State
    local now = os.clock()
    if not force and now < (state.nextBartiloProgressAt or 0) then
        return state.bartiloProgress
    end
    state.nextBartiloProgressAt = now + 2
    local success, result = pcall(function()
        return context.CommandRemote:InvokeServer("BartiloQuestProgress")
    end)
    if success then
        state.bartiloProgress = tonumber(result) or result
        state.lastBartiloError = nil
    else
        state.lastBartiloError = tostring(result)
    end
    return state.bartiloProgress
end

local function rootPart(context)
    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return humanoid and humanoid.Health > 0 and root or nil
end

local function solvePuzzle(context)
    local state = context.State
    local root = rootPart(context)
    if not root then
        state.status = TASK_NAME .. " | Waiting character"
        return true
    end

    local phase = state.bartiloPuzzlePhase or "approach"
    if phase == "approach" then
        state.status = TASK_NAME .. " | Moving to puzzle"
        if (root.Position - PUZZLE_APPROACH.Position).Magnitude > 10 then
            context.Functions.TP(PUZZLE_APPROACH, TASK_NAME, true)
            return true
        end
        context.Functions.StopTween()
        root.CFrame = PUZZLE_ENTRY
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        state.bartiloPuzzlePhase = "entry"
        state.bartiloPuzzleIndex = 1
        state.nextBartiloPuzzleStepAt = os.clock() + 0.5
        return true
    end

    if os.clock() < (state.nextBartiloPuzzleStepAt or 0) then
        return true
    end

    local index = math.clamp(tonumber(state.bartiloPuzzleIndex) or 1, 1, #PUZZLE_POINTS)
    local target = PUZZLE_POINTS[index]
    state.status = string.format("%s | Puzzle %d/%d", TASK_NAME, index, #PUZZLE_POINTS)
    context.Functions.StopTween()
    root.CFrame = target
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    state.bartiloPuzzlePhase = "points"
    state.nextBartiloPuzzleStepAt = os.clock() + 1
    if index < #PUZZLE_POINTS then
        state.bartiloPuzzleIndex = index + 1
    else
        state.bartiloPuzzleIndex = 1
        state.bartiloPuzzlePhase = "approach"
        state.nextBartiloProgressAt = 0
        refreshProgress(context, true)
    end
    return true
end

function AutoBartiloQuest.run(context)
    local state = context.State
    if context.TaskQueue:top() ~= TASK_NAME then
        return false
    end
    if not context.IsSea(2) or context.Level.Value < 850 then
        context.TaskQueue:pop(TASK_NAME)
        return false
    end

    local progress = refreshProgress(context, false)
    if context.TaskQueue:top() ~= TASK_NAME then
        return false
    end
    local stage = progressStage(progress)
    state.bartiloStage = stage
    if stage == 3 then
        state.bartiloCompleted = true
        state.bartiloPuzzlePhase = nil
        state.status = TASK_NAME .. " | Complete"
        context.TaskQueue:pop(TASK_NAME)
        return false
    end

    if stage == 0 then
        state.bartiloPuzzleIndex = 1
        state.bartiloPuzzlePhase = "approach"
        state.status = TASK_NAME .. " | Swan Pirates"
        if context.Functions.EnsureQuest(BARTILO_QUEST, TASK_NAME)
            and context.TaskQueue:top() == TASK_NAME
        then
            context.Functions.FarmMob({ "Swan Pirate" }, TASK_NAME)
        end
        return true
    end

    if stage == 1 then
        state.bartiloPuzzleIndex = 1
        state.bartiloPuzzlePhase = "approach"
        local boss = context.Functions.GetLiveBoss("Jeremy")
        if boss then
            state.bartiloJeremyMissingSince = nil
            state.status = TASK_NAME .. " | Jeremy"
            context.Functions.CombatTarget(boss, TASK_NAME, { boss = true, preserveBring = true })
            return true
        end

        local root = rootPart(context)
        state.bartiloJeremyMissingSince = state.bartiloJeremyMissingSince or os.clock()
        state.status = TASK_NAME .. " | Waiting Jeremy"
        if root and (root.Position - JEREMY_CFRAME.Position).Magnitude > 80 then
            context.Functions.TP(JEREMY_CFRAME, TASK_NAME, true)
        elseif os.clock() - state.bartiloJeremyMissingSince >= 60
            and os.clock() >= (state.nextBartiloHopAt or 0)
        then
            state.nextBartiloHopAt = os.clock() + 120
            context.Functions.HopServer(nil, true)
        end
        return true
    end

    if stage == 2 then
        return solvePuzzle(context)
    end

    state.status = TASK_NAME .. " | Checking progress"
    state.nextBartiloProgressAt = 0
    return true
end

AutoBartiloQuest.progressStage = progressStage
end

local AutoSaber
do
AutoSaber = {}

local TASK_NAME = "Auto Saber"
local PLATE_DISTANCE = 20
local PLATE_SETTLE_SECONDS = 1

local function isTaskCurrent(context)
    local functions = context.Functions
    if functions and type(functions.IsTaskCurrent) == "function" then
        return functions.IsTaskCurrent(TASK_NAME)
    end
    local state = context.State or {}
    return not state.stopped
        and not state.paused
        and context.TaskQueue:top() == TASK_NAME
end

local function invalidateProgress(state)
    if state.taskProgressCache then
        state.taskProgressCache.proQuestProgress = nil
    end
end

local function equipTool(context, tool)
    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 or not tool or not tool:IsA("Tool") then
        return false
    end
    if tool.Parent ~= character then
        humanoid:EquipTool(tool)
    end
    return tool.Parent == character
end

local function getQuestPlates(state)
    local map = workspace:FindFirstChild("Map")
    local jungle = map and map:FindFirstChild("Jungle")
    local root = jungle and jungle:FindFirstChild("QuestPlates")
    if not root then
        return nil
    end
    if state.saberQuestPlatesRoot == root and state.saberQuestPlates then
        return state.saberQuestPlates
    end

    local plates = {}
    for _, plate in root:GetChildren() do
        if plate:FindFirstChild("Button") then
            plates[#plates + 1] = plate
        end
    end
    state.saberQuestPlatesRoot = root
    state.saberQuestPlates = plates
    state.saberPlateIndex = 1
    state.saberPlateSettledAt = nil
    return plates
end

local function runQuestPlates(context)
    local state = context.State
    local plates = getQuestPlates(state)
    if not plates or #plates == 0 then
        state.status = TASK_NAME .. " | Waiting quest plates"
        return true
    end

    local index = math.clamp(tonumber(state.saberPlateIndex) or 1, 1, #plates + 1)
    if index > #plates then
        state.saberPlateIndex = 1
        state.saberPlateSettledAt = nil
        invalidateProgress(state)
        return true
    end

    local plate = plates[index]
    local button = plate and plate:FindFirstChild("Button")
    local character = context.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not button or not root then
        state.saberQuestPlates = nil
        return true
    end

    state.status = ("Saber Quest | Quest Plates | Touching %d/%d"):format(index, #plates)
    if (root.Position - button.Position).Magnitude > PLATE_DISTANCE then
        state.saberPlateSettledAt = nil
        context.Functions.TP(button.CFrame, TASK_NAME, true)
        return true
    end

    local now = os.clock()
    state.saberPlateSettledAt = state.saberPlateSettledAt or now
    if now - state.saberPlateSettledAt >= PLATE_SETTLE_SECONDS then
        state.saberPlateIndex = index + 1
        state.saberPlateSettledAt = nil
        if state.saberPlateIndex > #plates then
            invalidateProgress(state)
        end
    end
    return true
end

local function farmBossIfAlive(context, bossName)
    local functions = context.Functions
    if functions.GetLiveBoss(bossName) then
        context.State.saberWaitingBoss = nil
        functions.FarmBoss(bossName, TASK_NAME, false)
        return true
    end

    context.State.saberWaitingBoss = bossName
    context.State.status = TASK_NAME .. " | Waiting " .. bossName
    functions.FarmMob({ bossName }, TASK_NAME, false)
    return true
end

local function stageFor(context, progress)
    for _, completed in progress.Plates or {} do
        if completed == false then
            return 1
        end
    end
    if not progress.UsedTorch then
        return 2
    elseif not progress.UsedCup then
        return 3
    elseif not progress.TalkedSon then
        return 4
    elseif not progress.KilledMob then
        return 5
    elseif not progress.UsedRelic then
        return 6
    elseif not progress.KilledShanks
        and context.Functions.GetLiveBoss("Saber Expert")
    then
        return 7
    end
    return nil
end

function AutoSaber.run(context)
    if not isTaskCurrent(context) then
        return false
    end
    local functions = context.Functions
    local state = context.State
    local progress = functions.ReadTaskProgress(
        TASK_NAME,
        "proQuestProgress",
        1,
        "ProQuestProgress"
    )
    if type(progress) ~= "table" then
        return false
    end

    if progress.KilledShanks then
        state.saberAwaitingFinalBoss = nil
        if not state.saberProgressLoaded then
            if type(functions.LoadProgress) == "function" then
                functions.LoadProgress()
            else
                functions.RefreshInventory(true)
            end
            state.saberProgressLoaded = true
        end
        context.TaskQueue:pop(TASK_NAME)
        return true
    end

    local stage = stageFor(context, progress)
    if stage ~= 7 then
        state.saberAwaitingFinalBoss = nil
    end

    if stage == 1 then
        return runQuestPlates(context)
    elseif stage == 2 then
        state.status = "Saber Quest | Torch Puzzle | Using Torch"
        functions.TaskRequest(TASK_NAME, "get-torch", 1, "ProQuestProgress", "GetTorch")
        task.wait(1)
        if not isTaskCurrent(context) then
            return false
        end
        functions.TaskRequest(TASK_NAME, "use-torch", 1, "ProQuestProgress", "DestroyTorch")
        invalidateProgress(state)
        return true
    elseif stage == 3 then
        state.status = "Saber Quest | Sick Man | Helping with Cup"
        local cup = functions.Carries("Cup")
        if not cup then
            functions.TaskRequest(TASK_NAME, "get-cup", 1, "ProQuestProgress", "GetCup")
            task.wait(0.2)
            if not isTaskCurrent(context) then
                return false
            end
            cup = functions.Carries("Cup")
        end
        if cup and equipTool(context, cup) then
            task.wait(1)
            if not isTaskCurrent(context) then
                return false
            end
            functions.TaskRequest(TASK_NAME, "fill-cup", 1, "ProQuestProgress", "FillCup", cup)
        end
        functions.TaskRequest(TASK_NAME, "sick-man", 1, "ProQuestProgress", "SickMan")
        invalidateProgress(state)
        return true
    elseif stage == 4 then
        state.status = "Saber Quest | Rich Son | Getting Information"
        functions.TaskRequest(TASK_NAME, "rich-son", 1, "ProQuestProgress", "RichSon")
        invalidateProgress(state)
        return true
    elseif stage == 5 then
        state.status = "Saber Quest | Mob Leader | Defeating Boss"
        return farmBossIfAlive(context, "Mob Leader")
    elseif stage == 6 then
        state.status = "Saber Quest | Relic | Placing at Location"
        functions.TaskRequest(TASK_NAME, "relic-reward", 1, "ProQuestProgress", "RichSon")
        functions.TaskRequest(TASK_NAME, "place-relic", 1, "ProQuestProgress", "PlaceRelic")
        invalidateProgress(state)
        return true
    elseif stage == 7 then
        state.status = "Saber Quest | Saber Expert | Final Battle"
        return farmBossIfAlive(context, "Saber Expert")
    end

    state.saberAwaitingFinalBoss = true
    state.status = "Saber Quest | Waiting Saber Expert spawn"
    context.TaskQueue:pop(TASK_NAME)
    return false
end

AutoSaber.farmBossIfAlive = farmBossIfAlive
AutoSaber.stageFor = stageFor
end

local TrevorPolicy
do
TrevorPolicy = {}

TrevorPolicy.MinimumFruitValue = 1000000
TrevorPolicy.MaximumFruitValue = 2500000

TrevorPolicy.FallbackOrder = {
    "Quake-Quake",
    "Buddha-Buddha",
    "Love-Love",
    "Spider-Spider",
    "Sound-Sound",
    "Phoenix-Phoenix",
    "Portal-Portal",
    "Rumble-Rumble",
    "Pain-Pain",
    "Blizzard-Blizzard",
    "Gravity-Gravity",
    "T-Rex-T-Rex",
    "Mammoth-Mammoth",
    "Dough-Dough",
    "Shadow-Shadow",
    "Venom-Venom",
    "Gas-Gas",
    "Spirit-Spirit",
    "Yeti-Yeti",
    "Tiger-Tiger",
    "Magnet-Magnet",
    "Kitsune-Kitsune",
    "Control-Control",
    "Dragon-Dragon",
}

local function storageId(key, item)
    if type(item) ~= "table" then
        return nil
    end
    return item.StorageKey or item.Name or (type(key) == "string" and key or nil)
end

local function count(item)
    return type(item) == "table" and (tonumber(item.Count) or 0) or 0
end

local function value(item)
    if type(item) ~= "table" then
        return nil
    end
    return tonumber(item.Value) or tonumber(item.Price) or tonumber(item.Cost)
end

local function find(inventory, wanted)
    local direct = inventory[wanted]
    if count(direct) > 0 then
        return wanted, direct
    end
    for key, item in pairs(inventory) do
        if storageId(key, item) == wanted and count(item) > 0 then
            return wanted, item
        end
    end
end

local function eligible(item)
    local fruitValue = value(item)
    return fruitValue ~= nil
        and fruitValue >= TrevorPolicy.MinimumFruitValue
        and fruitValue < TrevorPolicy.MaximumFruitValue
end

function TrevorPolicy.selectFruit(inventory, configured)
    inventory = inventory or {}
    for _, wanted in ipairs(configured or {}) do
        local id, item = find(inventory, wanted)
        if id and eligible(item) then
            return id, "configured"
        end
    end

    local candidates = {}
    for key, item in pairs(inventory) do
        local id = storageId(key, item)
        local fruitValue = value(item)
        if id and count(item) > 0 and eligible(item)
        then
            candidates[#candidates + 1] = { id = id, value = fruitValue }
        end
    end
    table.sort(candidates, function(left, right)
        if left.value == right.value then
            return left.id < right.id
        end
        return left.value < right.value
    end)
    if candidates[1] then
        return candidates[1].id, "lowest-value"
    end

    for _, wanted in ipairs(TrevorPolicy.FallbackOrder) do
        local id, item = find(inventory, wanted)
        if id and eligible(item) then
            return id, "fallback-order"
        end
    end
    return nil
end


TrevorPolicy.isEligible = eligible
end

local AutoThirdSea
do
AutoThirdSea = {}
local DON_SWAN_ROOM_CFRAME = CFrame.new(2293.70, 24.50, 663.10)
local DON_SWAN_STREAM_DISTANCE = 90
local DON_SWAN_STREAM_SECONDS = 10
local DON_SWAN_HOP_COOLDOWN = 10
local THIRD_SEA_TRAVEL_COOLDOWN = 30
local INDRA_BEGIN_INTERVAL = 2
local INDRA_BRANCH_TIMEOUT = 60
local INDRA_HOP_RETRY_SECONDS = 10

local function isTaskCurrent(context, owner)
    local functions = context.Functions
    if functions and type(functions.IsTaskCurrent) == "function" then
        return functions.IsTaskCurrent(owner)
    end
    local state = context.State or {}
    return not state.stopped
        and not state.paused
        and context.TaskQueue:top() == owner
end

local TREVOR_FRUIT_SET = {}
for _, storageId in TrevorPolicy.FallbackOrder do
    TREVOR_FRUIT_SET[storageId] = true
end

local function invoke(context, ...)
    local args = table.pack(...)
    return pcall(function()
        return context.CommandRemote:InvokeServer(table.unpack(args, 1, args.n))
    end)
end

local function thirdSeaFruit(context)
    local configured = context.Environment.Configs["Fruit to use for auto third sea"] or {}
    local inventory = context.Inventory.PhysicalMoveset or {}
    return TrevorPolicy.selectFruit(inventory, configured)
end

local function refreshFlamingoAccess(context, force)
    local state = context.State
    if state.flamingoAccess == true then
        return true
    end
    if not force and os.clock() < (state.nextUnlockablesAt or 0) then
        return false
    end

    state.nextUnlockablesAt = os.clock() + 5
    local success, unlockables = invoke(context, "GetUnlockables")
    if success and type(unlockables) == "table" then
        state.flamingoAccess = unlockables.FlamingoAccess == true
    end
    return state.flamingoAccess == true
end

local function fruitToolName(storageId)
    storageId = tostring(storageId or "")
    for index = 1, #storageId do
        if storageId:sub(index, index) == "-" then
            local left = storageId:sub(1, index - 1)
            local right = storageId:sub(index + 1)
            if left == right then
                return left .. " Fruit"
            end
        end
    end
    return storageId .. " Fruit"
end

local function loadedFruitTool(context, storageId)
    local expectedName = fruitToolName(storageId)
    for _, root in {
        context.LocalPlayer.Character,
        context.LocalPlayer:FindFirstChildOfClass("Backpack"),
    } do
        for _, tool in root and root:GetChildren() or {} do
            if tool:IsA("Tool") then
                local matches = tool.Name == expectedName
                for _, attributeName in { "StorageKey", "ItemId", "FruitId" } do
                    matches = matches or tool:GetAttribute(attributeName) == storageId
                end
                if matches then
                    return tool
                end
            end
        end
    end
end

local function equipLoadedFruit(context, storageId)
    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local tool = loadedFruitTool(context, storageId)
    if not humanoid or humanoid.Health <= 0 or not tool then
        return false
    end
    if tool.Parent ~= character then
        humanoid:EquipTool(tool)
        task.wait(0.05)
    end
    return tool.Parent == character
end

local function probeThirdSeaSharkman(context, force)
    local state = context.State
    local now = os.clock()
    if not force and now < (state.nextThirdSeaSharkmanProbeAt or 0) then
        return state.thirdSeaSharkmanProbeResult
    end

    state.nextThirdSeaSharkmanProbeAt = now + 2
    local success, result = invoke(context, "BuySharkmanKarate", true)
    state.lastThirdSeaSharkmanProbe = {
        success = success,
        result = tostring(result),
        at = now,
    }
    if not success then
        return nil
    end

    state.thirdSeaSharkmanProbeResult = result
    if type(result) == "number" then
        state.thirdSeaBlockedBySharkman = nil
    else
        state.thirdSeaBlockedBySharkman = true
        state.meleePrerequisite = "Sharkman Karate"
    end
    return result
end

local function worldFruitStorageId(tool)
    for _, attributeName in { "StorageKey", "ItemId", "FruitId" } do
        local value = tool:GetAttribute(attributeName)
        if type(value) == "string" and TREVOR_FRUIT_SET[value] then
            return value
        end
    end
    local prefix = tool.Name:match("^%s*([^%s%-]+)")
    local storageId = prefix and (prefix .. "-" .. prefix) or nil
    return storageId and TREVOR_FRUIT_SET[storageId] and storageId or nil
end

local function fruitHandle(tool)
    if typeof(tool) ~= "Instance" or not tool:IsA("Tool") then
        return nil, nil
    end
    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
    if not handle then
        return nil, nil
    end
    local storageId = worldFruitStorageId(tool)
    return storageId and handle or nil, storageId
end

local function ensureFruitWatcher(state)
    if state.trevorFruitAddedConnection then
        return
    end
    state.trevorFruitAddedConnection = workspace.ChildAdded:Connect(function(child)
        local handle, storageId = fruitHandle(child)
        if handle then
            state.trevorWorldFruit = child
            state.trevorWorldFruitHandle = handle
            state.trevorWorldFruitStorageId = storageId
            state.trevorFruitDetectedAt = os.clock()
        end
    end)
end

local function findWorldFruit(rootPart, state)
    local nearest
    local nearestHandle
    local nearestStorageId
    local nearestDistance = math.huge
    for _, child in workspace:GetChildren() do
        local handle, storageId = fruitHandle(child)
        local blockedUntil = state and state.trevorFruitBlacklist
            and state.trevorFruitBlacklist[child] or 0
        if handle and os.clock() >= blockedUntil then
            local distance = (handle.Position - rootPart.Position).Magnitude
            if distance < nearestDistance then
                nearest = child
                nearestHandle = handle
                nearestStorageId = storageId
                nearestDistance = distance
            end
        end
    end
    return nearest, nearestHandle, nearestDistance, nearestStorageId
end

local function carriedFruit(context, storageId)
    for _, root in { context.LocalPlayer:FindFirstChildOfClass("Backpack"), context.LocalPlayer.Character } do
        for _, tool in root and root:GetChildren() or {} do
            if tool:IsA("Tool") and worldFruitStorageId(tool) == storageId then
                return tool
            end
        end
    end
end

local function touchFruit(rootPart, handle)
    if type(firetouchinterest) == "function" then
        firetouchinterest(rootPart, handle, 0)
        task.wait(0.05)
        firetouchinterest(rootPart, handle, 1)
    else
        rootPart.CFrame = handle.CFrame
    end
end

local function huntTrevorFruit(context, owner)
    local state = context.State
    ensureFruitWatcher(state)
    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart then
        return true
    end

    local now = os.clock()
    local pending = state.trevorFruitCollection
    if pending then
        local carried = carriedFruit(context, pending.storageId)
        if carried then
            state.status = "Auto Trevor | Storing " .. pending.storageId
            if now >= (pending.nextStoreAt or 0) then
                pending.nextStoreAt = now + 1
                pending.storeAttempts = (pending.storeAttempts or 0) + 1
                local stored = context.Functions.StoreFruit(carried)
                if stored then
                    state.lastTrevorFruitCollection = {
                        id = pending.storageId,
                        success = true,
                        attempts = pending.touchAttempts,
                        at = now,
                    }
                    state.trevorFruitCollection = nil
                    state.trevorFruitSearchStartedAt = nil
                elseif pending.storeAttempts >= 3 then
                    state.lastTrevorFruitCollection = {
                        id = pending.storageId,
                        success = false,
                        error = "store-retries-exhausted",
                        at = now,
                    }
                    state.trevorFruitCollection = nil
                end
            end
            return true
        end

        local tool = pending.tool
        local handle = tool and tool.Parent == workspace and fruitHandle(tool) or nil
        if handle and now >= (pending.nextTouchAt or 0) and pending.touchAttempts < 3 then
            pending.touchAttempts = pending.touchAttempts + 1
            pending.nextTouchAt = now + 0.75
            touchFruit(rootPart, handle)
            return true
        end
        if not handle and now - pending.startedAt < 3 then
            return true
        end
        if not handle or pending.touchAttempts >= 3 then
            state.trevorFruitBlacklist = state.trevorFruitBlacklist or {}
            if tool then
                state.trevorFruitBlacklist[tool] = now + 30
            end
            state.lastTrevorFruitCollection = {
                id = pending.storageId,
                success = false,
                error = "pickup-retries-exhausted",
                at = now,
            }
            state.trevorFruitCollection = nil
        end
    end

    if now >= (state.nextTrevorFruitScanAt or 0) then
        state.nextTrevorFruitScanAt = now + 0.5
        local fruit, handle, distance, storageId = findWorldFruit(rootPart, state)
        state.trevorWorldFruit = fruit
        state.trevorWorldFruitHandle = handle
        state.trevorWorldFruitDistance = distance
        state.trevorWorldFruitStorageId = storageId
    end

    local fruit = state.trevorWorldFruit
    local handle = state.trevorWorldFruitHandle
    local storageId = state.trevorWorldFruitStorageId
    if fruit and fruit.Parent == workspace and handle and handle.Parent then
        state.trevorFruitSearchStartedAt = now
        state.status = "Auto Trevor | Collecting " .. fruit.Name
        if (handle.Position - rootPart.Position).Magnitude > 6 then
            context.Functions.TP(handle.CFrame, owner, true, nil, true)
        else
            context.Functions.CancelTween()
            state.trevorFruitCollection = {
                tool = fruit,
                storageId = storageId,
                touchAttempts = 1,
                nextTouchAt = now + 0.75,
                startedAt = now,
            }
            touchFruit(rootPart, handle)
        end
        return true
    end

    state.trevorWorldFruit = nil
    state.trevorWorldFruitHandle = nil
    state.trevorWorldFruitStorageId = nil
    state.trevorFruitSearchStartedAt = state.trevorFruitSearchStartedAt or now
    state.trevorFruitSearchSeconds = now - state.trevorFruitSearchStartedAt
    state.trevorFruitHuntMode = "passive"
    return false
end

local function resetIndraBranch(state)
    state.indraBranchStartedAt = nil
    state.nextZQuestBeginAt = nil
    state.nextIndraBranchHopAt = nil
end

local function runIndraBranch(context)
    local state = context.State
    local now = os.clock()
    state.indraBranchStartedAt = state.indraBranchStartedAt or now
    local elapsed = now - state.indraBranchStartedAt
    state.indraBranchSeconds = elapsed

    if elapsed >= INDRA_BRANCH_TIMEOUT then
        if now >= (state.nextIndraBranchHopAt or 0) then
            state.nextIndraBranchHopAt = now + INDRA_HOP_RETRY_SECONDS
            state.status = "Auto Third Sea | Hopping for rip_indra"
            context.Functions.StopTween()
            local hopped = context.Functions.HopServer(nil, "third-sea-indra-timeout")
            state.lastIndraBranchHop = {
                success = hopped,
                seconds = elapsed,
                at = os.time(),
            }
            if not hopped then
                state.indraBranchStartedAt = now - (
                    INDRA_BRANCH_TIMEOUT - INDRA_HOP_RETRY_SECONDS
                )
            end
        end
        return true
    end

    state.status = "Auto Third Sea | Starting quest"
    if now >= (state.nextZQuestBeginAt or 0) then
        state.nextZQuestBeginAt = now + INDRA_BEGIN_INTERVAL
        context.Functions.CancelTween()
        invoke(context, "ZQuestProgress", "Begin")
    end
    return true
end

function AutoThirdSea.shouldTrevor(context)
    if not context.IsSea(2) or context.Level.Value < 1100 then
        return false
    end
    if refreshFlamingoAccess(context, false) then
        context.State.trevorSubmitted = nil
        context.State.trevorLoadedFruit = nil
        return false
    end
    if context.State.trevorSubmitted == true then
        return false
    end
    return context.State.trevorLoadedFruit ~= nil
        or thirdSeaFruit(context) ~= nil
end

function AutoThirdSea.canSchedule(context)
    if not context.IsSea(2) or context.Level.Value < 1500 then
        return false
    end
    if not refreshFlamingoAccess(context, false) then
        return false
    end
    if context.Functions.Carries
        and context.Functions.Carries("Water Key")
    then
        return false
    end

    local result = probeThirdSeaSharkman(context, false)
    return type(result) == "number"
end

function AutoThirdSea.runTrevor(context, taskName)
    local state = context.State
    local owner = taskName or "Auto Trevor"
    if context.TaskQueue:top() ~= owner then
        return false
    end
    if refreshFlamingoAccess(context, false) then
        state.trevorSubmitted = nil
        state.trevorLoadedFruit = nil
        context.TaskQueue:pop(owner)
        state.status = "Auto Trevor | Complete"
        return false
    end
    if not isTaskCurrent(context, owner) then
        return false
    end
    if state.trevorSubmitted == true then
        context.TaskQueue:pop(owner)
        state.status = "Auto Trevor | Waiting for Flamingo access"
        return false
    end

    local fruit = state.trevorLoadedFruit or thirdSeaFruit(context)
    if not fruit then
        context.TaskQueue:pop(owner)
        return false
    end
    if os.clock() < (state.nextTrevorAt or 0) then
        return true
    end

    if state.fruitStoreInFlight and state.fruitStoreInFlight.id == fruit then
        state.status = "Auto Trevor | Waiting for fruit storage handoff"
        state.nextTrevorAt = os.clock() + 0.5
        return true
    end
    state.nextTrevorAt = os.clock() + 5
    state.status = "Auto Trevor | Loading " .. fruit
    state.trevorFruitLocks = state.trevorFruitLocks or {}
    state.trevorFruitLocks[fruit] = os.clock() + 30
    local alreadyLoaded = loadedFruitTool(context, fruit) ~= nil
    local loaded, loadResult = true, "already-loaded"
    if not alreadyLoaded then
        loaded, loadResult = invoke(context, "LoadFruit", fruit)
    end
    state.lastTrevorFruit = {
        name = fruit,
        success = loaded,
        result = tostring(loadResult),
        at = os.clock(),
    }
    if not loaded then
        state.trevorFruitLocks[fruit] = nil
        state.trevorLoadedFruit = nil
        state.status = "Auto Trevor | Fruit load failed"
        return true
    end
    state.trevorLoadedFruit = fruit

    task.wait(0.2)
    if not isTaskCurrent(context, owner) then
        return true
    end
    if not equipLoadedFruit(context, fruit) then
        state.status = "Auto Trevor | Waiting to equip fruit"
        return true
    end
    if not isTaskCurrent(context, owner) then
        return true
    end

    state.status = "Auto Trevor | Talking"
    local talked = true
    for phase = 1, 3 do
        if not isTaskCurrent(context, owner) then
            return true
        end
        local phaseOk = pcall(function()
            context.CommandRemote:InvokeServer("TalkTrevor", tostring(phase))
        end)
        if not phaseOk then
            talked = false
            break
        end
    end
    if talked then
        task.wait(1)
        state.trevorSubmitted = true
        state.nextUnlockablesAt = 0
        if not isTaskCurrent(context, owner) then
            return true
        end
        refreshFlamingoAccess(context, true)
    end
    if state.flamingoAccess == true or state.trevorSubmitted == true then
        state.trevorFruitLocks[fruit] = nil
        state.trevorLoadedFruit = nil
        context.TaskQueue:pop(owner)
        state.status = state.flamingoAccess == true
            and "Auto Trevor | Complete"
            or "Auto Trevor | Submitted; waiting for access"
    end
    return true
end

function AutoThirdSea.run(context, taskName)
    local state = context.State
    local owner = taskName or "Auto Third Sea"
    if context.TaskQueue:top() ~= owner then
        return false
    end

    if not refreshFlamingoAccess(context, false) then
        state.lockSpawnCheckpoint = nil
        context.TaskQueue:pop(owner)
        return false
    end
    if not isTaskCurrent(context, owner) then
        return false
    end

    if context.Functions.Carries
        and context.Functions.Carries("Water Key")
    then
        state.status = "Auto Third Sea | Handing off Water Key"
        context.TaskQueue:pop(owner)
        return false
    end

    local sharkmanProbe = probeThirdSeaSharkman(context, false)
    if not isTaskCurrent(context, owner) then
        return false
    end
    if type(sharkmanProbe) ~= "number" then
        state.status = "Auto Third Sea | Waiting for Sharkman Karate"
        context.TaskQueue:pop(owner)
        return false
    end

    state.lockSpawnCheckpoint = nil

    local success, progress = invoke(context, "ZQuestProgress")
    if not isTaskCurrent(context, owner) then
        return false
    end
    if success and (type(progress) == "table" or tonumber(progress) ~= nil) then
        state.zQuestProgress = progress
    end
    progress = state.zQuestProgress
    if tonumber(progress) == 1 then
        resetIndraBranch(state)
        state.thirdSeaTravelReady = true
        state.status = "Auto Third Sea | Travelling"
        if os.clock() >= (state.nextThirdSeaTravelAt or 0) then
            state.nextThirdSeaTravelAt = os.clock() + THIRD_SEA_TRAVEL_COOLDOWN
            context.Functions.StopTween()
            invoke(context, "TravelZou")
        end
        return true
    end
    if type(progress) == "table" and progress.KilledIndraBoss then
        resetIndraBranch(state)
        state.thirdSeaTravelReady = true
        state.status = "Auto Third Sea | Travelling"
        if os.clock() >= (state.nextThirdSeaTravelAt or 0) then
            state.nextThirdSeaTravelAt = os.clock() + THIRD_SEA_TRAVEL_COOLDOWN
            context.Functions.StopTween()
            invoke(context, "TravelZou")
        end
        return true
    end

    local indra = context.Functions.GetLiveBoss("rip_indra")
    if indra then
        resetIndraBranch(state)
        state.status = "Auto Third Sea | rip_indra"
        context.Functions.CombatTarget(indra, owner, { boss = true, preserveBring = true })
        return true
    end

    local checkOk, check = invoke(context, "ZQuestProgress", "Check")
    if not isTaskCurrent(context, owner) then
        return false
    end
    if checkOk and check == nil then
        resetIndraBranch(state)
        local donSwan = context.Functions.GetLiveBoss("Don Swan")
        if donSwan then
            state.donSwanMissingSince = nil
            state.status = "Auto Third Sea | Don Swan"
            context.Functions.CombatTarget(donSwan, owner, { boss = true, preserveBring = true })
        else
            local character = context.LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            if not rootPart or not humanoid or humanoid.Health <= 0 then
                state.status = "Auto Third Sea | Respawning for Don Swan"
                return true
            end

            local distance = (rootPart.Position - DON_SWAN_ROOM_CFRAME.Position).Magnitude
            if distance > DON_SWAN_STREAM_DISTANCE then
                state.donSwanMissingSince = nil
                state.status = "Auto Third Sea | Moving to Don Swan"
                context.Functions.TP(DON_SWAN_ROOM_CFRAME, owner, true)
                return true
            end

            state.donSwanMissingSince = state.donSwanMissingSince or os.clock()
            local missingFor = os.clock() - state.donSwanMissingSince
            if missingFor < DON_SWAN_STREAM_SECONDS then
                state.status = string.format(
                    "Auto Third Sea | Streaming Don Swan (%.0fs/%ds)",
                    missingFor,
                    DON_SWAN_STREAM_SECONDS
                )
                context.Functions.StopTween()
                return true
            end

            if os.clock() >= (state.nextDonSwanHopAt or 0) then
                state.nextDonSwanHopAt = os.clock() + DON_SWAN_HOP_COOLDOWN
                state.status = "Auto Third Sea | Hopping for Don Swan"
                context.Functions.StopTween()
                local hopped = context.Functions.HopServer(nil, "third-sea-don-swan-missing")
                state.lastDonSwanHop = { success = hopped, at = os.clock() }
                if not hopped then
                    state.donSwanMissingSince = os.clock()
                end
            else
                state.status = "Auto Third Sea | Waiting Don Swan hop"
            end
        end
        return true
    end

    return runIndraBranch(context)
end
end

local AutoYama
do
AutoYama = {}

local TASK_NAME = "Auto Yama"
local REQUIRED_ELITES = 30
local MAX_LEVEL = 2800

local function refreshEliteProgress(context)
    local state = context.State
    local elites = tonumber(state.eliteProgress)
    if elites == nil and os.clock() >= (state.nextYamaProgressAt or 0) then
        state.nextYamaProgressAt = os.clock() + 10
        local ok, result = pcall(function()
            return context.CommandRemote:InvokeServer("EliteHunter", "Progress")
        end)
        if ok then
            elites = tonumber(result)
            state.eliteProgress = elites or state.eliteProgress
        end
    end
    return tonumber(state.eliteProgress) or elites or 0
end

function AutoYama.shouldSchedule(context)
    if not context.IsSea(3) or context.Level.Value < MAX_LEVEL
        or context.Functions.Owns("Moveset", "Yama")
    then
        return false
    end
    return refreshEliteProgress(context) >= REQUIRED_ELITES
end

function AutoYama.run(context)
    local state = context.State
    if context.TaskQueue:top() ~= TASK_NAME then return false end
    if not AutoYama.shouldSchedule(context) then
        context.TaskQueue:pop(TASK_NAME)
        return false
    end
    if context.TaskQueue:top() ~= TASK_NAME then
        return false
    end

    local map = workspace:FindFirstChild("Map")
    local waterfall = map and map:FindFirstChild("Waterfall")
    local katana = waterfall and waterfall:FindFirstChild("SealedKatana")
    local hitbox = katana and katana:FindFirstChild("Hitbox")
    local detector = hitbox and hitbox:FindFirstChildOfClass("ClickDetector")
    if detector then
        state.status = "Auto Yama | Pulling sword"
        local root = context.LocalPlayer.Character
            and context.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and (root.Position - hitbox.Position).Magnitude > 15 then
            context.Functions.TP(hitbox.CFrame, TASK_NAME, true)
        elseif type(fireclickdetector) == "function" then
            fireclickdetector(detector)
        end
        return true
    end

    if waterfall then
        state.status = "Auto Yama | Loading waterfall"
        context.Functions.TP(waterfall:GetPivot(), TASK_NAME, true)
    end
    return true
end

AutoYama.MAX_LEVEL = MAX_LEVEL
AutoYama.REQUIRED_ELITES = REQUIRED_ELITES
end

local AutoTushita
do
AutoTushita = {}

local TASK_NAME = "Auto Tushita"
local TORCH_ROOM = CFrame.new(5714, 20, 256)

local function request(context, ...)
    local args = table.pack(...)
    return pcall(function()
        return context.CommandRemote:InvokeServer(table.unpack(args, 1, args.n))
    end)
end

local function refreshProgress(context, force)
    local state = context.State
    local now = os.clock()
    if not force and now < (state.nextTushitaProgressAt or 0) then
        return state.tushitaProgress
    end

    state.nextTushitaProgressAt = now + 3
    local ok, result = request(context, "TushitaProgress")
    if ok and type(result) == "table" then
        state.tushitaProgress = result
        state.tushitaDoorOpened = result.OpenedDoor == true
    end
    return state.tushitaProgress
end

function AutoTushita.shouldSchedule(context)
    if not context.IsSea(3) or context.Level.Value < 2000
        or context.Functions.Owns("Moveset", "Tushita")
    then
        return false
    end

    local progress = refreshProgress(context, false) or {}
    if not progress.OpenedDoor then
        return context.Functions.GetLiveBoss("rip_indra True Form") ~= nil
    end
    return context.Functions.GetLiveBoss("Longma") ~= nil
end

function AutoTushita.run(context)
    local state = context.State
    if context.TaskQueue:top() ~= TASK_NAME then return false end
    if not context.IsSea(3) or context.Level.Value < 2000
        or context.Functions.Owns("Moveset", "Tushita")
    then
        context.TaskQueue:pop(TASK_NAME)
        return false
    end

    local progress = refreshProgress(context, false) or {}
    if context.TaskQueue:top() ~= TASK_NAME then
        return false
    end
    local indra = context.Functions.GetLiveBoss("rip_indra True Form")
    if not progress.OpenedDoor and indra then
        state.status = "Auto Tushita | Lighting torches"
        local root = context.LocalPlayer.Character
            and context.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and (root.Position - TORCH_ROOM.Position).Magnitude > 15 then
            context.Functions.TP(TORCH_ROOM, TASK_NAME, true)
            return true
        end
        if context.Functions.Carries("Holy Torch") then
            for index = 1, 5 do
                if context.TaskQueue:top() ~= TASK_NAME then
                    return true
                end
                request(context, "TushitaProgress", "Torch", index)
            end
            state.nextTushitaProgressAt = 0
            state.tushitaProgress = nil
        end
        return true
    end

    local longma = context.Functions.GetLiveBoss("Longma")
    if progress.OpenedDoor and longma then
        state.status = "Auto Tushita | Defeating Longma"
        return context.Functions.CombatTarget(longma, TASK_NAME, {
            boss = true,
            preserveBring = true,
        })
    end

    context.TaskQueue:pop(TASK_NAME)
    return false
end
end

local AutoPirateRaid
do
AutoPirateRaid = {}

local TASK_NAME = "Pirate Raid"
local RAID_CENTER = Vector3.new(-5543.5327148438, 313.80062866211, -2964.2585449219)

local function nearestRaidEnemy(rootPart)
    local nearest, nearestDistance
    local enemies = workspace:FindFirstChild("Enemies")
    for _, enemy in enemies and enemies:GetChildren() or {} do
        local humanoid = enemy:FindFirstChildOfClass("Humanoid")
        local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
        if humanoid and humanoid.Health > 0 and enemyRoot then
            local centerDistance = (enemyRoot.Position - RAID_CENTER).Magnitude
            local playerDistance = (enemyRoot.Position - rootPart.Position).Magnitude
            if centerDistance < 500 and (not nearestDistance or playerDistance < nearestDistance) then
                nearest, nearestDistance = enemy, playerDistance
            end
        end
    end
    return nearest
end

function AutoPirateRaid.run(context)
    if context.TaskQueue:top() ~= TASK_NAME then return false end
    local state = context.State
    local root = context.LocalPlayer.Character
        and context.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return true end

    local enemy = nearestRaidEnemy(root)
    if enemy then
        state.status = "Pirate Raid | Defeating " .. enemy.Name
        return context.Functions.CombatTarget(enemy, TASK_NAME, {
            preserveBring = true,
            bringRadius = 500,
        })
    end

    state.status = "Pirate Raid | Moving to Castle"
    context.Functions.TP(CFrame.new(RAID_CENTER), TASK_NAME, true)
    return true
end
end

local AutoTyrantBoss
do
AutoTyrantBoss = {}

local TASK_NAME = "Tyrant Boss"
local EYE_POINTS = {
    CFrame.new(-16335.1, 158.1, 1465.6),
    CFrame.new(-16288.6, 158.1, 1470.3),
    CFrame.new(-16258, 156.7, 1461.4),
    CFrame.new(-16212.4, 158.1, 1466.3),
    CFrame.new(-16335, 159.3, 1324.8),
    CFrame.new(-16286, 155.9, 1323.8),
    CFrame.new(-16250.3, 159.3, 1316.3),
}
local MINIONS = {
    "Isle Outlaw", "Island Boy", "Isle Champion",
    "Sun-kissed Warrior", "Serpent Hunter", "Skull Slayer",
}

local function getEyesCount()
    local map = workspace:FindFirstChild("Map")
    local tiki = map and map:FindFirstChild("TikiOutpost")
    local island = tiki and tiki:FindFirstChild("IslandModel")
    if not island then return 0 end

    local chunks = island:FindFirstChild("IslandChunks")
    local section = chunks and chunks:FindFirstChild("E")
    local eyes = {
        island:FindFirstChild("Eye1"),
        island:FindFirstChild("Eye2"),
        section and section:FindFirstChild("Eye3"),
        section and section:FindFirstChild("Eye4"),
    }
    local count = 0
    for _, eye in eyes do
        if eye and eye.Transparency == 0 then count += 1 end
    end
    return count
end

local function queryDeathStep(context)
    local ok, result = pcall(function()
        return context.CommandRemote:InvokeServer("BuyDeathStep", true)
    end)
    return ok and result or nil
end

function AutoTyrantBoss.run(context)
    if context.TaskQueue:top() ~= TASK_NAME then return false end
    local state = context.State
    if not context.IsSea(3) or context.Level.Value < 2400
        or context.Functions.Owns("Material", "Fire Feather")
    then
        context.TaskQueue:pop(TASK_NAME)
        return false
    end

    if not context.Functions.Owns("Moveset", "Death Step")
        and type(queryDeathStep(context)) == "number"
    then
        state.status = "Tyrant Boss | Buying Death Step"
        pcall(function() context.CommandRemote:InvokeServer("BuyDeathStep") end)
        return true
    end

    local eyeCount = getEyesCount()
    if eyeCount == 4 then
        local point = EYE_POINTS[1]
        local root = context.LocalPlayer.Character
            and context.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        state.status = "Tyrant Boss | Collecting eyes"
        if root and (root.Position - point.Position).Magnitude > 15 then
            context.Functions.TP(point, TASK_NAME, true)
        elseif type(context.Functions.SendKey) == "function" then
            context.Functions.SendKey(({ "Z", "X", "C" })[math.random(1, 3)], 0.31)
        end
        return true
    end

    local tyrant = context.Functions.GetLiveBoss("Tyrant of the Skies")
    if tyrant then
        state.status = "Tyrant Boss | Defeating boss"
        return context.Functions.CombatTarget(tyrant, TASK_NAME, {
            boss = true,
            preserveBring = true,
        })
    end

    state.status = "Tyrant Boss | Defeating minions"
    return context.Functions.FarmMob(MINIONS, TASK_NAME, true, 2400)
end
end

local AutoSoulGuitar
do
AutoSoulGuitar = {}

local TASK_NAME = "Auto Soul Guitar"
local GRAVESTONE = CFrame.new(-8654, 140, 6167)
local TABLET = CFrame.new(-9530.0126953125, 6.104853630065918, 6054.83349609375)
local SHIP_MOBS = { "Ship Deckhand", "Ship Engineer", "Ship Steward", "Ship Officer" }
local PLACARDS = {
    Placard1 = "Right", Placard2 = "Right", Placard3 = "Left",
    Placard4 = "Right", Placard5 = "Left", Placard6 = "Left", Placard7 = "Left",
}
local BLANK_TABLETS = { "Segment6", "Segment2", "Segment8", "Segment9", "Segment5" }
local TROPHIES = {
    Segment1 = "Trophy1", Segment3 = "Trophy2", Segment4 = "Trophy3",
    Segment7 = "Trophy4", Segment10 = "Trophy5",
}
local PIPE_COLORS = {
    Part1 = "Really black", Part2 = "Really black", Part3 = "Dusty Rose",
    Part4 = "Storm blue", Part5 = "Really black", Part6 = "Parsley green",
    Part7 = "Really black", Part8 = "Dusty Rose", Part9 = "Really black",
    Part10 = "Storm blue",
}

local function invoke(context, ...)
    local args = table.pack(...)
    return pcall(function()
        return context.CommandRemote:InvokeServer(table.unpack(args, 1, args.n))
    end)
end

local function materialCount(context, name)
    local item = context.Inventory.Material and context.Inventory.Material[name]
    return type(item) == "table" and tonumber(item.Count) or item == true and 1 or 0
end

local function isFullMoon()
    local lighting = game:GetService("Lighting")
    local sky = lighting:FindFirstChildOfClass("Sky")
    if not sky or sky.MoonTextureId ~= "http://www.roblox.com/asset/?id=9709149431" then
        return false
    end
    return lighting.ClockTime > 18 or lighting.ClockTime < 5
end

local function click(detector)
    if detector and type(fireclickdetector) == "function" then
        fireclickdetector(detector)
        return true
    end
    return false
end

local function rootPart(context)
    local character = context.LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function collectChest(context)
    local root = rootPart(context)
    if not root then return true end
    local tagged = game:GetService("CollectionService"):GetTagged("_ChestTagged")
    local candidates = {}
    for _, chest in tagged do
        if chest:IsA("BasePart") and chest.Name:find("Chest") and chest.CanTouch then
            table.insert(candidates, { object = chest, distance = (chest.Position - root.Position).Magnitude })
        end
    end
    table.sort(candidates, function(a, b) return a.distance < b.distance end)

    local state = context.State
    state.soulGuitarChestCount = state.soulGuitarChestCount or 0
    if #candidates == 0 or state.soulGuitarChestCount >= 20 then
        state.status = "Soul Guitar | Hopping for chests"
        context.Functions.HopServer(nil, true)
        return true
    end

    local chest = candidates[1].object
    state.status = ("Soul Guitar | Chest %d/20"):format(state.soulGuitarChestCount)
    if (root.Position - chest.Position).Magnitude > 12 then
        context.Functions.TP(chest.CFrame, TASK_NAME, true)
    elseif type(firetouchinterest) == "function" then
        firetouchinterest(root, chest, 0)
        firetouchinterest(root, chest, 1)
        state.soulGuitarChestCount += 1
    end
    return true
end

local function refreshStage(context)
    if context.Functions.Owns("Moveset", "Skull Guitar") then return nil end
    if not context.Functions.Owns("Material", "Dark Fragment") then return 10 end
    if materialCount(context, "Ectoplasm") < 250 then return 2 end
    if not context.IsSea(3) then return nil end

    local ok, progress = invoke(context, "GuitarPuzzleProgress", "Check")
    if not ok then return nil end
    context.State.soulGuitarProgress = progress
    if type(progress) ~= "table" then return 8 end
    if not progress.Swamp then return 3 end
    if not progress.Gravestones then return 4 end
    if not progress.Ghost then return 5 end
    if not progress.Trophies then return 6 end
    if not progress.Pipes then return 7 end
    if materialCount(context, "Bones") >= 500 then return 9 end
    return nil
end

local function solvePlacards()
    local map = workspace:FindFirstChild("Map")
    local castle = map and map:FindFirstChild("Haunted Castle")
    if not castle then return false end
    for placard, side in PLACARDS do
        local model = castle:FindFirstChild(placard)
        local target = model and model:FindFirstChild(side)
        click(target and target:FindFirstChildOfClass("ClickDetector"))
    end
    return true
end

local function solveTrophies()
    local map = workspace:FindFirstChild("Map")
    local castle = map and map:FindFirstChild("Haunted Castle")
    local tablet = castle and castle:FindFirstChild("Tablet")
    local trophies = castle and castle:FindFirstChild("Trophies")
    trophies = trophies and trophies:FindFirstChild("Quest")
    if not tablet or not trophies then return false end

    for _, segmentName in BLANK_TABLETS do
        local segment = tablet:FindFirstChild(segmentName)
        local line = segment and segment:FindFirstChild("Line")
        local detector = segment and segment:FindFirstChildOfClass("ClickDetector")
        local attempts = 0
        while line and math.abs(line.Rotation.Z) > 0.1 and attempts < 6 do
            click(detector)
            attempts += 1
            task.wait(0.1)
        end
    end

    for segmentName, trophyName in TROPHIES do
        local segment = tablet:FindFirstChild(segmentName)
        local trophy = trophies:FindFirstChild(trophyName)
        local handle = trophy and trophy:FindFirstChild("Handle")
        local line = segment and segment:FindFirstChild("Line")
        local detector = segment and segment:FindFirstChildOfClass("ClickDetector")
        if handle and line and detector then
            local component = tostring(handle.CFrame):split(", ")[4]
            local wanted = (component == "1" or component == "-1") and 90 or 180
            local attempts = 0
            while math.abs(math.abs(line.Rotation.Z) - wanted) > 0.1 and attempts < 6 do
                click(detector)
                attempts += 1
                task.wait(0.1)
            end
        end
    end
    return true
end

local function solvePipes()
    local map = workspace:FindFirstChild("Map")
    local castle = map and map:FindFirstChild("Haunted Castle")
    local lab = castle and castle:FindFirstChild("Lab Puzzle")
    local floor = lab and lab:FindFirstChild("ColorFloor")
    local model = floor and floor:FindFirstChild("Model")
    if not model then return false end
    for partName, colorName in PIPE_COLORS do
        local part = model:FindFirstChild(partName)
        local detector = part and part:FindFirstChildOfClass("ClickDetector")
        local attempts = 0
        while part and part.BrickColor.Name ~= colorName and attempts < 8 do
            click(detector)
            attempts += 1
            task.wait(0.1)
        end
    end
    return true
end

function AutoSoulGuitar.run(context)
    if context.TaskQueue:top() ~= TASK_NAME then return false end
    local state = context.State
    local stage = refreshStage(context)
    state.soulGuitarStage = stage
    if not stage then
        context.TaskQueue:pop(TASK_NAME)
        return false
    end

    if stage == 10 then
        if not context.IsSea(2) then
            state.status = "Soul Guitar | Traveling for Dark Fragment"
            invoke(context, "TravelDressrosa")
            return true
        end
        local darkbeard = context.Functions.GetLiveBoss("Darkbeard")
        if darkbeard then
            state.status = "Soul Guitar | Defeating Darkbeard"
            return context.Functions.CombatTarget(darkbeard, TASK_NAME, { boss = true, preserveBring = true })
        end
        local fist = context.Functions.Carries("Fist of Darkness")
        if fist then
            local map = workspace:FindFirstChild("Map")
            local arena = map and map:FindFirstChild("DarkbeardArena")
            local summoner = arena and arena:FindFirstChild("Summoner")
            local detection = summoner and summoner:FindFirstChild("Detection")
            state.status = "Soul Guitar | Summoning Darkbeard"
            local root = rootPart(context)
            if detection and root and (root.Position - detection.Position).Magnitude > 12 then
                context.Functions.TP(detection.CFrame, TASK_NAME, true)
            elseif detection and root and type(firetouchinterest) == "function" then
                firetouchinterest(detection, root, 0)
                task.wait(0.2)
                firetouchinterest(detection, root, 1)
            end
            return true
        end
        return collectChest(context)
    elseif stage == 2 then
        if not context.IsSea(2) then
            state.status = "Soul Guitar | Traveling for Ectoplasm"
            invoke(context, "TravelDressrosa")
            return true
        end
        state.status = "Soul Guitar | Farming Ectoplasm"
        return context.Functions.FarmMob(SHIP_MOBS, TASK_NAME, true)
    elseif stage == 8 then
        if not isFullMoon() then
            state.status = "Soul Guitar | Waiting full moon"
            return true
        end
        local root = context.LocalPlayer.Character
            and context.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and (root.Position - GRAVESTONE.Position).Magnitude > 5 then
            context.Functions.TP(GRAVESTONE, TASK_NAME, true)
        else
            invoke(context, "gravestoneEvent", 2, true)
        end
        return true
    elseif stage == 3 then
        state.status = "Soul Guitar | Swamp zombies"
        return context.Functions.FarmMob({ "Living Zombie" }, TASK_NAME, true)
    elseif stage == 4 then
        state.status = "Soul Guitar | Gravestones"
        local target = CFrame.new(-8800, 178, 6033)
        local root = rootPart(context)
        if root and (root.Position - target.Position).Magnitude > 10 then
            context.Functions.TP(target, TASK_NAME, true)
        else
            solvePlacards()
        end
    elseif stage == 5 then
        state.status = "Soul Guitar | Ghost"
        invoke(context, "GuitarPuzzleProgress", "Ghost")
    elseif stage == 6 then
        state.status = "Soul Guitar | Trophies"
        local root = rootPart(context)
        if root and (root.Position - TABLET.Position).Magnitude > 10 then
            context.Functions.TP(TABLET, TASK_NAME, true)
        else
            solveTrophies()
        end
    elseif stage == 7 then
        state.status = "Soul Guitar | Pipes"
        solvePipes()
        invoke(context, "soulGuitarBuy")
    elseif stage == 9 then
        state.status = "Soul Guitar | Buying"
        invoke(context, "soulGuitarBuy")
    end
    state.nextSoulGuitarRefreshAt = os.clock() + 1
    return true
end
end

local AutoFactory
do
AutoFactory = {}

local FACTORY_WAIT_CFRAME = CFrame.new(428.35, 208.86, -429.03)
local FACTORY_ROUTE_SPEED = 480
local WARNING_LIFETIME = 75
local CORE_MISSING_GRACE = 4
local REWARD_WINDOW_SECONDS = 12
local COMPLETED_DOOR_SUPPRESS_SECONDS = 20

local function isFactoryMessage(text)
    text = tostring(text or ""):lower()
    if text:find("factory", 1, true) then
        return text:find("30", 1, true) ~= nil
            or text:find("breach", 1, true) ~= nil
    end
    local vietnameseFactory = "m\195\161y"
    return text:find("30", 1, true) ~= nil
        and text:find(vietnameseFactory, 1, true) ~= nil
end

function AutoFactory.markWarning(state, source, text)
    local now = os.clock()
    state.factoryWarningAt = now
    state.factoryWarningUntil = now + WARNING_LIFETIME
    state.factorySignal = source
    state.factorySignalText = tostring(text or "")
    state.factoryActive = true
    state.nearbyPlayerSamples = {}
end

local function disconnect(connection)
    if connection then
        pcall(connection.Disconnect, connection)
    end
end

local function removeTextLabel(session, label)
    disconnect(session.textConnections[label])
    disconnect(session.destroyConnections[label])
    session.textConnections[label] = nil
    session.destroyConnections[label] = nil
end

local function detachWatchers(state)
    local session = state.factoryWatcherSession
    state.factoryWatcherSession = nil
    state.factoryWatchersReady = nil
    state.factoryWatcherCleanup = nil
    if not session then
        disconnect(state.factoryNotificationConnection)
        disconnect(state.factoryEnemyConnection)
        for _, connection in state.factoryTextConnections or {} do
            disconnect(connection)
        end
        state.factoryNotificationConnection = nil
        state.factoryEnemyConnection = nil
        state.factoryTextConnections = nil
        return
    end
    disconnect(session.added)
    disconnect(session.removing)
    disconnect(session.enemyAdded)
    for label in session.textConnections do
        removeTextLabel(session, label)
    end
    state.factoryNotificationConnection = nil
    state.factoryEnemyConnection = nil
    state.factoryTextConnections = nil
end

local function currentSession(state, session)
    return not state.stopped and state.factoryWatcherSession == session
end

local function watchTextLabel(state, session, label)
    if not label:IsA("TextLabel") and not label:IsA("TextButton") then
        return
    end
    if not currentSession(state, session) or session.textConnections[label]
        or not label:IsDescendantOf(session.stack)
    then
        return
    end
    local function inspect()
        if currentSession(state, session) and label:IsDescendantOf(session.stack)
            and isFactoryMessage(label.Text)
        then
            AutoFactory.markWarning(state, "notification", label.Text)
        end
    end
    inspect()
    session.textConnections[label] = label:GetPropertyChangedSignal("Text"):Connect(inspect)
    session.destroyConnections[label] = label.Destroying:Connect(function()
        removeTextLabel(session, label)
    end)
end

local function ensureWatchers(context)
    local state = context.State
    local playerGui = context.LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local notifications = playerGui and playerGui:FindFirstChild("Notifications")
    local stack = notifications and notifications:FindFirstChild("NotificationStack")
    local enemies = workspace:FindFirstChild("Enemies")
    local previous = state.factoryWatcherSession
    if previous and previous.stack == stack and previous.enemies == enemies then
        return
    end
    detachWatchers(state)
    local session = { stack = stack, enemies = enemies, textConnections = {}, destroyConnections = {} }
    state.factoryWatcherSession = session
    state.factoryTextConnections = session.textConnections
    state.factoryWatchersReady = stack ~= nil and enemies ~= nil
    state.factoryWatcherCleanup = function()
        detachWatchers(state)
    end
    if stack then
        for _, descendant in stack:GetDescendants() do
            watchTextLabel(state, session, descendant)
        end
        session.added = stack.DescendantAdded:Connect(function(descendant)
            watchTextLabel(state, session, descendant)
        end)
        session.removing = stack.DescendantRemoving:Connect(function(descendant)
            removeTextLabel(session, descendant)
        end)
        state.factoryNotificationConnection = session.added
    end

    if enemies then
        session.enemyAdded = enemies.ChildAdded:Connect(function(enemy)
            if currentSession(state, session)
                and (enemy.Name == "Core" or enemy.Name:match("^Core%s"))
            then
                AutoFactory.markWarning(state, "core-added", enemy.Name)
            end
        end)
        state.factoryEnemyConnection = session.enemyAdded
    end
end

local function liveCore()
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then
        return nil
    end
    for _, enemy in enemies:GetChildren() do
        if enemy.Name == "Core" or enemy.Name:match("^Core%s") then
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            local root = enemy:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and root then
                return enemy
            end
        end
    end
end

local function factoryDoorOpen()
    local map = workspace:FindFirstChild("Map")
    local dressrosa = map and map:FindFirstChild("Dressrosa")
    local factory = dressrosa and dressrosa:FindFirstChild("SmileFactory")
    local door = factory and factory:FindFirstChild("Door")
    return door and (not door.CanCollide or door.Transparency >= 0.95)
end

local function carriedFruitSnapshot(context)
    local snapshot = {}
    local player = context.LocalPlayer
    for _, root in { player:FindFirstChildOfClass("Backpack"), player.Character } do
        for _, child in root and root:GetChildren() or {} do
            if child:IsA("Tool") and child.Name:match("Fruit$") then
                snapshot[child] = true
            end
        end
    end
    return snapshot
end

local function newFactoryFruit(context, snapshot)
    local player = context.LocalPlayer
    for _, root in { player:FindFirstChildOfClass("Backpack"), player.Character } do
        for _, child in root and root:GetChildren() or {} do
            if child:IsA("Tool") and child.Name:match("Fruit$")
                and not (snapshot and snapshot[child])
            then
                return child
            end
        end
    end
    return nil
end

local function finishFactoryRewardCheck(context)
    local state = context.State
    state.factoryRewardUntil = nil
    state.factoryFruitSnapshot = nil
    state.factoryWarningUntil = nil
    state.factorySignal = nil
    state.factoryActive = false
    state.factoryCoreLastSeenAt = nil
    context.Functions.StopTween()
end

function AutoFactory.run(context)
    local state = context.State
    if state.stopped or not context.IsSea(2) then
        detachWatchers(state)
        state.factoryActive = false
        return false
    end

    ensureWatchers(context)
    local now = os.clock()
    local core = liveCore()
    if core then
        if not state.factoryCoreAlive then
            state.factoryFruitSnapshot = carriedFruitSnapshot(context)
        end
        state.factoryCoreAlive = true
        state.factoryRewardUntil = nil
        state.factoryActive = true
        state.factoryCoreLastSeenAt = now
        state.status = "Auto Farm Level | Factory: attacking Core"
        return context.Functions.CombatTarget(core, "Auto Farm Level", {
            boss = true,
            preserveBring = true,
        })
    end

    if state.factoryCoreAlive then
        state.factoryCoreAlive = false
        state.factoryCompletedAt = now
        state.factoryRewardUntil = now + REWARD_WINDOW_SECONDS
        state.factoryWarningUntil = nil
    end

    if state.factoryRewardUntil then
        if now >= state.factoryRewardUntil then
            state.factoryRewardHandledAt = now
            finishFactoryRewardCheck(context)
            return true
        end
        local fruit = newFactoryFruit(context, state.factoryFruitSnapshot)
        if fruit then
            state.status = "Auto Farm Level | Factory: storing " .. fruit.Name
            local stored = context.Functions.StoreFruit(fruit)
            state.factoryRewardFruit = fruit.Name
            state.factoryRewardStored = stored == true
            if stored then
                state.factoryRewardHandledAt = now
                finishFactoryRewardCheck(context)
            else
                state.factoryActive = true
                state.nearbyPlayerSamples = {}
                state.lastIdlingAt = os.time()
                state.lastIdleProgressKind = "factory-reward"
            end
            return true
        end
        if now < state.factoryRewardUntil then
            state.factoryActive = true
            state.nearbyPlayerSamples = {}
            state.lastIdlingAt = os.time()
            state.lastIdleProgressKind = "factory-reward"
            state.status = "Auto Farm Level | Factory: checking reward"
            return true
        end
        state.factoryRewardHandledAt = now
        finishFactoryRewardCheck(context)
    end

    local completedRecently = now - (state.factoryCompletedAt or -math.huge)
        < COMPLETED_DOOR_SUPPRESS_SECONDS
    if not completedRecently and factoryDoorOpen()
        and now >= (state.nextFactoryDoorSignalAt or 0)
    then
        state.nextFactoryDoorSignalAt = now + 5
        AutoFactory.markWarning(state, "door-open", "")
    end

    local warningActive = now < (state.factoryWarningUntil or 0)
    local recentlySawCore = now - (state.factoryCoreLastSeenAt or -math.huge) < CORE_MISSING_GRACE
    if warningActive or recentlySawCore then
        state.factoryActive = true
        state.nearbyPlayerSamples = {}
        state.lastIdlingAt = os.time()
        state.lastIdleProgressKind = "factory-wait"
        state.status = core and "Auto Farm Level | Factory: attacking Core"
            or "Auto Farm Level | Factory: pre-positioning"
        context.Functions.TP(
            FACTORY_WAIT_CFRAME,
            "Auto Farm Level",
            true,
            nil,
            nil,
            nil,
            FACTORY_ROUTE_SPEED
        )
        return true
    end

    if state.factoryActive then
        state.factoryActive = false
        state.factoryWarningUntil = nil
        state.factorySignal = nil
        context.Functions.StopTween()
    end
    return false
end
end

local ElectricUnlockPolicy
do
ElectricUnlockPolicy = {}

local CLOUD_SCAN_RADIUS = 100
local CLOUD_HOP_SECONDS = 6

function ElectricUnlockPolicy.shouldPrefetch(
    level,
    sea,
    ownsElectro,
    hasLightningBolt,
    hasChargedCloud
)
    return tonumber(level) > 100
        and tonumber(sea) == 1
        and ownsElectro ~= true
        and hasLightningBolt ~= true
        and hasChargedCloud == true
end

function ElectricUnlockPolicy.route(questState, hasLightningBolt, sea)
    questState = tonumber(questState)
    sea = tonumber(sea)

    if questState == 2 then
        return "complete"
    end
    if questState == 6 then
        return "purchase"
    end
    if hasLightningBolt or questState == 0 or questState == 3 or questState == 4 then
        return sea == 2 and "quest" or "travel-sea-2"
    end
    if questState == 1 then
        return sea == 1 and "cloud" or "travel-sea-1"
    end
    return "idle"
end

function ElectricUnlockPolicy.cloudAction(distanceToSky, missingSeconds)
    distanceToSky = tonumber(distanceToSky) or math.huge
    missingSeconds = tonumber(missingSeconds) or 0

    if distanceToSky > CLOUD_SCAN_RADIUS then
        return "travel"
    end
    if missingSeconds >= CLOUD_HOP_SECONDS then
        return "hop"
    end
    return "wait"
end
end

local AutoElectricUnlock
do
AutoElectricUnlock = {}
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MAD_SCIENTIST_BY_SEA = {
    [1] = CFrame.new(-4628.8877, 15.5, -350.8),
    [2] = CFrame.new(-4866.150390625, 33.929847717285, -4767.1025390625),
}
local SKY_AREA_1 = CFrame.new(-4166.6098632812, 1093.6979980469, -347.16226196289)
local QUEST_INTERACTION_DISTANCE = 10
local CLOUD_ATTACK_DISTANCE = 12
local CLOUD_CACHE_SECONDS = 6

local function isTaskCurrent(context, owner)
    local functions = context.Functions
    if functions and type(functions.IsTaskCurrent) == "function" then
        return functions.IsTaskCurrent(owner)
    end
    local state = context.State or {}
    return not state.stopped
        and not state.paused
        and context.TaskQueue:top() == owner
end

local function currentSea(context)
    for sea = 1, 3 do
        if context.IsSea(sea) then
            return sea
        end
    end
    return 0
end

local function characterParts(context)
    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 then
        return nil
    end
    return character, humanoid, root
end

local function inventoryHas(context, name)
    local player = context.LocalPlayer
    local backpack = player:FindFirstChildOfClass("Backpack")
    if player.Character and player.Character:FindFirstChild(name) then
        return true, "character"
    end
    if backpack and backpack:FindFirstChild(name) then
        return true, "backpack"
    end

    for categoryName, category in context.Inventory or {} do
        local item = type(category) == "table" and category[name]
        if item == true then
            return true, "inventory:" .. tostring(categoryName)
        end
        if type(item) == "table" then
            local count = tonumber(item.Count or item.count or item.Amount or item.amount
                or item.Value or item.value)
            if count == nil or count > 0 then
                return true, "inventory:" .. tostring(categoryName)
            end
        end
    end
    return false, "missing"
end

local function ensureInventoryReady(context)
    local state = context.State
    if state.inventoryReady then
        return true
    end

    local now = os.clock()
    if now >= (state.nextElectricInventoryRefreshAt or 0) then
        state.nextElectricInventoryRefreshAt = now + 2
        local ok, result = pcall(context.Functions.RefreshInventory, true)
        state.lastElectricInventoryGate = {
            at = now,
            ok = ok,
            result = tostring(result),
            ready = state.inventoryReady == true,
        }
    end

    if not state.inventoryReady then
        state.electricUnlockPhase = "waiting-inventory"
        state.status = "Material Farming | Electro | Waiting inventory"
        context.Functions.CancelTween()
        return false
    end
    return true
end

local function recordRouteDecision(state, questState, sea, hasBolt, boltSource, route)
    local previous = state.lastElectricUnlockDecision
    if previous and previous.questState == questState and previous.sea == sea
        and previous.hasLightningBolt == hasBolt and previous.route == route
    then
        return
    end

    local decision = {
        at = os.clock(),
        questState = questState,
        sea = sea,
        hasLightningBolt = hasBolt,
        lightningBoltSource = boltSource,
        route = route,
    }
    state.lastElectricUnlockDecision = decision
    state.electricUnlockHistory = state.electricUnlockHistory or {}
    table.insert(state.electricUnlockHistory, decision)
    while #state.electricUnlockHistory > 32 do
        table.remove(state.electricUnlockHistory, 1)
    end
end

local function findMadScientist(context)
    local npcManagerModule = ReplicatedStorage:FindFirstChild("NPCManager")
    if npcManagerModule then
        local ok, manager = pcall(require, npcManagerModule)
        if ok and type(manager) == "table" and type(manager.getNPCsByName) == "function" then
            local listOk, list = pcall(manager.getNPCsByName, "Mad Scientist")
            local npc = listOk and type(list) == "table" and list[1]
            local modelState = npc and npc._modelState
            if modelState and typeof(modelState._targetLocation) == "CFrame" then
                return modelState._targetLocation
            end
            local root = modelState and modelState._rootPart
            if typeof(root) == "Instance" and root:IsA("BasePart") then
                return root.CFrame
            end
        end
    end

    for _, container in {
        workspace:FindFirstChild("NPCs"),
        ReplicatedStorage:FindFirstChild("NPCs"),
    } do
        local npc = container and container:FindFirstChild("Mad Scientist")
        if npc and npc:IsA("PVInstance") then
            return npc:GetPivot()
        end
    end
    return MAD_SCIENTIST_BY_SEA[currentSea(context)]
end

local function moveToMadScientist(context, root, owner)
    local scientist = findMadScientist(context)
    if not root or typeof(scientist) ~= "CFrame" then
        return false
    end

    local distance = (root.Position - scientist.Position).Magnitude
    context.State.electricPurchaseNpcDistance = distance
    if distance < QUEST_INTERACTION_DISTANCE then
        return false
    end

    context.State.status = "Material Farming | Electro | Moving to Mad Scientist"
    context.Functions.TP(
        scientist + Vector3.new(0, 5, 3),
        owner or "Auto Farm Level",
        true
    )
    return true
end

local function readQuestState(context, force)
    local state = context.State
    local now = os.clock()
    if not force and now < (state.nextElectroQuestStateAt or 0) then
        return state.electroQuestState
    end

    state.nextElectroQuestStateAt = now + 2
    local ok, result = pcall(function()
        return context.CommandRemote:InvokeServer("ElectroQuestState")
    end)
    if ok and tonumber(result) ~= nil then
        state.electroQuestState = tonumber(result)
    end
    return state.electroQuestState
end

local function issueTravel(context, sea)
    local state = context.State
    local now = os.clock()
    local fromSea = currentSea(context)
    local nextSea = fromSea == 3 and 2 or sea
    local command = nextSea == 1 and "TravelMain" or "TravelDressrosa"
    state.status = "Sea Travel | Melee Material | Lightning Bolt"
    state.electricUnlockPhase = "travel-sea-" .. tostring(sea)
    context.Functions.CancelTween()

    if now < (state.nextElectricTravelAt or 0) then
        return
    end
    state.nextElectricTravelAt = now + 8
    state.worldTravelOwner = "AutoElectricUnlock"
    state.worldTravelDestination = nextSea
    state.worldTravelIssuedAt = now
    local ok, result = pcall(function()
        return context.CommandRemote:InvokeServer(command)
    end)
    state.lastElectricTravel = {
        ok = ok,
        result = tostring(result),
        sea = nextSea,
        destinationSea = sea,
        fromSea = fromSea,
        command = command,
        at = now,
    }
end

local function findChargedCloud(context)
    local state = context.State
    local now = os.clock()
    local map = workspace:FindFirstChild("Map")
    local sky = map and map:FindFirstChild("Sky")
    local cloudPieces = workspace:FindFirstChild("CloudPieces")
    local darkest, darkestColor

    for _, part in CollectionService:GetTagged("M1HitRegistry") do
        local valid = part:IsA("BasePart")
            and part:IsDescendantOf(workspace)
            and string.find(string.lower(part.Name), "cloud", 1, true) ~= nil
            and (sky and part:IsDescendantOf(sky)
                or cloudPieces and part:IsDescendantOf(cloudPieces))
        if valid then
            local colorSum = part.Color.R + part.Color.G + part.Color.B
            if colorSum < 2.88 and (darkestColor == nil or colorSum < darkestColor) then
                darkest = part
                darkestColor = colorSum
            end
        end
    end

    if darkest then
        state.electricCloudInstance = darkest
        state.electricCloudSeenAt = now
    else
        local cached = state.electricCloudInstance
        if not cached or not cached.Parent
            or now - (state.electricCloudSeenAt or 0) > CLOUD_CACHE_SECONDS
        then
            state.electricCloudInstance = nil
            state.electricCloudSeenAt = nil
        end
    end
    return state.electricCloudInstance
end

local function ownsElectro(context)
    return context.Functions.Owns("Moveset", "Electro")
        or context.Functions.Owns("Moveset", "Electric")
end

function AutoElectricUnlock.shouldPrefetch(context)
    local state = context.State
    local level = context.Level and context.Level.Value
    local sea = currentSea(context)
    local hasLightningBolt = inventoryHas(context, "Lightning Bolt")
    local owned = ownsElectro(context)

    if tonumber(level) == nil or tonumber(level) <= 100
        or sea ~= 1
        or owned
        or hasLightningBolt
    then
        state.electricPrefetchPending = nil
        return false
    end

    local cloud = findChargedCloud(context)
    local eligible = ElectricUnlockPolicy.shouldPrefetch(
        level,
        sea,
        owned,
        hasLightningBolt,
        cloud ~= nil
    )

    if not eligible then
        state.electricPrefetchPending = nil
        return false
    end

    return true
end

local function equipElectro(context)
    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local backpack = context.LocalPlayer:FindFirstChildOfClass("Backpack")
    local tool = character and (character:FindFirstChild("Electro") or character:FindFirstChild("Electric"))
        or backpack and (backpack:FindFirstChild("Electro") or backpack:FindFirstChild("Electric"))
    if tool and humanoid and tool.Parent ~= character then
        humanoid:EquipTool(tool)
        task.wait(0.05)
    end
    return tool ~= nil
end

local function attackCloud(context, cloud)
    local state = context.State
    if os.clock() < (state.nextElectricCloudAttackAt or 0) then
        return
    end
    state.nextElectricCloudAttackAt = os.clock() + 0.35
    context.SetCurrentWeaponType("Melee")
    context.Functions.LoadTools()
    context.Functions.EquipWeapon("Melee")
    context.Functions.AutoBuso()
    context.RegisterAttackRemote:FireServer(0.4)
    context.RegisterHitRemote:FireServer(cloud, {})
end

local function finishElectro(context, owner)
    local state = context.State
    state.electricUnlockNeeded = nil
    state.electricUnlockActive = nil
    state.electricUnlockPhase = "complete"
    state.meleeMastery = state.meleeMastery or {}
    state.meleeMastery.Electro = math.max(state.meleeMastery.Electro or 0, 1)
    context.Functions.CancelTween()

    if equipElectro(context) then
        state.electricEquipPending = nil
        return "busy"
    end
    if context.Beli.Value < 500000 then
        state.electricEquipPending = nil
        return false
    end
    local _, _, root = characterParts(context)
    if moveToMadScientist(context, root, owner) then
        return "busy"
    end
    if os.clock() >= (state.nextElectricPurchaseAt or 0) then
        state.nextElectricPurchaseAt = os.clock() + 2
        local ok, result = pcall(function()
            return context.CommandRemote:InvokeServer("BuyElectro")
        end)
        state.lastElectricPurchase = { ok = ok, result = tostring(result), at = os.clock() }
        task.wait(0.2)
        if not isTaskCurrent(context, owner) then
            return "busy"
        end
        context.Functions.LoadTools()
        if equipElectro(context) then
            state.electricEquipPending = nil
        end
    end
    return "busy"
end

local function runPurchaseBranch(context, root, owner)
    local state = context.State
    state.electricUnlockPhase = "purchase"
    state.status = "Material Farming | Electro | Buying Electric"
    context.Functions.CancelTween()

    if context.Beli.Value < 500000 then
        state.status = string.format(
            "Auto Farm Level | Saving for Electric (%d/500000 Beli)",
            context.Beli.Value
        )
        return false
    end

    if moveToMadScientist(context, root, owner) then
        return "busy"
    end

    local now = os.clock()
    if now < (state.nextElectricPurchaseAt or 0) then
        return "busy"
    end
    state.nextElectricPurchaseAt = now + 4

    local probeOk, probeResult = pcall(function()
        return context.CommandRemote:InvokeServer("BuyElectro", true)
    end)
    if not isTaskCurrent(context, owner) then
        return "busy"
    end
    local buyOk, buyResult = pcall(function()
        return context.CommandRemote:InvokeServer("BuyElectro")
    end)
    local resultCode = buyOk and tonumber(buyResult) or nil
    state.lastElectricPurchase = {
        probeOk = probeOk,
        probeResult = tostring(probeResult),
        ok = buyOk,
        result = tostring(buyResult),
        at = now,
    }
    if not isTaskCurrent(context, owner) then
        return "busy"
    end

    if resultCode == 1 or resultCode == 2 then
        task.wait(0.2)
        if not isTaskCurrent(context, owner) then
            return "busy"
        end
        context.Functions.LoadTools()
        state.nextElectroQuestStateAt = 0
        local questState = readQuestState(context, true)
        if not isTaskCurrent(context, owner) then
            return "busy"
        end
        if questState == 2 or equipElectro(context) then
            return finishElectro(context, owner)
        end
        state.status = "Material Farming | Electro | Waiting for Electric tool"
        return "busy"
    end

    state.nextElectroQuestStateAt = 0
    local questState = readQuestState(context, true)
    if not isTaskCurrent(context, owner) then
        return "busy"
    end
    if questState == 2 then
        return finishElectro(context)
    end
    if resultCode == 3 then
        state.status = "Auto Farm Level | Saving for Electric (purchase rejected)"
        return false
    end
    if resultCode == 4 then
        state.status = "Material Farming | Electro | Waiting for combat to end"
        return "busy"
    end
    if resultCode == 0 then
        state.status = "Material Farming | Electro | Lightning Bolt required"
        return "busy"
    end
    if not probeOk or not buyOk then
        state.status = "Material Farming | Electro | Purchase request failed"
    else
        state.status = "Material Farming | Electro | Purchase pending"
    end
    return "busy"
end

local function runQuestBranch(context, root, owner)
    local state = context.State
    local scientist = findMadScientist(context)
    state.electricUnlockPhase = "electro-quest"
    state.status = "Material Farming | Electro | Lightning Bolt Quest"
    if (root.Position - scientist.Position).Magnitude >= QUEST_INTERACTION_DISTANCE then
        context.Functions.TP(
            scientist + Vector3.new(0, 5, 3),
            owner,
            true
        )
        return "busy"
    end

    context.Functions.CancelTween()
    if os.clock() < (state.nextElectricQuestActionAt or 0) then
        return "busy"
    end
    state.nextElectricQuestActionAt = os.clock() + 2
    local response = readQuestState(context, true)
    if not isTaskCurrent(context, owner) then
        return "busy"
    end
    if response == 0 then
        pcall(function()
            context.CommandRemote:InvokeServer("AcceptElectroQuest")
        end)
        task.wait(0.5)
        if not isTaskCurrent(context, owner) then
            return "busy"
        end
        response = readQuestState(context, true)
    end
    if response == 3 or response == 4 or inventoryHas(context, "Lightning Bolt") then
        pcall(function()
            context.CommandRemote:InvokeServer("DeliverLightningBolt")
        end)
        state.nextElectroQuestStateAt = 0
        state.nextMeleeElectroQuestProbeAt = 0
    end
    return "busy"
end

local function runCloudBranch(context, root, owner)
    local state = context.State
    local cloud = findChargedCloud(context)
    if not cloud or not cloud.Parent then
        local now = os.clock()
        local staging = SKY_AREA_1 + Vector3.new(0, 20, 0)
        local distanceToSky = (root.Position - staging.Position).Magnitude
        local missingFor = state.electricCloudMissingSince
            and now - state.electricCloudMissingSince
            or 0
        local action = ElectricUnlockPolicy.cloudAction(distanceToSky, missingFor)

        if action == "travel" then
            state.electricUnlockPhase = "travel-cloud-area"
            state.electricCloudMissingSince = nil
            state.status = "Material Farming | Electro | Moving to charged cloud area"
            context.Functions.TP(staging, owner, true)
            return "busy"
        end

        state.electricUnlockPhase = "scan-cloud"
        state.electricCloudMissingSince = state.electricCloudMissingSince or now
        state.status = "Material Farming | Electro | Waiting charged cloud"
        context.Functions.CancelTween()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        missingFor = now - state.electricCloudMissingSince
        action = ElectricUnlockPolicy.cloudAction(distanceToSky, missingFor)
        if action == "hop" and now >= (state.nextElectricCloudHopAt or 0) then
            state.nextElectricCloudHopAt = os.clock() + 30
            context.Functions.HopServer(5, "electro-cloud-missing")
        end
        return "busy"
    end

    state.electricUnlockPhase = "attack-cloud"
    state.electricCloudMissingSince = nil
    state.status = "Material Farming | Electro | Lightning Bolt"
    local destination = cloud.CFrame
        + Vector3.new(0, math.min(cloud.Size.Y / 2 + 5, 90), 0)
    if (root.Position - destination.Position).Magnitude >= CLOUD_ATTACK_DISTANCE then
        context.Functions.TP(destination, owner, true)
        return "busy"
    end
    context.Functions.CancelTween()
    attackCloud(context, cloud)
    return "busy"
end

function AutoElectricUnlock.runPrefetch(context, taskName)
    local state = context.State
    local owner = taskName or context.TaskQueue:top() or "Melee Materials"
    if not isTaskCurrent(context, owner) then
        return false
    end
    if not AutoElectricUnlock.shouldPrefetch(context) then
        return false
    end

    local _, _, root = characterParts(context)
    if not root then
        state.status = "Material Farming | Electro | Waiting character"
        return "busy"
    end
    if not ensureInventoryReady(context) then
        return "busy"
    end

    state.electricUnlockPhase = "prefetch-lightning-bolt"
    return runCloudBranch(
        context,
        root,
        owner
    )
end

function AutoElectricUnlock.run(context, taskName)
    local state = context.State
    local owner = taskName or context.TaskQueue:top() or "Auto Farm Level"
    if not isTaskCurrent(context, owner) then
        return false
    end
    if not state.electricUnlockNeeded and not state.electricEquipPending then
        return false
    end

    local _, _, root = characterParts(context)
    if not root then
        state.status = "Material Farming | Electro | Waiting character"
        return "busy"
    end

    if not ensureInventoryReady(context) then
        return "busy"
    end

    local questState = readQuestState(context)
    if not isTaskCurrent(context, owner) then
        return false
    end
    local hasLightningBolt, lightningBoltSource = inventoryHas(context, "Lightning Bolt")
    local sea = currentSea(context)
    local route = ElectricUnlockPolicy.route(
        questState,
        hasLightningBolt,
        sea
    )
    state.electricUnlockRoute = route
    recordRouteDecision(
        state,
        questState,
        sea,
        hasLightningBolt,
        lightningBoltSource,
        route
    )

    if route == "complete" then
        return finishElectro(context, owner)
    elseif route == "purchase" then
        return runPurchaseBranch(context, root, owner)
    elseif route == "travel-sea-2" then
        issueTravel(context, 2)
        return "busy"
    elseif route == "travel-sea-1" then
        issueTravel(context, 1)
        return "busy"
    elseif route == "quest" then
        return runQuestBranch(context, root, owner)
    elseif route == "cloud" then
        return runCloudBranch(context, root, owner)
    end

    state.status = "Material Farming | Electro | Waiting quest state"
    return false
end
end

local AutoMeleeProgress
do
AutoMeleeProgress = {}
local MASTERY_FILE_PREFIX = "seahub_melee_progress_"
local MASTERY_STATE_VERSION = 5
local HttpService = game:GetService("HttpService")

local STYLES = {
    {
        name = "Black Leg", display = "Dark Step", goal = 400,
        command = "BuyBlackLeg", npc = "Dark Step Teacher", minSea = 1, price = 150000,
        purchaseSeas = { [1] = true, [2] = true }, preferredPurchaseSea = 1,
        purchaseCFrames = {
            [2] = CFrame.new(-4752.4321289062, 33.929847717285, -4848.0390625),
            [3] = CFrame.new(-5045.60205078125, 370.010986328125, -3182.304931640625),
        },
    },
    {
        name = "Electro", display = "Electric", goal = 400,
        command = "BuyElectro", npc = "Mad Scientist", minSea = 1, price = 500000,
        purchaseSeas = { [1] = true }, preferredPurchaseSea = 1,
        purchaseCFrames = {
            [2] = CFrame.new(-4866.150390625, 33.929847717285, -4767.1025390625),
            [3] = CFrame.new(-4996.0517578125, 313.2139587402344, -3201.82373046875),
        },
    },
    {
        name = "Fishman Karate", display = "Water Kung Fu", goal = 400,
        command = "BuyFishmanKarate", npc = "Water Kung-fu Teacher",
        minSea = 1, price = 750000,
        purchaseSeas = { [1] = true, [2] = true }, preferredPurchaseSea = 2,
        purchaseCFrames = {
            [2] = CFrame.new(-4957.6704101562, 35.949836730957, -4665.599609375),
            [3] = CFrame.new(-5023.9091796875, 371.0299987792969, -3191.45751953125),
        },
    },
    {
        name = "Dragon Claw", display = "Dragon Breath", goal = 400,
        command = "BlackbeardReward", args = { "DragonClaw", "2" },
        npc = "Sabi", minSea = 2, fragments = 1500,
        purchaseSeas = { [2] = true, [3] = true }, preferredPurchaseSea = 2,
        purchaseCFrames = {
            [2] = CFrame.new(699.02899169922, 185.6609954834, 654.89501953125),
            [3] = CFrame.new(-4981.162109375, 370.010986328125, -3208.3388671875),
        },
    },
    {
        name = "Superhuman", goal = 400, command = "BuySuperhuman",
        npc = "Martial Arts Master", minSea = 2, price = 3000000,
        purchaseSeas = { [2] = true, [3] = true }, preferredPurchaseSea = 2,
        purchaseCFrames = {
            [2] = CFrame.new(1377.125, 246.54200744629, -5189.951171875),
            [3] = CFrame.new(-5004.72119140625, 370.42333984375, -3198.915283203125),
        },
    },
    {
        name = "Death Step", goal = 400, command = "BuyDeathStep",
        npc = "Phoeyu, the Reformed", minSea = 2, price = 2500000, fragments = 5000,
        key = "Library Key", boss = "Awakened Ice Admiral",
        bossCFrame = CFrame.new(6407, 340, -6892),
        purchaseSeas = { [2] = true, [3] = true }, preferredPurchaseSea = 2,
        purchaseCFrames = {
            [2] = CFrame.new(6356.4721679688, 296.10000610352, -6762.7709960938),
            [3] = CFrame.new(-4999.23046875, 314.01449584961, -3221.572265625),
        },
    },
    {
        name = "Sharkman Karate", goal = 400, command = "BuySharkmanKarate",
        npc = "Sharkman Teacher", minSea = 2, price = 2500000, fragments = 5000,
        key = "Water Key", boss = "Tide Keeper",
        bossCFrame = CFrame.new(-3570, 123, -11555),
        purchaseSeas = { [2] = true, [3] = true }, preferredPurchaseSea = 2,
        purchaseCFrames = {
            [2] = CFrame.new(-2599.6218261719, 238.19833374023, -10315.998046875),
            [3] = CFrame.new(-4971.2060546875, 313.8869323730469, -3223.0791015625),
        },
    },
    {
        name = "Electric Claw", goal = 400, command = "BuyElectricClaw",
        npc = "Previous Hero", minSea = 3, price = 3000000, fragments = 5000,
        purchaseSeas = { [3] = true }, preferredPurchaseSea = 3,
        purchaseCFrames = {
            [3] = CFrame.new(-10371.4716796875, 330.76400756836, -10131.419921875),
        },
    },
    {
        name = "Dragon Talon", goal = 400, command = "BuyDragonTalon",
        npc = "Uzoth", minSea = 3, price = 3000000, fragments = 5000,
        purchaseSeas = { [3] = true }, preferredPurchaseSea = 3,
        purchaseCFrames = {
            [3] = CFrame.new(5661.89794921875, 1210.876953125, 863.176025390625),
        },
    },
}

local LEGENDARY_SWORD_MASTERY = 350
local LEGENDARY_SWORDS = { "Yama", "Tushita" }
local PREREQUISITE_ARENA_RADIUS = 450
local PREREQUISITE_LOOT_GRACE = 5
local PREREQUISITE_HOP_AFTER = 90
local PREREQUISITE_HOP_COOLDOWN = 120
local PURCHASE_RETRY_SECONDS = 2
local PURCHASE_RETRY_INTERVAL = 0.5
local PURCHASE_NPC_DISTANCE = 15
local DRAGON_TALON_PROBE_INTERVAL = 5
local GODHUMAN_PURCHASE_STYLE = {
    name = "Godhuman",
    display = "Godhuman",
    npc = "Ancient Monk",
    purchaseCFrames = {
        [3] = CFrame.new(-13774.0908203125, 333.73300170898, -9879.9072265625),
    },
}

local GODHUMAN_MATERIALS = {
    { name = "Fish Tail", count = 20, sea = 3 },
    { name = "Dragon Scale", count = 10, sea = 3 },
    { name = "Mystic Droplet", count = 10, sea = 2 },
    { name = "Magma Ore", count = 20, sea = 2 },
}

local function masteryFile(context)
    return MASTERY_FILE_PREFIX .. tostring(context.LocalPlayer.UserId) .. ".json"
end

local function savePersistedProgress(context)
    if type(writefile) ~= "function" then
        return
    end
    pcall(function()
        writefile(masteryFile(context), HttpService:JSONEncode({
            version = MASTERY_STATE_VERSION,
            userId = context.LocalPlayer.UserId,
            mastery = context.State.meleeMastery or {},
        }))
    end)
end

local function currentSea(context)
    for sea = 1, 3 do
        if context.IsSea(sea) then
            return sea
        end
    end
    return 0
end

local function currentMelee(context)
    context.Functions.LoadTools()
    local tool = context.ToolsByType.Melee
    if typeof(tool) ~= "Instance" then
        return nil, 0
    end
    local level = tool:FindFirstChild("Level")
    return tool.Name, level and tonumber(level.Value) or 0
end

local function matchesStyle(toolName, style)
    return type(toolName) == "string"
        and (toolName == style.name or (style.display ~= nil and toolName == style.display))
end

local function findStyleTool(context, style)
    local player = context.LocalPlayer
    for _, root in { player.Character, player:FindFirstChildOfClass("Backpack") } do
        for _, tool in root and root:GetChildren() or {} do
            if tool:IsA("Tool") and matchesStyle(tool.Name, style) then
                return tool
            end
        end
    end
    return nil
end

local function equipStyle(context, style)
    local tool = findStyleTool(context, style)
    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not tool or not humanoid or humanoid.Health <= 0 then
        return false
    end
    if tool.Parent ~= character then
        humanoid:EquipTool(tool)
        task.wait(0.05)
    end
    context.Functions.LoadTools()
    return tool.Parent == character
end

local function markCurrentProgress(context)
    local state = context.State
    state.meleeMastery = state.meleeMastery or {}
    local toolName, mastery = currentMelee(context)
    if not toolName then
        return nil, 0
    end
    for _, style in STYLES do
        if matchesStyle(toolName, style) then
            state.meleeMastery[style.name] = math.max(state.meleeMastery[style.name] or 0, mastery)
            savePersistedProgress(context)
            return style.name, mastery
        end
    end
    if toolName == "Godhuman" then
        state.godhumanOwned = true
    end
    return toolName, mastery
end

local function markGodhumanComplete(context, equippedName, equippedMastery)
    if equippedName ~= "Godhuman" then
        return false
    end

    local state = context.State
    state.godhumanOwned = true
    state.meleeTarget = "Godhuman"
    state.meleeTargetDisplay = "Godhuman"
    state.meleeCurrentMastery = equippedMastery
    state.meleeMastery = state.meleeMastery or {}

    for _, style in STYLES do
        state.meleeMastery[style.name] = math.max(
            state.meleeMastery[style.name] or 0,
            style.goal
        )
    end

    context.MeleeInventory = context.MeleeInventory or {}
    context.MeleeInventory.Melee = context.MeleeInventory.Melee or {}
    context.MeleeInventory.Melee.Godhuman = {
        Bought = true,
        Level = equippedMastery,
    }

    savePersistedProgress(context)
    return true
end

local function loadPersistedProgress(context)
    local state = context.State
    if state.meleeProgressVersion == MASTERY_STATE_VERSION then
        return
    end
    state.meleeProgressLoaded = true
    state.meleeProgressVersion = MASTERY_STATE_VERSION
    local fileName = masteryFile(context)
    if type(readfile) ~= "function" or type(isfile) ~= "function" or not isfile(fileName) then
        return
    end
    local ok, stored = pcall(function()
        return HttpService:JSONDecode(readfile(fileName))
    end)
    if ok and type(stored) == "table"
        and tonumber(stored.userId) == context.LocalPlayer.UserId
        and tonumber(stored.version) == MASTERY_STATE_VERSION
        and type(stored.mastery) == "table"
    then
        state.meleeMastery = state.meleeMastery or {}
        for name, level in pairs(stored.mastery) do
            if tonumber(level) then
                state.meleeMastery[name] = math.max(state.meleeMastery[name] or 0, tonumber(level))
            end
        end
    end
end

local function syncStoredProgress(context)
    local mastery = context.State.meleeMastery
    local progress = context.MeleeProgress or {}
    local inventory = context.MeleeInventory and context.MeleeInventory.Melee or {}

    for _, style in STYLES do
        local level = tonumber(progress[style.name] and progress[style.name].Level)
            or tonumber(inventory[style.name] and inventory[style.name].Level)
        if level then
            mastery[style.name] = math.max(mastery[style.name] or 0, level)
        end
    end

    if inventory.Godhuman and inventory.Godhuman.Bought then
        context.State.godhumanOwned = true
    end
end

local function nextIncompleteStyle(mastery)
    for _, style in STYLES do
        if (mastery[style.name] or 0) < style.goal then
            return style
        end
    end
end

local findNpcCFrame

local function invokePurchase(context, style)
    if style.args then
        return context.CommandRemote:InvokeServer(style.command, table.unpack(style.args))
    end
    return context.CommandRemote:InvokeServer(style.command)
end

local function probePurchase(context, style)
    if style.name == "Dragon Claw" then
        return context.CommandRemote:InvokeServer("BlackbeardReward", "DragonClaw", "1")
    end
    return context.CommandRemote:InvokeServer(style.command, true)
end

local function ownsStyle(context, style)
    return context.Functions.Owns("Moveset", style.name)
        or context.Functions.Owns("Moveset", style.display or style.name)
end

local function refreshStyle(context, style)
    if type(context.Functions.RefreshInventory) == "function" then
        pcall(context.Functions.RefreshInventory, true)
    end
    context.Functions.LoadTools()
    local tool = findStyleTool(context, style)
    return tool ~= nil or ownsStyle(context, style)
end

local function purchaseCFrame(context, style)
    return findNpcCFrame(style.npc)
        or style.purchaseCFrames and style.purchaseCFrames[currentSea(context)]
end

local function moveToPurchaseNpc(context, style, rootPart)
    local destination = purchaseCFrame(context, style)
    if typeof(destination) ~= "CFrame" then
        return false
    end
    if (rootPart.Position - destination.Position).Magnitude <= PURCHASE_NPC_DISTANCE then
        return false
    end

    context.State.status = "Auto Farm Level | Moving to " .. style.npc
    context.Functions.TP(
        destination + Vector3.new(0, 5, 3),
        "Auto Farm Level",
        false
    )
    return true
end

local function purchaseNpcState(context, style, rootPart)
    local destination = purchaseCFrame(context, style)
    local available = typeof(destination) == "CFrame"
    local distance
    if rootPart and available then
        distance = (rootPart.Position - destination.Position).Magnitude
    end
    return available, distance, distance ~= nil and distance <= PURCHASE_NPC_DISTANCE
end

local function loadOwnedStyle(context, style, allowMovement)
    local state = context.State
    state.nextMeleeOwnedLoadAt = state.nextMeleeOwnedLoadAt or {}
    if allowMovement == nil then
        allowMovement = true
    end

    local character = context.LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if allowMovement and style.name == "Dragon Claw" and rootPart
        and moveToPurchaseNpc(context, style, rootPart)
    then
        return "busy"
    end

    local now = os.clock()
    if now < (state.nextMeleeOwnedLoadAt[style.name] or 0) then
        state.status = "Auto Farm Level | Loading " .. (style.display or style.name)
        return "busy"
    end
    state.nextMeleeOwnedLoadAt[style.name] = now + PURCHASE_RETRY_SECONDS

    local success, result = pcall(invokePurchase, context, style)
    if success then
        task.wait(0.2)
        refreshStyle(context, style)
        equipStyle(context, style)
    end

    local equippedName, equippedMastery = markCurrentProgress(context)
    local equipped = matchesStyle(equippedName, style)
    state.lastMeleeOwnedLoad = {
        name = style.name,
        success = success,
        result = tostring(result),
        equipped = equipped,
        at = now,
    }
    if equipped then
        state.meleeCurrentMastery = equippedMastery
        state.meleePurchaseNeedsNpc = state.meleePurchaseNeedsNpc or {}
        state.meleePurchaseNeedsNpc[style.name] = nil
        state.status = string.format(
            "Auto Farm Level | %s equipped (%d/%d)",
            style.display or style.name,
            equippedMastery,
            style.goal
        )
    else
        state.status = "Auto Farm Level | Loading " .. (style.display or style.name)
    end
    return "busy"
end

local function readElectroQuestState(context, force)
    local state = context.State
    if state.electroQuestState == 2 then
        return true, 2
    end
    local now = os.clock()
    if not force and now < (state.nextMeleeElectroQuestProbeAt or 0) then
        return state.electroQuestState ~= nil, state.electroQuestState
    end
    state.nextMeleeElectroQuestProbeAt = now + 5
    local ok, result = pcall(function()
        return context.CommandRemote:InvokeServer("ElectroQuestState")
    end)
    if ok then
        state.electroQuestState = tonumber(result)
    end
    return ok, state.electroQuestState
end

local function readDragonTalonUnlock(context, force)
    local state = context.State
    local now = os.clock()
    if not force and now < (state.nextDragonTalonUnlockProbeAt or 0) then
        return state.dragonTalonUnlockProbeSuccess == true,
            state.dragonTalonUnlockProbeResult
    end

    state.nextDragonTalonUnlockProbeAt = now + DRAGON_TALON_PROBE_INTERVAL
    local success, result = pcall(function()
        return context.CommandRemote:InvokeServer("BuyDragonTalon", true)
    end)
    state.dragonTalonUnlockProbeSuccess = success
    if success then
        state.dragonTalonUnlockProbeResult = result
        if type(result) ~= "string" then
            state.fireEssenceDelivered = true
        elseif string.find(string.lower(result), "heart ablaze", 1, true) then
            state.fireEssenceDelivered = nil
        end
    end
    state.lastDragonTalonUnlockProbe = {
        success = success,
        result = tostring(result),
        at = now,
    }
    return success, result
end

findNpcCFrame = function(name)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local npcManagerModule = ReplicatedStorage:FindFirstChild("NPCManager")
    if npcManagerModule then
        local ok, manager = pcall(require, npcManagerModule)
        if ok and type(manager) == "table"
            and type(manager.getNPCsByName) == "function"
        then
            local listOk, list = pcall(manager.getNPCsByName, name)
            if listOk and type(list) == "table" then
                for _, npc in list do
                    local modelState = npc and npc._modelState
                    local target = modelState and modelState._targetLocation
                    if typeof(target) == "CFrame" then
                        return target
                    end
                    local root = modelState and modelState._rootPart
                    if typeof(root) == "Instance" and root:IsA("BasePart") then
                        return root.CFrame
                    end
                end
            end
        end
    end

    for _, root in {
        workspace:FindFirstChild("NPCs"),
        ReplicatedStorage:FindFirstChild("NPCs"),
    } do
        local npc = root and root:FindFirstChild(name)
        if npc and npc:IsA("PVInstance") then
            return npc:GetPivot()
        end
    end

    if type(getnilinstances) == "function" then
        for _, npc in getnilinstances() do
            if npc.Name == name
                and (npc:IsA("PVInstance") or npc:IsA("BasePart"))
            then
                local ok, pivot = pcall(function()
                    return npc:IsA("PVInstance") and npc:GetPivot() or npc.CFrame
                end)
                if ok and typeof(pivot) == "CFrame" then
                    return pivot
                end
            end
        end
    end
    return nil
end

local function carries(context, itemName)
    local player = context.LocalPlayer
    return (player.Character and player.Character:FindFirstChild(itemName))
        or (player:FindFirstChildOfClass("Backpack") and player.Backpack:FindFirstChild(itemName))
end

local function isMissingSharkmanKeyResult(result)
    return type(result) == "string"
        and string.find(result, "house keys", 1, true) ~= nil
end

local function findLiveBoss(name)
    local enemies = workspace:FindFirstChild("Enemies")
    for _, enemy in enemies and enemies:GetChildren() or {} do
        local humanoid = enemy:FindFirstChildOfClass("Humanoid")
        if enemy.Name:find(name, 1, true) and humanoid and humanoid.Health > 0 then
            return enemy
        end
    end
    return nil
end

local function activateLibraryKey(context, key)
    local state = context.State
    if os.clock() < (state.nextLibraryKeyActivationAt or 0) then
        return false
    end

    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local iceCastle = workspace:FindFirstChild("IceCastle", true)
    local libraryDoor = iceCastle and iceCastle:FindFirstChild("LibraryDoor", true)
    local keyhole = libraryDoor and libraryDoor:FindFirstChild("Keyhole")
    local detector = keyhole and keyhole:FindFirstChild("Detect")
    if not humanoid or not root or not detector or not detector:IsA("BasePart") then
        state.libraryKeyActivationState = "detector-missing"
        return false
    end

    state.nextLibraryKeyActivationAt = os.clock() + 2
    local remoteSuccess, remoteResult = pcall(function()
        return context.CommandRemote:InvokeServer("OpenLibrary")
    end)
    if remoteSuccess and (remoteResult == true or not carries(context, "Library Key")) then
        state.deathStepUnlockConfirmed = true
        state.libraryKeyActivationState = "complete"
        state.lastLibraryKeyActivation = {
            success = true,
            result = tostring(remoteResult),
            source = "remote",
            at = os.clock(),
        }
        return true
    end

    if key.Parent ~= character then
        humanoid:EquipTool(key)
        task.wait(0.05)
    end

    local touch = firetouchinterest
    if type(touch) ~= "function" then
        state.libraryKeyActivationState = "touch-api-missing"
        return false
    end

    local success, err = pcall(function()
        touch(root, detector, 0)
        task.wait(0.05)
        touch(root, detector, 1)
    end)
    state.libraryKeyActivationState = success and "touch-sent" or "touch-failed"
    state.lastLibraryKeyActivation = {
        success = success,
        error = success and nil or tostring(err),
        remoteResult = tostring(remoteResult),
        source = "touch-fallback",
        at = os.clock(),
    }
    return success
end

local function probeSharkmanUnlock(context, force)
    local state = context.State
    local now = os.clock()
    if not force and now < (state.nextSharkmanUnlockProbeAt or 0) then
        return state.sharkmanUnlockProbeResult
    end

    state.nextSharkmanUnlockProbeAt = now + 2
    local hadWaterKey = carries(context, "Water Key") ~= nil
    local success, result = pcall(function()
        return context.CommandRemote:InvokeServer("BuySharkmanKarate", true)
    end)
    local hasWaterKey = carries(context, "Water Key") ~= nil
    state.lastSharkmanUnlockProbe = {
        success = success,
        result = tostring(result),
        keyBefore = hadWaterKey,
        keyAfter = hasWaterKey,
        at = now,
    }
    if not success then
        return nil
    end

    state.sharkmanUnlockProbeResult = result
    if hadWaterKey and not hasWaterKey then
        state.sharkmanKeyDelivered = true
        state.sharkmanUnlockConfirmed = true
        state.thirdSeaBlockedBySharkman = nil
        state.meleePrerequisite = nil
    elseif tonumber(result) == 1 then
        state.sharkmanKeyDelivered = true
        state.sharkmanUnlockConfirmed = true
        state.thirdSeaBlockedBySharkman = nil
        state.meleePrerequisite = nil
    elseif isMissingSharkmanKeyResult(result) then
        state.sharkmanUnlockConfirmed = nil
        state.thirdSeaBlockedBySharkman = true
        state.meleePrerequisite = "Sharkman Karate"
    elseif tonumber(result) == 3 then
        state.sharkmanUnlockConfirmed = state.sharkmanKeyDelivered == true
            and true or nil
        state.thirdSeaBlockedBySharkman = nil
        if state.meleePrerequisite == "Sharkman Karate" then
            state.meleePrerequisite = nil
        end
    else
        state.sharkmanUnlockConfirmed = state.sharkmanKeyDelivered == true
            and true or nil
        state.thirdSeaBlockedBySharkman = nil
        if state.meleePrerequisite == "Sharkman Karate" then
            state.meleePrerequisite = nil
        end
    end
    return result
end

local function deathStepUnlocked(context, force)
    local state = context.State
    if state.deathStepUnlockConfirmed == true then
        return true
    end

    local iceCastle = workspace:FindFirstChild("IceCastle", true)
    local hall = iceCastle and iceCastle:FindFirstChild("Hall")
    local libraryDoor = hall and hall:FindFirstChild("LibraryDoor")
    if libraryDoor
        and not libraryDoor:FindFirstChild("PhoeyuDoor", true)
        and not libraryDoor:FindFirstChild("Keyhole", true)
    then
        state.deathStepUnlockConfirmed = true
        return true
    end

    local now = os.clock()
    if not force and now < (state.nextDeathStepUnlockProbeAt or 0) then
        return state.deathStepUnlockConfirmed == true
    end
    state.nextDeathStepUnlockProbeAt = now + 2
    local success, result = pcall(function()
        return context.CommandRemote:InvokeServer("OpenLibrary")
    end)
    state.lastDeathStepUnlockProbe = {
        success = success,
        result = tostring(result),
        at = now,
    }
    if success and result == true then
        state.deathStepUnlockConfirmed = true
    end
    return state.deathStepUnlockConfirmed == true
end

local function maintainFireEssenceUnlock(context)
    local state = context.State
    local essence = carries(context, "Fire Essence")
    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local alive = humanoid and humanoid.Health > 0

    if not essence then
        local pending = state.fireEssenceDeliveryPending
        if pending and alive and os.clock() - pending.at <= 10 then
            state.fireEssenceDelivered = true
            state.lastFireEssenceDelivery.confirmed = true
        end
        state.fireEssenceDeliveryPending = nil
        return
    end

    if currentSea(context) ~= 3 or os.clock() < (state.nextFireEssenceDeliveryAt or 0) then
        return
    end

    state.nextFireEssenceDeliveryAt = os.clock() + 2
    local attemptedAt = os.clock()
    local success, result = pcall(function()
        return context.CommandRemote:InvokeServer("BuyDragonTalon", true)
    end)
    state.lastFireEssenceDelivery = {
        success = success,
        result = tostring(result),
        confirmed = false,
        at = attemptedAt,
    }
    if not success or type(result) == "string" then
        return
    end

    state.fireEssenceDelivered = true
    state.fireEssenceDeliveryPending = { at = attemptedAt }
    if not carries(context, "Fire Essence") then
        state.fireEssenceDelivered = true
        state.fireEssenceDeliveryPending = nil
        state.lastFireEssenceDelivery.confirmed = true
    end
end

local function handlePrerequisite(context, style, owner)
    local state = context.State
    owner = owner or "Auto Farm Level"
    local statusPrefix = owner == "Melee Materials" and "Material Farming" or owner
    if style.name == "Sharkman Karate" and state.sharkmanUnlockConfirmed then
        state.meleePrerequisite = nil
        return false
    end
    if not style.key or state.meleePrerequisite ~= style.name then
        return false
    end
    local key = carries(context, style.key)
    if key and style.key == "Library Key" then
        state.status = statusPrefix .. " | Activating Library Key"
        activateLibraryKey(context, key)
        if state.deathStepUnlockConfirmed == true then
            key = nil
        elseif carries(context, style.key) then
            return true
        else
            key = nil
        end
    end
    if key and style.key == "Water Key" then
        state.status = statusPrefix .. " | Delivering Water Key"
        probeSharkmanUnlock(context, false)
        if carries(context, style.key) and not state.sharkmanUnlockConfirmed then
            return true
        end
        state.sharkmanUnlockConfirmed = true
        state.meleePrerequisite = nil
        state.prerequisiteBossName = nil
        state.prerequisiteBossSeen = nil
        state.prerequisiteBossMissingSince = nil
        state.prerequisiteBossDefeatedAt = nil
        return false
    end
    if key then
        state.meleePrerequisite = nil
        state.prerequisiteBossName = nil
        state.prerequisiteBossSeen = nil
        state.prerequisiteBossMissingSince = nil
        state.prerequisiteBossDefeatedAt = nil
        return false
    end
    if style.key == "Library Key" and state.libraryKeyActivationState == "touch-sent" then
        state.meleePrerequisite = nil
        state.prerequisiteBossName = nil
        state.prerequisiteBossSeen = nil
        state.prerequisiteBossMissingSince = nil
        state.prerequisiteBossDefeatedAt = nil
        state.libraryKeyActivationState = "complete"
        return false
    end

    local boss = findLiveBoss(style.boss)
    state.status = statusPrefix .. " | " .. style.boss .. " for " .. style.key
    if boss then
        state.prerequisiteBossName = style.boss
        state.prerequisiteBossSeen = true
        state.prerequisiteBossMissingSince = nil
        state.prerequisiteBossDefeatedAt = nil
        context.Functions.CombatTarget(boss, owner, {
            boss = true,
            preserveBring = true,
            weaponType = "Melee",
        })
    else
        local character = context.LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local distance = root and (root.Position - style.bossCFrame.Position).Magnitude or math.huge
        local now = os.clock()
        if state.prerequisiteBossName ~= style.boss then
            state.prerequisiteBossName = style.boss
            state.prerequisiteBossSeen = nil
            state.prerequisiteBossMissingSince = nil
            state.prerequisiteBossDefeatedAt = nil
        end

        if state.prerequisiteBossSeen and not state.prerequisiteBossDefeatedAt then
            state.prerequisiteBossDefeatedAt = now
        end
        if distance <= PREREQUISITE_ARENA_RADIUS then
            state.prerequisiteBossMissingSince = state.prerequisiteBossMissingSince or now
            local missingFor = now - state.prerequisiteBossMissingSince
            local lootGraceRemaining = math.max(
                0,
                PREREQUISITE_LOOT_GRACE - (now - (state.prerequisiteBossDefeatedAt or 0))
            )
            if state.prerequisiteBossDefeatedAt and lootGraceRemaining > 0 then
                state.status = string.format(
                    statusPrefix .. " | Checking %s drop (%.0fs)",
                    style.key,
                    lootGraceRemaining
                )
            elseif state.prerequisiteBossDefeatedAt
                and now - (state.lastPrerequisiteHopAt or -PREREQUISITE_HOP_COOLDOWN)
                    >= PREREQUISITE_HOP_COOLDOWN
            then
                state.status = statusPrefix .. " | No " .. style.key .. "; hopping now"
                state.lastPrerequisiteHopAt = now
                state.prerequisiteBossMissingSince = now
                context.Functions.HopServer(nil, true)
                return true
            elseif missingFor >= PREREQUISITE_HOP_AFTER
                and now - (state.lastPrerequisiteHopAt or -PREREQUISITE_HOP_COOLDOWN)
                    >= PREREQUISITE_HOP_COOLDOWN
            then
                state.status = statusPrefix .. " | Hopping for " .. style.boss
                state.lastPrerequisiteHopAt = now
                state.prerequisiteBossMissingSince = now
                context.Functions.HopServer(nil, true)
                return true
            else
                state.status = string.format(
                    statusPrefix .. " | Waiting %s (%.0fs)",
                    style.boss,
                    missingFor
                )
            end
        else
            state.prerequisiteBossMissingSince = nil
        end
        context.Functions.TP(style.bossCFrame, owner, true)
    end
    return true
end

local function canAfford(context, style)
    return context.Beli.Value >= (style.price or 0)
        and context.Fragments.Value >= (style.fragments or 0)
end

local function clearPurchaseHandoff(context, styleName)
    if not styleName then
        return
    end

    local state = context.State
    local pending = state.meleePurchaseNeedsNpc
    if type(pending) == "table" then
        pending[styleName] = nil
    end
    if state.meleeTarget == styleName then
        state.meleePurchaseNpcDistance = nil
        state.meleePurchaseNpcUnavailable = nil
    end
end

local function materialCount(context, name)
    local material = context.Inventory.Material and context.Inventory.Material[name]
    return material and tonumber(material.Count or material.Value) or 0
end

local function dragonTalonMaterialMode(context)
    local state = context.State
    local target = nextIncompleteStyle(state.meleeMastery or {})
    if not target or target.name ~= "Dragon Talon" then
        state.dragonTalonMaterialMode = nil
        state.dragonTalonLevelCycleActive = nil
        return nil
    end
    if carries(context, "Fire Essence") then
        state.dragonTalonNeedsEssence = false
        state.dragonTalonMaterialMode = nil
        state.dragonTalonLevelCycleActive = nil
        return nil
    end

    local success, result = readDragonTalonUnlock(context, false)
    local needsEssence = success and type(result) == "string"
        and string.find(string.lower(result), "heart ablaze", 1, true) ~= nil
    state.dragonTalonNeedsEssence = needsEssence
    if not needsEssence then
        state.dragonTalonMaterialMode = nil
        state.dragonTalonLevelCycleActive = nil
        return nil
    end

    if currentSea(context) ~= 3 then
        state.dragonTalonLevelCycleActive = nil
        state.dragonTalonMaterialMode = "Travel"
        return "Travel"
    end

    state.dragonTalonMaterialMode = nil
    state.dragonTalonLevelCycleActive = true
    state.dragonTalonLevelCycleDeferredAt = os.clock()
    return nil
end

local function runDragonTalonMaterial(context, owner, mode)
    local state = context.State
    if mode ~= "Travel" then
        return false
    end

    state.status = "Sea Travel | Melee Material | Fire Essence"
    if os.clock() >= (state.nextDragonTalonMaterialTravelAt or 0) then
        state.nextDragonTalonMaterialTravelAt = os.clock() + 5
        state.worldTravelOwner = owner
        state.worldTravelDestination = 3
        state.worldTravelIssuedAt = os.clock()
        local ok, result = pcall(function()
            return context.CommandRemote:InvokeServer("TravelZou")
        end)
        state.lastDragonTalonMaterialTravel = {
            ok = ok,
            result = tostring(result),
            at = os.clock(),
        }
    end
    return true
end

local function missingGodhumanMaterial(context)
    if context.State.godhumanOwned == true
        or context.Functions.Owns("Moveset", "Godhuman")
    then
        return nil
    end
    local sea = currentSea(context)
    local firstMissing
    for _, requirement in GODHUMAN_MATERIALS do
        if materialCount(context, requirement.name) < requirement.count then
            firstMissing = firstMissing or requirement
            if requirement.sea == sea then
                return requirement
            end
        end
    end
    return firstMissing
end

local function handleGodhuman(context, allowMovement)
    allowMovement = allowMovement ~= false
    local state = context.State
    state.meleeTarget = "Godhuman"
    state.meleeTargetDisplay = "Godhuman"
    state.meleeTargetMastery = 400
    state.meleeReadyForGodhuman = true

    if state.godhumanOwned then
        clearPurchaseHandoff(context, "Godhuman")
        state.status = "Godhuman acquired"
        return false
    end
    local requirement = missingGodhumanMaterial(context)
    if requirement then
        clearPurchaseHandoff(context, "Godhuman")
        local count = materialCount(context, requirement.name)
        state.status = string.format(
            "Godhuman | %s: %d/%d",
            requirement.name,
            count,
            requirement.count
        )
        if allowMovement and type(context.Functions.FarmMaterial) == "function" then
            context.Functions.FarmMaterial(
                requirement.name,
                "Godhuman",
                requirement.count,
                requirement.sea
            )
        else
            state.meleeMissingMaterial = requirement.name
            state.meleeMissingMaterialCount = requirement.count - count
        end
        return allowMovement and "busy" or false
    end
    state.meleeMissingMaterial = nil
    state.meleeMissingMaterialCount = nil

    if context.Beli.Value < 5000000 or context.Fragments.Value < 5000 then
        clearPurchaseHandoff(context, "Godhuman")
        state.needFragments = context.Fragments.Value < 5000
        state.status = string.format(
            "Godhuman | Money %d/5000000 | Fragments %d/5000",
            context.Beli.Value,
            context.Fragments.Value
        )
        return false
    end

    state.meleePurchaseNeedsNpc = state.meleePurchaseNeedsNpc or {}
    state.meleePurchaseNeedsNpc.Godhuman = true
    local character = context.LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local hasPurchaseNpc, npcDistance, atPurchaseNpc = purchaseNpcState(
        context,
        GODHUMAN_PURCHASE_STYLE,
        rootPart
    )
    state.meleePurchaseNpcDistance = npcDistance
    if not allowMovement and not atPurchaseNpc then
        return false
    end
    if allowMovement and rootPart and hasPurchaseNpc and not atPurchaseNpc then
        if moveToPurchaseNpc(context, GODHUMAN_PURCHASE_STYLE, rootPart) then
            state.status = "Godhuman | Moving to Ancient Monk"
            return "busy"
        end
    end

    if os.clock() < (state.nextGodhumanPurchaseAt or 0) then
        return "busy"
    end

    state.nextGodhumanPurchaseAt = os.clock() + 5
    local probeSuccess, probeResult = pcall(function()
        return context.CommandRemote:InvokeServer("BuyGodhuman", true)
    end)
    local success, result = pcall(function()
        return context.CommandRemote:InvokeServer("BuyGodhuman")
    end)
    state.lastGodhumanPurchase = {
        probeSuccess = probeSuccess,
        probeResult = tostring(probeResult),
        success = success,
        result = tostring(result),
        at = os.clock(),
    }
    if success then
        task.wait(0.25)
        refreshStyle(context, GODHUMAN_PURCHASE_STYLE)
        equipStyle(context, GODHUMAN_PURCHASE_STYLE)
        local name = markCurrentProgress(context)
        if name == "Godhuman" or ownsStyle(context, GODHUMAN_PURCHASE_STYLE) then
            state.godhumanOwned = true
            state.needFragments = false
            state.meleePurchaseNeedsNpc.Godhuman = nil
        end
    end
    return "busy"
end

local function handleDragonTalon(context, style)
    if style.name ~= "Dragon Talon" or carries(context, "Fire Essence") then
        return false
    end

    local state = context.State
    if state.fireEssenceDelivered == true then
        return false
    end

    local probeSuccess, probeResult = readDragonTalonUnlock(context, false)
    local needsEssence = probeSuccess and type(probeResult) == "string"
        and string.find(string.lower(probeResult), "heart ablaze", 1, true) ~= nil
    if probeSuccess and type(probeResult) ~= "string" then
        state.fireEssenceDelivered = true
        return false
    end
    if not needsEssence then
        return false
    end
    state.dragonTalonNeedsEssence = true
    state.dragonTalonLevelCycleActive = currentSea(context) == 3
    state.status = "Auto Farm Level | Dragon Talon Bones cycle"
    return "defer"
end

local function maintainLegendarySwordMastery(context)
    local state = context.State
    local movesets = context.Inventory.Moveset or {}
    local targetName, targetItem

    for _, name in LEGENDARY_SWORDS do
        local item = movesets[name]
        if type(item) == "table"
            and (tonumber(item.Mastery or item.Level) or 0) < LEGENDARY_SWORD_MASTERY
        then
            targetName = name
            targetItem = item
            break
        end
    end

    if not targetName then
        if state.forceSwordMasteryTarget then
            state.forceSwordMasteryTarget = nil
            if state.selectedWeaponType == "Sword" then
                state.selectedWeaponType = nil
            end
        end
        return false
    end

    local mastery = tonumber(targetItem.Mastery or targetItem.Level) or 0
    state.forceSwordMasteryTarget = targetName
    state.selectedWeaponType = "Sword"
    state.status = string.format(
        "Farming mastery for %s (%d/%d)",
        targetName,
        mastery,
        LEGENDARY_SWORD_MASTERY
    )

    local tool = carries(context, targetName)
    if not tool and os.clock() >= (state.nextLegendarySwordLoadAt or 0) then
        state.nextLegendarySwordLoadAt = os.clock() + 3
        pcall(function()
            context.CommandRemote:InvokeServer("LoadItem", targetName)
        end)
        context.Functions.LoadTools()
        tool = carries(context, targetName)
    end

    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if tool and humanoid and humanoid.Health > 0 and tool.Parent ~= character then
        humanoid:EquipTool(tool)
        context.Functions.LoadTools()
    end
    return true
end

function AutoMeleeProgress.run(context, options)
    options = options or {}
    local allowMovement = options.allowMovement ~= false
    local background = options.background == true
    local configs = context.Environment.Configs
    if configs["Switch Melee"] == false then
        return false
    end

    local state = context.State
    if not context.LocalPlayer.Character then
        state.status = "Auto Farm Level | Waiting for player data"
        return "busy"
    end

    local mastery = state.meleeMastery or {}
    state.meleeMastery = mastery
    loadPersistedProgress(context)
    mastery = state.meleeMastery
    syncStoredProgress(context)
    maintainFireEssenceUnlock(context)
    local equippedName, equippedMastery = markCurrentProgress(context)
    if markGodhumanComplete(context, equippedName, equippedMastery)
        or state.godhumanOwned == true
        or context.Functions.Owns("Moveset", "Godhuman")
    then
        state.godhumanOwned = true
        maintainLegendarySwordMastery(context)
        return false
    end

    local target = nextIncompleteStyle(mastery)

    if not target then
        return handleGodhuman(context, allowMovement)
    end

    if state.meleeTarget and state.meleeTarget ~= target.name then
        clearPurchaseHandoff(context, state.meleeTarget)
    end
    state.meleeTarget = target.name
    state.meleeTargetDisplay = target.display or target.name
    state.meleeTargetMastery = target.goal
    state.meleeCurrentMastery = mastery[target.name] or 0
    local ownedByInventory = ownsStyle(context, target)

    if target.name == "Electro" and not ownedByInventory then
        local questOk, questState = readElectroQuestState(context)
        if questOk and tonumber(questState) == 2 then
            clearPurchaseHandoff(context, target.name)
            state.electricUnlockNeeded = nil
            state.electricUnlockActive = nil
            state.electricUnlockPhase = "complete"
            if not matchesStyle(equippedName, target) then
                state.electricEquipPending = true
                if allowMovement then
                    return context.Functions.AutoElectricUnlock("Auto Farm Level")
                end
            end
        elseif questOk and questState ~= nil then
            clearPurchaseHandoff(context, target.name)
            state.electricUnlockNeeded = true
            state.electricUnlockPhase = "quest-state-" .. tostring(questState)
            state.status = "Material Farming | Electro | Lightning Bolt Quest"
            if not allowMovement then
                return false
            end
            return context.Functions.AutoElectricUnlock("Auto Farm Level")
        elseif state.electricUnlockNeeded then
            clearPurchaseHandoff(context, target.name)
            if not allowMovement then
                return false
            end
            return context.Functions.AutoElectricUnlock("Auto Farm Level")
        end
    end

    if matchesStyle(equippedName, target) then
        clearPurchaseHandoff(context, target.name)
        if target.name == "Electro" then
            state.electricEquipPending = nil
        end
        state.meleeCurrentMastery = equippedMastery
        if equippedMastery >= target.goal then
            mastery[target.name] = equippedMastery
        end
        return true
    end

    local ownedTarget = findStyleTool(context, target)
    if ownedTarget then
        clearPurchaseHandoff(context, target.name)
        state.status = "Auto Farm Level | Equipping " .. (target.display or target.name)
        if equipStyle(context, target) then
            local newName, newMastery = markCurrentProgress(context)
            if matchesStyle(newName, target) then
                if target.name == "Electro" then
                    state.electricEquipPending = nil
                end
                state.meleeCurrentMastery = newMastery
                return "busy"
            end
        end
        return "busy"
    end

    if ownedByInventory then
        clearPurchaseHandoff(context, target.name)
        return loadOwnedStyle(context, target, allowMovement)
    end

    if currentSea(context) < target.minSea then
        clearPurchaseHandoff(context, target.name)
        state.meleeWaitingForSea = target.minSea
        return false
    end
    state.meleeWaitingForSea = nil

    if target.name == "Death Step" then
        if carries(context, "Library Key") then
            state.meleePrerequisite = target.name
        elseif deathStepUnlocked(context, false) then
            if state.meleePrerequisite == target.name then
                state.meleePrerequisite = nil
            end
        else
            state.meleePrerequisite = target.name
        end
    elseif target.name == "Sharkman Karate" then
        local unlockResult
        if carries(context, "Water Key") then
            state.meleePrerequisite = target.name
        else
            unlockResult = probeSharkmanUnlock(context, false)
        end
        if tonumber(unlockResult) == 1 then
            state.sharkmanUnlockConfirmed = true
            if state.meleePrerequisite == target.name then
                state.meleePrerequisite = nil
            end
        elseif isMissingSharkmanKeyResult(unlockResult) then
            state.meleePrerequisite = target.name
        end
    end

    if not allowMovement and state.meleePrerequisite == target.name then
        clearPurchaseHandoff(context, target.name)
        return false
    end
    if allowMovement and currentSea(context) == 2
        and handlePrerequisite(context, target)
    then
        clearPurchaseHandoff(context, target.name)
        return "busy"
    end
    if target.name == "Dragon Talon" then
        local dragonTalonState = allowMovement and handleDragonTalon(context, target)
        if dragonTalonState == "defer" then
            clearPurchaseHandoff(context, target.name)
            return false
        elseif dragonTalonState then
            clearPurchaseHandoff(context, target.name)
            return "busy"
        end
        if not allowMovement and not carries(context, "Fire Essence")
            and state.fireEssenceDelivered ~= true
        then
            local unlockOk, unlockResult = readDragonTalonUnlock(context, false)
            local needsEssence = unlockOk and type(unlockResult) == "string"
                and string.find(
                    string.lower(unlockResult),
                    "heart ablaze",
                    1,
                    true
                ) ~= nil
            if needsEssence then
                state.dragonTalonNeedsEssence = true
                clearPurchaseHandoff(context, target.name)
                return false
            end
        end
    end
    if target.name == "Electric Claw"
        and (state.electricClawUtilityActive
            or tonumber(state.utilityElectricClawProbeResult) == 4)
    then
        clearPurchaseHandoff(context, target.name)
        state.status = "Auto Farm Level | Electric Claw trial"
        return "busy"
    end

    if not canAfford(context, target) then
        clearPurchaseHandoff(context, target.name)
        state.status = string.format(
            "Auto Farm Level | Saving for %s (%d/%d Beli)",
            target.display or target.name,
            context.Beli.Value,
            target.price or 0
        )
        return false
    end

    state.meleePurchaseNeedsNpc = state.meleePurchaseNeedsNpc or {}
    local needsNpc = state.meleePurchaseNeedsNpc[target.name] == true
    if not needsNpc then
        state.meleePurchaseNeedsNpc[target.name] = true
        state.nextMeleePurchaseAt = 0
        needsNpc = true
    end
    local character = context.LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local hasPurchaseNpc, npcDistance, atPurchaseNpc = purchaseNpcState(
        context,
        target,
        rootPart
    )
    state.meleePurchaseNpcDistance = npcDistance
    if needsNpc and not atPurchaseNpc then
        if allowMovement and rootPart and hasPurchaseNpc then
            moveToPurchaseNpc(context, target, rootPart)
        end
        return allowMovement and "busy" or false
    end

    if os.clock() < (state.nextMeleePurchaseAt or 0) then
        return needsNpc and hasPurchaseNpc and "busy" or false
    end
    state.nextMeleePurchaseAt = os.clock() + PURCHASE_RETRY_SECONDS

    local probeSuccess, probeResult = pcall(probePurchase, context, target)
    state.lastMeleeProbe = {
        name = target.name,
        success = probeSuccess,
        result = tostring(probeResult),
        at = os.clock(),
    }

    if target.name == "Electric Claw" and tonumber(probeResult) == 4 then
        state.meleePurchaseNeedsNpc[target.name] = nil
        state.utilityElectricClawProbeResult = 4
        state.nextUtilityElectricClawProbeAt = 0
        state.status = "Auto Farm Level | Electric Claw trial pending"
        return "busy"
    end

    local startedAt = os.clock()
    local success, result
    local attempts = 0
    repeat
        attempts += 1
        success, result = pcall(invokePurchase, context, target)
        if success then
            task.wait(0.1)
            refreshStyle(context, target)
        end
        equipStyle(context, target)
        local newName, newMastery = markCurrentProgress(context)
        if matchesStyle(newName, target) then
            state.meleePurchaseNeedsNpc[target.name] = nil
            if target.name == "Electro" then
                state.electricUnlockNeeded = nil
                state.electricEquipPending = nil
                state.nextElectricUnlockAttemptAt = nil
                state.electroQuestState = 2
            end
            state.meleeCurrentMastery = newMastery
            state.status = string.format(
                "Auto Farm Level | %s equipped (%d/%d)",
                target.display or target.name,
                newMastery,
                target.goal
            )
            state.lastMeleePurchase = {
                name = target.name,
                success = success,
                result = tostring(result),
                probeResult = tostring(probeResult),
                attempts = attempts,
                acquired = true,
                at = os.clock(),
            }
            return "busy"
        end

        if not background and os.clock() - startedAt < PURCHASE_RETRY_SECONDS then
            task.wait(PURCHASE_RETRY_INTERVAL)
        end
    until background or os.clock() - startedAt >= PURCHASE_RETRY_SECONDS

    state.lastMeleePurchase = {
        name = target.name,
        success = success,
        result = tostring(result),
        probeResult = tostring(probeResult),
        attempts = attempts,
        requiresNpc = state.meleePurchaseNeedsNpc[target.name] == true,
        at = os.clock(),
    }
    if target.name == "Electro" and tostring(result) == "0" then
        local questOk, questState = readElectroQuestState(context, true)
        if questOk and tonumber(questState) == 2 then
            clearPurchaseHandoff(context, target.name)
            state.electricUnlockNeeded = nil
            state.electricUnlockActive = nil
            state.electricUnlockPhase = "complete"
            state.electricEquipPending = true
            state.status = "Auto Farm Level | Electric owned; waiting to equip"
            return "busy"
        else
            state.meleePurchaseNeedsNpc[target.name] = nil
            state.electricUnlockNeeded = true
            state.nextElectricUnlockAttemptAt = nil
            state.status = "Auto Farm Level | Electric requires Lightning Bolt"
            return "busy"
        end
    end
    return false
end

function AutoMeleeProgress.runBackground(context)
    local state = context.State
    local previousStatus = state.status
    local result = AutoMeleeProgress.run(context, {
        allowMovement = false,
        background = true,
    })
    state.lastMeleeBackgroundAt = os.clock()
    state.lastMeleeBackgroundResult = tostring(result)
    state.meleeBackgroundStatus = state.status

    if context.TaskQueue and context.TaskQueue:top() ~= "Auto Farm Level" then
        state.status = previousStatus
    end
    return result
end

function AutoMeleeProgress.runPurchaseMovement(context)
    local state = context.State
    local pending = state.meleePurchaseNeedsNpc
    local targetName = state.meleeTarget
    if type(pending) ~= "table" or pending[targetName] ~= true then
        return false
    end

    local target
    if targetName == GODHUMAN_PURCHASE_STYLE.name then
        target = GODHUMAN_PURCHASE_STYLE
    else
        for _, style in STYLES do
            if style.name == targetName then
                target = style
                break
            end
        end
    end
    if not target then
        clearPurchaseHandoff(context, targetName)
        return false
    end

    local expectedTarget = nextIncompleteStyle(state.meleeMastery or {})
    local invalid = targetName ~= GODHUMAN_PURCHASE_STYLE.name
        and (not expectedTarget or expectedTarget.name ~= targetName)
    local dragonTalonBlocked = false
    if targetName == "Dragon Talon"
        and not carries(context, "Fire Essence")
        and state.fireEssenceDelivered ~= true
    then
        dragonTalonBlocked = state.dragonTalonNeedsEssence == true
        if not dragonTalonBlocked then
            local unlockOk, unlockResult = readDragonTalonUnlock(context, false)
            dragonTalonBlocked = unlockOk and type(unlockResult) == "string"
                and string.find(
                    string.lower(unlockResult),
                    "heart ablaze",
                    1,
                    true
                ) ~= nil
            if dragonTalonBlocked then
                state.dragonTalonNeedsEssence = true
            end
        end
    end
    if targetName == GODHUMAN_PURCHASE_STYLE.name then
        invalid = state.godhumanOwned == true
            or missingGodhumanMaterial(context) ~= nil
            or context.Beli.Value < 5000000
            or context.Fragments.Value < 5000
    else
        invalid = invalid
            or ownsStyle(context, target)
            or currentSea(context) < target.minSea
            or not canAfford(context, target)
            or state.meleePrerequisite == targetName
            or (targetName == "Electric Claw"
                and (state.electricClawUtilityActive
                    or tonumber(state.utilityElectricClawProbeResult) == 4))
            or dragonTalonBlocked
    end
    if invalid then
        clearPurchaseHandoff(context, targetName)
        return false
    end

    local character = context.LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        state.status = "Auto Farm Level | Waiting for melee teacher route"
        return "busy"
    end

    local destination = purchaseCFrame(context, target)
    if typeof(destination) ~= "CFrame" then
        state.meleePurchaseNpcUnavailable = target.name
        return false
    end
    state.meleePurchaseNpcUnavailable = nil

    if moveToPurchaseNpc(context, target, rootPart) then
        return "busy"
    end

    state.status = "Auto Farm Level | Waiting for "
        .. (target.display or target.name) .. " purchase"
    return "busy"
end

local function prerequisiteStyle(state)
    local wanted = state.meleePrerequisite
    if not wanted then
        return nil
    end
    for _, style in STYLES do
        if style.name == wanted and style.key then
            return style
        end
    end
end

function AutoMeleeProgress.needsMaterialTask(context)
    if context.Environment.Configs["Switch Melee"] == false then
        return false
    end

    local state = context.State
    state.meleeMastery = state.meleeMastery or {}
    loadPersistedProgress(context)
    syncStoredProgress(context)

    if state.godhumanOwned == true
        or context.Functions.Owns("Moveset", "Godhuman")
    then
        state.electricPrefetchPending = nil
        state.electricUnlockNeeded = nil
        state.godhumanMaterialRequirement = nil
        return false
    end

    if type(context.Functions.ShouldPrefetchElectric) == "function"
        and context.Functions.ShouldPrefetchElectric()
    then
        state.electricPrefetchPending = true
        return true
    end
    state.electricPrefetchPending = nil

    local target = nextIncompleteStyle(state.meleeMastery)
    if target and target.name == "Electro" and not ownsStyle(context, target) then
        local questOk, questState = readElectroQuestState(context)
        if questOk and tonumber(questState) == 2 then
            state.electricUnlockNeeded = nil
            state.electricUnlockActive = nil
            state.electricUnlockPhase = "complete"
        else
            state.electricUnlockNeeded = true
            state.electricUnlockPhase = questState ~= nil
                and "quest-state-" .. tostring(questState)
                or "quest-state-pending"
            return true
        end
    elseif state.electricUnlockNeeded then
        state.electricUnlockNeeded = nil
        state.electricUnlockActive = nil
    end

    local dragonTalonMode = dragonTalonMaterialMode(context)
    if dragonTalonMode then
        state.godhumanMaterialRequirement = nil
        return true
    end

    local style = prerequisiteStyle(state)
    if style and style.name == "Death Step" then
        state.godhumanMaterialRequirement = nil
        if carries(context, "Library Key") then
            return true
        end
        if deathStepUnlocked(context, false) then
            state.meleePrerequisite = nil
            return false
        end
        return true
    end
    if style and style.name == "Sharkman Karate" then
        state.godhumanMaterialRequirement = nil
        if carries(context, "Water Key") then
            return true
        end
        local result = probeSharkmanUnlock(context, false)
        if isMissingSharkmanKeyResult(result) then
            return true
        end
        state.meleePrerequisite = nil
        return false
    end

    if not target then
        local requirement = missingGodhumanMaterial(context)
        state.godhumanMaterialRequirement = requirement
        return requirement ~= nil
    end
    state.godhumanMaterialRequirement = nil
    return false
end

function AutoMeleeProgress.runMaterial(context)
    local owner = "Melee Materials"
    if context.TaskQueue:top() ~= owner then
        return false
    end

    local state = context.State
    if state.electricPrefetchPending then
        local result = context.Functions.AutoElectricPrefetch(owner)
        if result == false then
            state.electricPrefetchPending = nil
            context.TaskQueue:pop(owner)
        end
        return result
    end
    if AutoMeleeProgress.needsMaterialTask(context) and state.electricUnlockNeeded then
        return context.Functions.AutoElectricUnlock(owner)
    end

    local dragonTalonMode = dragonTalonMaterialMode(context)
    if dragonTalonMode then
        return runDragonTalonMaterial(context, owner, dragonTalonMode)
    end

    local requirement = state.godhumanMaterialRequirement
    if requirement then
        state.status = "Material Farming | Godhuman | " .. requirement.name
        return context.Functions.FarmMaterial(
            requirement.name,
            "Godhuman",
            requirement.count,
            requirement.sea
        )
    end

    local style = prerequisiteStyle(state)
    if not style then
        context.TaskQueue:pop(owner)
        return false
    end

    if currentSea(context) ~= 2 then
        state.status = "Sea Travel | Melee Material | " .. style.key
        local now = os.clock()
        if now >= (state.nextMeleeMaterialTravelAt or 0) then
            state.nextMeleeMaterialTravelAt = now + 5
            state.worldTravelOwner = owner
            state.worldTravelDestination = 2
            state.worldTravelIssuedAt = now
            local ok, result = pcall(function()
                return context.CommandRemote:InvokeServer("TravelDressrosa")
            end)
            state.lastMeleeMaterialTravel = {
                ok = ok,
                result = tostring(result),
                sea = 2,
                at = now,
            }
        end
        return true
    end

    local busy = handlePrerequisite(context, style, owner)
    if not busy then
        context.TaskQueue:pop(owner)
    end
    return busy
end

function AutoMeleeProgress.needsDragonTalonEssence(context)
    local state = context.State
    if currentSea(context) ~= 3
        or carries(context, "Fire Essence")
        or state.fireEssenceDelivered == true
        or state.godhumanOwned == true
        or context.Functions.Owns("Moveset", "Dragon Talon")
        or context.Functions.Owns("Moveset", "Godhuman")
    then
        state.dragonTalonNeedsEssence = false
        return false
    end

    local success, result = readDragonTalonUnlock(context, false)
    local needsEssence = success and type(result) == "string"
        and string.find(string.lower(result), "heart ablaze", 1, true) ~= nil
    state.dragonTalonNeedsEssence = needsEssence
    return needsEssence
end

function AutoMeleeProgress.shouldTargetOrderedBoss(context, bossName)
    if bossName == "Awakened Ice Admiral" then
        if currentSea(context) ~= 2
            or carries(context, "Library Key")
            or context.Functions.Owns("Moveset", "Death Step")
        then
            return false
        end
        return not deathStepUnlocked(context, false)
    end
    if bossName == "Tide Keeper" then
        if currentSea(context) ~= 2
            or carries(context, "Water Key")
            or context.Functions.Owns("Moveset", "Sharkman Karate")
        then
            return false
        end
        local result = probeSharkmanUnlock(context, false)
        return type(result) == "string"
            and string.find(result, "house keys", 1, true) ~= nil
    end
    return true
end

AutoMeleeProgress.Styles = STYLES
AutoMeleeProgress.GodhumanMaterials = GODHUMAN_MATERIALS
end

local AutoRaid
do
AutoRaid = {}
local MAX_RAID_FRUIT_VALUE = 1000000
local RAID_CHIP_REPLICATION_TIMEOUT = 12
local RAID_PURCHASE_HISTORY_LIMIT = 12

local function isTaskCurrent(context, owner)
    local functions = context.Functions
    if functions and type(functions.IsTaskCurrent) == "function" then
        return functions.IsTaskCurrent(owner)
    end
    local state = context.State or {}
    return not state.stopped
        and not state.paused
        and context.TaskQueue:top() == owner
end

local function clearChipPurchasePending(state)
    state.raidChipPurchasePendingAt = nil
    state.raidChipPurchasePendingUntil = nil
    state.raidChipPurchasePendingFruit = nil
end

local function purchaseAccepted(success, result)
    return success == true
        and (result == true or result == 1 or result == "1")
end

local function recordRaidPurchase(state, fruit, success, result, now)
    local purchasedAt = now or os.clock()
    local entry = {
        success = success,
        result = tostring(result),
        fruit = fruit,
        at = purchasedAt,
    }
    state.lastRaidPurchase = entry
    state.raidPurchaseHistory = state.raidPurchaseHistory or {}
    table.insert(state.raidPurchaseHistory, entry)
    while #state.raidPurchaseHistory > RAID_PURCHASE_HISTORY_LIMIT do
        table.remove(state.raidPurchaseHistory, 1)
    end

    if purchaseAccepted(success, result) then
        state.raidChipPurchasePendingAt = purchasedAt
        state.raidChipPurchasePendingUntil = purchasedAt + RAID_CHIP_REPLICATION_TIMEOUT
        state.raidChipPurchasePendingFruit = fruit
        return true
    end
    return false
end

local function isChipPurchasePending(state, hasChip, now)
    if hasChip then
        clearChipPurchasePending(state)
        return false
    end

    local pendingUntil = tonumber(state.raidChipPurchasePendingUntil)
    if not pendingUntil then
        return false
    end
    if (now or os.clock()) < pendingUntil then
        return true
    end

    clearChipPurchasePending(state)
    return false
end

local function raidTestConfig(context)
    local configs = context.Environment.Configs or {}
    local config = configs["Raid Test"]
    return type(config) == "table" and config or nil
end

local function testAllowsFruit(context, storageId)
    local test = raidTestConfig(context)
    return test and test.Enable == true
        and type(test.ForcedFruit) == "string"
        and test.ForcedFruit == storageId
end

local function carries(context, itemName)
    local player = context.LocalPlayer
    return (player.Character and player.Character:FindFirstChild(itemName))
        or (player:FindFirstChildOfClass("Backpack") and player.Backpack:FindFirstChild(itemName))
end

local function isRaidActive(context)
    if context.LocalPlayer:GetAttribute("IslandRaiding") == true then
        return true
    end
    local gui = context.LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local main = gui and gui:FindFirstChild("Main")
    local top = main and main:FindFirstChild("TopHUDList")
    local timer = top and top:FindFirstChild("RaidTimer")
    if timer and timer.Visible == true then
        return true
    end

    local character = context.LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
    local locations = worldOrigin and worldOrigin:FindFirstChild("Locations")
    for _, location in locations and locations:GetChildren() or {} do
        if rootPart and location:IsA("BasePart")
            and location.Name:match("^Island [1-5]$")
            and location.Position.Magnitude > 7000
            and (location.Position - rootPart.Position).Magnitude < 2000
        then
            return true
        end
    end
    return false
end

local function requiredFragments(context)
    local test = raidTestConfig(context)
    if test and test.Enable == true and context.State.raidTestComplete ~= true then
        return math.max(1, tonumber(test.FragmentDeficit) or 1000), {
            canStart = context.IsSea(2) or context.IsSea(3),
        }
    end

    local player = context.LocalPlayer
    local startedAt = tonumber(player:GetAttribute("ExpBoostTick")) or 0
    local duration = tonumber(player:GetAttribute("ExpBoost"))
    local expBoostRemaining = duration and duration > 0 and startedAt > 0
        and math.max(0, duration - math.max(0, tick() - startedAt))
        or math.max(tonumber(context.State.expBoostRemaining) or 0, startedAt - tick(), 0)
    local ownsGodhuman = context.Functions.Owns("Melee", "Godhuman")
        or context.Functions.Owns("Moveset", "Godhuman")
    local ownsDragonClaw = context.Functions.Owns("Melee", "Dragon Claw")
        or context.Functions.Owns("Moveset", "Dragon Claw")
    local decision = RaidTaskPolicy.decide({
        level = context.Level.Value,
        fragments = context.Fragments.Value,
        maximumLevel = RaidTaskPolicy.MaximumLevel,
        ownsDragonClaw = ownsDragonClaw == true,
        expBoostActive = expBoostRemaining > 0,
        ownsGodhuman = ownsGodhuman == true,
        inRaidSea = context.IsSea(2) or context.IsSea(3),
    })
    return decision.autoDeficit, decision
end

local function storageIdFromTool(tool)
    if not tool or not tool:IsA("Tool") then
        return nil
    end
    for _, attribute in { "StorageKey", "ItemId", "FruitId" } do
        local value = tool:GetAttribute(attribute)
        if type(value) == "string" and value ~= "" then
            return value
        end
    end
    local prefix = tool.Name:match("^%s*(%S+)%s+Fruit$")
    return prefix and prefix .. "-" .. prefix or nil
end

local function inventoryEntry(context, storageId)
    local inventory = context.Inventory.PhysicalMoveset or {}
    local direct = inventory[storageId]
    if type(direct) == "table" then
        return direct
    end
    for _, item in inventory do
        if type(item) == "table" and (item.StorageKey or item.Name) == storageId then
            return item
        end
    end
end

local function fruitValue(item)
    if type(item) ~= "table" then return nil end
    return tonumber(item.Value) or tonumber(item.Price) or tonumber(item.Cost)
end

local function protectedFruit(context, storageId)
    local state = context.State
    if testAllowsFruit(context, storageId) then
        return false
    end
    local preferred = state.preferredFruit ~= state.currentFruit and state.preferredFruit or nil
    if type(context.Functions.ReservedGrindingFruit) == "function" then
        preferred = context.Functions.ReservedGrindingFruit()
    end
    if storageId == preferred then
        return true
    end
    local config = context.Environment.Config or context.Environment.Configs
    local fruitConfig = config and (config.Fruit or config["Fruit"])
    for _, wanted in fruitConfig and fruitConfig.Fruit or {} do
        if wanted == storageId then return true end
    end
    return false
end

local function carriedRaidableFruit(context)
    local player = context.LocalPlayer
    for _, root in { player:FindFirstChildOfClass("Backpack"), player.Character } do
        for _, tool in root and root:GetChildren() or {} do
            local storageId = storageIdFromTool(tool)
            if storageId and not protectedFruit(context, storageId) then
                local value = fruitValue(inventoryEntry(context, storageId))
                if testAllowsFruit(context, storageId)
                    or value and value < MAX_RAID_FRUIT_VALUE
                then
                    return tool, storageId
                end
            end
        end
    end
end

local function findSacrificialFruit(context)
    local inventory = context.Inventory.PhysicalMoveset or {}
    local test = raidTestConfig(context)
    local forcedFruit = test and test.Enable == true and test.ForcedFruit or nil
    if type(forcedFruit) == "string" and forcedFruit ~= "" then
        local item = inventory[forcedFruit]
        if type(item) == "table" and (tonumber(item.Count) or 0) > 0
            and not protectedFruit(context, forcedFruit)
        then
            return forcedFruit
        end
        for _, candidate in inventory do
            if type(candidate) == "table"
                and (candidate.StorageKey or candidate.Name) == forcedFruit
                and (tonumber(candidate.Count) or 0) > 0
                and not protectedFruit(context, forcedFruit)
            then
                return forcedFruit
            end
        end
        return nil
    end

    local candidates = {}
    for key, item in pairs(inventory) do
        if type(item) == "table" and (tonumber(item.Count) or 0) > 0 then
            local storageId = item.StorageKey or item.Name
            if type(storageId) ~= "string" and type(key) == "string" then
                storageId = key
            end
            local value = fruitValue(item)
            if storageId and value
                and (testAllowsFruit(context, storageId)
                    or value < MAX_RAID_FRUIT_VALUE)
                and not protectedFruit(context, storageId)
            then
                candidates[#candidates + 1] = { id = storageId, value = value }
            end
        end
    end
    table.sort(candidates, function(left, right)
        return left.value < right.value
    end)
    if candidates[1] then
        return candidates[1].id
    end

end

local function latestRaidIsland(rootPart)
    local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
    local locations = worldOrigin and worldOrigin:FindFirstChild("Locations")
    local latestIndex = 0
    local latest
    for _, location in locations and locations:GetChildren() or {} do
        local index = tonumber(location.Name:match("^Island (%d+)$"))
        if index and index > latestIndex and location:IsA("BasePart")
            and location.Position.Magnitude > 7000
            and (location.Position - rootPart.Position).Magnitude < 2000
        then
            latestIndex = index
            latest = location
        end
    end
    return latest
end

local function nearestRaidIsland(position)
    local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
    local locations = worldOrigin and worldOrigin:FindFirstChild("Locations")
    local nearest
    local nearestDistance = math.huge
    for _, location in locations and locations:GetChildren() or {} do
        if location:IsA("BasePart")
            and location.Name:match("^Island %d+$")
            and location.Position.Magnitude > 7000
        then
            local offset = position - location.Position
            local distance = Vector3.new(offset.X, 0, offset.Z).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearest = location
            end
        end
    end
    return nearest, nearestDistance
end

local function isOnRaidIsland(enemy, enemyRoot, island)
    if not island or not enemyRoot then
        return island == nil
    end
    local originalPosition = enemy:GetAttribute("OldPosition")
    if typeof(originalPosition) ~= "Vector3" then
        originalPosition = enemyRoot.Position
    end
    local nearest, horizontalDistance = nearestRaidIsland(originalPosition)
    return nearest == island
        and horizontalDistance <= 650
        and math.abs(originalPosition.Y - island.Position.Y) <= 500
end

local function raidMobNames(rootPart, island)
    local names = {}
    local seen = {}
    local enemies = workspace:FindFirstChild("Enemies")
    for _, enemy in enemies and enemies:GetChildren() or {} do
        local humanoid = enemy:FindFirstChildOfClass("Humanoid")
        local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
        local onIsland = not island or isOnRaidIsland(enemy, enemyRoot, island)
        if humanoid and humanoid.Health > 0 and enemyRoot and onIsland
            and (enemyRoot.Position - rootPart.Position).Magnitude <= 3000
            and enemy.Name ~= "PirateGrandBrigade"
            and enemy.Name ~= "PirateBrigade"
            and enemy.Name ~= "FishBoat"
            and not seen[enemy.Name]
        then
            seen[enemy.Name] = true
            names[#names + 1] = enemy.Name
        end
    end
    return names
end

local function currentRaidType(context)
    return "Ice"
end

local function nearestRaidEnemy(rootPart, island)
    local enemies = workspace:FindFirstChild("Enemies")
    local nearestDistance = math.huge
    local nearest
    for _, enemy in enemies and enemies:GetChildren() or {} do
        local humanoid = enemy:FindFirstChildOfClass("Humanoid")
        local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
        local nearIsland = not island or isOnRaidIsland(enemy, enemyRoot, island)
        if humanoid and humanoid.Health > 0 and enemyRoot and nearIsland
            and enemy.Name ~= "PirateGrandBrigade"
            and enemy.Name ~= "PirateBrigade"
            and enemy.Name ~= "FishBoat"
        then
            local distance = (enemyRoot.Position - rootPart.Position).Magnitude
            if distance <= 3000 and distance < nearestDistance then
                nearestDistance = distance
                nearest = enemy
            end
        end
    end
    return nearest
end

local function raidButton(context)
    local map = workspace:FindFirstChild("Map")
    local container = map and map:FindFirstChild(context.IsSea(3) and "Boat Castle" or "CircleIsland")
    local summon = container and container:FindFirstChild("RaidSummon2")
    local button = summon and summon:FindFirstChild("Button")
    local main = button and button:FindFirstChild("Main")
    local destination = main and main:IsA("BasePart") and main.CFrame
        or button and button:IsA("PVInstance") and button:GetPivot()
        or context.GetNPCCFrame("Mysterious Scientist")
    return main, destination
end

local function detachedRaidDetectors(context)
    local getAll = rawget(context.Environment, "getinstances")
        or rawget(_G, "getinstances")
    if type(getAll) ~= "function" then
        return {}
    end

    local detectors = {}
    local ok, instances = pcall(getAll)
    if not ok or type(instances) ~= "table" then
        return detectors
    end
    for _, instance in instances do
        if typeof(instance) == "Instance"
            and instance:IsA("ClickDetector")
            and instance.Parent == nil
            and instance.MaxActivationDistance == 32
        then
            detectors[#detectors + 1] = instance
        end
    end
    table.sort(detectors, function(left, right)
        local leftId = tonumber(left:GetDebugId():match("(%d+)$")) or math.huge
        local rightId = tonumber(right:GetDebugId():match("(%d+)$")) or math.huge
        return leftId < rightId
    end)
    return detectors
end

local function activateRaidRemotely(context, liveButton, owner)
    local state = context.State
    local candidates = {}
    local liveDetector = liveButton
        and liveButton:FindFirstChildOfClass("ClickDetector")
    if liveDetector then
        candidates[#candidates + 1] = liveDetector
    end
    if state.raidSummonDetector
        and state.raidSummonDetector.Parent == nil
    then
        candidates[#candidates + 1] = state.raidSummonDetector
    end
    for _, detector in detachedRaidDetectors(context) do
        if detector ~= state.raidSummonDetector then
            candidates[#candidates + 1] = detector
        end
    end

    for _, detector in candidates do
        if not isTaskCurrent(context, owner) then
            return false
        end
        local fired = pcall(fireclickdetector, detector)
        if fired then
            state.lastRaidDetectorCandidate = detector
            task.wait(0.12)
            if isRaidActive(context) then
                state.raidSummonDetector = detector
                state.lastRaidRemoteStartAt = os.clock()
                return true
            end
            if not isTaskCurrent(context, owner) then
                return false
            end
        end
    end
    return false
end

local function decrementStoredFruit(context, storageId)
    local item = context.Inventory.PhysicalMoveset
        and context.Inventory.PhysicalMoveset[storageId]
    if type(item) == "table" then
        item.Count = math.max(0, (tonumber(item.Count) or 1) - 1)
    end
end

local function resetRaidSession(context, stopMotion)
    local state = context.State
    if stopMotion then
        if type(context.Functions.StopTween) == "function" then
            context.Functions.StopTween()
        end
        if type(context.Functions.ReleaseBring) == "function" then
            context.Functions.ReleaseBring()
        end
    end
    state.raidActive = false
    state.raidIslandKey = nil
    state.raidCombatAnchor = nil
    state.raidSawIsland = nil
    state.raidEndCandidateAt = nil
    state.raidStartRequestedAt = nil
    state.raidStartPendingUntil = nil
    state.lastRaidDetectorCandidate = nil
    state.raidFruitLocks = {}
    state.raidChainReadyAt = nil
    clearChipPurchasePending(state)
end

local function shouldSchedule(context)
    local state = context.State
    if isRaidActive(context)
        or state.raidActive == true
        or state.raidStartRequestedAt ~= nil
        or os.clock() < (state.raidStartPendingUntil or 0)
    then
        return true
    end
    local missing, decision = requiredFragments(context)
    local chainReadyAt = tonumber(state.raidChainReadyAt)
    if chainReadyAt then
        if missing <= 0 then
            state.raidChainReadyAt = nil
        elseif os.clock() < chainReadyAt then
            return true
        else
            state.raidChainReadyAt = nil
        end
    end
    if os.clock() < (state.raidUnavailableUntil or 0) then
        return false
    end
    if not decision or decision.canStart ~= true or missing <= 0 then
        return false
    end
    local hasChip = carries(context, "Special Microchip") ~= nil
    if isChipPurchasePending(state, hasChip) then
        return true
    end
    return hasChip
        or carriedRaidableFruit(context) ~= nil
        or findSacrificialFruit(context) ~= nil
end

function AutoRaid.run(context, activeOnly)
    local state = context.State
    local test = raidTestConfig(context)
    local owner = context.TaskQueue:top()
    if not owner or not isTaskCurrent(context, owner) then
        return false
    end
    local active = isRaidActive(context)
    if activeOnly and not active then
        if state.raidActive or state.raidSawIsland or state.raidIslandKey then
            resetRaidSession(context, true)
        end
        return false
    end
    local missing, decision = requiredFragments(context)
    if not active and missing <= 0 then
        local completedSession = state.raidActive == true
            or state.raidSawIsland ~= nil
            or state.raidIslandKey ~= nil
        if completedSession then
            resetRaidSession(context, true)
            state.raidUnavailableUntil = os.clock() + 3
            state.status = "Godhuman | Raid target reached"
        end
        return false
    end
    if not decision or decision.canStart ~= true then
        return false
    end
    if not active and os.clock() < (state.raidChainReadyAt or 0) then
        state.status = "Auto Raid | Preparing next raid"
        return true
    end
    state.raidChainReadyAt = nil

    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart then
        return true
    end

    if active then
        clearChipPurchasePending(state)
        if test and test.Enable == true and state.raidTestStartedAt == nil then
            state.raidTestStartedAt = os.clock()
            state.raidTestStartFragments = context.Fragments.Value
        end
        if state.lastRaidDetectorCandidate then
            state.raidSummonDetector = state.lastRaidDetectorCandidate
            state.lastRaidDetectorCandidate = nil
        end
        local island = latestRaidIsland(rootPart)
        state.raidActive = true
        state.raidEndCandidateAt = nil
        if island then
            state.raidSawIsland = true
            state.raidStartPendingUntil = nil
            state.raidStartRequestedAt = nil
        end
        local islandKey = island and island.Name or "Raid Combat"
        if state.raidIslandKey ~= islandKey then
            context.Functions.ReleaseBring()
            state.raidIslandKey = islandKey
            state.raidCombatAnchor = island and CFrame.new(island.Position) or nil
        end
        local enemy = nearestRaidEnemy(rootPart, island)
        if enemy then
            local names = raidMobNames(rootPart, island)
            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
            if not state.raidCombatAnchor and enemyRoot then
                state.raidCombatAnchor = enemyRoot.CFrame
            end
            state.status = "Godhuman | Raid combat"
            context.Functions.CombatTarget(enemy, owner, {
                boss = false,
                preserveBring = true,
                weaponType = "Melee",
                targetNames = names,
                bringRadius = 650,
                maxBringMembers = math.huge,
                bringAnchor = state.raidCombatAnchor,
                raidIsland = island,
                attackRadius = 120,
                destination = state.raidCombatAnchor
                    and state.raidCombatAnchor + Vector3.new(0, 30, 0),
                status = "Auto Raid | " .. (island and island.Name or "Combat"),
            })
        elseif island then
            if state.raidCombatAnchor then
                state.status = "Auto Raid | " .. island.Name .. " | Waiting wave"
                context.Functions.TP(
                    state.raidCombatAnchor + Vector3.new(0, 30, 0),
                    owner,
                    true
                )
            else
                state.status = "Godhuman | Moving to " .. island.Name
                context.Functions.TP(island.CFrame + Vector3.new(0, 80, 0), owner, true)
            end
        else
            state.status = "Godhuman | Waiting for raid island"
        end
        return true
    end

    if state.raidActive and not state.raidSawIsland then
        local requestedAt = state.raidStartRequestedAt or state.raidTestStartedAt or os.clock()
        if os.clock() - requestedAt < 30 then
            state.status = "Raid Test | Waiting for first island"
            return true
        end
        if test and test.Enable == true then
            state.raidTestComplete = true
            state.raidTestResult = {
                success = false,
                reason = "raid-island-timeout",
                fruitsUsed = state.raidTestFruitsUsed or 0,
            }
            test.Enable = false
            resetRaidSession(context, true)
            state.status = "Raid Test | Island did not load"
            return false
        end
    end

    if state.raidActive and state.raidSawIsland then
        state.raidEndCandidateAt = state.raidEndCandidateAt or os.clock()
        if os.clock() - state.raidEndCandidateAt < 2 then
            state.status = "Auto Raid | Confirming completion"
            return true
        end
        resetRaidSession(context, true)
        state.raidUnavailableUntil = nil
        state.raidChainReadyAt = os.clock() + 3
        state.status = "Godhuman | Raid complete"
        if test and test.Enable == true then
            state.raidTestComplete = true
            state.raidTestResult = {
                success = true,
                fruitsUsed = state.raidTestFruitsUsed or 0,
                fragmentsGained = context.Fragments.Value
                    - (state.raidTestStartFragments or context.Fragments.Value),
                elapsed = state.raidTestStartedAt
                    and os.clock() - state.raidTestStartedAt or 0,
            }
            test.Enable = false
            state.status = "Raid Test | Complete"
        end
        return true
    end
    if os.clock() < (state.raidUnavailableUntil or 0) then
        return false
    end

    if state.raidStartRequestedAt
        and os.clock() - state.raidStartRequestedAt >= 30
    then
        if test and test.Enable == true then
            state.raidTestComplete = true
            state.raidTestResult = {
                success = false,
                reason = "raid-start-timeout",
                fruitsUsed = state.raidTestFruitsUsed or 0,
            }
            test.Enable = false
            state.raidStartRequestedAt = nil
            state.raidStartPendingUntil = nil
            state.status = "Raid Test | Start timed out"
            return false
        end
        state.status = "Godhuman | Raid start timed out; changing server"
        state.raidStartRequestedAt = nil
        state.raidStartPendingUntil = nil
        state.raidUnavailableUntil = os.clock() + 30
        context.Functions.HopServer(nil, true)
        return true
    end
    if os.clock() < (state.raidStartPendingUntil or 0) then
        context.Functions.CancelTween()
        state.status = "Godhuman | Waiting for raid start"
        return true
    end
    local chip = carries(context, "Special Microchip")
    if chip then
        clearChipPurchasePending(state)
        local button = raidButton(context)
        context.Functions.CancelTween()
        state.raidFruitLocks = {}
        if chip and chip.Parent ~= character then
            humanoid:EquipTool(chip)
            state.status = "Godhuman | Equipping raid chip"
            state.nextRaidStartAt = math.max(state.nextRaidStartAt or 0, os.clock() + 0.2)
            return true
        end
        if type(fireclickdetector) == "function"
            and os.clock() >= (state.nextRaidStartAt or 0)
        then
            state.status = "Godhuman | Starting " .. (state.currentRaidType or "Ice") .. " raid"
            if activateRaidRemotely(context, button, owner) then
                state.nextRaidStartAt = os.clock() + 15
                state.raidStartPendingUntil = os.clock() + 30
                state.raidStartRequestedAt = os.clock()
            elseif not isTaskCurrent(context, owner) then
                return true
            else
                state.nextRaidStartAt = os.clock() + 1
                state.raidStartPendingUntil = nil
                state.raidStartRequestedAt = nil
                state.status = "Godhuman | Retrying remote raid start"
            end
        end
        return true
    end

    if isChipPurchasePending(state, false) then
        context.Functions.CancelTween()
        state.status = "Godhuman | Waiting for raid chip"
        return true
    end

    if os.clock() < (state.nextRaidPurchaseAt or 0) then
        return true
    end
    if test and test.Enable == true
        and (state.raidTestFruitsUsed or 0) >= (tonumber(test.MaxFruits) or 1)
    then
        state.raidTestComplete = true
        state.raidTestResult = {
            success = false,
            reason = "fruit-limit",
            fruitsUsed = state.raidTestFruitsUsed or 0,
        }
        test.Enable = false
        state.status = "Raid Test | Stopped at one fruit"
        return false
    end
    local carriedFruit, carriedStorageId = carriedRaidableFruit(context)
    if carriedFruit then
        if state.fruitStoreInFlight and state.fruitStoreInFlight.id == carriedStorageId then
            state.status = "Godhuman | Waiting for fruit storage handoff"
            state.nextRaidPurchaseAt = os.clock() + 0.5
            return true
        end
        state.raidFruitLocks = state.raidFruitLocks or {}
        state.raidFruitLocks[carriedStorageId] = os.clock() + 30
    end
    if carriedFruit and carriedFruit.Parent ~= character then
        humanoid:EquipTool(carriedFruit)
        state.status = "Godhuman | Equipping raid fruit"
        state.nextRaidPurchaseAt = os.clock() + 1
        return true
    end

    state.nextRaidPurchaseAt = os.clock() + 5
    local raidType = currentRaidType(context)
    state.currentRaidType = raidType
    if carriedFruit then
        state.status = "Godhuman | Buying " .. raidType .. " raid chip"
        local success, result = pcall(function()
            return context.CommandRemote:InvokeServer("RaidsNpc", "Select", raidType)
        end)
        recordRaidPurchase(state, carriedStorageId, success, result)
        if test and test.Enable == true
            and success and result ~= nil and result ~= false
            and state.raidTestCountedCarriedFruit ~= carriedFruit
        then
            state.raidTestCountedCarriedFruit = carriedFruit
            state.raidTestFruitsUsed = (state.raidTestFruitsUsed or 0) + 1
        end
        state.nextRaidPurchaseAt = os.clock() + 2
        return true
    end

    local storageId = findSacrificialFruit(context)
    if not storageId then
        state.status = "Godhuman | Waiting for a cheap raid fruit"
        state.raidUnavailableUntil = os.clock() + 60
        return false
    end

    state.status = "Godhuman | Loading raid fruit"
    state.raidFruitLocks = state.raidFruitLocks or {}
    state.raidFruitLocks[storageId] = os.clock() + 30
    local loaded, loadResult = pcall(function()
        return context.CommandRemote:InvokeServer("LoadFruit", storageId)
    end)
    state.lastRaidFruitLoad = {
        fruit = storageId,
        success = loaded,
        result = tostring(loadResult),
        at = os.clock(),
    }
    if not loaded then
        state.raidFruitLocks[storageId] = nil
        state.nextRaidPurchaseAt = os.clock() + 30
        return true
    end

    decrementStoredFruit(context, storageId)
    if test and test.Enable == true then
        state.raidTestFruitsUsed = (state.raidTestFruitsUsed or 0) + 1
    end
    task.wait(2)
    if not isTaskCurrent(context, owner) then
        return true
    end
    local success, result = pcall(function()
        return context.CommandRemote:InvokeServer("RaidsNpc", "Select", raidType)
    end)
    recordRaidPurchase(state, storageId, success, result)
    state.nextRaidPurchaseAt = os.clock() + 2
    if type(context.Functions.RefreshInventory) == "function" then
        context.Functions.RefreshInventory(true)
    end
    return true
end

AutoRaid.isActive = isRaidActive
AutoRaid.shouldSchedule = shouldSchedule
AutoRaid.requiredFragments = requiredFragments
AutoRaid.resetSession = resetRaidSession
AutoRaid.isChipPurchasePending = isChipPurchasePending
AutoRaid.recordRaidPurchase = recordRaidPurchase
end

local AutoExpCodes
do
AutoExpCodes = {}
local TASK_NAME = "Exp Redeem"
local MAX_LEVEL = 2800
local REMOTE_RETRY_SECONDS = 3
local SUCCESS_RECHECK_SECONDS = 1
local PERSISTENCE_VERSION = 1
local PERSISTENCE_FILE_PREFIX = "seahub_exp_codes_"

local EXP_CODES = {
    "BANEXPLOIT",
    "NOMOREHACK",
    "WildDares",
    "BossBuild",
    "GetPranked",
    "EARN_FRUITS",
    "Sub2UncleKizaru",
    "FIGHT4FRUIT",
    "kittgaming",
    "TRIPLEABUSE",
    "Sub2CaptainMaui",
    "Sub2Fer999",
    "Enyu_is_Pro",
    "Magicbus",
    "JCWK",
    "Starcodeheo",
    "Bluxxy",
    "SUB2GAMERROBOT_EXP1",
    "Sub2NoobMaster123",
    "Sub2Daigrock",
    "Axiore",
    "TantaiGaming",
    "StrawHatMaine",
    "Sub2OfficialNoobie",
    "TheGreatAce",
    "SEATROLLING",
    "24NOADMIN",
    "ADMIN_TROLL",
    "NEWTROLL",
    "SECRET_ADMIN",
    "staffbattle",
    "NOEXPLOIT",
    "NOOB2ADMIN",
    "CODESLIDE",
    "EASTEREXP",
    "LIGHTNINGABUSE",
}

local CODE_SIGNATURE = table.concat(EXP_CODES, "\31")

local function isTaskCurrent(context)
    local functions = context.Functions
    if functions and type(functions.IsTaskCurrent) == "function" then
        return functions.IsTaskCurrent(TASK_NAME)
    end
    local state = context.State or {}
    return not state.stopped
        and not state.paused
        and context.TaskQueue ~= nil
        and context.TaskQueue:top() == TASK_NAME
end

local function persistenceFile(context)
    local userId = context.LocalPlayer and context.LocalPlayer.UserId
    if userId == nil then
        return nil
    end
    return PERSISTENCE_FILE_PREFIX .. tostring(userId) .. ".json"
end

local function loadPersistedState(context)
    local state = context.State
    if state.expCodePersistenceLoaded then
        return
    end
    state.expCodePersistenceLoaded = true

    local path = persistenceFile(context)
    if not path or type(readfile) ~= "function"
        or type(isfile) ~= "function" or not isfile(path)
    then
        return
    end

    local ok, stored = pcall(function()
        return game:GetService("HttpService"):JSONDecode(readfile(path))
    end)
    if not ok or type(stored) ~= "table"
        or tonumber(stored.version) ~= PERSISTENCE_VERSION
        or tostring(stored.userId) ~= tostring(context.LocalPlayer.UserId)
        or stored.signature ~= CODE_SIGNATURE
    then
        return
    end

    local index = math.max(1, math.floor(tonumber(stored.index) or 1))
    state.expCodeIndex = math.max(tonumber(state.expCodeIndex) or 1, index)
    state.expCodesExhausted = stored.exhausted == true
    state.lastExpCodePersistence = {
        action = "load",
        path = path,
        index = state.expCodeIndex,
        exhausted = state.expCodesExhausted,
        at = os.clock(),
    }
end

local function savePersistedState(context)
    local state = context.State
    local path = persistenceFile(context)
    if not path or type(writefile) ~= "function" then
        return false
    end

    local ok, failure = pcall(function()
        writefile(path, game:GetService("HttpService"):JSONEncode({
            version = PERSISTENCE_VERSION,
            userId = context.LocalPlayer.UserId,
            signature = CODE_SIGNATURE,
            index = state.expCodeIndex or 1,
            exhausted = state.expCodesExhausted == true,
            unix = os.time(),
        }))
    end)
    state.lastExpCodePersistence = {
        action = "save",
        path = path,
        index = state.expCodeIndex or 1,
        exhausted = state.expCodesExhausted == true,
        success = ok,
        error = not ok and tostring(failure) or nil,
        at = os.clock(),
    }
    return ok
end

local function remainingBoost(player)
    local startedAt = tonumber(player:GetAttribute("ExpBoostTick")) or 0
    local duration = tonumber(player:GetAttribute("ExpBoost"))
    if duration and duration > 0 and startedAt > 0 then
        return math.max(0, duration - math.max(0, tick() - startedAt)), startedAt + duration
    end
    return math.max(0, startedAt - tick()), startedAt
end

local function observeLevelProgress(state, level)
    if state.expCodeObservedLevel == nil then
        state.expCodeObservedLevel = level
    elseif state.expCodeObservedLevel ~= level then
        state.expCodeObservedLevel = level
        state.expCodeObservedProgress = true
    end
    return state.expCodeObservedProgress == true
end

local function responseActivatedBoost(response)
    return type(response) == "string"
        and string.find(response, "SUCC", 1, true) ~= nil
end

function AutoExpCodes.shouldSchedule(context)
    loadPersistedState(context)
    local level = context.Level.Value
    local observedProgress = observeLevelProgress(context.State, level)
    if context.Environment.Configs["Auto 2x Exp Codes"] == false
        or level >= MAX_LEVEL
        or context.State.expCodesExhausted == true
        or not observedProgress
    then
        return false
    end
    local remaining = remainingBoost(context.LocalPlayer)
    context.State.expBoostRemaining = remaining
    return remaining <= 0
        and os.clock() >= (context.State.nextExpCodeAttemptAt or 0)
end

function AutoExpCodes.run(context)
    if not isTaskCurrent(context) then
        return false
    end
    loadPersistedState(context)
    local state = context.State
    local level = context.Level.Value
    local observedProgress = observeLevelProgress(state, level)

    local remaining, expiresAt = remainingBoost(context.LocalPlayer)
    state.expBoostRemaining = remaining
    state.expBoostExpiresAt = expiresAt

    if context.Environment.Configs["Auto 2x Exp Codes"] == false
        or level >= MAX_LEVEL
        or not observedProgress
        or remaining > 0
        or os.clock() < (state.nextExpCodeAttemptAt or 0)
    then
        return false
    end

    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
    local redeem = remotes and remotes:FindFirstChild("Redeem")
    if not redeem then
        state.nextExpCodeAttemptAt = os.clock() + 30
        return false
    end

    local index = state.expCodeIndex or 1
    local attempted = false
    while true do
        if not isTaskCurrent(context) then
            return attempted
        end
        local code = EXP_CODES[index]
        if not code then
            state.expCodesExhausted = true
            state.nextExpCodeAttemptAt = math.huge
            savePersistedState(context)
            return attempted
        end

        attempted = true
        state.status = "Code Redemption | " .. code .. " | Redeeming"
        local before = expiresAt
        local success, result = pcall(function()
            return redeem:InvokeServer(code)
        end)
        task.wait()

        local afterRemaining, after = remainingBoost(context.LocalPlayer)
        local responseText = tostring(result)
        local activated = afterRemaining > 0
            or after > before
            or responseActivatedBoost(result)
        state.expBoostRemaining = afterRemaining
        state.expBoostExpiresAt = after
        state.lastExpCode = {
            code = code,
            success = success,
            result = responseText,
            addedSeconds = math.max(0, after - before),
            at = os.clock(),
        }

        if not success then
            state.nextExpCodeAttemptAt = os.clock() + REMOTE_RETRY_SECONDS
            return false
        end

        index += 1
        state.expCodeIndex = index
        savePersistedState(context)
        state.status = "Code Redemption | " .. code .. " | " .. responseText
        if activated then
            state.status = "Code Redemption | X2 Exp Boost Activated!"
            if afterRemaining <= 0 then
                state.nextExpCodeAttemptAt = os.clock() + SUCCESS_RECHECK_SECONDS
            end
            return true
        end

        if not isTaskCurrent(context) then
            return attempted
        end

        expiresAt = after
    end
end

AutoExpCodes.Codes = EXP_CODES
AutoExpCodes.CodeSignature = CODE_SIGNATURE
AutoExpCodes.PersistenceVersion = PERSISTENCE_VERSION
AutoExpCodes.persistenceFile = persistenceFile
end

local AutoFruitPolicy
do
AutoFruitPolicy = {}

local WEAK_FIRST_SEA_FRUITS = {
    [""] = true,
    ["Rocket-Rocket"] = true,
    ["Spin-Spin"] = true,
    ["Blade-Blade"] = true,
    ["Spring-Spring"] = true,
    ["Bomb-Bomb"] = true,
    ["Spike-Spike"] = true,
}

local function currentFruit(context)
    local data = context.LocalPlayer:FindFirstChild("Data")
    local fruit = data and data:FindFirstChild("DevilFruit")
    return fruit and tostring(fruit.Value) or ""
end

function AutoFruitPolicy.reservedFruit(context)
    if context.Environment.Configs["Auto Use Grinding Fruit"] == false then
        return nil
    end
    local fruit = currentFruit(context)
    local preferred = fruit:lower():find("buddha", 1, true) and "Buddha-Buddha"
        or context.IsSea(1) and "Light-Light" or "Buddha-Buddha"
    return preferred ~= fruit and preferred or nil
end

local function findFruitTool(player, prefix)
    for _, root in { player.Character, player:FindFirstChildOfClass("Backpack") } do
        for _, child in root and root:GetChildren() or {} do
            if child:IsA("Tool") and child.Name:lower():find(prefix:lower(), 1, true) then
                return child
            end
        end
    end
end

local function eatTool(context, tool, storageId)
    local state = context.State
    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end
    if tool.Parent ~= character then
        humanoid:EquipTool(tool)
        state.nextFruitPolicyAt = os.clock() + 1
        return true
    end
    local eatRemote = tool:FindFirstChild("EatRemote", true)
    if not eatRemote then
        state.nextFruitPolicyAt = os.clock() + 3
        return false
    end
    state.nextFruitPolicyAt = os.clock() + 10
    local success, result = pcall(function()
        return eatRemote:InvokeServer()
    end)
    state.lastFruitPolicyAction = {
        action = "eat",
        fruit = storageId,
        success = success,
        result = tostring(result),
        at = os.clock(),
    }
    return success
end

local function acquireOrEat(context, prefix, storageId)
    local tool = findFruitTool(context.LocalPlayer, prefix)
    if tool then
        return eatTool(context, tool, storageId)
    end

    local state = context.State
    local stored = context.Inventory.PhysicalMoveset
        and context.Inventory.PhysicalMoveset[storageId]
    if not stored then
        for _, item in context.Inventory.PhysicalMoveset or {} do
            if (item.StorageKey or item.Name) == storageId then
                stored = item
                break
            end
        end
    end
    if type(stored) ~= "table" or (tonumber(stored.Count) or 0) <= 0 then
        state.nextFruitPolicyAt = os.clock() + 60
        state.lastFruitPolicyAction = {
            action = "waiting-for-stored-fruit",
            fruit = storageId,
            at = os.clock(),
        }
        return false
    end

    state.nextFruitPolicyAt = os.clock() + 20
    local success, result = pcall(function()
        return context.CommandRemote:InvokeServer("LoadFruit", storageId)
    end)
    state.lastFruitPolicyAction = {
        action = "load",
        fruit = storageId,
        success = success,
        result = tostring(result),
        at = os.clock(),
    }
    return success and result ~= false
end

function AutoFruitPolicy.run(context)
    local state = context.State
    local fruit = currentFruit(context)
    state.currentFruit = fruit

    if context.Environment.Configs["Auto Use Grinding Fruit"] == false then
        return false
    end
    if fruit:lower():find("buddha", 1, true) then
        state.preferredFruit = "Buddha-Buddha"
        state.fruitPolicyLocked = true
        return false
    end
    if os.clock() < (state.nextFruitPolicyAt or 0) then
        return false
    end

    state.fruitPolicyLocked = false
    if context.IsSea(1) then
        state.preferredFruit = "Light-Light"
        if fruit:lower():find("light", 1, true) or not WEAK_FIRST_SEA_FRUITS[fruit] then
            return false
        end
        return acquireOrEat(context, "Light", "Light-Light")
    end

    state.preferredFruit = "Buddha-Buddha"
    return acquireOrEat(context, "Buddha", "Buddha-Buddha")
end
end

local AutoFruitSniper
do
AutoFruitSniper = {}

local function configuredFruitPolicy(context)
    local environment = context.Environment
    local primary = type(environment.Config) == "table" and environment.Config or nil
    local fallback = type(environment.Configs) == "table" and environment.Configs or nil
    return primary and (primary.Fruit or primary["Fruit"])
        or fallback and (fallback.Fruit or fallback["Fruit"])
end

function AutoFruitSniper.run(context)
    local policy = configuredFruitPolicy(context)
    if type(policy) ~= "table" or policy.Sniper ~= true
        or type(policy.Fruit) ~= "table" or #policy.Fruit == 0
    then
        return false
    end

    local data = context.LocalPlayer:FindFirstChild("Data")
    local devilFruit = data and data:FindFirstChild("DevilFruit")
    local current = tostring(devilFruit and devilFruit.Value or "")
    if table.find(policy.Fruit, current) then
        return false
    end

    local state = context.State
    if os.clock() < (state.nextFruitSniperAt or 0) then
        return false
    end
    state.nextFruitSniperAt = os.clock() + 10

    local ok, fruits = pcall(function()
        return context.CommandRemote:InvokeServer("GetFruits", true)
    end)
    if not ok or type(fruits) ~= "table" then
        state.lastFruitSniper = { success = false, stage = "GetFruits", at = os.clock() }
        return false
    end

    for _, fruit in pairs(fruits) do
        local name = type(fruit) == "table" and fruit.Name
        local price = type(fruit) == "table" and tonumber(fruit.Price)
        if fruit.OnSale and type(name) == "string" and table.find(policy.Fruit, name)
            and price and context.Beli and context.Beli.Value > price
        then
            local selected, selectResult = pcall(function()
                return context.CommandRemote:InvokeServer("PurchaseRawFruit", name)
            end)
            local purchased, purchaseResult = pcall(function()
                return context.CommandRemote:InvokeServer("PurchaseRawFruit", true, name)
            end)
            state.lastFruitSniper = {
                fruit = name,
                success = selected and purchased,
                selectResult = tostring(selectResult),
                purchaseResult = tostring(purchaseResult),
                at = os.clock(),
            }
            state.nextFruitSniperAt = os.clock() + 30
            return selected and purchased
        end
    end

    state.lastFruitSniper = { success = false, stage = "not-on-sale", at = os.clock() }
    return false
end
end

local AutoUtilityItems
do
AutoUtilityItems = {}

local TASK_NAME = "Utility Items Activation"
local ELECTRIC_CLAW_DESTINATION = CFrame.new(-12548, 332.378, -7617)
local ELECTRIC_CLAW_TIMEOUT = 45
local PROBE_INTERVAL = 2

local function isTaskCurrent(context)
    local functions = context.Functions
    if functions and type(functions.IsTaskCurrent) == "function" then
        return functions.IsTaskCurrent(TASK_NAME)
    end
    local state = context.State or {}
    return not state.stopped
        and not state.paused
        and context.TaskQueue:top() == TASK_NAME
end

local function carries(context, itemName)
    local player = context.LocalPlayer
    return player.Character and player.Character:FindFirstChild(itemName)
        or player:FindFirstChildOfClass("Backpack")
            and player.Backpack:FindFirstChild(itemName)
end

local function owns(context, category, name)
    return context.Functions.Owns(category, name) == true
end

local function request(context, ...)
    local args = table.pack(...)
    return pcall(function()
        return context.CommandRemote:InvokeServer(table.unpack(args, 1, args.n))
    end)
end

local function equip(context, tool)
    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not tool or not humanoid or humanoid.Health <= 0 then
        return false
    end
    if tool.Parent ~= character then
        humanoid:EquipTool(tool)
        task.wait(0.05)
    end
    return tool.Parent == character
end

local function electricClawProbe(context, force)
    local state = context.State
    local now = os.clock()
    if not force and now < (state.nextUtilityElectricClawProbeAt or 0) then
        return state.utilityElectricClawProbeResult
    end

    state.nextUtilityElectricClawProbeAt = now + PROBE_INTERVAL
    local ok, result = request(context, "BuyElectricClaw", true)
    state.lastUtilityElectricClawProbe = {
        success = ok,
        result = tostring(result),
        at = now,
    }
    if ok then
        state.utilityElectricClawProbeResult = result
    end
    return ok and result or state.utilityElectricClawProbeResult
end

local function chooseAction(context)
    local state = context.State

    if carries(context, "Hidden Key") then
        return "Hidden Key"
    end
    if carries(context, "Library Key")
        and state.deathStepUnlockConfirmed ~= true
    then
        return "Library Key"
    end
    if carries(context, "Water Key")
        and not owns(context, "Moveset", "Sharkman Karate")
        and os.clock() >= (state.utilityWaterKeyBlockedUntil or 0)
    then
        return "Water Key"
    end

    if state.electricClawUtilityActive then
        return "Previous Hero"
    end
    if context.IsSea(3)
        and not owns(context, "Moveset", "Electric Claw")
        and os.clock() >= (state.utilityElectricClawBlockedUntil or 0)
        and electricClawProbe(context, false) == 4
    then
        return "Previous Hero"
    end

    if carries(context, "Red Key") then
        return "Red Key"
    end
    if carries(context, "Hallow Essence")
        and context.Functions.GetLiveBoss("Soul Reaper") == nil
    then
        return "Soul Reaper Spawner"
    end
    if carries(context, "Fire Essence") then
        return "Uzoth"
    end
    return nil
end

local function finish(context, action)
    local state = context.State
    if action == "Previous Hero" then
        state.electricClawUtilityActive = nil
        state.electricClawUtilityStartedAt = nil
        state.electricClawUtilityReadyAt = nil
        state.electricClawUtilityMoveStartedAt = nil
    end
    state.utilityItemAction = nil
    state.lastUtilityItemAction = {
        action = action,
        at = os.clock(),
    }
    context.TaskQueue:pop(TASK_NAME)
end

local function defer(context, action, seconds, result)
    local state = context.State
    if action == "Previous Hero" then
        state.electricClawUtilityActive = nil
        state.electricClawUtilityStartedAt = nil
        state.electricClawUtilityReadyAt = nil
        state.electricClawUtilityMoveStartedAt = nil
    end
    state.utilityItemAction = nil
    state.lastUtilityItemAttempt = {
        action = action,
        result = tostring(result),
        at = os.clock(),
    }
    if action == "Water Key" then
        state.utilityWaterKeyBlockedUntil = os.clock() + (seconds or PROBE_INTERVAL)
    elseif action == "Previous Hero" then
        state.utilityElectricClawBlockedUntil = os.clock() + (seconds or PROBE_INTERVAL)
    end
    context.TaskQueue:pop(TASK_NAME)
end

local function activateLibraryKey(context)
    local state = context.State
    if os.clock() < (state.nextUtilityLibraryKeyAt or 0) then
        return true
    end
    state.nextUtilityLibraryKeyAt = os.clock() + PROBE_INTERVAL

    local ok, result = request(context, "OpenLibrary")
    state.lastLibraryKeyActivation = {
        success = ok,
        result = tostring(result),
        source = "utility-remote",
        at = os.clock(),
    }
    if not isTaskCurrent(context) then
        return false
    end
    if ok and (result == true or not carries(context, "Library Key")) then
        state.deathStepUnlockConfirmed = true
        state.libraryKeyActivationState = "complete"
        finish(context, "Library Key")
    end
    return true
end

local function activateWaterKey(context)
    local state = context.State
    if os.clock() < (state.nextUtilityWaterKeyAt or 0) then
        return true
    end
    state.nextUtilityWaterKeyAt = os.clock() + PROBE_INTERVAL

    local key = carries(context, "Water Key")
    equip(context, key)
    if not isTaskCurrent(context) then
        return false
    end
    local probeOk, probeResult = request(context, "BuySharkmanKarate", true)
    local keyAfter = carries(context, "Water Key")
    state.lastWaterKeyActivation = {
        probeSuccess = probeOk,
        probeResult = tostring(probeResult),
        keyBefore = key ~= nil,
        keyAfter = keyAfter ~= nil,
        at = os.clock(),
    }
    if owns(context, "Moveset", "Sharkman Karate")
        or not keyAfter
        or probeOk and probeResult == 1
    then
        state.sharkmanKeyDelivered = true
        state.sharkmanUnlockConfirmed = true
        state.meleePrerequisite = nil
        finish(context, "Water Key")
    else
        defer(context, "Water Key", 2, probeResult)
    end
    return true
end

local function runElectricClawTrial(context)
    local state = context.State
    local now = os.clock()
    local character = context.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        state.status = "Utility Items | Waiting character"
        return true
    end

    if not state.electricClawUtilityActive then
        local ok, result = request(context, "BuyElectricClaw", "Start")
        state.lastElectricClawTrialStart = {
            success = ok,
            result = tostring(result),
            at = now,
        }
        if not ok then
            defer(context, "Previous Hero", 2, result)
            return true
        end
        state.electricClawUtilityActive = true
        state.electricClawUtilityStartedAt = now
        state.electricClawUtilityReadyAt = now + 3
        state.status = "Utility Items | Starting Electric Claw trial"
        return true
    end

    if now < (state.electricClawUtilityReadyAt or 0) then
        state.status = "Utility Items | Waiting Electric Claw trial"
        return true
    end
    state.electricClawUtilityMoveStartedAt = state.electricClawUtilityMoveStartedAt or now
    local distance = (root.Position - ELECTRIC_CLAW_DESTINATION.Position).Magnitude
    if distance >= 30
        and now - state.electricClawUtilityMoveStartedAt
            >= ELECTRIC_CLAW_TIMEOUT
    then
        state.lastElectricClawTrialTimeout = {
            distance = distance,
            elapsed = now - state.electricClawUtilityMoveStartedAt,
            at = now,
        }
        defer(context, "Previous Hero", 5, "movement-timeout")
        return true
    end
    if distance >= 30 then
        state.status = "Utility Items | Electric Claw trial"
        context.Functions.TP(
            CFrame.new(
                ELECTRIC_CLAW_DESTINATION.Position.X,
                ELECTRIC_CLAW_DESTINATION.Position.Y + math.random(-2, 2),
                ELECTRIC_CLAW_DESTINATION.Position.Z
            ),
            TASK_NAME,
            true
        )
        return true
    end
    if now < (state.nextUtilityElectricClawCompleteAt or 0) then
        return true
    end

    state.nextUtilityElectricClawCompleteAt = now + PROBE_INTERVAL
    local result = electricClawProbe(context, true)
    if type(result) == "number" and result ~= 3 and result ~= 4 then
        state.electricClawUtilityActive = nil
        state.electricClawTrialComplete = true
        finish(context, "Previous Hero")
    elseif result == 3 then
        state.electricClawUtilityActive = nil
        defer(context, "Previous Hero", 5, result)
    end
    return true
end

local function activateHallowEssence(context)
    local state = context.State
    local map = workspace:FindFirstChild("Map")
    local castle = map and map:FindFirstChild("Haunted Castle")
    local summoner = castle and castle:FindFirstChild("Summoner")
    local detection = summoner and summoner:FindFirstChild("Detection")
    local character = context.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not detection or not root then
        state.status = "Utility Items | Waiting Soul Reaper summoner"
        return true
    end

    equip(context, carries(context, "Hallow Essence"))
    if not isTaskCurrent(context) then
        return false
    end
    state.status = "Utility Items | Using Hallow Essence"
    if (root.Position - detection.Position).Magnitude >= 100 then
        context.Functions.TP(detection.CFrame, TASK_NAME, true)
        return true
    end

    if not carries(context, "Hallow Essence")
        or context.Functions.GetLiveBoss("Soul Reaper") ~= nil
    then
        finish(context, "Soul Reaper Spawner")
    end
    return true
end

function AutoUtilityItems.shouldSchedule(context)
    return chooseAction(context) ~= nil
end

function AutoUtilityItems.run(context)
    if not isTaskCurrent(context) then
        return false
    end

    local state = context.State
    local action = chooseAction(context)
    if not isTaskCurrent(context) then
        return false
    end
    state.utilityItemAction = action
    if not action then
        context.TaskQueue:pop(TASK_NAME)
        return false
    end

    if action == "Hidden Key" then
        state.status = "Utility Items | Opening Rengoku"
        if os.clock() >= (state.nextUtilityHiddenKeyAt or 0) then
            state.nextUtilityHiddenKeyAt = os.clock() + PROBE_INTERVAL
            request(context, "OpenRengoku")
        end
        if not carries(context, "Hidden Key") then
            finish(context, action)
        end
        return true
    elseif action == "Library Key" then
        state.status = "Utility Items | Opening Library"
        return activateLibraryKey(context)
    elseif action == "Water Key" then
        state.status = "Utility Items | Unlocking Sharkman Karate"
        return activateWaterKey(context)
    elseif action == "Previous Hero" then
        return runElectricClawTrial(context)
    elseif action == "Red Key" then
        state.status = "Utility Items | Delivering Red Key"
        if os.clock() >= (state.nextUtilityRedKeyAt or 0) then
            state.nextUtilityRedKeyAt = os.clock() + PROBE_INTERVAL
            local key = carries(context, "Red Key")
            local ok, result = request(context, "CakeScientist", "Check")
            state.lastRedKeyDelivery = {
                success = ok,
                result = tostring(result),
                at = os.clock(),
            }
            if ok and key and key.Parent then
                pcall(key.Destroy, key)
            end
        end
        if not carries(context, "Red Key") then
            finish(context, action)
        end
        return true
    elseif action == "Soul Reaper Spawner" then
        return activateHallowEssence(context)
    elseif action == "Uzoth" then
        state.status = "Utility Items | Using Fire Essence"
        if os.clock() >= (state.nextUtilityFireEssenceAt or 0) then
            state.nextUtilityFireEssenceAt = os.clock() + PROBE_INTERVAL
            local ok, result = request(context, "BuyDragonTalon", true)
            state.lastFireEssenceDelivery = {
                success = ok,
                result = tostring(result),
                at = os.clock(),
            }
        end
        if not carries(context, "Fire Essence") then
            state.fireEssenceDelivered = true
            finish(context, action)
        end
        return true
    end
    return false
end

AutoUtilityItems.TASK_NAME = TASK_NAME
end

local AutoProgressionItems
do
AutoProgressionItems = {}

local function materialCount(context, name)
    local item = context.Inventory.Material and context.Inventory.Material[name]
    return type(item) == "table" and (tonumber(item.Count) or 0) or 0
end

function AutoProgressionItems.run(context)
    local state = context.State
    local now = os.clock()

    if context.IsSea(3)
        and context.Functions.Carries("God's Chalice")
        and not context.Functions.Carries("Sweet Chalice")
        and not context.Functions.Owns("Material", "Mirror Fractal")
        and materialCount(context, "Conjured Cocoa") >= 10
        and now >= (state.nextSweetChaliceAt or 0)
    then
        state.nextSweetChaliceAt = now + 5
        state.status = "Progression | Crafting Sweet Chalice"
        local ok, result = pcall(function()
            return context.CommandRemote:InvokeServer("SweetChaliceNpc")
        end)
        state.lastSweetChaliceCraft = {
            success = ok,
            result = tostring(result),
            at = now,
        }
        return true
    end

    return false
end
end

local AutoSetSpawn
do
AutoSetSpawn = {}

local MAX_CHECKPOINT_DISTANCE = 500
local RETRY_SECONDS = 10

local function getLastSpawnValue(player)
    local data = player:FindFirstChild("Data")
    return data and data:FindFirstChild("LastSpawnPoint")
end

local function nearestCheckpoint(context, rootPart, requiredName)
    local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
    local playerSpawns = worldOrigin and worldOrigin:FindFirstChild("PlayerSpawns")
    local team = context.LocalPlayer.Team
    local teamSpawns = team and playerSpawns and playerSpawns:FindFirstChild(team.Name)
    if not teamSpawns then
        return nil, math.huge
    end

    local nearest
    local nearestDistance = math.huge
    for _, checkpoint in teamSpawns:GetChildren() do
        if (not requiredName or checkpoint.Name == requiredName)
            and (checkpoint:IsA("Model") or checkpoint:IsA("BasePart"))
        then
            local success, pivot = pcall(function()
                return checkpoint:GetPivot()
            end)
            if success then
                local distance = (rootPart.Position - pivot.Position).Magnitude
                if distance < nearestDistance then
                    nearest = checkpoint
                    nearestDistance = distance
                end
            end
        end
    end
    return nearest, nearestDistance
end

function AutoSetSpawn.run(context)
    if context.Environment.Configs["Auto Set Spawn"] == false then
        return false
    end

    local state = context.State
    local character = context.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart or not humanoid or humanoid.Health <= 0 then
        return false
    end

    local lastSpawn = getLastSpawnValue(context.LocalPlayer)
    if lastSpawn and lastSpawn.Value ~= "" then
        state.lastSpawnCheckpoint = lastSpawn.Value
        state.lastSpawnVerified = true
    end

    local lockedCheckpoint = state.lockSpawnCheckpoint
    if lockedCheckpoint and lastSpawn and lastSpawn.Value == lockedCheckpoint then
        state.lastSpawnCheckpoint = lockedCheckpoint
        state.lastSpawnVerified = true
        return false
    end

    local checkpoint, distance = nearestCheckpoint(context, rootPart, lockedCheckpoint)
    if not checkpoint or distance > MAX_CHECKPOINT_DISTANCE then
        return false
    end

    if lastSpawn and lastSpawn.Value == checkpoint.Name then
        state.lastSpawnCheckpoint = checkpoint.Name
        state.lastSpawnVerified = true
        return false
    end
    if os.clock() < (state.nextSetSpawnAt or 0) then
        return false
    end

    state.nextSetSpawnAt = os.clock() + RETRY_SECONDS
    local success, result = pcall(function()
        return context.CommandRemote:InvokeServer("SetLastSpawnPoint", checkpoint.Name)
    end)
    state.lastSetSpawn = {
        checkpoint = checkpoint.Name,
        distance = distance,
        success = success,
        result = tostring(result),
        at = os.clock(),
    }
    state.lastSpawnCheckpoint = checkpoint.Name
    state.lastSpawnVerified = success and lastSpawn and lastSpawn.Value == checkpoint.Name or false
    return success
end
end

local AutoAbilities
do
AutoAbilities = {}

local REQUESTS = {
    { name = "AirJump", args = { "BuyHaki", "Geppo" } },
    { name = "Aura", args = { "BuyHaki", "Buso" } },
    { name = "FlashStep", args = { "BuyHaki", "Soru" } },
    { name = "Instinct", args = { "KenTalk", "Buy" } },
}

local function carriesBlackLeg(context)
    local melee = context.MeleeInventory
        and context.MeleeInventory.Melee
        and context.MeleeInventory.Melee["Black Leg"]
    if type(melee) == "table" and melee.Bought == true then
        return true
    end

    if context.Functions and type(context.Functions.Owns) == "function" then
        local success, owned = pcall(context.Functions.Owns, "Moveset", "Black Leg")
        if success and owned then
            return true
        end
    end

    local player = context.LocalPlayer
    for _, container in { player and player.Character, player and player.Backpack } do
        if container and (container:FindFirstChild("Black Leg") or container:FindFirstChild("Dark Step")) then
            return true
        end
    end
    return false
end

function AutoAbilities.canAttemptPurchases(context)
    return not context.IsSea(1) or carriesBlackLeg(context)
end

function AutoAbilities.run(context)
    local configs = context.Environment.Configs
    if configs["Buy Stuffs"] == false then
        return false
    end

    local state = context.State
    if not AutoAbilities.canAttemptPurchases(context) then
        state.abilityGate = "waiting-black-leg"
        return false
    end
    if os.clock() < (state.nextAbilityCheckAt or 0) then
        return false
    end
    state.nextAbilityCheckAt = os.clock() + 30
    state.abilityGate = nil
    state.lastAbilityPurchases = {}

    for _, request in REQUESTS do
        local success, result = pcall(function()
            return context.CommandRemote:InvokeServer(table.unpack(request.args))
        end)
        local purchase = {
            name = request.name,
            result = tostring(result),
            success = success,
            at = os.clock(),
        }
        state.lastAbilityPurchases[#state.lastAbilityPurchases + 1] = purchase
        state.lastAbilityPurchase = purchase
        if not success then
            state.lastAbilityError = tostring(result)
        end
    end
    return true
end
end

local AutoFruitGacha
do
AutoFruitGacha = {}
local ItemConfig

local GACHA_BOXES = { "MagnetEventGacha26", "ZiolesGacha" }
local GACHA_NPC = "Blox Fruit Gacha"
local DEFAULT_CHECK_SECONDS = 300
local FAILED_CHECK_SECONDS = 60
local REQUIREMENT_RETRY_SECONDS = 30
local PURCHASE_RETRY_SECONDS = 5
local STORE_RETRY_SECONDS = 3
local STORE_MAX_RETRY_SECONDS = 30
local STORE_REQUEST_TIMEOUT_SECONDS = 10

local function lifecycleGuard(context)
    local state = context.State
    local generation, revision = state.runtimeGeneration, state.runtimeLifecycleRevision
    return function()
        return not state.stopped and not state.paused
            and state.runtimeGeneration == generation and state.runtimeLifecycleRevision == revision
    end
end

local function storeRequestRunning(state)
    local thread = state.fruitStoreRequestThread
    if type(thread) == "thread" and coroutine.status(thread) ~= "dead" then return true end
    state.fruitStoreRequestThread = nil
    return false
end

local function isCarried(context, tool)
    local parent = tool.Parent
    local player = context.LocalPlayer
    return parent ~= nil and (parent == player.Character
        or parent == player:FindFirstChildOfClass("Backpack"))
end

local function storedCount(context, storageId)
    local inventory = context.Inventory.PhysicalMoveset or {}
    local stored = inventory[storageId]
    if type(stored) ~= "table" then
        for _, candidate in inventory do
            if type(candidate) == "table"
                and (candidate.StorageKey or candidate.Name) == storageId
            then
                stored = candidate
                break
            end
        end
    end
    return type(stored) == "table" and (tonumber(stored.Count) or 0) or 0
end

local function confirmStore(context, tool, pending)
    if not pending or isCarried(context, tool)
        or storedCount(context, pending.id) <= pending.before
    then
        return false
    end
    local state = context.State
    state.lastFruitStore = {
        id = pending.id, success = true, confirmed = true,
        result = pending.result, at = os.clock(),
    }
    state.fruitStorePending[tool] = nil
    state.fruitStoreFailures[tool] = nil
    state.fruitStoreAttempts[tool] = nil
    return true
end

local function itemConfigForTool(tool)
    local success, result = pcall(function()
        ItemConfig = ItemConfig or require(game:GetService("ReplicatedStorage"):WaitForChild("ItemConfig"))
        local matched = ItemConfig.match(tool)
        return matched and matched.unwrap and matched:unwrap() or matched
    end)
    return success and type(result) == "table" and result or nil
end

local function getGachaClient()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local controllers = replicatedStorage:FindFirstChild("Controllers")
    local module = controllers and controllers:FindFirstChild("GachaClient")
    if not module then
        return nil
    end
    local success, client = pcall(require, module)
    return success and type(client) == "table" and client or nil
end

local function getGachaNetwork(context)
    if context.GachaNetworkRF then
        return context.GachaNetworkRF
    end

    local success, remote = pcall(function()
        local replicatedStorage = game:GetService("ReplicatedStorage")
        local modules = replicatedStorage:FindFirstChild("Modules")
        local netModule = modules and modules:FindFirstChild("Net")
        if not netModule then
            return nil
        end
        local net = require(netModule)
        return net:RemoteFunction("GachaNetworkRF")
    end)
    return success and remote or nil
end

local function clearSpinnerLocks(context, current)
    current = current or lifecycleGuard(context)
    if not current() then return false end
    pcall(function()
        local replicatedStorage = game:GetService("ReplicatedStorage")
        local locks = require(replicatedStorage.Controllers.Locks)
        if current() and locks and locks.SpinnerLock then
            locks.SpinnerLock:Unlock()
        end
    end)
    if not current() then return false end
    pcall(function()
        local replicatedStorage = game:GetService("ReplicatedStorage")
        local spinner = require(replicatedStorage.Controllers.UI.Spinner)
        if current() and spinner and spinner.Close then
            spinner:Close()
        end
    end)
    if not current() then return false end

    for _, attribute in {
        "NPC_INTERACTION_LOCKClient",
        "HOT_BAR_LOCKClient",
        "TOUCH_GUI_LOCKClient",
        "NOTIFICATIONS_SCREEN_LOCKClient",
        "MenuHiddenClient",
    } do
        if (tonumber(context.LocalPlayer:GetAttribute(attribute)) or 0) > 0 then
            context.LocalPlayer:SetAttribute(attribute, 0)
        end
    end
    return true
end

local function closeGachaWindowWhenReady(context)
    local state = context.State
    if state.stopped then return end
    local generation = state.runtimeGeneration
    if type(state.gachaCloseThread) == "thread"
        and type(task.cancel) == "function"
    then
        pcall(task.cancel, state.gachaCloseThread)
    end
    local token = {}
    state.gachaCloseToken = token
    local function owns()
        return not state.stopped and state.runtimeGeneration == generation and state.gachaCloseToken == token
    end
    local function current()
        return owns() and not state.paused
    end
    local function finish()
        if state.gachaCloseToken == token then
            state.gachaCloseThread = nil
            state.gachaCloseToken = nil
        end
    end
    local thread = task.spawn(function()
        local deadline = os.clock() + 15
        repeat
            if not owns() then finish(); return end
            if state.paused then
                deadline = os.clock() + 15
                task.wait(0.25)
                continue
            end
            if not clearSpinnerLocks(context, current) then
                if not owns() then finish(); return end
                task.wait(0.25)
                continue
            end
            local playerGui = context.LocalPlayer:FindFirstChildOfClass("PlayerGui")
            local spinner = playerGui and playerGui:FindFirstChild("SpinnerWindow")
            local closeButton = spinner and spinner:FindFirstChild("CloseButton", true)
            if spinner and spinner.Enabled and closeButton and type(firesignal) == "function" then
                local success, failure = pcall(firesignal, closeButton.Activated)
                if not current() then
                    if not owns() then finish(); return end
                    task.wait(0.25)
                    continue
                end
                context.State.lastGachaWindowClose = {
                    success = success,
                    error = not success and tostring(failure) or nil,
                    at = os.clock(),
                }
                if success then
                    finish()
                    return
                end
            end
            task.wait(0.25)
        until not state.paused and os.clock() >= deadline
        if not clearSpinnerLocks(context, current) then
            finish(); return
        end
        state.lastGachaWindowClose = {
            success = false,
            error = "close-button-timeout",
            at = os.clock(),
        }
        finish()
    end)
    if state.gachaCloseToken == token then
        state.gachaCloseThread = thread
    end
end

local function networkRequirementsMet(check)
    if type(check) ~= "table" then
        return false
    end
    local restricted = type(check.PaidRandomItemsRestricted) == "table"
        and check.PaidRandomItemsRestricted.Value == true
    local levelBlocked = type(check.Level) == "table"
        and check.Level.RequirementMet == false
    local currencyReady = type(check.Cooldown) == "table"
        and check.Cooldown.RequirementMet == true
        and type(check.Price) == "table"
        and check.Price.RequirementMet == true
    local silverReady = type(check.Keys) == "table"
        and type(check.Keys.Silver) == "table"
        and check.Keys.Silver.RequirementMet == true
    return not restricted and not levelBlocked and (currencyReady or silverReady)
end

local function networkRetrySeconds(check)
    if type(check) ~= "table" then
        return FAILED_CHECK_SECONDS
    end
    if type(check.Cooldown) == "table"
        and check.Cooldown.RequirementMet == false
    then
        return math.max(
            PURCHASE_RETRY_SECONDS,
            (tonumber(check.Cooldown.TimeEnds) or 0) - os.time()
        )
    end
    return REQUIREMENT_RETRY_SECONDS
end

local function fruitStorageId(tool)
    if typeof(tool) ~= "Instance" or not tool:IsA("Tool") then
        return nil
    end
    for _, attributeName in { "StorageKey", "FruitId" } do
        local value = tool:GetAttribute(attributeName)
        if type(value) == "string" and value ~= "" then
            return value
        end
    end
    local matched = itemConfigForTool(tool)
    local index = matched and matched.Index or {}
    local storageId = matched and (matched.FruitId or matched.StorageKey)
        or index.StorageKey
    if type(storageId) == "string" and storageId ~= "" then
        return storageId
    end
    if not tool.Name:match("Fruit$") then
        return nil
    end
    local prefix = tool.Name:match("^%s*(%S+)")
    return prefix and prefix .. "-" .. prefix or nil
end

local function storeFruit(context, tool, options)
    options = options or {}
    local state = context.State
    local current = lifecycleGuard(context)
    if not current() or state.fruitStoreInFlight or storeRequestRunning(state) then
        return false
    end
    local storageId = fruitStorageId(tool)
    if not storageId or not current() or state.fruitStoreInFlight or storeRequestRunning(state) then
        return false
    end
    state.fruitStoreAttempts = state.fruitStoreAttempts or setmetatable({}, { __mode = "k" })
    state.fruitStoreFailures = state.fruitStoreFailures or setmetatable({}, { __mode = "k" })
    state.fruitStorePending = state.fruitStorePending or setmetatable({}, { __mode = "k" })
    if confirmStore(context, tool, state.fruitStorePending[tool]) then
        return true
    end
    if not isCarried(context, tool) then
        return false
    end
    local preferred = state.preferredFruit ~= state.currentFruit and state.preferredFruit or nil
    if type(context.Functions.ReservedGrindingFruit) == "function" then
        preferred = context.Functions.ReservedGrindingFruit()
    end
    if not current() or state.fruitStoreInFlight or storeRequestRunning(state) then return false end
    if not options.ignoreReservations and storageId == preferred then
        return false
    end
    for _, locks in { state.raidFruitLocks, state.trevorFruitLocks } do
        local lockedUntil = locks and locks[storageId]
        if not options.ignoreReservations and lockedUntil and os.clock() < lockedUntil then
            return false
        elseif lockedUntil and os.clock() >= lockedUntil then
            locks[storageId] = nil
        end
    end
    if os.clock() < (state.fruitStoreAttempts[tool] or 0) then
        return false
    end

    local pending = { id = storageId, before = storedCount(context, storageId), at = os.clock() }
    state.fruitStorePending[tool] = pending
    state.fruitStoreInFlight = pending
    state.fruitStoreStartedAt = os.clock()
    state.fruitStoreAttempts[tool] = os.clock() + STORE_REQUEST_TIMEOUT_SECONDS
    local finished, success, result = false, false, nil
    local expired = false
    local deadline = os.clock() + STORE_REQUEST_TIMEOUT_SECONDS
    local requestThread = task.spawn(function()
        success, result = pcall(function()
            return context.CommandRemote:InvokeServer("StoreFruit", storageId, tool)
        end)
        if not expired and os.clock() < deadline and current() and state.fruitStoreInFlight == pending
            and type(context.Functions.RefreshInventory) == "function"
        then
            pcall(context.Functions.RefreshInventory, true)
        end
        finished = true
        if state.fruitStoreRequestThread == coroutine.running() then
            state.fruitStoreRequestThread = nil
        end
    end)
    if not finished then state.fruitStoreRequestThread = requestThread end
    while not finished and os.clock() < deadline
        and state.fruitStoreInFlight == pending and current()
    do
        task.wait(0.1)
    end
    if not finished then
        expired = true
        if type(requestThread) == "thread" and type(task.cancel) == "function" then
            pcall(task.cancel, requestThread)
        end
        success, result = false, "store-request-timeout-or-cancelled"
    end
    if state.fruitStoreRequestThread == requestThread
        and (type(requestThread) ~= "thread" or coroutine.status(requestThread) == "dead") then
        state.fruitStoreRequestThread = nil
    end
    if state.fruitStoreInFlight ~= pending then
        return false
    end
    pending.result = tostring(result)
    state.fruitStoreInFlight = nil
    if not current() then
        return false
    end
    if confirmStore(context, tool, pending) then
        return true
    end
    local failures = math.min(5, (state.fruitStoreFailures[tool] or 0) + 1)
    state.fruitStoreFailures[tool] = failures
    state.fruitStoreAttempts[tool] = os.clock()
        + (not finished and STORE_MAX_RETRY_SECONDS
            or math.min(STORE_MAX_RETRY_SECONDS, STORE_RETRY_SECONDS * 2 ^ (failures - 1)))
    state.lastFruitStore = {
        id = storageId, success = false, confirmed = false,
        requestOk = success, result = tostring(result),
        reason = not success and "request-error" or result == false and "rejected" or "awaiting-replication",
        retryAt = state.fruitStoreAttempts[tool], at = os.clock(),
    }
    return false
end

local function storeCarriedFruits(context)
    local state = context.State
    local current = lifecycleGuard(context)
    if not current() or state.fruitStoreInFlight or storeRequestRunning(state) then
        return false
    end
    local player = context.LocalPlayer
    local fruits = {}
    for _, root in { player:FindFirstChildOfClass("Backpack"), player.Character } do
        for _, child in root and root:GetChildren() or {} do
            if child:IsA("Tool") and child.Name:match("Fruit$") then
                table.insert(fruits, child)
            end
        end
    end
    if #fruits == 0 and not next(state.fruitStorePending or {}) then
        return false
    end
    if type(context.Functions.RefreshInventory) == "function" then
        pcall(context.Functions.RefreshInventory)
    end
    if not current() then
        return false
    end
    for tool, pending in state.fruitStorePending or {} do
        if not confirmStore(context, tool, pending)
            and not isCarried(context, tool) and os.clock() - pending.at > 30
        then
            state.fruitStorePending[tool] = nil
            state.fruitStoreFailures[tool] = nil
            state.fruitStoreAttempts[tool] = nil
        end
    end
    for _, fruit in fruits do
        if not current() then return false end
        storeFruit(context, fruit)
    end
    return true
end

local function runNetworkGacha(context, remote, current, cleanupPurchase)
    local state = context.State
    local checks = {}
    local nextDelay = DEFAULT_CHECK_SECONDS

    for _, boxName in GACHA_BOXES do
        if not current() then return false end
        local checked, check = pcall(function()
            return remote:InvokeServer({
                Context = "Check",
                BoxName = boxName,
                SpokeNPC = GACHA_NPC,
            })
        end)
        if not current() then return false end
        local record = {
            box = boxName,
            success = checked,
            ready = checked and networkRequirementsMet(check) or false,
            at = os.clock(),
        }
        if checked and type(check) == "table" then
            record.cooldownEnds = type(check.Cooldown) == "table"
                and check.Cooldown.TimeEnds or nil
            record.cooldownReady = type(check.Cooldown) == "table"
                and check.Cooldown.RequirementMet or nil
            record.priceReady = type(check.Price) == "table"
                and check.Price.RequirementMet or nil
            nextDelay = math.min(nextDelay, networkRetrySeconds(check))

            if record.ready then
                local purchased, result = pcall(function()
                    return remote:InvokeServer({
                        Context = "Purchase",
                        BoxName = boxName,
                    })
                end)
                if not current() then cleanupPurchase(purchased, result); return false end
                record.purchaseSuccess = purchased
                record.purchaseResult = tostring(result)
                state.lastFruitGacha = {
                    path = "GachaNetworkRF",
                    box = boxName,
                    success = purchased and result ~= nil and result ~= false,
                    result = tostring(result),
                    at = os.clock(),
                }
                table.insert(checks, record)
                state.lastFruitGachaChecks = checks

                if purchased and result ~= nil and result ~= false then
                    task.wait(1)
                    if not clearSpinnerLocks(context, current) then return false end
                    closeGachaWindowWhenReady(context)
                    if not current() then return false end
                    if type(context.Functions.RefreshInventory) == "function" then
                        pcall(context.Functions.RefreshInventory, true)
                    end
                    if not current() then return false end
                    storeCarriedFruits(context)
                    if not current() then return false end
                    state.nextFruitGachaAt = os.clock() + PURCHASE_RETRY_SECONDS
                    return true
                end
                nextDelay = math.min(nextDelay, PURCHASE_RETRY_SECONDS)
            end
        else
            record.error = tostring(check)
            nextDelay = math.min(nextDelay, FAILED_CHECK_SECONDS)
        end
        table.insert(checks, record)
    end

    if not clearSpinnerLocks(context, current) then return false end
    state.lastFruitGachaChecks = checks
    state.lastFruitGacha = {
        path = "GachaNetworkRF",
        success = false,
        stage = "not-ready",
        at = os.clock(),
    }
    state.nextFruitGachaAt = os.clock()
        + math.max(PURCHASE_RETRY_SECONDS, nextDelay)
    return false
end

function AutoFruitGacha.run(context)
    local state = context.State
    local alive = lifecycleGuard(context)
    local generation = state.runtimeGeneration
    local token = state.fruitGachaBackgroundToken
    local function current()
        return alive() and state.fruitGachaBackgroundToken == token
            and context.Environment.Configs["Auto Random Fruit"] ~= false
    end
    local function cleanupPurchase(success, result)
        if success and result ~= nil and result ~= false and not state.stopped
            and state.runtimeGeneration == generation and state.fruitGachaBackgroundToken == token
        then closeGachaWindowWhenReady(context) end
    end
    if not current() then
        return false
    end

    storeCarriedFruits(context)
    if not current() then return false end

    local level = context.Level.Value
    if level < 50 then
        return false
    end
    if os.clock() < (state.nextFruitGachaAt or 0) then
        return false
    end

    local network = getGachaNetwork(context)
    if not current() then return false end
    if network then
        state.fruitGachaPath = "GachaNetworkRF"
        return runNetworkGacha(context, network, current, cleanupPurchase)
    end
    state.fruitGachaPath = "legacy-fallback"

    local price = (level - 1) * 150 + 25000
    local gachaClient = getGachaClient()
    if not current() then return false end
    local check
    if gachaClient and type(gachaClient.CheckGachaAsync) == "function" then
        local checked, result = pcall(
            gachaClient.CheckGachaAsync,
            GACHA_BOXES[2],
            GACHA_NPC
        )
        if not current() then return false end
        if checked and type(result) == "table" then
            check = result
            if type(result.Price) == "table" then
                price = tonumber(result.Price.Value) or price
            end
            state.lastFruitGachaCheck = {
                requirementsMet = result.RequirementsMet == true,
                price = price,
                cooldownEnds = type(result.Cooldown) == "table" and result.Cooldown.TimeEnds or nil,
                at = os.clock(),
            }
            if result.RequirementsMet ~= true then
                local cooldownEnds = type(result.Cooldown) == "table"
                    and tonumber(result.Cooldown.TimeEnds) or nil
                local retry = cooldownEnds and math.max(5, cooldownEnds - os.time()) or 120
                state.nextFruitGachaAt = os.clock() + math.min(retry, 120)
                return false
            end
        end
    end

    if context.Beli.Value < price then
        state.fruitGachaWaitingForMoney = price
        return false
    end

    state.fruitGachaWaitingForMoney = nil
    state.nextFruitGachaAt = os.clock() + 120
    local before = context.Beli.Value
    local success, result
    if gachaClient and type(gachaClient.PurchaseGachaAsync) == "function" then
        success, result = pcall(gachaClient.PurchaseGachaAsync, GACHA_BOXES[2])
    else
        success, result = pcall(function()
            return context.CommandRemote:InvokeServer("Cousin", "Buy")
        end)
    end
    if not current() then cleanupPurchase(success, result); return false end
    state.lastFruitGacha = {
        success = success,
        result = tostring(result),
        expectedPrice = price,
        spent = math.max(0, before - context.Beli.Value),
        at = os.clock(),
    }
    local purchased = success and result ~= nil and result ~= false
    if purchased then
        state.nextFruitGachaAt = os.clock() + 7200
        closeGachaWindowWhenReady(context)
        task.wait(0.25)
        if not current() then return false end
        storeCarriedFruits(context)
    end
    return success
end

AutoFruitGacha.storeFruit = storeFruit
AutoFruitGacha.storeCarriedFruits = storeCarriedFruits
AutoFruitGacha.networkRequirementsMet = networkRequirementsMet
AutoFruitGacha.networkRetrySeconds = networkRetrySeconds
AutoFruitGacha.GachaBoxes = GACHA_BOXES
end

local TaskQueue
do
TaskQueue = {}
TaskQueue.__index = TaskQueue

function TaskQueue.new()
    return setmetatable({ entries = {}, sequence = 0 }, TaskQueue)
end

function TaskQueue:push(name, priority)
    local entry = self.entries[name]
    if entry then
        entry.priority = tonumber(priority) or entry.priority
        return
    end
    self.sequence += 1
    self.entries[name] = {
        name = name,
        priority = tonumber(priority) or 0,
        sequence = self.sequence,
    }
end

function TaskQueue:pop(name)
    self.entries[name] = nil
end

function TaskQueue:top()
    local selected
    for _, entry in self.entries do
        if not selected or entry.priority > selected.priority
            or entry.priority == selected.priority and entry.sequence < selected.sequence
        then
            selected = entry
        end
    end
    return selected and selected.name or nil
end

function TaskQueue:clear()
    table.clear(self.entries)
end
end

local CleanRuntimeController
do
CleanRuntimeController = {}
CleanRuntimeController.__index = CleanRuntimeController
local function cancelThread(thread)
    if type(thread) == "thread" and type(task.cancel) == "function" then
        pcall(task.cancel, thread)
    end
end

local function copyContext(base)
    local context = {}
    for key, value in base do
        context[key] = value
    end
    return context
end

local function copyState(base)
    local state = {}
    for key, value in base do
        state[key] = value
    end
    return state
end

local function makeRecorder(controller, name, returnValue)
    return function(...)
        controller:record(name, ...)
        return returnValue
    end
end

function CleanRuntimeController.create(baseContext, modules, options)
    options = options or {}
    local self = setmetatable({}, CleanRuntimeController)
    local context = copyContext(baseContext)

    context.State = copyState(baseContext.State)
    context.State.paused = options.paused ~= false
    context.State.stopped = false
    context.State.status = "Clean runtime ready"
    context.TaskQueue = TaskQueue.new()
    context.TaskPriorities = ControllerOrder.copyPriorities()
    context.TaskDefinitions = setmetatable({}, {
        __index = function(definitions, name)
            local definition = { args = {} }
            rawset(definitions, name, definition)
            return definition
        end,
    })
    context.NearbyTargets = {}
    context.NearbyTargetParts = {}
    context.MobCFrameCache = {}
    self.FallbackCalls = {}
    self.FallbackFirstSeen = {}
    self.InvokeFallbacks = options.invokeFallbacks == true
    local fallbackWrappers = {}
    context.Functions = setmetatable({}, {
        __index = function(_, name)
            local value = baseContext.Functions[name]
            if type(value) ~= "function" then
                return value
            end
            if not fallbackWrappers[name] then
                fallbackWrappers[name] = function(...)
                    self.FallbackCalls[name] = (self.FallbackCalls[name] or 0) + 1
                    self.FallbackFirstSeen[name] = self.FallbackFirstSeen[name] or os.clock()
                    self:record("CapturedFallback", name)
                    if self.InvokeFallbacks then
                        return value(...)
                    end
                    return nil
                end
            end
            return fallbackWrappers[name]
        end,
    })
    context.FarmWatchdogState = {
        Enabled = true,
        Config = { PollSeconds = 0.5, MissingMobHopSeconds = 60, HopRetrySeconds = 120 },
        Hops = 0,
        MissingSince = 0,
        MissingSeconds = 0,
        LastProgressAt = os.clock(),
        LastProgressKind = "initial",
        TargetCount = 0,
        TargetHealth = 0,
    }

    self.Context = context
    self.BaseContext = baseContext
    self.DryRun = options.dryRun ~= false
    self.ActionPolicy = {
        quest = options.actions and options.actions.quest == true,
        movement = options.actions and options.actions.movement == true,
        equip = options.actions and options.actions.equip == true,
        combat = options.actions and options.actions.combat == true,
        remote = options.actions and options.actions.remote == true,
        stats = options.actions and options.actions.stats == true,
        serverHop = options.actions and options.actions.serverHop == true,
    }
    self.Events = {}
    self.MaxEvents = options.maxEvents or 300
    self.Generation = 0
    self.LifecycleRevision = 0
    RuntimeContext.bindCleanFunctions(context, modules)

    context.TaskDefinitions["Auto Farm Level"].func = context.Functions.AutoFarmLevel
    context.TaskDefinitions["Auto Raid"].func = function()
        return context.Functions.AutoRaid(false)
    end
    context.TaskDefinitions["Farm Boss"].func = context.Functions.FarmBoss
    context.TaskDefinitions["Special Boss"].func = context.Functions.FarmBoss
    context.TaskDefinitions["Auto Bartilo Quest"].func = context.Functions.AutoBartiloQuest
    context.TaskDefinitions["Melee Materials"].func = context.Functions.AutoMeleeMaterial
    context.TaskDefinitions["Auto Second Sea"].func = function()
        return context.Functions.AutoSecondSea("Auto Second Sea")
    end
    context.TaskDefinitions["Auto Third Sea"].func = function()
        return context.Functions.AutoThirdSea("Auto Third Sea")
    end
    context.TaskDefinitions["Auto Trevor"].func = function()
        return context.Functions.AutoTrevor("Auto Trevor")
    end
    context.TaskDefinitions["Get Fruits"].func = context.Functions.CollectDroppedFruit
    context.TaskDefinitions["Auto Saber"].func = context.Functions.AutoSaber
    context.TaskDefinitions["Auto Yama"].func = context.Functions.AutoYama
    context.TaskDefinitions["Auto Tushita"].func = context.Functions.AutoTushita
    context.TaskDefinitions["Utility Items Activation"].func = context.Functions.AutoUtilityItems
    context.TaskDefinitions["Pirate Raid"].func = context.Functions.AutoPirateRaid
    context.TaskDefinitions["Tyrant Boss"].func = context.Functions.AutoTyrantBoss
    context.TaskDefinitions["Auto Soul Guitar"].func = context.Functions.AutoSoulGuitar
    context.TaskDefinitions["Exp Redeem"].func = context.Functions.AutoExpCodes
    context.TaskQueue:push("Auto Farm Level", context.TaskPriorities["Auto Farm Level"])
    context.Functions.ReleaseBossCombat = makeRecorder(self, "ReleaseBossCombat")

    if self.DryRun or not self.ActionPolicy.movement then
        context.Functions.TP = makeRecorder(self, "TP", true)
    end
    if self.DryRun or not self.ActionPolicy.combat then
        context.Functions.Attack = makeRecorder(self, "Attack")
        context.Functions.AutoBuso = makeRecorder(self, "AutoBuso", true)
        context.Functions.BringMob = makeRecorder(self, "BringMob")
    end
    if self.DryRun or not self.ActionPolicy.movement then
        context.Functions.StopTween = makeRecorder(self, "StopTween")
    end
    if self.DryRun or not self.ActionPolicy.serverHop then
        context.Functions.HopServer = makeRecorder(self, "HopServer", false)
    end
    if self.DryRun or not self.ActionPolicy.equip then
        context.Functions.EquipWeapon = makeRecorder(self, "EquipWeapon", true)
        context.Functions.AutoAccessory = makeRecorder(self, "AutoAccessory", false)
    end

    if self.DryRun or not (self.ActionPolicy.remote or self.ActionPolicy.stats) then
        local remote = {}
        function remote:InvokeServer(...)
            self.Controller:record("Remote", ...)
            return nil
        end
        remote.Controller = self
        context.CommandRemote = remote
    else
        local realCommandRemote = baseContext.CommandRemote
        if type(realCommandRemote) == "table" and type(realCommandRemote.BindState) == "function" then
            realCommandRemote = realCommandRemote:BindState(context.State)
        end
        local commandGate = { Controller = self }
        function commandGate:InvokeServer(command, ...)
            local controller = self.Controller
            local allowed = controller.ActionPolicy.remote
                or controller.ActionPolicy.stats and command == "AddPoint"
            if not allowed then
                controller:record("RemoteBlocked", command, ...)
                return nil
            end
            controller:record("RemoteCall", command, ...)
            local results = table.pack(realCommandRemote:InvokeServer(command, ...))
            controller:record("RemoteResult", command, results[1])
            return table.unpack(results, 1, results.n)
        end
        context.CommandRemote = commandGate
    end

    if self.ActionPolicy.quest and not self.DryRun then
        local realQuestRemote = baseContext.QuestRemote
        local questGate = { Controller = self }
        function questGate:InvokeServer(command, ...)
            local controller = self.Controller
            local state = controller.Context.State
            local acquire = state.questAcquire
            if command == "StartQuest" and (not acquire or (acquire.distance or math.huge) > 25) then
                controller:record("QuestRemoteBlockedDistance", command, ...)
                return nil
            end
            controller:record("QuestRemoteForwarded", command, ...)
            local results = table.pack(realQuestRemote:InvokeServer(command, ...))
            controller:record("QuestRemoteResult", command, results[1])
            return table.unpack(results, 1, results.n)
        end
        context.QuestRemote = questGate
    else
        local questRemote = { Controller = self }
        function questRemote:InvokeServer(...)
            self.Controller:record("QuestRemote", ...)
            return nil
        end
        context.QuestRemote = questRemote
    end

    return self
end

function CleanRuntimeController:record(action, ...)
    local event = { at = os.clock(), action = action, args = table.pack(...) }
    self.Events[#self.Events + 1] = event
    if #self.Events > self.MaxEvents then
        table.remove(self.Events, 1)
    end
    self.Context.State.lastDryRunAction = action
    return event
end

function CleanRuntimeController:start()
    self.LifecycleRevision = (tonumber(self.LifecycleRevision) or 0) + 1
    if self.Running then
        return false, "already-running"
    end
    self.Generation += 1
    local generation = self.Generation
    local state = self.Context.State
    state.runtimeGeneration = generation
    state.runtimeLifecycleRevision = self.LifecycleRevision
    state.inventoryStartupPending = self.DryRun == false
        and type(self.Context.Functions.RefreshInventory) == "function"
        and state.inventoryReady ~= true
    state.stopped = false
    state.paused = false
    self.Running = true
    local function currentGeneration()
        return generation == self.Generation and not state.stopped
    end
    state.lastTaskName = nil
    self.Context.TaskQueue:clear()
    self.Context.TaskQueue:push(
        "Auto Farm Level",
        self.Context.TaskPriorities["Auto Farm Level"]
    )
    if type(self.Context.AttachQuestNotification) == "function" then
        pcall(self.Context.AttachQuestNotification)
    end
    if not currentGeneration() then
        return false, "start-cancelled"
    end
    self:record("ControllerStart", self.DryRun)

    if type(self.Context.Functions.RejoinPersistence) == "function" then
        pcall(self.Context.Functions.RejoinPersistence)
    end
    if not currentGeneration() then
        return false, "start-cancelled"
    end

    if type(self.Context.Functions.RefreshInventory) == "function" then
        local inventoryOk, inventoryResult = pcall(
            self.Context.Functions.RefreshInventory,
            true
        )
        if not currentGeneration() then
            return false, "start-cancelled"
        end
        state.initialInventoryRefresh = {
            at = os.clock(),
            ok = inventoryOk,
            result = tostring(inventoryResult),
            ready = state.inventoryReady == true,
        }
    end
    if state.inventoryStartupPending then
        state.inventoryStartupPending = state.inventoryReady ~= true
        if state.inventoryStartupPending then
            state.status = "Waiting initial inventory | Retrying read"
        end
    end

    TaskExecutorLoop.startFruitStoreBackground(self.Context)
    if not currentGeneration() then
        return false, "start-cancelled"
    end
    local executorThread = task.spawn(function()
        local ok, failure = xpcall(function()
            TaskExecutorLoop.run(self.Context, currentGeneration)
        end, debug.traceback)
        if generation == self.Generation then
            self.ExecutorThread = nil
            self:stop()
            if not ok then
                state.lastError = tostring(failure)
                self:record("ControllerError", tostring(failure))
            end
        end
    end)
    if not currentGeneration() then
        cancelThread(executorThread)
        return false, "start-cancelled"
    end
    self.ExecutorThread = executorThread
    local schedulerThread = task.spawn(function()
        while currentGeneration() do
            if not state.paused and not state.inventoryStartupPending then
                if type(self.Context.Functions.AutoAccessory) == "function" then
                    local accessoryOk, accessoryError = pcall(self.Context.Functions.AutoAccessory)
                    if not currentGeneration() then return end
                    if not accessoryOk then
                        state.lastAccessoryError = tostring(accessoryError)
                    end
                end
                local ok, failure = xpcall(function()
                    self.Context.Functions.ScheduleGoalTasks()
                end, debug.traceback)
                if not currentGeneration() then
                    return
                end
                if not ok then
                    state.lastSchedulerError = tostring(failure)
                    self:record("SchedulerError", tostring(failure))
                end
            end
            task.wait(0.5)
        end
        if generation == self.Generation then
            self.SchedulerThread = nil
        end
    end)
    if not currentGeneration() then
        cancelThread(schedulerThread)
        return false, "start-cancelled"
    end
    self.SchedulerThread = schedulerThread
    return true
end

function CleanRuntimeController:pause()
    self.LifecycleRevision = (tonumber(self.LifecycleRevision) or 0) + 1
    self.Context.State.runtimeLifecycleRevision = self.LifecycleRevision
    self.Context.State.paused = true
    pcall(self.Context.Functions.StopTween)
    if type(self.Context.Functions.StopAttack) == "function" then
        pcall(self.Context.Functions.StopAttack)
    end
    self:record("ControllerPause")
end

function CleanRuntimeController:resume()
    self.LifecycleRevision = (tonumber(self.LifecycleRevision) or 0) + 1
    self.Context.State.runtimeLifecycleRevision = self.LifecycleRevision
    self.Context.State.paused = false
    if self.Running and not self.Context.State.stopped then
        TaskExecutorLoop.startFruitStoreBackground(self.Context)
    end
    self:record("ControllerResume")
end

function CleanRuntimeController:stop()
    self.LifecycleRevision = (tonumber(self.LifecycleRevision) or 0) + 1
    self.Generation += 1
    local state = self.Context.State
    state.runtimeGeneration = self.Generation
    state.runtimeLifecycleRevision = self.LifecycleRevision
    state.stopped = true
    state.paused = true
    if type(self.Context.Functions.CancelPendingReads) == "function" then
        pcall(self.Context.Functions.CancelPendingReads)
    end
    if type(self.Context.Functions.StopFastTravel) == "function" then
        pcall(self.Context.Functions.StopFastTravel)
    end
    cancelThread(self.ExecutorThread)
    cancelThread(self.SchedulerThread)
    self.ExecutorThread = nil
    self.SchedulerThread = nil
    for _, name in {
        "meleeBackgroundThread",
        "fruitGachaBackgroundThread",
        "fruitStoreBackgroundThread",
        "gachaCloseThread",
        "cursedShipTransitionThread",
    } do
        cancelThread(state[name])
        state[name] = nil
    end
    local storeThread = state.fruitStoreRequestThread
    cancelThread(storeThread)
    if type(storeThread) ~= "thread" or coroutine.status(storeThread) == "dead" then
        state.fruitStoreRequestThread = nil
    end
    state.meleeBackgroundToken = nil
    state.fruitGachaBackgroundToken = nil
    state.fruitStoreBackgroundToken = nil
    state.fruitStoreInFlight = nil
    state.gachaCloseToken = nil
    state.cursedShipTransitionToken = nil
    state.meleeBackgroundRunning = false
    state.fruitGachaBackgroundRunning = false
    state.cursedShipTransitionActive = nil
    state.factoryWatchersReady = nil
    state.factoryCoreAlive = nil
    state.factoryFruitSnapshot = nil
    state.factoryRewardUntil = nil
    state.accessoryDependencies = nil
    state.farmMobCacheToken = nil
    state.farmSpawnRegionsCache = nil
    if type(state.factoryWatcherCleanup) == "function" then
        pcall(state.factoryWatcherCleanup)
    end
    for _, name in {
        "teleportFailureConnection",
        "trevorFruitAddedConnection",
        "factoryNotificationConnection",
        "factoryEnemyConnection",
        "farmEnemyAddedConnection",
        "farmEnemyRemovedConnection",
    } do
        local connection = state[name]
        if connection then
            pcall(connection.Disconnect, connection)
            state[name] = nil
        end
    end
    for label, connection in state.factoryTextConnections or {} do
        pcall(connection.Disconnect, connection)
        state.factoryTextConnections[label] = nil
    end
    pcall(self.Context.Functions.StopTween)
    if type(self.Context.Functions.StopAttack) == "function" then
        pcall(self.Context.Functions.StopAttack)
    end
    if type(self.Context.DetachQuestNotification) == "function" then
        pcall(self.Context.DetachQuestNotification)
    end
    self.Running = false
    self:record("ControllerStop")
    return true
end

function CleanRuntimeController:snapshot()
    return {
        running = self.Running == true,
        dryRun = self.DryRun,
        actionPolicy = self.ActionPolicy,
        paused = self.Context.State.paused == true,
        stopped = self.Context.State.stopped == true,
        task = self.Context.TaskQueue:top(),
        status = self.Context.State.status,
        eventCount = #self.Events,
        lastAction = self.Context.State.lastDryRunAction,
        lastError = self.Context.State.lastError,
        fallbackKinds = (function()
            local count = 0
            for _ in self.FallbackCalls do
                count += 1
            end
            return count
        end)(),
    }
end

function CleanRuntimeController:fallbackSummary()
    local rows = {}
    local total = 0
    for name, count in self.FallbackCalls do
        total += count
        rows[#rows + 1] = { name = name, count = count }
    end
    table.sort(rows, function(left, right)
        return left.count > right.count
            or left.count == right.count and left.name < right.name
    end)
    return { total = total, kinds = #rows, rows = rows }
end
end

local ShadowComparator
do
ShadowComparator = {}
ShadowComparator.__index = ShadowComparator

local function instanceName(value)
    return typeof(value) == "Instance" and value.Name or nil
end

local function statusPhase(value)
    local text = tostring(value or "")
    return text:match("|%s*(.-)%s*$") or text
end

local function positionOf(value)
    if typeof(value) == "CFrame" then
        return value.Position
    end
    if typeof(value) == "Vector3" then
        return value
    end
    if type(value) == "table" then
        return positionOf(value.goal or value.destination or value.cframe)
    end
    return nil
end

local function roundedPosition(value)
    local position = positionOf(value)
    if not position then
        return nil
    end
    return {
        x = math.round(position.X),
        y = math.round(position.Y),
        z = math.round(position.Z),
    }
end

local function samePosition(left, right, tolerance)
    if not left or not right then
        return left == right
    end
    local dx, dy, dz = left.x - right.x, left.y - right.y, left.z - right.z
    return math.sqrt(dx * dx + dy * dy + dz * dz) <= tolerance
end

local function snapshot(context)
    local state = context.State
    local questVisible, questText = context.ReadQuest()
    return {
        task = context.TaskQueue and context.TaskQueue:top() or nil,
        status = tostring(state.status or ""),
        phase = statusPhase(state.status),
        target = instanceName(state.farmTarget) or state.currentFarmMobName,
        waitSource = state.lastFarmWaitSource,
        destination = roundedPosition(state.travel or state.movement),
        runtimePaused = state.paused == true,
        questVisible = questVisible == true,
        questText = tostring(questText or ""),
    }
end

function ShadowComparator.create(cleanController, capturedContext, options)
    options = options or {}
    return setmetatable({
        CleanController = cleanController,
        CapturedContext = capturedContext,
        Samples = {},
        MaxSamples = options.maxSamples or 240,
        PositionTolerance = options.positionTolerance or 15,
        Running = false,
        Generation = 0,
    }, ShadowComparator)
end

function ShadowComparator:sample()
    local clean = snapshot(self.CleanController.Context)
    local captured = snapshot(self.CapturedContext)
    local comparison = {
        at = os.clock(),
        clean = clean,
        captured = captured,
        taskMatch = clean.task == captured.task,
        phaseMatch = clean.phase == captured.phase,
        targetMatch = clean.target == captured.target,
        destinationMatch = samePosition(
            clean.destination,
            captured.destination,
            self.PositionTolerance
        ),
        questMatch = clean.questVisible == captured.questVisible
            and clean.questText == captured.questText,
    }
    self.Samples[#self.Samples + 1] = comparison
    if #self.Samples > self.MaxSamples then
        table.remove(self.Samples, 1)
    end
    return comparison
end

function ShadowComparator:start(interval)
    if self.Running then
        return false, "already-running"
    end
    self.Generation += 1
    local generation = self.Generation
    self.Running = true
    task.spawn(function()
        while self.Running and generation == self.Generation do
            self:sample()
            task.wait(interval or 0.5)
        end
    end)
    return true
end

function ShadowComparator:stop()
    self.Generation += 1
    self.Running = false
end

function ShadowComparator:summary()
    local summary = {
        samples = #self.Samples,
        taskMatches = 0,
        phaseMatches = 0,
        targetMatches = 0,
        destinationMatches = 0,
        questMatches = 0,
        capturedPausedSamples = 0,
        comparablePhaseSamples = 0,
        comparablePhaseMatches = 0,
    }
    for _, sample in self.Samples do
        summary.taskMatches += sample.taskMatch and 1 or 0
        summary.phaseMatches += sample.phaseMatch and 1 or 0
        summary.targetMatches += sample.targetMatch and 1 or 0
        summary.destinationMatches += sample.destinationMatch and 1 or 0
        summary.questMatches += sample.questMatch and 1 or 0
        if sample.captured.runtimePaused then
            summary.capturedPausedSamples += 1
        else
            summary.comparablePhaseSamples += 1
            summary.comparablePhaseMatches += sample.phaseMatch and 1 or 0
        end
    end
    local last = self.Samples[#self.Samples]
    summary.lastClean = last and last.clean or nil
    summary.lastCaptured = last and last.captured or nil
    return summary
end
end

local SeaHub = {
    Config = Config,
    QuestData = QuestData,
    BossQuestData = BossQuestData,
    UIState = UIState,
    RuntimeFunctions = {
        ControllerOrder = ControllerOrder,
        FruitCollectionPolicy = FruitCollectionPolicy,
        BossTaskPolicy = BossTaskPolicy,
        BossTelemetry = BossTelemetry,
        QuestNotificationBridge = QuestNotificationBridge,
        QuestRoutePolicy = QuestRoutePolicy,
        GetQuest = GetQuest,
        NormalizeEnemyName = NormalizeEnemyName,
        ResolveMobCFrame = ResolveMobCFrame,
        GetBossQuest = GetBossQuest,
        GetLiveBoss = GetLiveBoss,
        GetBossCFrame = GetBossCFrame,
        GetFarmWatchdog = GetFarmWatchdog,
        GetQuestGiverCFrame = GetQuestGiverCFrame,
        EnsureQuest = EnsureQuest,
        LoadTools = LoadTools,
        EquipWeapon = EquipWeapon,
        Attack = Attack,
        SendKey = SendKey,
        AddVelocity = AddVelocity,
        RemoveVelocity = RemoveVelocity,
        ShouldCancelTP = ShouldCancelTP,
        ShouldNotBypassTP = ShouldNotBypassTP,
        TryFastTravel = TryFastTravel,
        CancelTween = CancelTween,
        NoClip = NoClip,
        RunMovement = RunMovement,
        TP = TP,
        StopTween = StopTween,
        BringMob = BringMob,
        ReleaseBring = BringMob.release,
        AutoBuso = AutoBuso,
        EnsureTeam = EnsureTeam,
        UpStats = UpStats,
        IsNetworkOwner = IsNetworkOwner,
        RefreshSimulationRadius = RefreshSimulationRadius,
        SelectFarmWaitCFrame = SelectFarmWaitCFrame,
        IsActiveEnemyModel = IsActiveEnemyModel,
        ObserveFarmTarget = ObserveFarmTarget,
        RecordFarmRecovery = RecordFarmRecovery,
        ResetFarmWatchdog = ResetFarmWatchdog,
        UpdateFarmWatchdog = UpdateFarmWatchdog,
        IsTaskCurrent = IsTaskCurrent,
        ReadTaskProgress = ReadTaskProgress,
        TaskRequest = TaskRequest,
        ProgressionProbe = ProgressionProbe,
        RefreshInventory = RefreshInventory,
        AutoAccessory = AutoAccessory,
        ProgressionPlanner = ProgressionPlanner,
        RejoinPersistence = RejoinPersistence,
        HopServer = HopServer,
        RecoveryWatchdog = RecoveryWatchdog,
        TaskExecutorLoop = TaskExecutorLoop,
        ScheduleGoalTasks = ScheduleGoalTasks,
        CollectDroppedFruit = CollectDroppedFruit,
        RuntimeContext = RuntimeContext,
        CombatTarget = CombatTarget,
        FarmBoss = FarmBoss,
        FarmMob = FarmMob,
        SkipMode = SkipMode,
        FarmMaterial = FarmMaterial,
        AutoBoneBoost = AutoBoneBoost,
        AutoFarmLevel = AutoFarmLevel,
        AutoSecondSea = AutoSecondSea,
        AutoBartiloQuest = AutoBartiloQuest,
        AutoSaber = AutoSaber,
        AutoThirdSea = AutoThirdSea,
        AutoYama = AutoYama,
        AutoTushita = AutoTushita,
        AutoPirateRaid = AutoPirateRaid,
        AutoTyrantBoss = AutoTyrantBoss,
        AutoSoulGuitar = AutoSoulGuitar,
        AutoFactory = AutoFactory,
        AutoElectricUnlock = AutoElectricUnlock,
        AutoMeleeProgress = AutoMeleeProgress,
        AutoRaid = AutoRaid,
        AutoExpCodes = AutoExpCodes,
        AutoFruitPolicy = AutoFruitPolicy,
        AutoFruitSniper = AutoFruitSniper,
        AutoUtilityItems = AutoUtilityItems,
        AutoProgressionItems = AutoProgressionItems,
        AutoSetSpawn = AutoSetSpawn,
        AutoAbilities = AutoAbilities,
        AutoFruitGacha = AutoFruitGacha,
        TaskQueue = TaskQueue,
        CleanRuntimeController = CleanRuntimeController,
        ShadowComparator = ShadowComparator,
    },
}

function SeaHub.bootstrap(options)
    options = options or {}

    local state = {
        config = Config,
        ui = UIState,
    }

    if options.installUi ~= false then
        state.interface = UIState.install(options.uiParent)
    end
    return state
end

function SeaHub.attachCapturedRuntime(options)
    options = options or {}
    local context = RuntimeContext.fromCapturedRuntime(options)
    RuntimeContext.bindCleanFunctions(context, SeaHub.RuntimeFunctions)
    SeaHub.CleanContext = context
    return context
end

function SeaHub.attachStandaloneRuntime(options)
    options = options or {}
    local context = RuntimeContext.fromStandalone(options)
    RuntimeContext.bindCleanFunctions(context, SeaHub.RuntimeFunctions)
    context.Functions.LoadTools()
    SeaHub.CleanContext = context
    return context
end

function SeaHub.createCleanRuntime(options)
    options = options or {}
    local baseContext = options.BaseContext or SeaHub.CleanContext
    if not baseContext then
        baseContext = SeaHub.attachStandaloneRuntime(options)
    end
    local controller = CleanRuntimeController.create(baseContext, SeaHub.RuntimeFunctions, options)
    SeaHub.CleanRuntime = controller
    SeaHub.CleanContext = controller.Context
    local runtimeEnvironment = getgenv and getgenv() or _G
    runtimeEnvironment.__SEAHUB_CLEAN_CONTEXT = controller.Context
    return controller
end

function SeaHub.startCleanRuntime(options)
    local controller = SeaHub.CleanRuntime or SeaHub.createCleanRuntime(options)
    return controller:start()
end

function SeaHub.stopCleanRuntime()
    return SeaHub.CleanRuntime and SeaHub.CleanRuntime:stop() or false
end

function SeaHub.createShadowComparator(options)
    options = options or {}
    local controller = options.Controller or SeaHub.CleanRuntime
    assert(controller, "clean runtime controller is unavailable")
    local capturedContext = options.CapturedContext or controller.BaseContext
    assert(capturedContext, "captured comparison context is unavailable")
    local comparator = ShadowComparator.create(controller, capturedContext, options)
    SeaHub.ShadowComparator = comparator
    return comparator
end

local environment = getgenv and getgenv() or _G
environment.Configs = environment.Configs or {}
if environment.Configs.FPS == nil then
    environment.Configs.FPS = Config.Performance.FPS
end
environment.SeaHub = SeaHub

if environment.__SEAHUB_DISABLE_AUTOSTART ~= true then
    local interfaceEnabled = environment.__SEAHUB_UI_ENABLED ~= false
    Config.Interface.BlackScreen = environment.__SEAHUB_BLACK_SCREEN_ENABLED == true
    local previous = environment.SeaHubCleanController
    if previous and type(previous.stop) == "function" then
        pcall(previous.stop, previous)
    end
    environment.SeaHubCleanController = nil
    environment.__SEAHUB_CLEAN_CONTEXT = nil

    SeaHub.Runtime = SeaHub.bootstrap({
        installUi = interfaceEnabled,
    })

    local attached, contextOrError = pcall(SeaHub.attachStandaloneRuntime)
    SeaHub.Runtime.standaloneAttached = attached
    SeaHub.Runtime.standaloneError = not attached and tostring(contextOrError) or nil

    if attached then
        local controller = SeaHub.createCleanRuntime({
            BaseContext = contextOrError,
            dryRun = false,
            paused = true,
            maxEvents = 600,
            invokeFallbacks = false,
            actions = {
                quest = true,
                movement = true,
                equip = true,
                combat = true,
                remote = true,
                stats = true,
                serverHop = true,
            },
        })
        environment.SeaHubCleanController = controller
        local started, startError = controller:start()
        SeaHub.Runtime.cleanStarted = started
        SeaHub.Runtime.cleanStartError = startError
    end
end

return SeaHub
