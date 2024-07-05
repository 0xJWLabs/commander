local bundler = require("./build/bundler")
local fs = require('@lune/fs')
fs.writeFile('./bundled1.luau', bundler.bundle("./test.luau"))