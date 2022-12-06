local TS = game:GetService("TweenService")

local objectInfo = {
    {
        checkMethod = "ClassName.find",
        checkMethodInputs = { "Image[BL]" },
        transparencyProps = { "ImageTransparency" }
    },

    {
        checkMethod = "ClassName.find",
        checkMethodInputs = { "^Selection" },
        transparencyProps = { "SurfaceTransparency", "Transparency" }
    },

    {
        checkMethod = "ClassName.find",
        checkMethodInputs = { "Text[BL]" },
        transparencyProps = { "TextTransparency", "TextStrokeTransparency" }
    },

    {
        checkMethod = "IsA",
        checkMethodInputs = { "GuiObject" },
        transparencyProps = { "BackgroundTransparency" }
    },

    {
        checkMethod = "IsA",
        checkMethodInputs = { "BasePart", "Decal", "Texture", "ImageHandleAdornment", "SurfaceSelection", "UIStroke" },
        transparencyProps = { "Transparency" }
    },

    {
        checkMethod = "IsA",
        checkMethodInputs = { "ScrollingFrame" },
        transparencyProps = { "SrollBarImageTransparency" }
    },
}

local function getTransparencyProps(object, goalTransparency)
    local totalTransparencyProps = {}

    for _, objInfo in ipairs(objectInfo) do
        local checkMethodTokens = string.split(objInfo.checkMethod, ".")
        local currToken = object
        local hasTransparencyProp = false

        local len = #checkMethodTokens

        for i = 1, len - 1 do
            currToken = currToken[checkMethodTokens[i]]
        end

        for _, checkMethodInput in ipairs(objInfo.checkMethodInputs) do
            hasTransparencyProp = currToken[checkMethodTokens[len]](currToken, checkMethodInput)

            if hasTransparencyProp then
                break
            end
        end

        if hasTransparencyProp then
            for _, transparencyProp in ipairs(objInfo.transparencyProps) do
                totalTransparencyProps[transparencyProp] = goalTransparency or object[transparencyProp]
            end
        end
    end

    if next(totalTransparencyProps) == nil then return nil end

    return totalTransparencyProps
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local Terpy = {}
Terpy.__index = Terpy

function Terpy.new(container)
    local self = setmetatable({
        Transparency = 0,

        _container = container,
        _tweens = {}
    }, Terpy)

    self:_cache()

    return self
end

function Terpy:_cache()
    self._terpyObjects = {}
    self._originalTransparencies = {}

    local function cache(obj)
        local originalTransparencies = getTransparencyProps(obj)

        if originalTransparencies then
            self._originalTransparencies[obj] = originalTransparencies

            table.insert(self._terpyObjects, obj)
        end
    end

    for _, obj in ipairs(self._container:GetDescendants()) do
        cache(obj)
    end

    cache(self._container)
end

function Terpy:_playTweens()
    for _, tween in ipairs(self._tweens) do
        tween:Play()
    end
end

function Terpy:_cancelTweens()
    for _, tween in ipairs(self._tweens) do
        if tween.PlaybackState == Enum.PlaybackState.Playing then
            tween:Cancel()
        end
    end

    table.clear(self._tweens)
end

function Terpy:SetTransparency(goalTransparency, ignoreOriginalTransparencies)
    self.Transparency = goalTransparency

    self:_cancelTweens()

    for _, terpyObj in ipairs(self._terpyObjects) do
        for transparencyProperty, originalTransparency in pairs(self._originalTransparencies[terpyObj]) do
            if ignoreOriginalTransparencies then
                terpyObj[transparencyProperty] = goalTransparency
            else
                terpyObj[transparencyProperty] = lerp(originalTransparency, 1, goalTransparency)
            end
        end
    end
end

function Terpy:TweenTransparency(tweenInfo, goalTransparency, ignoreOriginalTransparencies)
    self.Transparency = goalTransparency

    self:_cancelTweens()

    for _, terpyObj in ipairs(self._terpyObjects) do
        local propertyTable = {}

        for transparencyProperty, originalTransparency in pairs(self._originalTransparencies[terpyObj]) do
            if ignoreOriginalTransparencies then
                propertyTable[transparencyProperty] = goalTransparency
            else
                propertyTable[transparencyProperty] = lerp(originalTransparency, 1, goalTransparency)
            end
        end

        table.insert(self._tweens, TS:Create(terpyObj, tweenInfo, propertyTable))
    end

    self:_playTweens()

    return self._tweens[1]
end

return Terpy