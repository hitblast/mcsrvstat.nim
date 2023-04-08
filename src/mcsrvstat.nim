# Imports.
import std/[
    asyncdispatch,
    os,
    options,
    strformat,
    strutils
]
import mcsrvstatpkg/base


# Procedure for defining the server's platform.
proc askForServerPlatform(): Platform =
    echo "\nEnter server edition (Java J / Bedrock B):"

    case (toLower(readLine(stdin)))
    of "java", "j":
        return Platform.JAVA
    of "bedrock", "b":
        return Platform.BEDROCK
    else:
        echo "\nInvalid platform passed. Retry with Java (J) or Bedrock (B)."
        quit(1)


# Primary run() procedure for the hybrid package.
proc run*(): Future[void] {.async.} =
    echo "\nEnter server IP:"
    let
        address = readLine(stdin)
        platform = askForServerPlatform()
        server = Server(
            address: address,
            platform: platform
        )

    await server.refreshData()
    discard execShellCmd("clear")

    echo "\n--- GENERAL ---\n"
    echo fmt"Online: {server.online}"
    echo fmt"IP: {server.ip}"
    echo fmt"Port: {server.port}"

    echo "\n--- DATA ---\n"
    echo fmt"Version: {server.version}"

    if server.protocol.isSome:
        echo fmt"Protocol: {server.protocol.get()}"

    for (name, value) in [
        ("Hostname", server.hostname), 
        ("Software", server.software), 
        ("Map", server.map), 
        ("Gamemode", server.gamemode), 
        ("ID", server.serverid)
    ]:
        if value.isSome:
            echo fmt"{name}: {value.get()}"

    echo "\n--- DEBUG VALUES ---\n"
    echo fmt"ping: {server.debug.ping}"
    echo fmt"query: {server.debug.query}"
    echo fmt"srv: {server.debug.srv}"
    echo fmt"querymismatch: {server.debug.querymismatch}"
    echo fmt"ipinsrv: {server.debug.ipinsrv}"
    echo fmt"cnameinsrv: {server.debug.cnameinsrv}"
    echo fmt"animatedmotd: {server.debug.animatedmotd}"
    echo fmt"cachetime: {server.debug.cachetime}"
    echo fmt"cacheexpire: {server.debug.cacheexpire}"
    echo fmt"apiversion: {server.debug.apiversion}"


# Run the program.
when isMainModule:
    waitFor run()
