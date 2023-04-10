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
