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
    discard execShellCmd(if hostOS == "windows": "cls" else: "clear")

    # The primary UI section.
    echo "\n--- BASIC CREDENTIALS ---\n"
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

    for (name, value) in [
        ("Ping", server.debug.ping),
        ("Query", server.debug.query),
        ("Srv", server.debug.srv),
        ("Query Mismatch", server.debug.querymismatch),
        ("IP in srv", server.debug.ipinsrv),
        ("CNAME in srv", server.debug.cnameinsrv),
        ("Animated MOTD", server.debug.animatedmotd),
    ]:
        echo fmt"{name}: {value}"

    for (name, value) in [
        ("Cache Time", server.debug.cachetime),
        ("Cache Expire", server.debug.cacheexpire),
        ("API Version", server.debug.apiversion)
    ]:
        echo fmt"{name}: {value}"


# Run the program.
when isMainModule:
    waitFor run()
