---Module that creates a parser for command line arguments
---Somewhat inspired by python's argparse module

---@class Parser
---@field private arguments table
---@field private positional_arg_count integer
local Parser = {}
Parser.__index = Parser

---Adds an argument to the parser
---@param name1 string Argument name. If name starts with "-", it's a flag, else it's positional.
---@param name2 string? Optional secondary argument name. Takes priority when determining the argument destination.
---@param nargs integer|"?" Number of arguments. Ignored if argument is positional. Can be 0. "?" means 1 or 0 arguments.
---@param is_number boolean Parser should convert the argument value into a number. If unable, parser will throw an error.
---@param action? "store_true"|"store_false"|"store_const"|"help" An action performed when this argument is encountered. Values provided by nargs have priority. Ignored if argument is positional.
---@param default any This argument's default value if nothing gets assigned. Ignored if argument is positional. Not type checked.
---@param const any This argument is assigned if the "store_const" action is used.
function Parser:add_argument(name1, name2, nargs, is_number, action, default, const)
    local new_entry = {
        nargs = nargs,
        is_number = is_number,
        action = action,
        default = default,
        const = const,
    }

    local function add(name)
        -- filter any invalid characters
        if name:find("[^%w_%-]") then
            error(string.format("`%s` cannot be used as an argument name or flag", name))
        end

        if name:find("^%-") then
            -- name starts with a hyphen -> flag
            new_entry.dest = name:gsub("^%-*", ""):gsub("%-", "%_")

            if self.arguments[name] then
                error(string.format("argument flag `%s` already exists", name))
            end
            self.arguments[name] = new_entry
        else
            -- name doesn't start with a hyphen -> positional
            new_entry.dest = name:gsub("%-", "%_")

            self.positional_arg_count = self.positional_arg_count + 1
            self.arguments[self.positional_arg_count] = new_entry
        end
    end

    add(name1)
    if name2 then
        add(name2)
    end
end

---Prints the help text
function Parser:print_help_text()
    -- TODO not very helpful right now
    for k, v in pairs(self.arguments) do
        io.write(k)
        io.write(" = { ")
        for k2, v2 in pairs(v) do
            io.write(string.format("%s = %s, ", k2, v2))
        end
        io.write("}\n")
    end
end

---Parse a list of strings
---@param args string[]
---@return table
---@nodiscard
function Parser:parse_args(args)
    local output = {}

    -- set up defaults
    for _, entry in pairs(self.arguments) do
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
                -- argument is a flag
                local entry = self.arguments[arg_str]
                if not entry then
                    error(string.format("unrecognized flag argument `%s`", arg_str))
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
                        love.event.quit(0)
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
                            error(string.format("argument `%s %s` requires 1 parameter", arg_str, string.upper(dest)))
                        end
                        if entry.is_number then
                            local n = tonumber(value)
                            if not n then
                                error(string.format("argument `%s %s` isn't a number", arg_str, string.upper(dest)))
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
                                        "`%s %s...` requires %d parameters",
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
                                            "parameter %d of argument `%s %s...` isn't a number",
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
                local entry = self.arguments[positional_arg_num]
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
---@return Parser
---@nodiscard
function argparse.new_parser()
    ---@type Parser
    local new_inst = setmetatable({
        positional_arg_count = 0,
        arguments = {},
    }, Parser)
    new_inst:add_argument("-h", nil, 0, false, "help", nil)
    return new_inst
end

return argparse
