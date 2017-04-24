--- === hs.ipc ===
---
--- Provides the server portion of the Hammerspoon command line interface
--- Note that in order to use the command line tool, you will need to explicitly load `hs.ipc` in your init.lua. The simplest way to do that is `require("hs.ipc")`
---
--- This module is based primarily on code from Mjolnir by [Steven Degutis](https://github.com/sdegutis/).

--- hs.ipc.cli
--- Command
--- This documents the external shell command `cmdpost` provided by the hs.ipc module for external access to and control of your `CommandPost` environment.
---
--- See the `hs.ipc.cli_*` functions for information on how to install this tool so you can access it from your terminal.
---
--- The man page of the command line tool is provided here:
---
---     NAME
---          cmdpost -- Command line interface to CommandPost.app
---
---     SYNOPSIS
---          cmdpost [-i | -s | -c code] [-r] [-n]
---
---     DESCRIPTION
---          Runs code from within CommandPost, and prints the results. The given code is passed to "hs.ipc.
---          handler" which normally executes it as plain Lua code, but may be overridden to do some custom
---          evaluation.
---
---          When no args are given, -i is implied.
---
---          -i       Runs in interactive-mode; uses each line as code . Prints in color unless otherwise speci-
---                   fied.
---          -c       Uses the given argument as code
---          -s       Uses stdin as code
---          -r       Forces CommandPost to interpret code as raw Lua code; the function "hs.ipc.handler" is not
---                   called.
---          -n       When specified, interactive-mode does not use colors.
---
---     EXIT STATUS
---          The hs utility exits 0 on success, and >0 if an error occurs.
---
--- This module is based primarily on code from Mjolnir by [Steven Degutis](https://github.com/sdegutis/).
---

local module = require("hs.ipc.internal")

-- private variables and methods -----------------------------------------

local function rawhandler(str)
    local fn, err = load("return " .. str)
    if not fn then fn, err = load(str) end
    if fn then return fn() else return err end
end

-- Public interface ------------------------------------------------------

--- hs.ipc.handler(str) -> value
--- Function
--- Processes received IPC messages and returns the results
---
--- Parameters:
---  * str - A string containing some a message to process (typically, some Lua code)
---
--- Returns:
---  * A string containing the results of the IPC message
---
--- Notes:
---  * This is not a function you should typically call directly, rather, it is documented because you can override it with your own function if you have particular IPC needs.
---  * The return value of this function is always turned into a string via `lua_tostring()` and returned to the IPC client (typically the `hs` command line tool)
---  * The default handler is:
--- ~~~
---     function hs.ipc.handler(str)
---         local fn, err = load("return " .. str)
---         if not fn then fn, err = load(str) end
---         if fn then return fn() else return err end
---     end
--- ~~~
module.handler = rawhandler


--- hs.ipc.cliGetColors() -> table
--- Function
--- Gets the terminal escape codes used to produce colors in the `hs` command line tool
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing the terminal escape codes used to produce colors. The available keys are:
---   * initial
---   * input
---   * output
module.cliGetColors = function()
    local settings = require("hs.settings")
    local colors = {}
    colors.initial = settings.get("ipc.cli.color_initial") or "\27[35m" ;
    colors.input   = settings.get("ipc.cli.color_input")   or "\27[33m" ;
    colors.output  = settings.get("ipc.cli.color_output")  or "\27[36m" ;
    return colors
end

--- hs.ipc.cliSetColors(table) -> table
--- Function
--- Sets the terminal escape codes used to produce colors in the `hs` command line tool
---
--- Parameters:
---  * table - A table of terminal escape sequences (or empty strings if you wish to suppress the usage of colors) containing the following keys:
---   * initial
---   * input
---   * output
---
--- Returns:
---  * A table containing the terminal escape codes that have been set. The available keys match the table parameter.
---
--- Notes:
---  * For a brief intro into terminal colors, you can visit a web site like this one [http://jafrog.com/2013/11/23/colors-in-terminal.html](http://jafrog.com/2013/11/23/colors-in-terminal.html)
---  * Lua doesn't support octal escapes in it's strings, so use `\x1b` or `\27` to indicate the `escape` character e.g. `ipc.cliSetColors{ initial = "", input = "\27[33m", output = "\27[38;5;11m" }`
---  * The values are stored by the `hs.settings` extension, so will persist across restarts of Hammerspoon
module.cliSetColors = function(colors)
    local settings = require("hs.settings")
    if colors.initial then settings.set("ipc.cli.color_initial", colors.initial) end
    if colors.input   then settings.set("ipc.cli.color_input",   colors.input)   end
    if colors.output  then settings.set("ipc.cli.color_output",  colors.output)  end
    return module.cliGetColors()
end

--- hs.ipc.cliResetColors()
--- Function
--- Restores default terminal escape codes used to produce colors in the `hs` command line tool
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
module.cliResetColors = function()
    local settings = require("hs.settings")
    settings.clear("ipc.cli.color_initial")
    settings.clear("ipc.cli.color_input")
    settings.clear("ipc.cli.color_output")
end

--- hs.ipc.cliStatus([path][,silent]) -> bool
--- Function
--- Gets the status of the `hs` command line tool
---
--- Parameters:
---  * path - An optional string containing a path to look for the `hs` tool. Defaults to `/usr/local`
---  * silent - An optional boolean indicating whether or not to print errors to the Hammerspoon Console
---
--- Returns:
---  * A boolean, true if the `hs` command line tool is correctly installed, otherwise false
module.cliStatus = function(path, silent)
    local path = path or "/usr/local"
    local mod_path = string.match(package.searchpath("hs.ipc",package.path), "^(.*)/init%.lua$")

    local silent = silent or false

    local bin_file = os.execute("[ -f \""..path.."/bin/cmdpost\" ]")
    local man_file = os.execute("[ -f \""..path.."/share/man/man1/cmdpost.1\" ]")
    local bin_link = os.execute("[ -L \""..path.."/bin/cmdpost\" ]")
    local man_link = os.execute("[ -L \""..path.."/share/man/man1/cmdpost.1\" ]")
    local bin_ours = os.execute("[ \""..path.."/bin/cmdpost\" -ef \""..mod_path.."/bin/cmdpost\" ]")
    local man_ours = os.execute("[ \""..path.."/share/man/man1/cmdpost.1\" -ef \""..mod_path.."/share/man/man1/cmdpost.1\" ]")

    local result = bin_file and man_file and bin_link and man_link and bin_ours and man_ours or false
    local broken = false

    if not bin_ours and bin_file then
        if not silent then
            print([[cli installation problem: 'cmdpost' is not ours.]])
        end
        broken = true
    end
    if not man_ours and man_file then
        if not silent then
            print([[cli installation problem: 'cmdpost.1' is not ours.]])
        end
        broken = true
    end
    if bin_file and not bin_link then
        if not silent then
            print([[cli installation problem: 'cmdpost' is an independant file won't be updated when CommandPost is.]])
        end
        broken = true
    end
    if not bin_file and bin_link then
        if not silent then
            print([[cli installation problem: 'cmdpost' is a dangling link.]])
        end
        broken = true
    end
    if man_file and not man_link then
        if not silent then
            print([[cli installation problem: man page for 'cmdpost.1' is an independant file and won't be updated when CommandPost is.]])
        end
        broken = true
    end
    if not man_file and man_link then
        if not silent then
            print([[cli installation problem: man page for 'cmdpost.1' is a dangling link.]])
        end
        broken = true
    end
    if ((bin_file and bin_link) and not (man_file and man_link)) or ((man_file and man_link) and not (bin_file and bin_link)) then
        if not silent then
            print([[cli installation problem: incomplete installation of 'cmdpost' and 'cmdpost.1'.]])
        end
        broken = true
    end

    return broken and "broken" or result
end

--- hs.ipc.cliInstall([path][,silent]) -> bool
--- Function
--- Installs the `hs` command line tool
---
--- Parameters:
---  * path - An optional string containing a path to install the tool in. Defaults to `/usr/local`
---  * silent - An optional boolean indicating whether or not to print errors to the Hammerspoon Console
---
--- Returns:
---  * A boolean, true if the tool was successfully installed, otherwise false
---
--- Notes:
---  * If this function fails, it is likely that you have some old/broken symlinks. You can use `hs.ipc.cliUninstall()` to forcibly tidy them up
module.cliInstall = function(path, silent)
    local path = path or "/usr/local"
    local silent = silent or false
    if module.cliStatus(path, true) == false then
        local mod_path = string.match(package.searchpath("hs.ipc",package.path), "^(.*)/init%.lua$")
        os.execute("ln -s \""..mod_path.."/bin/cmdpost\" \""..path.."/bin/\"")
        os.execute("ln -s \""..mod_path.."/share/man/man1/cmdpost.1\" \""..path.."/share/man/man1/\"")
    end
    return module.cliStatus(path, silent)
end

--- hs.ipc.cliUninstall([path][,silent]) -> bool
--- Function
--- Uninstalls the `hs` command line tool
---
--- Parameters:
---  * path - An optional string containing a path to remove the tool from. Defaults to `/usr/local`
---  * silent - An optional boolean indicating whether or not to print errors to the Hammerspoon Console
---
--- Returns:
---  * A boolean, true if the tool was successfully removed, otherwise false
---
--- Notes:
---  * This function used to be very conservative and refuse to remove symlinks it wasn't sure about, but now it will unconditionally remove whatever it finds at `path/bin/hs` and `path/share/man/man1/hs.1`. This is more likely to be useful in situations where this command is actually needed (please open an Issue on GitHub if you disagree!)
module.cliUninstall = function(path, silent)
    local path = path or "/usr/local"
    local silent = silent or false
    os.execute("rm \""..path.."/bin/cmdpost\"")
    os.execute("rm \""..path.."/share/man/man1/cmdpost.1\"")
    return not module.cliStatus(path, silent)
end

-- Set-up metatable ------------------------------------------------------

module.__handler = function(raw, str)
    local originalprint = print
    local fakestdout = ""
    print = function(...)
        originalprint(...)
        local things = table.pack(...)
        for i = 1, things.n do
            if i > 1 then fakestdout = fakestdout .. "\t" end
            fakestdout = fakestdout .. tostring(things[i])
        end
        fakestdout = fakestdout .. "\n"
    end

    local fn = raw and rawhandler or module.handler
    local results = table.pack(pcall(function() return fn(str) end))

    local str = ""
    for i = 2, results.n do
        if i > 2 then str = str .. "\t" end
        str = str .. tostring(results[i])
    end

    print = originalprint
    return fakestdout .. str
end

-- Return Module Object --------------------------------------------------

return module

