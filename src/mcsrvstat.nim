# Imports.
import std/[
    asyncdispatch,
    os,
    options,
    strformat,
    strutils
]
import simple_parseopt

import mcsrvstatpkg/base


# Primary run() procedure for the hybrid package.
proc run*(): Future[void] {.async.} =
    let 
        options = get_options:
            address: string
            bedrock: bool = False

        server = Server(
            address: options.address,
            platform: if options.bedrock: Platform.BEDROCK else: Platform.JAVA
        )

    try:
        await server.refreshData()
    except ConnectionError:
        echo("Make sure you've passed the correct IP for the server.")
        quit(1)

    # The primary UI section.
    echo "--- BASIC ---\n"
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
