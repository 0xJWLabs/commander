local function create_theme_color(color: any, style: any?): ThemeColor
    return setmetatable({ color = color, style = style }, {
        __index = {},
        __call = function(self, text)
            if self.style ~= nil then
                print(self.color(self.style(text)))
            else
                print(self.color(text))
            end
        end,
    })
end

export type ThemeColor = typeof(setmetatable(
    {} :: { color: any, style: any? },
    {} :: {
        __index: {},
        __call: (self: ThemeColor, text: string) -> (),
    }
))

return create_theme_color
