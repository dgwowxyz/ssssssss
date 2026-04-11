-- Services
local cloneref = cloneref or function(obj) return obj end   -- fallback if not defined

local Workspace   = cloneref(game:GetService("Workspace"))
local RunService  = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))
local Players     = cloneref(game:GetService("Players"))
local TweenService = cloneref(game:GetService("TweenService"))

local vec2      = Vector2.new
local dim2      = UDim2.new
local dimOffset = UDim2.fromOffset
local rgb       = Color3.fromRGB

local Camera = Workspace.CurrentCamera
local flags = {
    Enabled             = false,
    Max_Distance        = 10000,
    Distance_Type       = "Meters",
    Fade_Enabled        = false,
    Fade_Duration       = 0.3,
    Names               = false,
    Name_Color          = { Color = rgb(255, 255, 255) },
    Name_Font           = 5,
    Name_Size           = 9,
    Name_Gap            = 2,
    Name_Gradient       = false,
    Name_Gradient_Colors = { Top = rgb(255,255,255), Middle = rgb(170,170,170), Bottom = rgb(85,85,85) },
    Name_Gradient_Rotation = 90,
    Boxes               = false,
    Box_Type            = "Normal",
    Box_Color           = { Color = rgb(255, 255, 255) },
    Box_Fill            = false,
    Box_Fill_Gradient   = false,
    Box_Fill_Color      = { Color = rgb(255, 255, 255) },
    Box_Fill_Gradient_Colors = { Top = rgb(255,255,255), Middle = rgb(170,170,170), Bottom = rgb(85,85,85) },
    Box_Fill_Gradient_Rotation = 90,
    Box_Fill_Transparency = 0.5,
    Healthbar           = false,
    Healthbar_Thickness = 1,
    Healthbar_Gap       = 3,
    Health_High         = { Color = rgb(0, 255, 0) },
    Health_Low          = { Color = rgb(255, 0, 0) },
    Healthbar_Gradient  = false,
    Healthbar_Gradient_Colors = { Top = rgb(0,255,0), Middle = rgb(255,165,0), Bottom = rgb(255,0,0) },
    Healthbar_Gradient_Rotation = 90,
    Healthbar_Tween      = false,
    Healthbar_Tween_Speed = 0.15,
    Health_Text         = false,
    Health_Text_Dynamic = false,
    Health_Text_Color   = { Color = rgb(255, 255, 255) },
    Health_Text_Font    = 5,
    Health_Text_Size    = 9,
    Health_Text_Gap     = 2,
    Distance            = false,
    Distance_Type       = "Studs",
    Distance_Color      = { Color = rgb(255, 255, 255) },
    Distance_Font       = 5,
    Distance_Size       = 9,
    Distance_Gap        = 1,
    Distance_Gradient   = false,
    Distance_Gradient_Colors = { Top = rgb(255,255,255), Middle = rgb(170,170,170), Bottom = rgb(85,85,85) },
    Distance_Gradient_Rotation = 90,
    Weapon              = false,
    Weapon_Color        = { Color = rgb(255, 255, 255) },
    Weapon_Font         = 5,
    Weapon_Size         = 9,
    Weapon_Gap          = 1,
    Weapon_Gradient     = false,
    Weapon_Gradient_Colors = { Top = rgb(255,0,0), Middle = rgb(255,170,170), Bottom = rgb(255,255,255) },
    Weapon_Gradient_Rotation = 90,
}

-- Helper: build 3-color vertical gradient
local function buildGradientSeq(colors)
    local top    = colors.Top    or rgb(255, 255, 255)
    local middle = colors.Middle or top:Lerp(rgb(0,0,0), 0.5)
    local bottom = colors.Bottom or rgb(0, 0, 0)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0,   top),
        ColorSequenceKeypoint.new(0.5, middle),
        ColorSequenceKeypoint.new(1,   bottom)
    })
end

