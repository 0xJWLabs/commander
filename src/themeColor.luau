local function create_theme_color(color: any, style: string?): ThemeColor
    return setmetatable({color = color, style = style}, {
        __index =  {},
        __call = function(self, text)
            print(self.color(text))
        end
    })
end

export type ThemeColor = typeof(setmetatable({} :: { color: any, style: string? }, {} :: {
    __index: {},
    __call: (self: ThemeColor, text: string) -> ()
}))

return create_theme_color