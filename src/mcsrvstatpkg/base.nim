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
    httpclient,
    json,
    options,
    sequtils,
    strformat
]


# Type declarations.
type
    Platform* {.pure.} = enum
        ## Represents the platform (or edition) of a Minecraft server.
        JAVA
        BEDROCK

    Server* = ref object
        ## Represents an object reference of a Minecraft server. You will primarily use this object to interact with the API.
        address*: string
        platform*: Platform
        data*: Option[JsonNode]

    ServerDebugValues* = object
        ## Represents the debug values related to a Minecraft server.
        ping*, query*, srv*, querymismatch*, ipinsrv*, cnameinsrv*, animatedmotd*: bool
        cachetime*, cacheexpire*, apiversion*: int

    ServerMOTD* = object
        ## Represents the MOTD (Message of The Day) of the server (if any).
        raw*, clean*, html*: seq[string]

    ServerPlugins* = object
        ## Represents the plugins installed on the server (if detected).
        names*, raw*: seq[string]

    ServerMods* = object
        ## Represents the mods installed on the server (if detected).
        names*, raw*: seq[string]

    ServerInfo* = object
        ## Represents certain information related to the Minecraft server. Only included if the server uses player samples for information.
        raw*, clean*, html*: seq[string]

    PlayerCount* = object
        ## Represents the total amount of online players (and the maximum player capacity) of a Minecraft server.
        online*, max*: int


# Custom exception objects for handling data-related errors.
type
    NotInitializedError* = object of KeyError  ## Raised when the data required is missing from an instance of the `Server` object. This typically happens when `Server.refreshData()` has not been executed anywhere before interacting with the package.
    DataError* = object of KeyError  ## An internal exception primarily related to the library itself. Raised when the given key for accessing a particular data is not found.
    ConnectionError* = object of HttpRequestError  ## Raised when an attempt to connect with the API has failed. This mainly happens when the user passes an incorrect IP address.


#[
    These are the primary and helper procedures for processing the data
    we get from performing a GET request to the API in general. Most of
    these (should) originate from the Server object.

    Note that exporting any of these procs without proper notice might
    cause a fair share of issues with the user experience.

    Thanks for keeping the code clean! :)
]#


# Procedure for retrieving data.
proc refreshData*(self: Server): Future[void] {.async.} =
    let client = newAsyncHttpClient()
    let platform = if self.platform == Platform.JAVA: "2/" else: "bedrock/2/"

    let data = parseJson(await client.getContent(
            fmt"https://api.mcsrvstat.us/{platform}{self.address}"))

    if (
        data["debug"].hasKey("error") and
        data["debug"]["error"].hasKey("ping") and
        data["debug"]["error"]["ping"].getStr() == "No address to query"
    ):
        raise ConnectionError.newException("Make sure you have passed the correct IP address for the server.")

    else:
        self.data = some(data)

# Procedure for retrieving the desired data using a key.
proc retrieveData(self: Server, key: string): JsonNode =
    if not self.data.isSome:
        raise NotInitializedError.newException("You did not initialize the Server object using the refreshData() procedure first.")
    else:
        try:
            return self.data.get()[key]
        except KeyError:
            raise DataError.newException("Server is offline / the given server platform is invalid.")

# Helper-procedure for other procs based on retrieveData() with optional string returns.
proc retrieveOptionalStr(self: Server, key: string): Option[string] =
    try:
        return some(self.retrieveData(key).getStr())
    except DataError:
        return none(string)

# Helper-procedure for help mapping plugins, mods and other procs.
proc returnMappedStr(self: Server, key1, key2: string): seq[string] =
    let
        data = self.retrieveData(key1)
        mapped = map(toSeq(data[key2]), proc(x: JsonNode): string = x.getStr())

    return mapped


#[
    This is where the primary, public procedures are written for the end-developer to access.
    Stuff before this part is mostly the foundation for processing the data.

    If you need to write a helper function for a new feature / modification,
    consider writing it above this multiline comment.

    Once again, thanks for keeping the code clean! :D
]#


