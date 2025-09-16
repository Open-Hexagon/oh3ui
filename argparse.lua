---Module that creates a parser for command line arguments
---Somewhat inspired by python's argparse module

---@class ArgumentEntry
---@field name1 string
---@field name2 string?
---@field help string
---@field nargs integer|"?"
---@field is_number boolean
---@field action "store_true"|"store_false"|"store_const"|"help"|nil
---@field default any
---@field const any
---@field dest string
---@field is_positional boolean

---@class Parser
---@field private prog string
---@field private desc string
---@field private positional_arg_count integer
---@field private argument_table ArgumentEntry[]
---@field private argument_list ArgumentEntry[]
local Parser = {}
Parser.__index = Parser

---Adds an argument to the parser
---@param name1 string Argument name. If name starts with "-", it's an option, else it's a positional option.
---@param name2 string? Optional secondary argument name. Takes priority when determining the argument destination.
---@param help string? Help text for this argument.
---@param nargs integer|"?" Number of arguments. Ignored if argument is positional. Can be 0. "?" means 1 or 0 arguments.
---@param is_number boolean Parser should convert the argument value into a number. If unable, parser will throw an error.
---@param action "store_true"|"store_false"|"store_const"|"help"|nil An action performed when this argument is encountered. Explicit values provided by the user take priority over this. Ignored if argument is positional.
---@param default any This argument's default value if nothing gets assigned. Ignored if argument is positional. Not type checked.
---@param const any This argument is assigned if the "store_const" action is used.
function Parser:add_argument(name1, name2, help, nargs, is_number, action, default, const)
    local new_entry = {
        name1 = name1,
        name2 = name2,
        help = help,
        nargs = nargs,
        is_number = is_number,
        action = action,
        default = default,
        const = const,
    }

    local function add_name_to_argument_table(name)
        -- filter any invalid characters
        if name:find("[^%w_%-]") then
            error(string.format("`%s` cannot be used as a positional argument or option name", name))
        end

        if name:find("^%-") then
            -- name starts with a hyphen -> option
            new_entry.dest = name:gsub("^%-*", ""):gsub("%-", "%_")

            if self.argument_table[name] then
                error(string.format("option `%s` already exists", name))
            end
            self.argument_table[name] = new_entry

            return false
        else
            -- name doesn't start with a hyphen -> positional
            new_entry.dest = name:gsub("%-", "%_")

            self.positional_arg_count = self.positional_arg_count + 1
            self.argument_table[self.positional_arg_count] = new_entry

            return true
        end
    end

    local name1_is_positional, name2_is_positional
    name1_is_positional = add_name_to_argument_table(name1)
    if name1_is_positional then
        if name2 then
            error("positional arguments cannot have a name2")
        end
        new_entry.is_positional = true
    else
        if name2 then
            name2_is_positional = add_name_to_argument_table(name2)
            if name2_is_positional then
                error("an option cannot have a name2 that's positional")
            end
        end
        new_entry.is_positional = false
    end

    ---@cast new_entry ArgumentEntry
    table.insert(self.argument_list, new_entry)
end

---Prints the help text
function Parser:print_help_text()
    ---@type ArgumentEntry[]
    local positional_entries = {}
    ---@type ArgumentEntry[]
    local option_entries = {}

    for i = 1, #self.argument_list do
        local entry = self.argument_list[i]
        if entry.is_positional then
            table.insert(positional_entries, entry)
        else
            table.insert(option_entries, entry)
        end
    end

    local option_entries_count = #option_entries
    local positional_entries_count = #positional_entries

    do
        io.write("usage: ", self.prog, " ")

        for i = 1, option_entries_count do
            local entry = option_entries[i]
            io.write("[", entry.name1, " ")
            if entry.nargs == "?" then
                io.write("[", string.upper(entry.dest), "] ")
            else
                for _ = 1, entry.nargs do
                    io.write(string.upper(entry.dest), " ")
                end
            end
            io.write("\b] ")
        end

        for i = 1, positional_entries_count do
            local entry = positional_entries[i]
            io.write("[", string.upper(entry.dest), " ")
        end
        io.write("\b")
        io.write(string.rep("]", positional_entries_count))
    end

    io.write("\n\ndescription:\n  ", self.desc, "\n")

    if positional_entries_count > 0 then
        io.write("\npositional arguments:\n")
        for i = 1, positional_entries_count do
            local entry = positional_entries[i]
            io.write("  ", string.upper(entry.dest), "\n")
            if entry.help and #entry.help > 0 then
                io.write("    ", entry.help, "\n")
            end
        end
    end

    if option_entries_count > 0 then
        io.write("\noptions:\n")
        for i = 1, option_entries_count do
            local entry = option_entries[i]

            io.write("  ", entry.name1, " ")
            if entry.nargs == "?" then
                io.write("[", string.upper(entry.dest), "] ")
            else
                for _ = 1, entry.nargs do
                    io.write(string.upper(entry.dest), " ")
                end
            end

            if entry.name2 then
                io.write("  ", entry.name2, " ")

                if entry.nargs == "?" then
                    io.write("[", string.upper(entry.dest), "] ")
                else
                    for _ = 1, entry.nargs do
                        io.write(string.upper(entry.dest), " ")
                    end
                end
            end

            io.write("\n")
            if entry.help and #entry.help > 0 then
                io.write("    ", entry.help, "\n")
            end
        end
    end
