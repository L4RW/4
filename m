local startupArgs = ({...})[1] or {}

if getgenv().library ~= nil then
    pcall(function() getgenv().library:Unload() end)
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local function gs(a)
    return game:GetService(a)
end

-- // Services & Globals
local players, http, runservice, inputservice, tweenService, actionservice = 
    gs('Players'), gs('HttpService'), gs('RunService'), gs('UserInputService'), gs('TweenService'), gs('ContextActionService')

local localplayer = players.LocalPlayer
local setByConfig  = false

local floor, clamp = math.floor, math.clamp
local c3new, fromrgb, fromhsv = Color3.new, Color3.fromRGB, Color3.fromHSV
local next, newInstance, newUDim2, newVector2 = next, Instance.new, UDim2.new, Vector2.new

-- Universal Executor / API Helpers
local isexecutorclosure = isexecutorclosure or is_synapse_function or is_sirhurt_closure or iskrnlclosure
local executor = (syn and 'syn') or (getexecutorname and getexecutorname()) or 'unknown'

local protect_gui = (syn and syn.protect_gui) or (protectgui) or function(gui) end

local b64decode = function(data)
    if crypt and crypt.base64decode then return crypt.base64decode(data) end
    if crypt and crypt.base64_decode then return crypt.base64_decode(data) end
    if base64 and base64.decode then return base64.decode(data) end
    if syn and syn.crypt and syn.crypt.base64 then return syn.crypt.base64.decode(data) end

    -- Pure Lua Fallback
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) >= 2^(i-1) and '1' or '0') end
        return r
    end):gsub('%d%d%d%d%d%d%d%d', function(x)
        local n = 0
        for i = 1, 8 do if (x:sub(i, i) == '1') then n = n + 2^(8-i) end end
        return string.char(n)
    end))
end

-- // Main Library Table
local library = {
    windows      = {},
    indicators   = {},
    flags        = {},
    options      = {},
    connections  = {},
    drawings     = {},
    instances    = {},
    utility      = {},
    notifications= {},
    tweens       = {},
    theme        = {},
    zindexOrder  = {
        ['indicator']    = 950,
        ['window']       = 1000,
        ['colorpicker']  = 1100,
        ['dropdown']     = 1200,
        ['watermark']    = 1300,
        ['notification'] = 1400,
        ['cursor']       = 1500,
    },
    stats = {
        ['fps']  = 0,
        ['ping'] = 0,
    },
    images = {
        ['gradientp90'] = 'https://raw.githubusercontent.com/portallol/luna/main/modules/gradient90.png',
        ['gradientp45'] = 'https://raw.githubusercontent.com/portallol/luna/main/modules/gradient45.png',
        ['colorhue']    = 'https://raw.githubusercontent.com/portallol/luna/main/modules/lgbtqshit.png',
        ['colortrans']  = 'https://raw.githubusercontent.com/portallol/luna/main/modules/trans.png',
    },
    numberStrings = {
        ['Zero'] = 0, ['One'] = 1, ['Two'] = 2, ['Three'] = 3, ['Four'] = 4,
        ['Five'] = 5, ['Six'] = 6, ['Seven'] = 7, ['Eight'] = 8, ['Nine'] = 9
    },
    open       = false,
    opening    = false,
    hasInit    = false,
    toggleKey  = Enum.KeyCode.RightShift,
    cheatname  = startupArgs.cheatname or 'Clanware',
    gamename   = startupArgs.gamename or 'Universal',
    fileext    = startupArgs.fileext or '.txt',
}

-- Populate global environment immediately to prevent nil indexing
if getgenv then
    getgenv().library = library
    getgenv().ClanwareLib = library
    getgenv().Clanware = library
end


-- Simple signal implementation
local Signal = {}
Signal.__index = Signal
function Signal.new()
    return setmetatable({ _bindable = Instance.new("BindableEvent") }, Signal)
end
function Signal:Connect(fn)
    return self._bindable.Event:Connect(fn)
end
function Signal:Fire(...)
    self._bindable:Fire(...)
end
function Signal:Destroy()
    self._bindable:Destroy()
end

library.signal = Signal

