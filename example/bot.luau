-- Require "commander"
local Commander = require('@commander/')
local program = Commander.program

-- Create a commander instance
program
    :name('create-discord-bot')
    :description("Create discord bot from templates")
    :version('0.1.0')
    :argument('<name>', 'Bot name')
    :option('-t, --token <token>', 'Token')
    :option('-s, --save', 'Save bot')
    :action(function(botName, opts)
        print(botName)
        print(opts)
    end)

-- Parse and execute the command
program:parse()