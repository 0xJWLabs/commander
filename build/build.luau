local fs = require('@lune/fs')
local luau = require('@lune/luau')
local process = require('@lune/process')

local userOS = process.os
local arch = process.arch

local function processSpawn(processName: string, parameters: { string }): process.SpawnResult
    return process.spawn(processName, parameters, {
        stdio = 'forward',
    })
end

local function removeFileRecursive(folderPath: string)
    if not fs.isDir(folderPath) then
        fs.writeDir(folderPath)
        return
    end
    for _, path in fs.readDir(folderPath) do
        local itemPath = `{folderPath}/{path}`
        if fs.isDir(itemPath) then
            fs.removeDir(itemPath)
        else
            fs.removeFile(itemPath)
        end
    end
end

local function zipFile(target: string, source: string, keep: boolean?): process.SpawnResult
    local res = processSpawn('7z', { 'a', target, source })

    if res.ok then
        if not keep then
            fs.removeFile(`{source}`)
        end
    else
        print(res.stderr)
    end

    return res
end

local function build(os: string)
    local target = ''
    if string.find(os, 'windows') then
        target = 'commander.exe'
    else
        target = 'commander'
    end
    local res = processSpawn('lune', {
        'build',
        './dist/bundled.luau',
        '--output',
        `./release/{target}`,
        '--target',
        os,
    })
    if res.ok then
        if userOS .. '-' .. arch == os then
            fs.copy(`./release/{target}`, `./dist/{target}`)
        end

        res = zipFile(`./release/commander-{os}.zip`, `./release/{target}`)
    else
        print(res.stderr)
    end

    return res
end

local function buildBundle(targetOs: { string })
    local res
    for _, os in targetOs do
        res = build(os)
        if not res.ok then
            break
        end
    end

    return res
end

local INIT_FILE = [[
--!native
--!optimize 2

local fs = require("@lune/fs")
local luau = require("@lune/luau")

local Bytecode = fs.readFile("./bytecode.txt")
luau.load(Bytecode)()
]]

return function()
    removeFileRecursive('./dist')
    removeFileRecursive('./release')

    print('Building source code')
    local res = processSpawn('./build/luaup.exe', {
        'process',
        './example/command.luau',
        './dist/bundled.luau',
        '--config',
        './build/.luaup.json5',
    })

    local content = fs.readFile('./dist/bundled.luau')
    content = '--!nocheck\n--!native\n\n' .. content
    content = content:gsub('%.debugProgram', '.program')
    fs.writeFile('./dist/bundled.luau', content)

    if res.ok then
        local content = fs.readFile('./dist/bundled.luau')
        content = '--!nocheck\n--!native\n\n' .. content
        content = content:gsub('%.debugProgram', '.program')
        fs.writeFile('./dist/bundled.luau', content)
        print('Building standalone executable')
        local status = buildBundle({
            'windows-x86_64',
            'linux-x86_64',
            'linux-aarch64',
        })

        if status.ok then
            print('Compiling bytecode...')
            fs.writeFile(
                './release/bytecode.txt',
                luau.compile(content, {
                    optimizationLevel = 2,
                })
            )
            fs.writeFile('./release/init.luau', INIT_FILE)

            print('Zipping bytecode...')
            res = zipFile('./release/bytecode.zip', './release/bytecode.txt')
            if res.ok then
                res = zipFile('./release/bytecode.zip', './release/init.luau')
            end
        end
    end
end