library.themes = {
    {
        name = 'Default',
        theme = {
            ['Accent']                    = fromrgb(124, 97, 196),
            ['Background']                = fromrgb(17, 17, 17),
            ['Border']                    = fromrgb(0, 0, 0),
            ['Border 1']                  = fromrgb(47, 47, 47),
            ['Border 2']                  = fromrgb(17, 17, 17),
            ['Border 3']                  = fromrgb(10, 10, 10),
            ['Primary Text']              = fromrgb(235, 235, 235),
            ['Group Background']          = fromrgb(17, 17, 17),
            ['Selected Tab Background']   = fromrgb(25, 25, 30),
            ['Unselected Tab Background'] = fromrgb(17, 17, 17),
            ['Selected Tab Text']         = fromrgb(245, 245, 245),
            ['Unselected Tab Text']       = fromrgb(145, 145, 145),
            ['Section Background']        = fromrgb(17, 17, 17),
            ['Option Text 1']             = fromrgb(245, 245, 245),
            ['Option Text 2']             = fromrgb(195, 195, 195),
            ['Option Text 3']             = fromrgb(145, 145, 145),
            ['Option Border 1']           = fromrgb(47, 47, 47),
            ['Option Border 2']           = fromrgb(0, 0, 0),
            ['Option Background']         = fromrgb(35, 35, 35),
            ["Risky Text"]                = fromrgb(175, 21, 21),
            ["Risky Text Enabled"]        = fromrgb(255, 41, 41),
        }
    },
    {
        name = 'Midnight',
        theme = {
            ['Accent']                    = fromrgb(103, 89, 179),
            ['Background']                = fromrgb(22, 22, 31),
            ['Border']                    = fromrgb(0, 0, 0),
            ['Border 1']                  = fromrgb(50, 50, 50),
            ['Border 2']                  = fromrgb(24, 25, 37),
            ['Border 3']                  = fromrgb(10, 10, 10),
            ['Primary Text']              = fromrgb(235, 235, 235),
            ['Group Background']          = fromrgb(24, 25, 37),
            ['Selected Tab Background']   = fromrgb(24, 25, 37),
            ['Unselected Tab Background'] = fromrgb(22, 22, 31),
            ['Selected Tab Text']         = fromrgb(245, 245, 245),
            ['Unselected Tab Text']       = fromrgb(145, 145, 145),
            ['Section Background']        = fromrgb(22, 22, 31),
            ['Option Text 1']             = fromrgb(245, 245, 245),
            ['Option Text 2']             = fromrgb(195, 195, 195),
            ['Option Text 3']             = fromrgb(145, 145, 145),
            ['Option Border 1']           = fromrgb(50, 50, 50),
            ['Option Border 2']           = fromrgb(0, 0, 0),
            ['Option Background']         = fromrgb(24, 25, 37),
            ["Risky Text"]                = fromrgb(175, 21, 21),
            ["Risky Text Enabled"]        = fromrgb(255, 41, 41),
        }
    }
}

local blacklistedKeys = {
    Enum.KeyCode.Unknown, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S,
    Enum.KeyCode.D, Enum.KeyCode.Slash, Enum.KeyCode.Tab, Enum.KeyCode.Escape
}

local whitelistedBoxKeys = {
    Enum.KeyCode.Zero, Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three,
    Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven,
    Enum.KeyCode.Eight, Enum.KeyCode.Nine
}

local keyNames = {
    [Enum.KeyCode.LeftControl]   = 'LCTRL',
    [Enum.KeyCode.RightControl]  = 'RCTRL',
    [Enum.KeyCode.LeftShift]    = 'LSHIFT',
    [Enum.KeyCode.RightShift]   = 'RSHIFT',
    [Enum.UserInputType.MouseButton1] = 'MB1',
    [Enum.UserInputType.MouseButton2] = 'MB2',
    [Enum.UserInputType.MouseButton3] = 'MB3',
}

library.button1down = library.signal.new()
library.button1up   = library.signal.new()
library.mousemove   = library.signal.new()
library.unloaded    = library.signal.new()

local button1down, button1up, mousemove = library.button1down, library.button1up, library.mousemove
local mb1down = false

-- // Utility Methods
local utility = {}

function utility:Connection(signal, func)
    local c = signal:Connect(func)
    table.insert(library.connections, c)
    return c
end

function utility:Instance(class, properties)
    local inst = newInstance(class)
    for prop, val in next, properties or {} do
        pcall(function() inst[prop] = val end)
    end
    return inst
end

function utility:HasProperty(obj, prop)
    return ({(pcall(function() local a = obj[prop] end))})[1]
end

function utility:ToRGB(c3)
    return c3.R * 255, c3.G * 255, c3.B * 255
