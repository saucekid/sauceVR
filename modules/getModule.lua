return function(module)
    assert(type(module) == "string", "string only")
    local path = "https://raw.githubusercontent.com/saucekid/sauceVR/main/modules/"
    local module = loadstring(game:HttpGetAsync(path.. module.. ".lua"))()
    return module
end