end

---Parse a list of strings
---@param args string[]
---@return table
---@nodiscard
function Parser:parse_args(args)
    local output = {}

    -- set up defaults
    for _, entry in pairs(self.argument_table) do
        output[entry.dest] = entry.default
    end

    local force_positional = false
    local positional_arg_num = 1
    local arg_index = 1

    while args[arg_index] do
        local arg_str = args[arg_index]

        if arg_str == "--" then
            force_positional = true
        else
            if not force_positional and arg_str:find("^%-") then
                -- argument is an option
                local entry = self.argument_table[arg_str]
                if not entry then
                    error(string.format("unrecognized option `%s`", arg_str))
                end

                local dest = entry.dest

                if entry.action then
                    if entry.action == "store_true" then
                        output[dest] = true
                    elseif entry.action == "store_false" then
                        output[dest] = false
                    elseif entry.action == "store_const" then
                        output[dest] = entry.const
                    elseif entry.action == "help" then
                        self:print_help_text()
                        io.flush()
                        os.exit(0, true)
                    else
                        error("invalid argument action")
                    end
                end

                if entry.nargs == "?" then
                    local optional_value = args[arg_index + 1]
                    -- ignore the next argument if there's nothing
                    if optional_value then
                        if entry.is_number then
                            -- Try to convert the next argument into a number. Ignore if it fails.
                            local n = tonumber(optional_value)
                            if n then
                                output[dest] = n
                                arg_index = arg_index + 1
                            end
                        else
                            -- Ignore the next argument if it looks like a flag
                            if not optional_value:find("^%-") then
                                output[dest] = optional_value
                                arg_index = arg_index + 1
                            end
                        end
                    end
                elseif entry.nargs > 0 then
                    if entry.nargs == 1 then
                        local value = args[arg_index + 1]
                        if not value then
                            error(string.format("option `%s %s` requires 1 parameter", arg_str, string.upper(dest)))
                        end
                        if entry.is_number then
                            local n = tonumber(value)
                            if not n then
                                error(string.format("option `%s %s` isn't a number", arg_str, string.upper(dest)))
                            end
                            output[dest] = n
                        else
                            output[dest] = value
                        end
                    else
                        local list = {}
                        for i = 1, entry.nargs do
                            local value = args[arg_index + i]
                            if not value then
                                error(
                                    string.format(
                                        "option `%s %s...` requires %d parameters",
                                        arg_str,
                                        string.upper(dest),
                                        entry.nargs
                                    )
                                )
                            end
                            if entry.is_number then
                                local n = tonumber(value)
                                if not n then
                                    error(
                                        string.format(
                                            "parameter %d of option `%s %s...` isn't a number",
                                            i,
                                            arg_str,
                                            string.upper(dest)
                                        )
                                    )
                                end
                                table.insert(list, n)
                            else
                                table.insert(list, value)
                            end
                        end
                        output[dest] = list
                    end
                    arg_index = arg_index + entry.nargs
                end
            else
                -- argument is positional
                local entry = self.argument_table[positional_arg_num]
                if not entry then
                    error(string.format("too many positional arguments at `%s`", arg_str))
                end
                positional_arg_num = positional_arg_num + 1

                local dest = entry.dest

                if entry.is_number then
                    local n = tonumber(arg_str)
                    if not n then
                        error(string.format("positional argument `%s` isn't a number", string.upper(dest)))
                    end
                    output[dest] = n
                else
                    output[dest] = arg_str
                end
            end
        end
        arg_index = arg_index + 1
    end

    return output
end

local argparse = {}

---Makes a new parser
---@param prog string
---@param desc string
---@return Parser
---@nodiscard
function argparse.new_parser(prog, desc)
    ---@type Parser
    local new_inst = setmetatable({
        prog = prog,
        desc = desc,
        positional_arg_count = 0,
        argument_table = {},
        argument_list = {},
    }, Parser)
    new_inst:add_argument("-h", nil, "show this text", 0, false, "help", nil)
    return new_inst
end

return argparse
