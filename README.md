# Commander.luau

## Installation

- Using luau package manager
```sh
lpm install commander
```

- Using git submodules
```sh
git submodule add https://github.com/0xJWLabs/commander.luau
```

## Quick Start

The command line interface (CLI) is designed to provide users with a flexible and intuitive way to interact with the application. At the core of this system is the Commander component, which is responsible for handling the parsing of arguments, managing options, and providing user feedback when issues arise. Below is an overview of its key features and functionalities:
Argument Parsing

- Command-Arguments: Commander accurately identifies and processes the commands and their associated arguments provided by the user.
- Options: It distinguishes between different types of options, ensuring each is correctly interpreted.

Options Handling

- Boolean Options: These options act as flags. When present, they toggle a specific feature or functionality. For example, --verbose or -v might enable verbose logging.
- Value Options: These options require a subsequent argument to specify their value. For example, --output <file> or -o <file> directs the output to the specified file.

Error Handling
- Strict Validation: Commander is rigorous in its validation, immediately displaying errors for any unrecognized options or commands. This strictness helps prevent user mistakes and ensures the correct usage of the CLI.
- Usage Errors: When an error is detected, Commander provides clear and concise error messages, guiding the user towards the correct usage of commands and options.

Help System
-  Automatic Help Generation: Commander automatically generates a help message that lists all available commands and options, along with their descriptions and usage examples.
- Accessible Help: Users can easily access the help information by invoking a help option (e.g., --help or -h), which provides detailed instructions and examples.

By managing the parsing, validation, and help functions, Commander ensures a robust and user-friendly command line interface, facilitating effective interaction with the application.

## Support

The current version of Commander is fully supported on long term support versions of luau.