end

function utility:AddRGB(a, b)
    local r1, g1, b1 = self:ToRGB(a)
    local r2, g2, b2 = self:ToRGB(b)
    return fromrgb(clamp(r1 + r2, 0, 255), clamp(g1 + g2, 0, 255), clamp(b1 + b2, 0, 255))
end

function utility:ConvertNumberRange(val, oldmin, oldmax, newmin, newmax)
    return (((val - oldmin) * (newmax - newmin)) / (oldmax - oldmin)) + newmin
end

function utility:UDim2ToVector2(udim2, vector2)
    local x = udim2.X.Offset + self:ConvertNumberRange(udim2.X.Scale, 0, 1, 0, vector2.X)
    local y = udim2.Y.Offset + self:ConvertNumberRange(udim2.Y.Scale, 0, 1, 0, vector2.Y)
    return newVector2(x, y)
end

function utility:Lerp(a, b, c)
    return a + (b - a) * c
end

function utility:Tween(obj, prop, val, time, direction, style)
    if self:HasProperty(obj, prop) then
        if library.tweens[obj] and library.tweens[obj][prop] then
            library.tweens[obj][prop]:Cancel()
        end

        local startVal = obj[prop]
        local a = 0
        local tween = { Completed = library.signal.new() }

        library.tweens[obj] = library.tweens[obj] or {}
        library.tweens[obj][prop] = tween

        tween.Connection = self:Connection(runservice.RenderStepped, function(dt)
            a = a + (dt / time)
            if a >= 1 or obj == nil then
                tween:Cancel()
            end
            pcall(function()
                local progress = tweenService:GetValue(a, style or Enum.EasingStyle.Linear, direction or Enum.EasingDirection.In)
                local newVal = (typeof(startVal) == 'number') and utility:Lerp(startVal, val, progress) or startVal:Lerp(val, progress)
                obj[prop] = newVal
            end)
        end)

        function tween:Cancel()
            if tween.Connection then tween.Connection:Disconnect() end
            tween.Completed:Fire()
            table.clear(tween)
            if library.tweens[obj] then library.tweens[obj][prop] = nil end
        end

        return tween
    end
end

function utility:DetectTableChange(indexcallback, newindexcallback)
    local proxy = newproxy(true)
    local mt = getmetatable(proxy)
    mt.__index = indexcallback
    mt.__newindex = newindexcallback
    return proxy
end

function utility:MouseOver(obj)
    local mousePos = inputservice:GetMouseLocation()
    local x1 = obj.Position.X
    local y1 = obj.Position.Y
    local x2 = x1 + obj.Size.X
    local y2 = y1 + obj.Size.Y
    return (mousePos.X >= x1 and mousePos.Y >= y1 and mousePos.X <= x2 and mousePos.Y <= y2)
end

function utility:GetHoverObject()
    local objects = {}
    for _, v in next, library.drawings do
        if v.Object.Visible and v.Class == 'Square' and self:MouseOver(v.Object) then
            table.insert(objects, v.Object)
        end
    end
    table.sort(objects, function(a, b) return a.ZIndex > b.ZIndex end)
    return objects[1]
end