-- Fonts (unchanged)
local fonts; do
    local function registerFont(name, weight, style, asset)
        if not isfile(asset.id) then writefile(asset.id, asset.data) end
        if isfile(name .. ".font") then delfile(name .. ".font") end
        writefile(name .. ".font", HttpService:JSONEncode({
            name  = name,
            faces = {{ name = "Normal", weight = weight, style = style, assetId = getcustomasset(asset.id) }}
        }))
        return getcustomasset(name .. ".font")
    end
    local fontAssets = {
        proggyTiny     = { id = "ProggyTiny.ttf",     data = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/ProggyTiny.ttf") },
        proggyClean    = { id = "ProggyClean.ttf",    data = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/ProggyClean.ttf") },
        fsTahoma8px    = { id = "fs-tahoma-8px.ttf",  data = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/fs-tahoma-8px.ttf") },
        tahomaModern   = { id = "Tahoma-Modern.ttf",  data = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Tahoma-Modern.ttf") },
        smallestPixel7 = { id = "smallest_pixel-7.ttf", data = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/smallest_pixel-7.ttf") },
    }
    local fontIds = {}
    for name, asset in pairs(fontAssets) do fontIds[name] = registerFont("esp_" .. name, 100, "Normal", asset) end
    local fontList = {
        Font.new(fontIds.proggyTiny,     Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Font.new(fontIds.proggyClean,    Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Font.new(fontIds.fsTahoma8px,    Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Font.new(fontIds.tahomaModern,   Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Font.new(fontIds.smallestPixel7, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
    }
    fonts = {
        list = fontList,
        getForElement = function(element)
            local idx = 1
            if element == "Name" then idx = flags.Name_Font
            elseif element == "Distance" then idx = flags.Distance_Font
            elseif element == "Weapon" then idx = flags.Weapon_Font
            elseif element == "HealthText" then idx = flags.Health_Text_Font end
            return fontList[math.clamp(idx, 1, #fontList)] or fontList[1]
        end,
        getSizeForElement = function(element)
            if element == "Name" then return flags.Name_Size
            elseif element == "Distance" then return flags.Distance_Size
            elseif element == "Weapon" then return flags.Weapon_Size
            elseif element == "HealthText" then return flags.Health_Text_Size end
            return 9
        end
    }
end

-- ESP Module
local esp = { screengui = Instance.new("ScreenGui", gethui()), cache = Instance.new("ScreenGui", gethui()) }; do
    esp.screengui.IgnoreGuiInset = true
    esp.screengui.Name = "\0"
    esp.cache.Enabled = false
    local fadeTweenInfo = TweenInfo.new(flags.Fade_Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    -- World to screen
    function esp:screenPos(worldPos)
        local vp = Camera.ViewportSize
        local local_ = Camera.CFrame:pointToObjectSpace(worldPos)
        local ar = vp.X / vp.Y
        local halfH = -local_.Z * math.tan(math.rad(Camera.FieldOfView * 0.5))
        local halfW = ar * halfH
        local rel = local_ - Vector3.new(-halfW, halfH, local_.Z)
        local sx, sy = rel.X / (halfW * 2), -rel.Y / (halfH * 2)
        local onScreen = -local_.Z > 0 and sx >= 0 and sx <= 1 and sy >= 0 and sy <= 1
        return Vector3.new(sx * vp.X, sy * vp.Y, -local_.Z), onScreen
    end

    -- Box calculation with min height
    function esp:boxSolve(rootPart)
        if not rootPart then return nil, nil, nil, nil end
        local pos = rootPart.Position
        local upVec = rootPart.CFrame.UpVector
        local camUp = Camera.CFrame.UpVector
        local top2d, topVis = esp:screenPos(pos + upVec * 1.8 + camUp)
        local bot2d = esp:screenPos(pos - upVec * 2.5 - camUp)
        local w = math.max(math.floor(math.abs(top2d.X - bot2d.X)), 3)
        local h = math.max(math.floor(math.max(math.abs(bot2d.Y - top2d.Y), w * 0.5)), 3)
        local size = Vector2.new(math.floor(math.max(h / 1.5, w)), h)
        local bpos = Vector2.new(math.floor((top2d.X + bot2d.X) * 0.5 - size.X * 0.5), math.floor(math.min(top2d.Y, bot2d.Y)))
        local dist = (pos - Camera.CFrame.Position).Magnitude
        
        return size, bpos, topVis, dist
    end

    function esp:make(class, props) local ins = Instance.new(class) for k,v in props do ins[k]=v end return ins end

    -- Fade animations
    function esp:fadeIn(holder, instant)
        if not flags.Fade_Enabled or instant then
            holder.Visible = true
            for _, child in holder:GetDescendants() do
                if child:IsA("TextLabel") then
                    child.TextTransparency = 0
                    child.TextStrokeTransparency = 0
                elseif child:IsA("Frame") and child ~= holder then
                    local tgt = child:GetAttribute("TargetBgT")
                    if tgt then child.BackgroundTransparency = tgt end
                elseif child:IsA("UIStroke") then
                    child.Transparency = 0
                end
            end
            return
        end
        holder.Visible = true
        for _, child in holder:GetDescendants() do
            if child:IsA("TextLabel") then
                child.TextTransparency = 1
                child.TextStrokeTransparency = 1
                TweenService:Create(child, fadeTweenInfo, { TextTransparency = 0, TextStrokeTransparency = 0 }):Play()
            elseif child:IsA("Frame") and child ~= holder then
                local tgt = child:GetAttribute("TargetBgT")
                if tgt then
                    child.BackgroundTransparency = 1
                    TweenService:Create(child, fadeTweenInfo, { BackgroundTransparency = tgt }):Play()
                end
            elseif child:IsA("UIStroke") then
                child.Transparency = 1
                TweenService:Create(child, fadeTweenInfo, { Transparency = 0 }):Play()
            end
        end
    end

    function esp:fadeOut(holder, callback, instant)
        if not flags.Fade_Enabled or instant then
            holder.Visible = false
            if callback then callback() end
            return
        end
        local tweens = {}
        for _, child in holder:GetDescendants() do
            if child:IsA("TextLabel") then
                local t = TweenService:Create(child, fadeTweenInfo, { TextTransparency = 1, TextStrokeTransparency = 1 })
                table.insert(tweens, t) t:Play()
            elseif child:IsA("Frame") and child ~= holder then
                if child:GetAttribute("TargetBgT") then
                    local t = TweenService:Create(child, fadeTweenInfo, { BackgroundTransparency = 1 })
                    table.insert(tweens, t) t:Play()
                end
            elseif child:IsA("UIStroke") then
                local t = TweenService:Create(child, fadeTweenInfo, { Transparency = 1 })
                table.insert(tweens, t) t:Play()
            end
        end
        if #tweens > 0 then
            tweens[#tweens].Completed:Connect(function()
                holder.Visible = false
                if callback then callback() end
            end)
        else
            holder.Visible = false
            if callback then callback() end
        end
    end

    -- Create ESP for one player
    function esp:createObject(player)
        if not player or not player.Parent then return end

        -- ✅ FIX: Force cleanup of any existing data for this player (prevents residual UI on respawn)
        if esp[player.Name] then
            local oldData = esp[player.Name]
            for _, conn in ipairs(oldData.connections or {}) do
                conn:Disconnect()
            end
            for _, conn in ipairs(oldData.charConnections or {}) do
                conn:Disconnect()
            end
            if oldData.objects and oldData.objects.holder then
                oldData.objects.holder:Destroy()
            end
            esp[player.Name] = nil
        end

        local data = { objects = {}, info = {}, healthTween = nil, connections = {}, charConnections = {} }
        esp[player.Name] = data
        local o = data.objects
        local gui = esp.screengui
        local dead = esp.cache

        -- Main holder
        o.holder = esp:make("Frame", {
            Parent = gui,
            Name = "\0",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = dim2(0,0,0,0),
            Visible = false
        })

        -- Name
        o.name = esp:make("TextLabel", {
            Parent = flags.Names and o.holder or dead,
            FontFace = fonts.getForElement("Name"),
            Text = player.Name,
            TextColor3 = flags.Name_Gradient and rgb(255,255,255) or flags.Name_Color.Color,
            TextStrokeTransparency = 0,
            TextSize = fonts.getSizeForElement("Name"),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AnchorPoint = vec2(0.5,1),
            Size = dim2(1,0,0,0),
            Position = dim2(0.5,0,0,-flags.Name_Gap),
            AutomaticSize = Enum.AutomaticSize.Y,
            Name = "\0",
            TextTransparency = flags.Fade_Enabled and 1 or 0
        })
        o.name_gradient = Instance.new("UIGradient")
        o.name_gradient.Rotation = flags.Name_Gradient_Rotation
        o.name_gradient.Enabled = flags.Name_Gradient
        o.name_gradient.Color = buildGradientSeq(flags.Name_Gradient_Colors)
        o.name_gradient.Parent = o.name

        -- Box outline (normal)
        local isNormal = flags.Boxes and flags.Box_Type ~= "Corner"
        o.box_outline = esp:make("UIStroke", {
            Parent = isNormal and o.holder or dead,
            LineJoinMode = Enum.LineJoinMode.Miter
        })
        o.box_handler = esp:make("Frame", {
            Parent = isNormal and o.holder or dead,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = dim2(0,1,0,1),
            Size = dim2(1,-2,1,-2),
            Name = "\0"
        })
        o.box_color = esp:make("UIStroke", {
            Parent = o.box_handler,
            Color = flags.Box_Color.Color,
            LineJoinMode = Enum.LineJoinMode.Miter,
            Name = "\0"
        })
        -- Inner black border
        esp:make("UIStroke", {
            Parent = esp:make("Frame", {
                Parent = o.box_handler,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = dim2(0,1,0,1),
                Size = dim2(1,-2,1,-2),
                Name = "\0"
            }),
            LineJoinMode = Enum.LineJoinMode.Miter
        })

        -- Box fill
        o.box_fill = esp:make("Frame", {
            Parent = o.box_handler,
            BackgroundTransparency = flags.Box_Fill_Transparency,
            BackgroundColor3 = flags.Box_Fill_Gradient and rgb(255,255,255) or flags.Box_Fill_Color.Color,
            BorderSizePixel = 0,
            Position = dim2(0,1,0,1),
            Size = dim2(1,-2,1,-2),
            Name = "\0"
        })
        o.box_fill:SetAttribute("TargetBgT", flags.Box_Fill_Transparency)
        o.box_fill_gradient = Instance.new("UIGradient")
        o.box_fill_gradient.Rotation = flags.Box_Fill_Gradient_Rotation
        o.box_fill_gradient.Enabled = flags.Box_Fill_Gradient
        o.box_fill_gradient.Color = buildGradientSeq(flags.Box_Fill_Gradient_Colors)
        o.box_fill_gradient.Parent = o.box_fill
        o.box_fill.Visible = flags.Boxes and flags.Box_Fill

        -- Corner box
        local isCorner = flags.Boxes and flags.Box_Type == "Corner"
        o.corners = esp:make("Frame", {
            Parent = isCorner and o.holder or dead,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = dim2(0,-1,0,2),
            Size = dim2(1,0,1,0),
            Name = "\0"
        })
        local function cornerLine(props, innerProps)
            local outer = esp:make("Frame", props)
            outer:SetAttribute("TargetBgT", props.BackgroundTransparency or 0)
            local inner = esp:make("Frame", {
                Parent = outer,
                BackgroundColor3 = flags.Box_Color.Color,
                BorderSizePixel = 0,
                Position = innerProps.pos,
                Size = innerProps.size
            })
            inner:SetAttribute("TargetBgT", 0)
            return outer
        end
        local BLK = rgb(0,0,0)
        local lineProps = { BorderColor3 = BLK, BackgroundColor3 = BLK, BorderSizePixel = 0, Parent = o.corners, Name = "line" }
        cornerLine(table.move(lineProps,1,#lineProps,1,{ Position = dim2(0,0,0,-2), Size = dim2(0.4,0,0,3) }), { pos = dim2(0,1,0,1), size = dim2(1,-2,1,-2) })
        cornerLine(table.move(lineProps,1,#lineProps,1,{ Position = dim2(0,0,0,1),  Size = dim2(0,3,0.25,0) }), { pos = dim2(0,1,0,-2), size = dim2(1,-2,1,1) })
        cornerLine(table.move(lineProps,1,#lineProps,1,{ AnchorPoint = vec2(1,0), Position = dim2(1,0,0,-2), Size = dim2(0.4,0,0,3) }), { pos = dim2(0,1,0,1), size = dim2(1,-2,1,-2) })
        cornerLine(table.move(lineProps,1,#lineProps,1,{ AnchorPoint = vec2(1,0), Position = dim2(1,0,0,1),  Size = dim2(0,3,0.25,0) }), { pos = dim2(0,1,0,-2), size = dim2(1,-2,1,1) })
        cornerLine(table.move(lineProps,1,#lineProps,1,{ AnchorPoint = vec2(0,1), Position = dim2(0,0,1,-2), Size = dim2(0.4,0,0,3) }), { pos = dim2(0,1,0,1), size = dim2(1,-2,1,-2) })
        cornerLine(table.move(lineProps,1,#lineProps,1,{ AnchorPoint = vec2(0,1), Position = dim2(0,0,1,-5), Rotation = 180, Size = dim2(0,3,0.25,0) }), { pos = dim2(0,1,0,-2), size = dim2(1,-2,1,1) })
        cornerLine(table.move(lineProps,1,#lineProps,1,{ AnchorPoint = vec2(1,1), Position = dim2(1,0,1,-2), Size = dim2(0.4,0,0,3) }), { pos = dim2(0,1,0,1), size = dim2(1,-2,1,-2) })
        cornerLine(table.move(lineProps,1,#lineProps,1,{ AnchorPoint = vec2(1,1), Position = dim2(1,0,1,-5), Rotation = 180, Size = dim2(0,3,0.25,0) }), { pos = dim2(0,1,0,-2), size = dim2(1,-2,1,1) })

        -- Healthbar (will be sized dynamically in render loop)
        o.healthbar_holder = esp:make("Frame", {
            Parent = flags.Healthbar and o.holder or dead,
            AnchorPoint = vec2(1,0),
            Position = dim2(0,-flags.Healthbar_Gap,0,-1),
            Size = dim2(0, flags.Healthbar_Thickness + 2, 1, 2),

            BackgroundColor3 = BLK,
            BorderSizePixel = 0,
            Name = "\0",
            ZIndex = 2,
            Visible = true,
        })
        o.healthbar_holder:SetAttribute("TargetBgT", 0)
        o.healthbar = esp:make("Frame", {
            Parent = o.healthbar_holder,
            Position = dim2(0,1,0,1),
            Size = dim2(1,-2,1,-2),
            BackgroundColor3 = flags.Healthbar_Gradient and rgb(255,255,255) or flags.Health_High.Color,
            BorderSizePixel = 0,
            Name = "\0",
            ZIndex = 3,
        })
        o.healthbar:SetAttribute("TargetBgT", 0)

        o.healthbar_cover = esp:make("Frame", {
            Parent = o.healthbar,
            Position = dim2(0,0,0,0),
            Size = dim2(1,0,0,0),
            BackgroundColor3 = BLK,
            BorderSizePixel = 0,
            Name = "\0",
            ZIndex = 4,
        })
        o.healthbar_cover:SetAttribute("TargetBgT", 0)
        
        o.healthbar_gradient = Instance.new("UIGradient")
        o.healthbar_gradient.Rotation = flags.Healthbar_Gradient_Rotation
        o.healthbar_gradient.Enabled = flags.Healthbar_Gradient
        o.healthbar_gradient.Color = buildGradientSeq(flags.Healthbar_Gradient_Colors)
        o.healthbar_gradient.Parent = o.healthbar

        -- Health text
        o.health_text = esp:make("TextLabel", {
            Parent = flags.Health_Text and o.holder or dead,
            FontFace = fonts.getForElement("HealthText"),
            Text = "",
            TextColor3 = flags.Health_Text_Color.Color,
            TextStrokeTransparency = 0,
            TextSize = fonts.getSizeForElement("HealthText"),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AnchorPoint = vec2(1,0.5),
            Size = dim2(0,0,0,0),
            Position = dim2(0,0,0,0),
            AutomaticSize = Enum.AutomaticSize.XY,
            Name = "\0",
            TextTransparency = flags.Fade_Enabled and 1 or 0,
            ZIndex = 4,
        })

        -- Distance
        o.distance = esp:make("TextLabel", {
            Parent = flags.Distance and o.holder or dead,
            FontFace = fonts.getForElement("Distance"),
            Text = "0st",
            TextColor3 = flags.Distance_Gradient and rgb(255,255,255) or flags.Distance_Color.Color,
            TextStrokeTransparency = 0,
            TextSize = fonts.getSizeForElement("Distance"),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = dim2(1,0,0,0),
            Position = dim2(0,0,1,1),
            AutomaticSize = Enum.AutomaticSize.Y,
            Name = "\0",
            TextTransparency = flags.Fade_Enabled and 1 or 0,
        })
        o.distance_gradient = Instance.new("UIGradient")
        o.distance_gradient.Rotation = flags.Distance_Gradient_Rotation
        o.distance_gradient.Enabled = flags.Distance_Gradient
        o.distance_gradient.Color = buildGradientSeq(flags.Distance_Gradient_Colors)
        o.distance_gradient.Parent = o.distance

        -- Weapon
        o.weapon = esp:make("TextLabel", {
            Parent = dead,
            FontFace = fonts.getForElement("Weapon"),
            Text = "",
            TextColor3 = flags.Weapon_Gradient and rgb(255,255,255) or flags.Weapon_Color.Color,
            TextStrokeTransparency = 0,
            TextSize = fonts.getSizeForElement("Weapon"),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = dim2(1,0,0,0),
            Position = dim2(0,0,1,11),
            AutomaticSize = Enum.AutomaticSize.Y,
            Name = "\0",
            TextTransparency = flags.Fade_Enabled and 1 or 0,
        })
        o.weapon_gradient = Instance.new("UIGradient")
        o.weapon_gradient.Rotation = flags.Weapon_Gradient_Rotation
        o.weapon_gradient.Enabled = flags.Weapon_Gradient
        o.weapon_gradient.Color = buildGradientSeq(flags.Weapon_Gradient_Colors)
        o.weapon_gradient.Parent = o.weapon

        -- Event handlers
        data.onHealthChanged = function(value)
            if not flags.Healthbar then return end
            local hum = data.info.humanoid
            if not hum then return end
            local maxHealth = hum.MaxHealth
            local t = math.clamp(value / maxHealth, 0, 1)
            local barColor = flags.Health_Low.Color:Lerp(flags.Health_High.Color, t)
            
            if flags.Health_Text then
                o.health_text.Text = tostring(math.floor(value))
                o.health_text.TextColor3 = flags.Health_Text_Dynamic and barColor or flags.Health_Text_Color.Color
            end
            if value <= 0 then
                esp:fadeOut(o.holder)
                return
            else
                if not o.holder.Visible and data.info.character then
                    esp:fadeIn(o.holder)
                end
            end
            local targetSize = dim2(1, 0, 1 - t, 0)
            local targetTextPos = UDim2.new(0, -(flags.Healthbar_Gap + flags.Healthbar_Thickness + flags.Health_Text_Gap), 1 - t, 1)
            
            if flags.Healthbar_Tween then
                local tweenInfoHealth = TweenInfo.new(flags.Healthbar_Tween_Speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                if data.healthTween then data.healthTween:Cancel() end
                if data.textTween then data.textTween:Cancel() end
                local tween = TweenService:Create(o.healthbar_cover, tweenInfoHealth, { Size = targetSize })
                local textTween = TweenService:Create(o.health_text, tweenInfoHealth, { Position = targetTextPos })
                tween:Play()
                textTween:Play()
                data.healthTween = tween
                data.textTween = textTween
            else
                o.healthbar_cover.Size = targetSize
                o.health_text.Position = targetTextPos
            end
            if not flags.Healthbar_Gradient then
                o.healthbar.BackgroundColor3 = barColor
            end
        end

        data.onToolChanged = function(item)
            if not item:IsA("Tool") then return end
            local hasTool = data.info.character and data.info.character:FindFirstChild(item.Name)
            o.weapon.Text = hasTool and item.Name or ""
            o.weapon.Parent = (flags.Weapon and hasTool) and o.holder or dead
        end

        data.refreshOffsets = function()
            local yOff = flags.Distance_Gap
            if o.distance.Parent == o.holder then
                o.distance.Position = dim2(0,0,1,yOff)
                yOff = yOff + o.distance.AbsoluteSize.Y + flags.Weapon_Gap
            end
            if o.weapon.Parent == o.holder then
                o.weapon.Position = dim2(0,0,1,yOff)
            end
        end

        -- Clean up old character connections
        local function cleanupCharacter()
            for _, conn in ipairs(data.charConnections) do
                conn:Disconnect()
            end
            data.charConnections = {}
        end

        -- Set up character and humanoid
        local function setupCharacter(char)
            task.spawn(function()
                if not char then return end
                cleanupCharacter()
                local hum = char:WaitForChild("Humanoid", 3)
                local root = char:WaitForChild("HumanoidRootPart", 3)
                if not hum or not root then return end
                data.info.character = char
                data.info.humanoid = hum
                data.info.rootpart = root
                table.insert(data.charConnections, hum.HealthChanged:Connect(data.onHealthChanged))
                table.insert(data.charConnections, char.ChildAdded:Connect(data.onToolChanged))
                table.insert(data.charConnections, char.ChildRemoved:Connect(data.onToolChanged))
                data.onHealthChanged(hum.Health)
                local existingTool = char:FindFirstChildOfClass("Tool")
                if existingTool then data.onToolChanged(existingTool) end
            end)
        end

        if player.Character then
            setupCharacter(player.Character)
        end
        table.insert(data.connections, player.CharacterAdded:Connect(setupCharacter))

        esp:fadeIn(o.holder)
    end

    -- Refresh flags for all players
    function esp.refreshElements()
        fadeTweenInfo = TweenInfo.new(flags.Fade_Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        for _, player in Players:GetPlayers() do
            if player == Players.LocalPlayer then continue end
            local data = esp[player.Name]
            if not data then continue end
            local o = data.objects
            o.holder.Parent = flags.Enabled and esp.screengui or esp.cache
            o.name.Parent = flags.Names and o.holder or esp.cache
            o.name.Position = dim2(0.5, 0, 0, -flags.Name_Gap)
            o.name.TextColor3 = flags.Name_Gradient and rgb(255,255,255) or flags.Name_Color.Color
            o.name.FontFace = fonts.getForElement("Name")
            o.name.TextSize = fonts.getSizeForElement("Name")
            o.name_gradient.Enabled = flags.Name_Gradient
            o.name_gradient.Color = buildGradientSeq(flags.Name_Gradient_Colors)
            o.name_gradient.Rotation = flags.Name_Gradient_Rotation
            local isCorner = flags.Box_Type == "Corner"
            if flags.Boxes then
                o.corners.Parent = isCorner and o.holder or esp.cache
                o.box_handler.Parent = (not isCorner) and o.holder or esp.cache
                o.box_outline.Parent = (not isCorner) and o.holder or esp.cache
            else
                o.corners.Parent = esp.cache
                o.box_handler.Parent = esp.cache
                o.box_outline.Parent = esp.cache
            end
            o.box_color.Color = flags.Box_Color.Color
            for _, line in o.corners:GetChildren() do
                if line.Name == "line" and line:FindFirstChildOfClass("Frame") then
                    line:FindFirstChildOfClass("Frame").BackgroundColor3 = flags.Box_Color.Color
                end
            end
            o.box_fill.Visible = flags.Boxes and flags.Box_Fill and (not isCorner)
            if o.box_fill.Visible then
                o.box_fill.BackgroundTransparency = flags.Box_Fill_Transparency
                o.box_fill:SetAttribute("TargetBgT", flags.Box_Fill_Transparency)
                o.box_fill.BackgroundColor3 = flags.Box_Fill_Gradient and rgb(255,255,255) or flags.Box_Fill_Color.Color
                o.box_fill_gradient.Enabled = flags.Box_Fill_Gradient
                o.box_fill_gradient.Color = buildGradientSeq(flags.Box_Fill_Gradient_Colors)
                o.box_fill_gradient.Rotation = flags.Box_Fill_Gradient_Rotation
            end
            o.healthbar_holder.Parent = flags.Healthbar and o.holder or esp.cache
            o.healthbar_holder.Size = dim2(0, flags.Healthbar_Thickness + 2, 1, 2)
            o.healthbar_holder.Position = dim2(0, -flags.Healthbar_Gap, 0, -1)
            o.healthbar_gradient.Enabled = flags.Healthbar_Gradient
            o.healthbar_gradient.Rotation = flags.Healthbar_Gradient_Rotation
            o.health_text.Parent = flags.Health_Text and o.holder or esp.cache
            o.health_text.FontFace = fonts.getForElement("HealthText")
            o.health_text.TextSize = fonts.getSizeForElement("HealthText")
            
            if data.info.humanoid then data.onHealthChanged(data.info.humanoid.Health) end
            if flags.Healthbar_Gradient then
                o.healthbar.BackgroundColor3 = rgb(255,255,255)
                o.healthbar_gradient.Color = buildGradientSeq(flags.Healthbar_Gradient_Colors)
            end
            o.distance.TextColor3 = flags.Distance_Gradient and rgb(255,255,255) or flags.Distance_Color.Color
            o.distance.Parent = flags.Distance and o.holder or esp.cache
            o.distance.FontFace = fonts.getForElement("Distance")
            o.distance.TextSize = fonts.getSizeForElement("Distance")
            o.distance_gradient.Enabled = flags.Distance_Gradient
            o.distance_gradient.Color = buildGradientSeq(flags.Distance_Gradient_Colors)
            o.distance_gradient.Rotation = flags.Distance_Gradient_Rotation
            o.weapon.TextColor3 = flags.Weapon_Gradient and rgb(255,255,255) or flags.Weapon_Color.Color
            o.weapon.FontFace = fonts.getForElement("Weapon")
            o.weapon.TextSize = fonts.getSizeForElement("Weapon")
            o.weapon_gradient.Enabled = flags.Weapon_Gradient
            o.weapon_gradient.Color = buildGradientSeq(flags.Weapon_Gradient_Colors)
            o.weapon_gradient.Rotation = flags.Weapon_Gradient_Rotation
            local hasTool = player.Character and player.Character:FindFirstChildOfClass("Tool")
            o.weapon.Parent = (flags.Weapon and hasTool) and o.holder or esp.cache
            data.refreshOffsets()
            
            if o.holder.Visible then
                esp:fadeIn(o.holder, true)
            end
        end
    end

    -- Render loop
    esp.connection = RunService.RenderStepped:Connect(function()
        if not flags.Enabled then return end
        for _, player in Players:GetPlayers() do
            local data = esp[player.Name]
            if not data then continue end
            local info = data.info
            local o = data.objects

            if not (info.character and info.humanoid and info.rootpart and info.character.Parent) then 
                if o and o.holder.Visible then esp:fadeOut(o.holder, nil, true) end
                continue 
            end

            local isAlive = info.humanoid.Health > 0
            local boxSize, boxPos, onScreen, distance = esp:boxSolve(info.rootpart)
            
            if not isAlive then
                if o.holder.Visible and boxPos then
                    o.holder.Position = UDim2.fromOffset(boxPos.X, boxPos.Y)
                    o.holder.Size = UDim2.fromOffset(boxSize.X, boxSize.Y)
                end
                continue
            end

            local tooFar = (flags.Max_Distance > 0 and distance > flags.Max_Distance)
            local shouldShow = onScreen and not tooFar

            if o.holder.Visible ~= shouldShow then
                if shouldShow then esp:fadeIn(o.holder, true) else esp:fadeOut(o.holder, nil, true) end
            end
            if not shouldShow then continue end

            o.holder.Position = UDim2.fromOffset(boxPos.X, boxPos.Y)
            o.holder.Size = UDim2.fromOffset(boxSize.X, boxSize.Y)

            local distVal = flags.Distance_Type == "Meters" and math.round(distance / 3.3) or math.round(distance)
            local distStr = tostring(distVal) .. (flags.Distance_Type == "Meters" and "m" or "st")
            if o.distance.Text ~= distStr then o.distance.Text = distStr end

            data.refreshOffsets()
        end
    end)

    -- Remove player ESP (cleanup) – now immediate to prevent lingering UI
    function esp:removeObject(player)
        local data = esp[player.Name]
        if not data then return end
        for _, conn in ipairs(data.connections or {}) do
            conn:Disconnect()
        end
        for _, conn in ipairs(data.charConnections or {}) do
            conn:Disconnect()
        end
        if data.objects and data.objects.holder then
            data.objects.holder:Destroy()
        end
        esp[player.Name] = nil
    end

    -- Unload everything
    function esp:unload()
        for _, player in Players:GetPlayers() do
            esp:removeObject(player)
        end
        esp.connection:Disconnect()
        if esp.player_added then esp.player_added:Disconnect() end
        if esp.player_removed then esp.player_removed:Disconnect() end
        esp.cache:Destroy()
        esp.screengui:Destroy()
        esp = nil
    end
end

-- Initialize
for _, player in Players:GetPlayers() do
    if player ~= Players.LocalPlayer then
        esp:createObject(player)
    end
end
esp.player_added = Players.PlayerAdded:Connect(function(v) esp:createObject(v) end)
esp.player_removed = Players.PlayerRemoving:Connect(function(v) esp:removeObject(v) end)
task.wait()
esp.refreshElements()

-- =================================================================================
-- User Interface Integration (LinoriaLib)
-- =================================================================================
local repo = 'https://raw.githubusercontent.com/dgwowxyz/ssssssss/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

Library.Font = fonts.list[2]

local Window = Library:CreateWindow({
    Title = 'head',
	Suffix = 'shot',
    Center = true,
    AutoShow = true,
    TabPadding = 1,
    MenuFadeTime = 0.1
})

local Tabs = {
    Combat = Window:AddTab(' combat '),
    Main = Window:AddTab('    visuals    '),
    Misc = Window:AddTab(' misc '),	
    ['UI Settings'] = Window:AddTab('  ui  '),
    ['Configs'] = Window:AddTab('   config   '),
}

local AimbotGroup = Tabs.Combat:AddLeftGroupbox('aimbot')
AimbotGroup:AddToggle('Aimbot_Enabled', { Text = 'enabled', Default = false }):AddKeyPicker('Aimbot_Key', { Default = 'MB2', SyncToggleState = true, Mode = 'Hold', Text = 'aimbot' })
AimbotGroup:AddToggle('Aimbot_Enabled4', { Text = 'enabled4', Default = false }):AddKeyPicker('Aimbot_Key4', { Default = 'MB2', SyncToggleState = true, Mode = 'Hold', Text = 'aimbot4' })

local MainGroup = Tabs.Main:AddLeftGroupbox('esp')
local GradientsGroup = Tabs.Main:AddLeftGroupbox('gradients')
local SetupGroup = Tabs.Main:AddLeftGroupbox('esp settings')

local function r() esp.refreshElements() end
local fontOptions = {"ProggyTiny", "ProggyClean", "fsTahoma8px", "TahomaModern", "SmallestPixel7"}

-- Main Toggles
MainGroup:AddToggle('ESPEnabled', { Text = 'enabled', Default = false, Callback = function(v) flags.Enabled = v; r() end })
MainGroup:AddToggle('ESPBoxes', { Text = 'boxes', Default = false, Callback = function(v) flags.Boxes = v; r() end }):AddColorPicker('BoxCol', { Default = flags.Box_Color.Color, Callback = function(c) flags.Box_Color.Color = c; r() end })
MainGroup:AddToggle('ESPBoxFill', { Text = 'box fill', Default = false, Callback = function(v) flags.Box_Fill = v; r() end }):AddColorPicker('FillCol', { Default = flags.Box_Fill_Color.Color, Callback = function(c) flags.Box_Fill_Color.Color = c; r() end })
MainGroup:AddToggle('ESPNames', { Text = 'names', Default = false, Callback = function(v) flags.Names = v; r() end }):AddColorPicker('NameCol', { Default = flags.Name_Color.Color, Callback = function(c) flags.Name_Color.Color = c; r() end })
MainGroup:AddToggle('ESPDist', { Text = 'distance', Default = false, Callback = function(v) flags.Distance = v; r() end }):AddColorPicker('DistCol', { Default = flags.Distance_Color.Color, Callback = function(c) flags.Distance_Color.Color = c; r() end })
MainGroup:AddToggle('ESPWep', { Text = 'weapon', Default = false, Callback = function(v) flags.Weapon = v; r() end }):AddColorPicker('WepCol', { Default = flags.Weapon_Color.Color, Callback = function(c) flags.Weapon_Color.Color = c; r() end })
MainGroup:AddToggle('ESPHpBar', { Text = 'healthbar', Default = false, Callback = function(v) flags.Healthbar = v; r() end })
MainGroup:AddToggle('ESPHpText', { Text = 'health text', Default = false, Callback = function(v) flags.Health_Text = v; r() end }):AddColorPicker('HpTextCol', { Default = flags.Health_Text_Color.Color, Callback = function(c) flags.Health_Text_Color.Color = c; r() end })

-- Gradients
GradientsGroup:AddToggle('GradBoxFill', { Text = 'box fill', Default = flags.Box_Fill_Gradient, Callback = function(v) flags.Box_Fill_Gradient = v; r() end })
GradientsGroup:AddLabel('box'):AddColorPicker('GBoxFillT', { Default = flags.Box_Fill_Gradient_Colors.Top, Callback = function(c) flags.Box_Fill_Gradient_Colors.Top = c; r() end }):AddColorPicker('GBoxFillM', { Default = flags.Box_Fill_Gradient_Colors.Middle, Callback = function(c) flags.Box_Fill_Gradient_Colors.Middle = c; r() end }):AddColorPicker('GBoxFillB', { Default = flags.Box_Fill_Gradient_Colors.Bottom, Callback = function(c) flags.Box_Fill_Gradient_Colors.Bottom = c; r() end })
GradientsGroup:AddSlider('GradBoxFillRot', { Text = 'box fill rotation', Default = flags.Box_Fill_Gradient_Rotation, Compact = true, Min = 0, Max = 360, Rounding = 0, Callback = function(v) flags.Box_Fill_Gradient_Rotation = v; r() end })

GradientsGroup:AddToggle('GradNames', { Text = 'name', Default = flags.Name_Gradient, Callback = function(v) flags.Name_Gradient = v; r() end })
GradientsGroup:AddLabel('name'):AddColorPicker('GNameT', { Default = flags.Name_Gradient_Colors.Top, Callback = function(c) flags.Name_Gradient_Colors.Top = c; r() end }):AddColorPicker('GNameM', { Default = flags.Name_Gradient_Colors.Middle, Callback = function(c) flags.Name_Gradient_Colors.Middle = c; r() end }):AddColorPicker('GNameB', { Default = flags.Name_Gradient_Colors.Bottom, Callback = function(c) flags.Name_Gradient_Colors.Bottom = c; r() end })
GradientsGroup:AddSlider('GradNamesRot', { Text = 'name rotation', Default = flags.Name_Gradient_Rotation, Compact = true, Min = 0, Max = 360, Rounding = 0, Callback = function(v) flags.Name_Gradient_Rotation = v; r() end })

GradientsGroup:AddToggle('GradDist', { Text = 'distance', Default = flags.Distance_Gradient, Callback = function(v) flags.Distance_Gradient = v; r() end })
GradientsGroup:AddLabel('distance'):AddColorPicker('GDistT', { Default = flags.Distance_Gradient_Colors.Top, Callback = function(c) flags.Distance_Gradient_Colors.Top = c; r() end }):AddColorPicker('GDistM', { Default = flags.Distance_Gradient_Colors.Middle, Callback = function(c) flags.Distance_Gradient_Colors.Middle = c; r() end }):AddColorPicker('GDistB', { Default = flags.Distance_Gradient_Colors.Bottom, Callback = function(c) flags.Distance_Gradient_Colors.Bottom = c; r() end })
GradientsGroup:AddSlider('GradDistRot', { Text = 'distance rotation', Default = flags.Distance_Gradient_Rotation, Compact = true, Min = 0, Max = 360, Rounding = 0, Callback = function(v) flags.Distance_Gradient_Rotation = v; r() end })

GradientsGroup:AddToggle('GradWep', { Text = 'weapon', Default = flags.Weapon_Gradient, Callback = function(v) flags.Weapon_Gradient = v; r() end })
GradientsGroup:AddLabel('weapon'):AddColorPicker('GWepT', { Default = flags.Weapon_Gradient_Colors.Top, Callback = function(c) flags.Weapon_Gradient_Colors.Top = c; r() end }):AddColorPicker('GWepM', { Default = flags.Weapon_Gradient_Colors.Middle, Callback = function(c) flags.Weapon_Gradient_Colors.Middle = c; r() end }):AddColorPicker('GWepB', { Default = flags.Weapon_Gradient_Colors.Bottom, Callback = function(c) flags.Weapon_Gradient_Colors.Bottom = c; r() end })
GradientsGroup:AddSlider('GradWepRot', { Text = 'weapon rotation', Default = flags.Weapon_Gradient_Rotation, Compact = true, Min = 0, Max = 360, Rounding = 0, Callback = function(v) flags.Weapon_Gradient_Rotation = v; r() end })

GradientsGroup:AddToggle('GradHp', { Text = 'healthbar', Default = flags.Healthbar_Gradient, Callback = function(v) flags.Healthbar_Gradient = v; r() end })
GradientsGroup:AddLabel('healthbar'):AddColorPicker('GHpT', { Default = flags.Healthbar_Gradient_Colors.Top, Callback = function(c) flags.Healthbar_Gradient_Colors.Top = c; r() end }):AddColorPicker('GHpM', { Default = flags.Healthbar_Gradient_Colors.Middle, Callback = function(c) flags.Healthbar_Gradient_Colors.Middle = c; r() end }):AddColorPicker('GHpB', { Default = flags.Healthbar_Gradient_Colors.Bottom, Callback = function(c) flags.Healthbar_Gradient_Colors.Bottom = c; r() end })

-- ESP Setup
SetupGroup:AddSlider('ESPMaxDist', { Text = 'max distance', Default = flags.Max_Distance, Min = 0, Max = 10000, Rounding = 0, Callback = function(v) flags.Max_Distance = v; r() end })
SetupGroup:AddDropdown('ESPDistType', { Values = {"studs", "meters"}, Default = 2, Multi = false, Text = 'distance type', Callback = function(v) flags.Distance_Type = v == "meters" and "Meters" or "Studs"; r() end })
SetupGroup:AddDropdown('ESPBoxType', { Values = {"normal"}, Default = 1, Multi = false, Text = 'box type', Callback = function(v) flags.Box_Type = v == "normal" and "Normal"; r() end })
SetupGroup:AddSlider('ESPBoxFillTrans', { Text = 'fill transparency', Compact = true, Default = flags.Box_Fill_Transparency, Min = 0, Max = 1, Rounding = 1, Callback = function(v) flags.Box_Fill_Transparency = v; r() end })

SetupGroup:AddSlider('SzName', { Text = 'name size', Compact = true, Default = flags.Name_Size, Min = 8, Max = 32, Rounding = 0, Callback = function(v) flags.Name_Size = v; r() end })
SetupGroup:AddSlider('SzDist', { Text = 'distance size', Compact = true, Default = flags.Distance_Size, Min = 8, Max = 32, Rounding = 0, Callback = function(v) flags.Distance_Size = v; r() end })
SetupGroup:AddSlider('SzWep', { Text = 'weapon size', Compact = true, Default = flags.Weapon_Size, Min = 8, Max = 32, Rounding = 0, Callback = function(v) flags.Weapon_Size = v; r() end })
SetupGroup:AddSlider('SzHp', { Text = 'health text size', Compact = true, Default = flags.Health_Text_Size, Min = 8, Max = 32, Rounding = 0, Callback = function(v) flags.Health_Text_Size = v; r() end })

SetupGroup:AddSlider('GpName', { Text = 'name gap', Compact = true, Default = flags.Name_Gap, Min = 0, Max = 10, Rounding = 0, Callback = function(v) flags.Name_Gap = v; r() end })
SetupGroup:AddSlider('GpDist', { Text = 'distance gap', Compact = true, Default = flags.Distance_Gap, Min = 0, Max = 10, Rounding = 0, Callback = function(v) flags.Distance_Gap = v; r() end })
SetupGroup:AddSlider('GpWep', { Text = 'weapon gap', Compact = true, Default = flags.Weapon_Gap, Min = 0, Max = 10, Rounding = 0, Callback = function(v) flags.Weapon_Gap = v; r() end })
SetupGroup:AddSlider('GpHp', { Text = 'healthbar gap', Compact = true, Default = flags.Healthbar_Gap, Min = 0, Max = 10, Rounding = 0, Callback = function(v) flags.Healthbar_Gap = v; r() end })
SetupGroup:AddSlider('GpHpTxt', { Text = 'health text gap', Compact = true, Default = flags.Health_Text_Gap, Min = 0, Max = 10, Rounding = 0, Callback = function(v) flags.Health_Text_Gap = v; r() end })

SetupGroup:AddToggle('ESPHpTextDyn', { Text = 'dynamic health text color', Default = false, Callback = function(v) flags.Health_Text_Dynamic = v; r() end })
SetupGroup:AddToggle('ESPFade', { Text = 'fade animations', Default = false, Callback = function(v) flags.Fade_Enabled = v; r() end })
SetupGroup:AddSlider('ESPFadeDur', { Text = 'fade duration', Compact = true, Default = flags.Fade_Duration, Min = 0.1, Max = 1, Rounding = 1, Callback = function(v) flags.Fade_Duration = v; r() end })
SetupGroup:AddToggle('ESPHpTween', { Text = 'health tween animations', Default = false, Callback = function(v) flags.Healthbar_Tween = v; r() end })
SetupGroup:AddDropdown('ESPNameFont', { Values = fontOptions, Default = flags.Name_Font, Multi = false, Text = 'name font', Callback = function(v) flags.Name_Font = table.find(fontOptions, v) or 1; r() end })
SetupGroup:AddDropdown('ESPDistFont', { Values = fontOptions, Default = flags.Distance_Font, Multi = false, Text = 'distance font', Callback = function(v) flags.Distance_Font = table.find(fontOptions, v) or 1; r() end })
SetupGroup:AddDropdown('ESPWepFont', { Values = fontOptions, Default = flags.Weapon_Font, Multi = false, Text = 'weapon font', Callback = function(v) flags.Weapon_Font = table.find(fontOptions, v) or 1; r() end })

-- SaveManager
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('menu')
MenuGroup:AddButton('unload', function() Library:Unload() end)
MenuGroup:AddLabel('menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'menu keybind' })
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('ascend.cc')
SaveManager:SetFolder('ascend.cc/project delta')
SaveManager:BuildConfigSection(Tabs['Configs'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()
