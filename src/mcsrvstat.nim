# SPDX-License-Identifier: MIT


# Imports.
import std/[
    asyncdispatch,
    os,
    options,
    strformat,
    strutils,
    times
]
import illwill, argparse
import mcsrvstatpkg/base


# Procedure for updating the terminal buffer with new content.
proc updateScreen(tb: var TerminalBuffer, server: Server): void =
    tb.clear()

    # Start decorating.
    var yCoord = 14

    # The top panel for the terminal.
    tb.setForegroundColor(fgWhite, true)
    tb.write(2, 1, "Press ", fgYellow, "esc", fgWhite, "/", fgYellow, "Q", fgWhite, " to quit. ")
    
    if not server.autorefresh:
        tb.write(23, 1, fgYellow, "R", fgWhite, " to refresh.")

    tb.drawRect(0, 0, 40, 8)
    tb.drawHorizLine(2, 38, 2, doubleStyle=true)

    # Display the status, IP address and port of the server.
    tb.write(2, 4, "Online: ", (if server.isOnline: fgGreen else: fgRed), $server.isOnline, fgWhite)
    tb.write(2, 5, "IP: ", server.ip)
    tb.write(2, 6, "Port: ", $server.port)
    tb.write(2, 7, "API Version: ", $server.debug.apiversion, fgWhite)

    # Display basic information like versions and protocols.
    tb.write(2, 10, fmt"Version: {server.version}")
    if server.protocol.isSome:
        let protocol = server.protocol.get()
        tb.write(2, 11, fmt"Protocol: {protocol.name} ({protocol.version})")

    # Display the current player count of the server.
    tb.drawVertLine(40, 19, 2)
    if server.playerCount.isSome:
        tb.write(2, 13, fmt"Players online: {server.playerCount.get().online} / {server.playerCount.get().max}")

    # Display API-related information.
    for (name, value) in [
        ("Cache Time", server.debug.cachetime),
        ("Cache Expire", server.debug.cacheexpire)
    ]:
        tb.write(2, yCoord, fmt"{name}: ", fgCyan, $value, fgWhite)
        yCoord += 1

    # Display additional information like hostname, software and gamemodes.
    yCoord = 1

    for (name, value) in [
        ("Hostname", server.hostname), 
        ("Software", server.software), 
        ("[ B ] Gamemode", server.gamemode), 
        ("[ B ] ID", server.serverid)
    ]:
        if value.isSome:
            tb.write(45, yCoord, fmt"{name}: {value.get()}")
            yCoord += 1

    if (
        server.isEulaBlocked.isSome
    ):
        let eulaStat = server.isEulaBlocked.get()
        tb.write(45, yCoord, "[ J ] Server has ", (if eulaStat: "blocked" else: "unblocked"), " EULA.")
        yCoord += 1

    # Display the debug values associated with the server.
    for (name, value) in [
        ("ping", server.debug.ping),
        ("query", server.debug.query),
        ("srv", server.debug.srv),
        ("querymismatch", server.debug.querymismatch),
        ("ipinsrv", server.debug.ipinsrv),
        ("cnameinsrv", server.debug.cnameinsrv),
        ("animatedmotd", server.debug.animatedmotd),
        ("cachehit", server.debug.cachehit)
    ]:
        yCoord += 1
        tb.write(45, yCoord, fmt"{name}: ", (if value: fgGreen else: fgRed), $value, fgWhite)


    # Display the server's MOTD.
    tb.write(45, (yCoord + 2), server.motd.get().clean.join(" ").strip()[0..45], "...")


# Primary procedure for parsing command-line arguments, fetching server data 
# and displaying it in terminal.
proc main*(): Future[void] {.async.} =

    # The primary command-line parser.
    var
        parser = newParser:
            help("A hybrid and asynchronous Nim wrapper for the Minecraft Server Status API.")
            flag("-a", "--autorefresh", help="Automatically refreshes the server data when the cache expires.")
            flag("-b", "--bedrock", help="Flags the server as a Minecraft: Bedrock Edition server.")
            arg("address", help="The address of the Minecraft server.")
        server: Server

    try:
        let opts = parser.parse()
        server = Server(
            address: opts.address,
            platform: if opts.bedrock: Platform.BEDROCK else: Platform.JAVA,
            autorefresh: opts.autorefresh
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

    # Initialize a new illwill instance with fullscreen set to true.
    # Also set the procedure for exiting the terminal window.
    proc exitProc() {.noconv.} =
        illwillDeinit()
        showCursor()
        quit(0)

    illwillInit(fullscreen=true)
    setControlCHook(exitProc)
    hideCursor()

    # Finally, update screen using the defined procedure and display the thing.
    # This also includes checking for keypress events in order for the user to quit the interface.
    var tb = newTerminalBuffer(terminalWidth(), terminalHeight())
    tb.updateScreen(server)

    while true:
        var key = getKey()

        case key
        of Key.Escape, Key.Q: exitProc()
        of Key.R: 
            await server.refreshData()
            tb.updateScreen(server)
        else: discard

        if server.autorefresh and now() >= parse(server.debug.cacheexpire, "yyyy-MM-dd HH:mm:ss"):
            await server.refreshData()
            tb.updateScreen(server)
            await sleepAsync(5)

        tb.display()
        await sleepAsync(20)


# Run the program.
# Also handle some of the root exceptions as needed.
when isMainModule:
    try:
        waitFor main()

    except DataError:
        echo "Make sure you've passed the proper platform and/or IP for the server."
        quit(1)