function utility:Draw(class, properties)
    local blacklistedProperties = {'Object', 'Children', 'Class'}
    local drawing = {
        Object = Drawing.new(class),
        Children = {},
        ThemeColor = '',
        OutlineThemeColor = '',
        ThemeColorOffset = 0,
        OutlineThemeColorOffset = 0,
        Parent = nil,
        Size = newUDim2(0, 0, 0, 0),
        Position = newUDim2(0, 0, 0, 0),
        AbsoluteSize = newVector2(0, 0),
        AbsolutePosition = newVector2(0, 0),
        Hover = false,
        Visible = true,
        MouseButton1Down = library.signal.new(),
        MouseButton2Down = library.signal.new(),
        MouseButton1Up   = library.signal.new(),
        MouseButton2Up   = library.signal.new(),
        MouseEnter       = library.signal.new(),
        MouseLeave       = library.signal.new(),
        Class            = class,
    }

    function drawing:Update()
        local parent = drawing.Parent ~= nil and library.drawings[drawing.Parent.Object] or nil
        local parentSize, parentPos, parentVis = workspace.CurrentCamera.ViewportSize, Vector2.new(0,0), true
        if parent ~= nil then
            parentSize = (parent.Class == 'Square' or parent.Class == 'Image') and parent.Object.Size or parent.Class == 'Text' and parent.TextBounds or workspace.CurrentCamera.ViewportSize
            parentPos  = parent.Object.Position
            parentVis  = parent.Object.Visible
        end

        if drawing.Class == 'Square' or drawing.Class == 'Image' then
            drawing.Object.Size = typeof(drawing.Size) == 'Vector2' and drawing.Size or utility:UDim2ToVector2(drawing.Size, parentSize)
        end

        if drawing.Class == 'Square' or drawing.Class == 'Image' or drawing.Class == 'Circle' or drawing.Class == 'Text' then
            drawing.Object.Position = parentPos + (typeof(drawing.Position) == 'Vector2' and drawing.Position or utility:UDim2ToVector2(drawing.Position, parentSize))
        end

        drawing.Object.Visible = (parentVis and drawing.Visible) and true or false
        drawing:UpdateChildren()
    end

    function drawing:UpdateChildren()
        for _, v in next, drawing.Children do
            v:Update()
        end
    end

    function drawing:GetDescendants()
        local descendants = {}
        local function a(t)
            for _, v in next, t.Children do
                table.insert(descendants, v)
                a(v)
            end
        end
        a(self)
        return descendants
    end

    library.drawings[drawing.Object] = drawing

    local proxy = utility:DetectTableChange(
        function(obj, i)
            return drawing[i] == nil and drawing.Object[i] or drawing[i]
        end,
        function(obj, i, v)
            if not table.find(blacklistedProperties, i) then
                local lastval = drawing[i]

                if i == 'Size' and (class == 'Square' or class == 'Image') then
                    drawing.Object.Size = utility:UDim2ToVector2(v, drawing.Parent == nil and workspace.CurrentCamera.ViewportSize or drawing.Parent.Object.Size)
                    drawing.AbsoluteSize = drawing.Object.Size
                elseif i == 'Position' and (class == 'Square' or class == 'Image' or class == 'Text') then
                    drawing.Object.Position = utility:UDim2ToVector2(v, drawing.Parent == nil and newVector2(0,0) or drawing.Parent.Object.Position)
                    drawing.AbsolutePosition = drawing.Object.Position
                elseif i == 'Parent' then
                    if drawing.Parent ~= nil then
                        drawing.Parent.Children[drawing] = nil
                    end
                    if v ~= nil then
                        table.insert(v.Children, drawing)
                    end
                elseif i == 'Visible' then
                    drawing.Visible = v
                end

                pcall(function() drawing.Object[i] = v end)
                if drawing[i] ~= nil or i == 'Parent' then
                    drawing[i] = v
                end

                if table.find({'Size', 'Position', 'Visible', 'Parent'}, i) then
                    drawing:Update()
                end
                if table.find({'ThemeColor', 'OutlineThemeColor', 'ThemeColorOffset', 'OutlineThemeColorOffset'}, i) and lastval ~= v then
                    library.UpdateThemeColors()
                end
            end
        end
    )

    function drawing:Remove()
        for _, v in next, self.Children do v:Remove() end
        if drawing.Parent then drawing.Parent.Children[drawing.Object] = nil end
        library.drawings[drawing.Object] = nil
        drawing.Object:Remove()
        table.clear(drawing)
    end

    properties = typeof(properties) == 'table' and properties or {}
    if class == 'Square' and properties.Filled == nil then properties.Filled = true end
    if properties.Visible == nil then properties.Visible = true end

    for i, v in next, properties do proxy[i] = v end

    drawing:Update()
    return proxy
end

library.utility = utility

function library.UpdateThemeColors()
    for _, v in next, library.drawings do
        if v.ThemeColor and library.theme[v.ThemeColor] then
            v.Object.Color = utility:AddRGB(library.theme[v.ThemeColor], fromrgb(v.ThemeColorOffset or 0, v.ThemeColorOffset or 0, v.ThemeColorOffset or 0))
        end
        if v.ThemeColorOutline and library.theme[v.ThemeColorOutline] then
            v.Object.OutlineColor = utility:AddRGB(library.theme[v.ThemeColorOutline], fromrgb(v.OutlineThemeColorOffset or 0, v.OutlineThemeColorOffset or 0, v.OutlineThemeColorOffset or 0))
        end
    end
end

function library:SetTheme(theme)
    if typeof(theme) == 'table' then
        for i, v in next, theme do self.theme[i] = v end
        self.UpdateThemeColors()
    end
