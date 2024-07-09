export type ArgumentPrototype = {
    name: (self: Argument) -> string,
    default: (self: Argument, value: any, description: string?) -> string,
    argParser: (self: Argument, fn: (value: string, previous: any) -> any) -> Option
}

export type Argument = {
    description: string,
    variadic: boolean,
    parseArg: ((value: string, previous: any) -> any)?,
    defaultValue: any?,
    defaultValueDescription: string?,
    required: boolean,
    _name: string
} & ArgumentPrototype

export type OptionPrototype = {
    default: (self: Option, value: any, description: string?) -> Option,
    argParser: (self: Option, fn: (value: string, previous: any) -> any) -> Option,
    makeOptionMandatory: (self: Option, mandatory: boolean? ) -> Option,
    hideHelp: (self: Option, hide: boolean? ) -> Option,
    name: (self: Option) -> string,
    attributeName: (self: Option) -> string,
    is: (self: Option, arg: string) -> boolean,
    isBoolean: (self: Option) -> boolean
}

export type Option = {
    flags: string,
    description: string,
    required: boolean,
    optional: boolean,
    mandatory: boolean,
    hidden: boolean,
    short: string?,
    long: string?,
    defaultValue: any?,
    defaultValueDescription: string?,
    parseArg: ((value: string, previous: any) -> any)?
} & OptionPrototype

return {}