# Procedure for getting server status.
proc online*(self: Server): bool =
    return self.retrieveData("online").getBool()

# Procedure for getting the IP address of a server.
proc ip*(self: Server): string =
    return self.retrieveData("ip").getStr()

# Procedure for getting the port of a server.
proc port*(self: Server): int =
    return self.retrieveData("port").getInt()

# Procedure for getting the debug values of a server.
proc debug*(self: Server): ServerDebugValues =
    let data = self.retrieveData("debug")

    return ServerDebugValues(
        ping: data["ping"].getBool(),
        query: data["query"].getBool(),
        srv: data["srv"].getBool(),
        querymismatch: data["querymismatch"].getBool(),
        ipinsrv: data["ipinsrv"].getBool(),
        cnameinsrv: data["cnameinsrv"].getBool(),
        animatedmotd: data["animatedmotd"].getBool(),
        cachetime: data["cachetime"].getInt(),
        cacheexpire: data["cacheexpire"].getInt(),
        apiversion: data["apiversion"].getInt()
    )

# Procedure for getting the version of a server.
proc version*(self: Server): string =
    return self.retrieveData("version").getStr()

# Procedure for getting the protocol of a server.
proc protocol*(self: Server): Option[int] =
    try:
        let protocol = self.retrieveData("protocol")
        return some(protocol.getInt())
    except DataError:
        return none(int)

# Procedure for getting the hostname of a server.
proc hostname*(self: Server): Option[string] =
    return self.retrieveOptionalStr("hostname")

# Procedure for getting the software of a server.
proc software*(self: Server): Option[string] =
    return self.retrieveOptionalStr("software")

# Procedure for getting the map of a server.
proc map*(self: Server): Option[string] =
    return self.retrieveOptionalStr("map")

# Procedure for getting the gamemode of a server.
proc gamemode*(self: Server): Option[string] =
    return self.retrieveOptionalStr("gamemode")

# Procedure for getting the ID of a server.
proc serverid*(self: Server): Option[string] =
    return self.retrieveOptionalStr("serverid")

# Procedure for getting the MOTD of a server.
proc motd*(self: Server): Option[ServerMOTD] =
    try:
        let
            raw = self.returnMappedStr("motd", "raw")
            clean = self.returnMappedStr("motd", "clean")
            html = self.returnMappedStr("motd", "html")

        return some(
            ServerMOTD(
                raw: raw,
                clean: clean,
                html: html
            )
        )

    except DataError:
        return none(ServerMOTD)

# Procedure for getting the plugins of a server.
proc plugins*(self: Server): Option[ServerPlugins] =
    try:
        let
            names = self.returnMappedStr("plugins", "names")
            raw = self.returnMappedStr("plugins", "raw")

        return some(
            ServerPlugins(
                names: names,
                raw: raw
            )
        )

    except DataError:
        return none(ServerPlugins)

# Procedure for getting the mods of a server.
proc mods*(self: Server): Option[ServerMods] =
    try:
        let
            names = self.returnMappedStr("mods", "names")
            raw = self.returnMappedStr("mods", "raw")

        return some(
            ServerMods(
                names: names,
                raw: raw
            )
        )

    except DataError:
        return none(ServerMods)

# Procedure for getting the info attribute of a server.
proc info*(self: Server): Option[ServerInfo] =
    try:
        let
            raw = self.returnMappedStr("info", "raw")
            clean = self.returnMappedStr("info", "clean")
            html = self.returnMappedStr("info", "html")

        return some(
            ServerInfo(
                raw: raw,
                clean: clean,
                html: html
            )
        )

    except DataError:
        return none(ServerInfo)

proc playerCount*(self: Server): Option[PlayerCount] =
    try:
        let
            count = self.retrieveData("players")
            online = count["online"].getInt()
            max = count["max"].getInt()

        return some(
            PlayerCount(
                online: online,
                max: max
            )
        )

    except DataError:
        return none(PlayerCount)