end

function library:Unload()
    library.unloaded:Fire()
    for _, c in next, self.connections do c:Disconnect() end
    for obj in next, self.drawings do pcall(function() obj:Remove() end) end
    table.clear(self.drawings)
    getgenv().library = nil
end

function library:init()
    if self.hasInit then return end
    self.hasInit = true
    getgenv().library = self

    -- Set default theme
    if self.themes and self.themes[1] and self.themes[1].theme then
        self:SetTheme(self.themes[1].theme)
    end

    local tooltipObjects = {}

    -- Safe file system helpers
    pcall(function()
        if makefolder then
            makefolder(self.cheatname)
            makefolder(self.cheatname..'/assets')
            makefolder(self.cheatname..'/'..self.gamename)
            makefolder(self.cheatname..'/'..self.gamename..'/configs')
        end
    end)

    self.cursor1 = utility:Draw('Triangle', {Filled = true, Color = fromrgb(255,255,255), ZIndex = self.zindexOrder.cursor})
    self.cursor2 = utility:Draw('Triangle', {Filled = true, Color = fromrgb(85,85,85), ZIndex = self.zindexOrder.cursor - 1})

    local function updateCursor()
        self.cursor1.Visible = self.open

        self.cursor2.Visible = self.open
        if self.cursor1.Visible then
            local pos = inputservice:GetMouseLocation()
            self.cursor1.PointA = pos
            self.cursor1.PointB = pos + newVector2(16, 5)
            self.cursor1.PointC = pos + newVector2(5, 16)
            self.cursor2.PointA = self.cursor1.PointA
            self.cursor2.PointB = self.cursor1.PointB + newVector2(1, 1)
            self.cursor2.PointC = self.cursor1.PointC + newVector2(1, 1)
        end
    end

    local screenGui = Instance.new('ScreenGui')
    protect_gui(screenGui)
    screenGui.Parent = game:GetService('CoreGui')
    screenGui.Enabled = true

    utility:Connection(library.unloaded, function() screenGui:Destroy() end)

    utility:Connection(inputservice.InputBegan, function(input, gpe)
        if input.KeyCode == self.toggleKey and not library.opening and not gpe then
            self:SetOpen(not self.open)
            task.spawn(function()
                library.opening = true
                task.wait(0.15)
                library.opening = false
            end)
        end
        if library.open then
            local hoverObj = utility:GetHoverObject()
            local hoverObjData = library.drawings[hoverObj]
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                mb1down = true
                button1down:Fire()
                if hoverObj and hoverObjData then
                    hoverObjData.MouseButton1Down:Fire(inputservice:GetMouseLocation())
                end
                if library.draggingSlider ~= nil then
                    local rel = inputservice:GetMouseLocation() - library.draggingSlider.objects.background.Object.Position
                    local val = utility:ConvertNumberRange(rel.X, 0, library.draggingSlider.objects.background.Object.Size.X, library.draggingSlider.min, library.draggingSlider.max)
                    library.draggingSlider:SetValue(val)
                end
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                if hoverObj and hoverObjData then
                    hoverObjData.MouseButton2Down:Fire(inputservice:GetMouseLocation())
                end
            end
        end
    end)

    utility:Connection(inputservice.InputEnded, function(input)
        if library.open then
            local hoverObj = utility:GetHoverObject()
            local hoverObjData = library.drawings[hoverObj]
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                mb1down = false
                button1up:Fire()
                if hoverObj and hoverObjData then
                    hoverObjData.MouseButton1Up:Fire(inputservice:GetMouseLocation())
                end
            end
        end
    end)

    utility:Connection(inputservice.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and library.open then
            mousemove:Fire(inputservice:GetMouseLocation())
            updateCursor()

            local hoverObj = utility:GetHoverObject()
            for _, v in next, library.drawings do
                local hover = hoverObj == v.Object
                if hover and not v.Hover then
                    v.Hover = true
                    v.MouseEnter:Fire(inputservice:GetMouseLocation())
                elseif not hover and v.Hover then
                    v.Hover = false
                    v.MouseLeave:Fire(inputservice:GetMouseLocation())
                end
            end

            if mb1down and library.draggingSlider ~= nil then
                local rel = inputservice:GetMouseLocation() - library.draggingSlider.objects.background.Object.Position
                local val = utility:ConvertNumberRange(rel.X, 0, library.draggingSlider.objects.background.Object.Size.X, library.draggingSlider.min, library.draggingSlider.max)
                library.draggingSlider:SetValue(val)
            end
        end
    end)

    function self:SetOpen(bool)
        self.open = bool
        screenGui.Enabled = bool
        updateCursor()
        for _, window in next, self.windows do
            window:SetOpen(bool)
        end
    end

    function self.UpdateThemeColors()
        for _, v in next, library.drawings do
            if v.ThemeColor and library.theme[v.ThemeColor] then
                v.Object.Color = utility:AddRGB(library.theme[v.ThemeColor], fromrgb(v.ThemeColorOffset, v.ThemeColorOffset, v.ThemeColorOffset))
            end
            if v.ThemeColorOutline and library.theme[v.ThemeColorOutline] then
                v.Object.OutlineColor = utility:AddRGB(library.theme[v.ThemeColorOutline], fromrgb(v.OutlineThemeColorOffset, v.OutlineThemeColorOffset, v.OutlineThemeColorOffset))
            end
        end
    end
