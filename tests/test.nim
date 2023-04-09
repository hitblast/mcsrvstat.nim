# Imports.
import std/[
    asyncdispatch,
    options,
    unittest
]
import mcsrvstatpkg/base


# Initializing Server instances for test.
let
    goodServer = Server(
        address: "hypixel.net",
        platform: Platform.JAVA
    )
    badServer = Server(
        address: "play.pigselleggbd.com",
        platform: Platform.JAVA
    )

waitFor goodServer.refreshData()
waitFor badServer.refreshData()


# The required unit tests.
test "good server basics":
    check goodServer.hostname.get() == "mc.hypixel.net"

test "bad server basics":
    check badServer.online == false
    check badServer.ip == "127.0.0.1"