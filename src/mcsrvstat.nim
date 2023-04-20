#[
    MIT License

    Copyright (c) 2023 HitBlast

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]#


# Imports.
import std/[
    asyncdispatch,
    os,
    options,
    strformat,
    strutils
]
import illwill, argparse

import mcsrvstatpkg/base


# Primary run() procedure for the hybrid package.
proc run*(): Future[void] {.async.} =

    # The primary command-line parser.
    var
        parser = newParser:
            help("A hybrid and asynchronous Nim wrapper for the Minecraft Server Status API.")
            flag("-b", "--bedrock", help="Flags the server as a Minecraft: Bedrock Edition server.")
            arg("address", help="The address of the Minecraft server.")
        server = Server()

    try:
        let opts = parser.parse()
        server = Server(
            address: opts.address,
            platform: if opts.bedrock: Platform.BEDROCK else: Platform.JAVA
        )
        await server.refreshData()

    except ShortCircuit as err:
        if err.flag == "argparse_help":
            echo err.help
            quit(1)

    except UsageError:
        stderr.writeLine getCurrentExceptionMsg()
        quit(1)

    except ConnectionError:
        echo "Make sure you've passed the correct IP for the server."
        quit(1)

    # Initialize an instance of illwave and run the TUI if the code above succeeds.
    # This includes a cursor-less window, so an exit procedure is also required.
    illwillInit(fullscreen=true)

    var
        tb = newTerminalBuffer(terminalWidth(), terminalHeight())
        yCoord = 14

    # The top panel for the terminal.
    tb.setForegroundColor(fgWhite, true)
    tb.write(2, 1, "[ Press ", fgYellow, "esc", fgWhite, "/", fgYellow, "q", fgWhite, " to quit. ]")
    tb.drawRect(0, 0, 40, 7)
    tb.drawHorizLine(2, 38, 2, doubleStyle=true)

    # Basic
    tb.write(2, 4, "Online: ", (if server.online: fgGreen else: fgRed), $server.online, fgWhite)
    tb.write(2, 5, "IP: ", server.ip)
    tb.write(2, 6, "Port: ", $server.port)

    # Data (section 1)
    tb.write(2, 9, fmt"Version: {server.version}")
    if server.protocol.isSome:
        tb.write(2, 10, fmt"Protocol: {server.protocol.get()}")

    tb.drawVertLine(40, 20, 2)
    if server.playerCount.isSome:
        tb.write(2, 12, fmt"Players online: {server.playerCount.get().online} / {server.playerCount.get().max}")

    for (name, value) in [
        ("Cache Time", server.debug.cachetime),
        ("Cache Expire", server.debug.cacheexpire),
        ("API Version", server.debug.apiversion)
    ]:
        tb.write(2, yCoord, fmt"{name}: ", fgCyan, $value, fgWhite)
        yCoord += 1

    # Data (section 2)
    yCoord = 1

    for (name, value) in [
        ("Hostname", server.hostname), 
        ("Software", server.software), 
        ("Map", server.map), 
        ("Gamemode", server.gamemode), 
        ("ID", server.serverid)
    ]:
        if value.isSome:
            tb.write(45, yCoord, fmt"{name}: {value.get()}")
            yCoord += 1

    for (name, value) in [
        ("Ping", server.debug.ping),
        ("Query", server.debug.query),
        ("Srv", server.debug.srv),
        ("Query Mismatch", server.debug.querymismatch),
        ("IP in srv", server.debug.ipinsrv),
        ("CNAME in srv", server.debug.cnameinsrv),
        ("Animated MOTD", server.debug.animatedmotd),
    ]:
        yCoord += 1
        tb.write(45, yCoord, fmt"{name}: ", (if value: fgGreen else: fgRed), $value, fgWhite)

    # Finally, display the entire thing.
    # This also includes checking for keypress events in order for the user to quit the interface.
    proc exitProc() {.noconv.} =
        illwillDeinit()
        showCursor()
        quit(0)

    while true:
        tb.display()

        var key = getKey()
        case key
        of Key.Escape, Key.Q: exitProc()
        else:
            discard

        await sleepAsync(30)


# Run the program.
# Also handle some of the root exceptions as needed.
when isMainModule:
    try:
        waitFor run()

    except DataError:
        echo "Make sure you've passed the proper platform for the server."
        quit(1)

    except IOError:
        echo "Can't run mcsrvstat.nim since proper support for SSL couldn't be found."
        quit(1)