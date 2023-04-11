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

import illwill
import therapist

import mcsrvstatpkg/base


# Primary run() procedure for the hybrid package.
proc run*(): Future[void] {.async.} =

    # Terminal options for accessing the app from the command-line.
    let spec = (
        address: newStringArg(@["<address>"], help="The IP address of the server"),
        bedrock: newBoolArg(@["-b", "--bedrock"], defaultVal=false, help="Flags the server as a Minecraft Bedrock server"),
        help: newHelpArg(@["-h", "--help"], help="Show help message")
    )
    spec.parseOrQuit(prolog="mcsrvstat.nim", command="search")

    let server = Server(
        address: spec.address.value,
        platform: if spec.bedrock.value: Platform.BEDROCK else: Platform.JAVA
    )

    try:
        await server.refreshData()
    except ConnectionError:
        echo("Make sure you've passed the correct IP for the server.")
        quit(1)

    # And if it succeeds, initialize an instance of illwave and run the app.
    # This includes a cursor-less window, so an exit procedure is also required.
    proc exitProc() {.noconv.} =
        illwillDeinit()
        showCursor()
        quit(0)

    illwillInit(fullscreen=true)
    var
        tb = newTerminalBuffer(terminalWidth(), terminalHeight())
        yCoord = 11

    tb.setForegroundColor(fgWhite, true)
    tb.write(2, 1, "[ Press ", fgYellow, "esc", fgWhite, "/", fgYellow, "q", fgWhite, " to quit. ]")
    tb.drawRect(0, 0, 40, 7)
    tb.drawHorizLine(2, 38, 2, doubleStyle=true)

    # Basic
    tb.write(2, 4, "Online: ", (if server.online: fgGreen else: fgRed), $server.online, fgWhite)
    tb.write(2, 5, "IP: ", server.ip)
    tb.write(2, 6, "Port: ", $server.port)

    # Data
    tb.write(2, 9, fmt"Version: {server.version}")
    if server.protocol.isSome:
        tb.write(2, 10, fmt"Protocol: {server.protocol.get()}")

    for (name, value) in [
        ("Hostname", server.hostname), 
        ("Software", server.software), 
        ("Map", server.map), 
        ("Gamemode", server.gamemode), 
        ("ID", server.serverid)
    ]:
        if value.isSome:
            tb.write(2, yCoord, fmt"{name}: {value.get()}")
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
        tb.write(2, yCoord, fmt"{name}: ", (if value: fgGreen else: fgRed), $value, fgWhite)

    tb.drawHorizLine(2, 38, yCoord + 1)
    yCoord += 2

    for (name, value) in [
        ("Cache Time", server.debug.cachetime),
        ("Cache Expire", server.debug.cacheexpire),
        ("API Version", server.debug.apiversion)
    ]:
        yCoord += 1
        tb.write(2, yCoord, fmt"{name}: ", fgCyan, $value, fgWhite)

    while true:
        tb.display()

        var key = getKey()
        case key
        of Key.Escape, Key.Q: exitProc()
        else:
            discard


# Run the program.
when isMainModule:
    waitFor run()
