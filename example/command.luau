-- Require "commander"
local Commander = require('@commander/')
local program = Commander.program

-- Create a commander instance
program
    :name('lpm')
    :description("This is a luau package manager")

-- Add init command
program:command('init')
    :aliases({ 'create', 'innit' })
    :description('Create a package json file')
    :argument('[package-spec...]', 'Package specification')
    :option('-f, --force', 'Force option')
    :action(function(parsed)
        print(parsed['package-spec'])
        print(parsed.force)
    end)

-- Add install command
program:command("install")
    :argument("[package-spec...]", "Package specification")
    :description('Install a package')
    :option('-S, --save', 'Save package')
    :option('-d, --dev', 'Install package as dev dependencies')
    :action(function(parsed)
        print(parsed['package-spec'])
        print(parsed.save)
        print(parsed.dev)
    end)

-- Parse and execute the command
program:parse()