end

-- // Window Construction
function library.NewWindow(data)
    data = data or {}
    local window = {
        title       = data.title or 'Window',
        selectedTab = nil,
        tabs        = {},
        objects     = {},
        open        = true,
        dropdown    = { objects = { values = {} }, max = 5 }
    }

    table.insert(library.windows, window)

    local size     = data.size or newUDim2(0, 525, 0, 650)
    local position = data.position or newUDim2(0, 250, 0, 150)
    local objs     = window.objects
    local z        = library.zindexOrder.window

    objs.background = utility:Draw('Square', {
        Size = size, Position = position, ThemeColor = 'Background', ZIndex = z
    })

    objs.innerBorder1 = utility:Draw('Square', {
        Size = newUDim2(1,2,1,2), Position = newUDim2(0,-1,0,-1), ThemeColor = 'Border 3', ZIndex = z-1, Parent = objs.background
    })
    objs.innerBorder2 = utility:Draw('Square', {
        Size = newUDim2(1,2,1,2), Position = newUDim2(0,-1,0,-1), ThemeColor = 'Border 1', ZIndex = z-2, Parent = objs.innerBorder1
    })
    objs.midBorder = utility:Draw('Square', {
        Size = newUDim2(1,10,1,25), Position = newUDim2(0,-5,0,-20), ThemeColor = 'Border 2', ZIndex = z-3, Parent = objs.innerBorder2
    })
    objs.topBorder = utility:Draw('Square', {
        Size = newUDim2(1,0,0,1), ThemeColor = 'Accent', ZIndex = z+1, Parent = objs.background
    })
    objs.title = utility:Draw('Text', {
        Position = newUDim2(0,7,0,2), ThemeColor = 'Primary Text', Text = window.title, Font = 2, Size = 13, ZIndex = z+1, Outline = true, Parent = objs.midBorder
    })

    objs.groupBackground = utility:Draw('Square', {
        Size = newUDim2(1,-16,1,-(16+23)), Position = newUDim2(0,8,0,8+23), ThemeColor = 'Group Background', ZIndex = z+5, Parent = objs.background
    })

    objs.tabHolder = utility:Draw('Square', {
        Size = newUDim2(1,0,0,20), Position = newUDim2(0,0,0,-21), Parent = objs.groupBackground, Transparency = 0, ZIndex = z+1
    })

    objs.columnholder1 = utility:Draw('Square', {
        Size = newUDim2(.48, 0, .96, 0), Position = newUDim2(.01, 0, .02, 0), Transparency = 0, ZIndex = z+6, Parent = objs.groupBackground
    })
    objs.columnholder2 = utility:Draw('Square', {
        Size = newUDim2(.48, 0, .96, 0), Position = newUDim2(1 - (.48 + .01), 0, .02, 0), Transparency = 0, ZIndex = z+6, Parent = objs.groupBackground
    })

    objs.dragdetector = utility:Draw('Square', {
        Size = newUDim2(1,0,1,0), Parent = objs.midBorder, Transparency = 0, ZIndex = z+2
    })

    local dragging, mouseStart, objStart
    utility:Connection(objs.dragdetector.MouseButton1Down, function(pos)
        dragging   = true
        mouseStart = newUDim2(0, pos.X, 0, pos.Y)
        objStart   = objs.background.Position
    end)
    utility:Connection(button1up, function() dragging = false end)
    utility:Connection(mousemove, function(pos)
        if dragging and window.open then
            objs.background.Position = objStart + newUDim2(0, pos.X, 0, pos.Y) - mouseStart
        end
    end)

    function window:SetOpen(bool)
        self.open = bool
        self.objects.background.Visible = bool
    end

    function window:AddTab(text)
        local tab = {
            text = text,
            objects = {},
            sections = {},
        }
        table.insert(self.tabs, tab)

        local tabObjs = tab.objects
        local tz = library.zindexOrder.window + 5
        local tabWidth = floor(525 / math.max(#self.tabs, 1))

        tabObjs.background = utility:Draw('Square', {
            Size = newUDim2(0, tabWidth, 1, 0),
            Position = newUDim2(0, (#self.tabs - 1) * tabWidth, 0, 0),
            Parent = self.objects.tabHolder,
            ThemeColor = 'Unselected Tab Background',
            ZIndex = tz
        })

        tabObjs.topBorder = utility:Draw('Square', {
            Size = newUDim2(1, 0, 0, 1), ThemeColor = 'Unselected Tab Background', ZIndex = tz+1, Parent = tabObjs.background
        })

        tabObjs.text = utility:Draw('Text', {
            ThemeColor = 'Unselected Tab Text', Text = text, Size = 13, Font = 2, ZIndex = tz+1, Outline = true, Center = true, Position = newUDim2(0.5, 0, 0, 2), Parent = tabObjs.background
        })

        function tab:Select()
            window.selectedTab = tab
            for _, t in ipairs(window.tabs) do
                local active = (t == tab)
                t.objects.background.ThemeColor = active and 'Selected Tab Background' or 'Unselected Tab Background'
                t.objects.topBorder.ThemeColor  = active and 'Accent' or 'Unselected Tab Background'
                t.objects.text.ThemeColor       = active and 'Selected Tab Text' or 'Unselected Tab Text'
                for _, sec in ipairs(t.sections) do
                    sec.objects.background.Visible = active and sec.enabled
                end
            end
        end

        utility:Connection(tabObjs.background.MouseButton1Down, function()
            tab:Select()
        end)

        function tab:AddSection(secText, side)
            side = side or 1
            local section = {
                text = secText,
                side = side,
                enabled = true,
                options = {},
                objects = {}
            }
            table.insert(tab.sections, section)

            local sz = library.zindexOrder.window + 15
            local sobjs = section.objects

            sobjs.background = utility:Draw('Square', {
                ThemeColor = 'Section Background', ZIndex = sz, Parent = window.objects['columnholder' .. side]
            })

            sobjs.textlabel = utility:Draw('Text', {
                Position = newUDim2(0, 8, 0, 4), ThemeColor = 'Primary Text', Text = secText, Size = 13, Font = 2, ZIndex = sz+1, Parent = sobjs.background
            })

            sobjs.optionholder = utility:Draw('Square', {
                Size = newUDim2(1, -6, 1, -22), Position = newUDim2(0, 3, 0, 20), Transparency = 0, ZIndex = sz+1, Parent = sobjs.background
            })

            function section:UpdateOptions()
                local ySize = 25
                for _, opt in ipairs(self.options) do
                    if opt.enabled then
                        opt.objects.holder.Position = newUDim2(0, 0, 0, ySize - 20)
                        ySize = ySize + opt.objects.holder.Object.Size.Y + 4
                    end
                end
                self.objects.background.Size = newUDim2(1, 0, 0, ySize)
            end

            function section:AddToggle(cfg)
                cfg = cfg or {}
                local toggle = {
                    class = 'toggle', flag = cfg.flag, text = cfg.text or 'Toggle', state = cfg.state or false,
                    callback = cfg.callback or function() end, enabled = true, objects = {}
                }
                table.insert(section.options, toggle)
                if toggle.flag then library.flags[toggle.flag] = toggle.state end

                local tobjs = toggle.objects
                local oz = library.zindexOrder.window + 25

                tobjs.holder = utility:Draw('Square', {
                    Size = newUDim2(1, 0, 0, 18), Transparency = 0, ZIndex = oz+5, Parent = sobjs.optionholder
                })
                tobjs.background = utility:Draw('Square', {
                    Size = newUDim2(0, 10, 0, 10), Position = newUDim2(0, 2, 0, 4), ThemeColor = toggle.state and 'Accent' or 'Option Background', ZIndex = oz+3, Parent = tobjs.holder
                })
                tobjs.text = utility:Draw('Text', {
                    Position = newUDim2(0, 18, 0, 1), ThemeColor = 'Option Text 1', Text = toggle.text, Size = 13, Font = 2, ZIndex = oz+1, Outline = true, Parent = tobjs.holder
                })

                function toggle:SetState(val)
                    toggle.state = val
                    if toggle.flag then library.flags[toggle.flag] = val end
                    tobjs.background.ThemeColor = val and 'Accent' or 'Option Background'
                    toggle.callback(val)
                end

                utility:Connection(tobjs.holder.MouseButton1Down, function()
                    toggle:SetState(not toggle.state)
                end)

                section:UpdateOptions()
                return toggle
            end

            function section:AddSlider(cfg)
                cfg = cfg or {}
                local slider = {
                    class = 'slider', flag = cfg.flag, text = cfg.text or 'Slider', min = cfg.min or 0, max = cfg.max or 100,
                    value = cfg.value or cfg.min or 0, increment = cfg.increment or 1, suffix = cfg.suffix or '',
                    callback = cfg.callback or function() end, enabled = true, objects = {}
                }
                table.insert(section.options, slider)
                if slider.flag then library.flags[slider.flag] = slider.value end

                local sobjs2 = slider.objects
                local oz = library.zindexOrder.window + 25

                sobjs2.holder = utility:Draw('Square', {
                    Size = newUDim2(1, 0, 0, 30), Transparency = 0, ZIndex = oz+4, Parent = sobjs.optionholder
                })
                sobjs2.text = utility:Draw('Text', {
                    Position = newUDim2(0, 2, 0, 0), ThemeColor = 'Option Text 2', Text = slider.text .. ": " .. tostring(slider.value) .. slider.suffix, Size = 13, Font = 2, ZIndex = oz+1, Outline = true, Parent = sobjs2.holder
                })
                sobjs2.background = utility:Draw('Square', {
                    Size = newUDim2(1, -4, 0, 10), Position = newUDim2(0, 2, 1, -12), ThemeColor = 'Option Background', ZIndex = oz+2, Parent = sobjs2.holder
                })
                sobjs2.fill = utility:Draw('Square', {
                    Size = newUDim2((slider.value - slider.min) / (slider.max - slider.min), 0, 1, 0), ThemeColor = 'Accent', ZIndex = oz+3, Parent = sobjs2.background
                })

                function slider:SetValue(val)
                    val = clamp(floor(val / slider.increment) * slider.increment, slider.min, slider.max)
                    slider.value = val
                    if slider.flag then library.flags[slider.flag] = val end
                    sobjs2.text.Text = slider.text .. ": " .. tostring(val) .. slider.suffix
                    sobjs2.fill.Size = newUDim2((val - slider.min) / (slider.max - slider.min), 0, 1, 0)
                    slider.callback(val)
                end

                utility:Connection(sobjs2.holder.MouseButton1Down, function()
                    library.draggingSlider = slider
                end)

                section:UpdateOptions()
                return slider
            end

            function section:AddButton(cfg)
                cfg = cfg or {}
                local button = {
                    class = 'button', text = cfg.text or 'Button', callback = cfg.callback or function() end, enabled = true, objects = {}
                }
                table.insert(section.options, button)

                local bobjs = button.objects
                local oz = library.zindexOrder.window + 25

                bobjs.holder = utility:Draw('Square', {
                    Size = newUDim2(1, 0, 0, 20), Transparency = 0, ZIndex = oz+4, Parent = sobjs.optionholder
                })
                bobjs.background = utility:Draw('Square', {
                    Size = newUDim2(1, -4, 0, 16), Position = newUDim2(0, 2, 0, 2), ThemeColor = 'Option Background', ZIndex = oz+2, Parent = bobjs.holder
                })
                bobjs.text = utility:Draw('Text', {
                    Position = newUDim2(0.5, 0, 0, 1), ThemeColor = 'Option Text 2', Text = button.text, Size = 13, Font = 2, Center = true, Outline = true, ZIndex = oz+4, Parent = bobjs.background
                })

                utility:Connection(bobjs.holder.MouseButton1Down, function()
                    button.callback()
                end)

                section:UpdateOptions()
                return button
            end

            return section
        end

        if #self.tabs == 1 then
            tab:Select()
        end

        return tab
    end

    return window
end

return library
