local Colors = {
    trace = {
        background = '#CDD6F4',
        text = '#11111B',
    },
    debug = {
        background = '#A6E3A1',
        text = '#11111B',
    },
    info = {
        background = '#89B4FA',
        text = '#11111B',
    },
    warn = {
        background = '#FAB387',
        text = '#11111B',
    },
    error = {
        background = '#F38BA8',
        text = '#11111B',
    },
}

local FullName = {
    trace = ' | TRACE          ',
    info = ' | INFORMATION    ',
    warn = ' | WARNING        ',
    error = ' | ERROR          ',
    debug = ' | DEBUG          ',
}

local Abbreviation = {
    trace = ' | T   ',
    info = ' | I   ',
    warn = ' | W   ',
    error = ' | E   ',
    debug = ' | D   ',
}

local chars = {
    singleLine = '▪',
    startLine = '┏',
    line = '┃',
    endLine = '┗',
}

return table.freeze({
    colors = Colors,
    chars = chars,
    fullName = FullName,
    abbreviation = Abbreviation,
})
