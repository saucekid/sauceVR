local Event = {
    ["Connections"] = {},
    ["Clear"] = function(self)
        for _,con in pairs(self.Connections) do
            con:Disconnect()
        end
    end
}
Event.__index = Event


setmetatable(Event, {
    __call = function(self, ...)
        local args = {...}
        table.insert(self.Connections, args[1])
    end
})

return Event