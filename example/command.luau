-- Require "commander"
local Commander = require('@commander/')
local program = Commander.debugProgram

-- Create a commander instance
program
    :name('lpm')
    :description("This is a luau package manager")
    :version('0.1.0')

-- Add init command
program:command('init')
    :aliases({ 'create', 'innit' })
    :description('Create a package json file')
    :argument('[package-spec...]', 'Package specification')
    :option('-f, --force', 'Force option')
    :action(function(packages, opts)
        print('List of packages', packages)
        print(opts)
    end)

-- Add install command
program:command("install")
    :aliases({ 'add', 'i' })
    :argument("[package-spec...]", "Package specification")
    :description('Install a package')
    :option('-S, --save', 'Save package')
    :option('-D, --save-dev', 'Package will appear in your devDependencies')
    :option('-g, --global', 'Install package globally')
    :action(function(packages, opt)
    end)

program:command("update")
    :argument("<package-name>", "Package name")
    :argument("[version]", "Version", "latest")
    :description('Install a package')
    :action(function(package, version)
        print(package, version)
    end)

-- Parse and execute the command
program:parse()