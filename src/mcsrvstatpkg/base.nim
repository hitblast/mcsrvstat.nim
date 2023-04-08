# Imports.
import std/[
    asyncdispatch,
    httpclient,
    json,
    options,
    strformat
]


# Type declarations.
type
    Platform* {.pure.} = enum
        JAVA = "2/"
        BEDROCK = "bedrock/2/"

    Server* = ref object
        address*: string
        platform*: Platform
        data*: Option[JsonNode]

    ServerDebugValues* = object
        ping*: bool
        query*: bool
        srv*: bool
        querymismatch*: bool
        ipinsrv*: bool
        cnameinsrv*: bool
        animatedmotd*: bool
        cachetime*: int
        cacheexpire*: int
        apiversion*: int


# Custom exception objects for handling data-related errors.
type
    NotInitializedError* = object of KeyError
    DataError* = object of KeyError
    ConnectionError* = object of HttpRequestError


# Procedure for retrieving data.
proc refreshData*(self: Server): Future[void] {.async.} =
    let client = newAsyncHttpClient()
    let data = parseJson(await client.getContent(
            fmt"https://api.mcsrvstat.us/{self.platform}{self.address}"))

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
        raise NotInitializedError.newException("You did not initialize the Server object using refreshData() first.")
    else:
        try:
            return self.data.get()[key]
        except KeyError:
            raise DataError.newException("Server is offline / the given server platform is invalid.")


# Procedure for getting server status.
proc online*(self: Server): bool =
    let online = self.retrieveData("online")
    return online.getBool()

# Procedure for getting the IP address of a server.
proc ip*(self: Server): string =
    let ip = self.retrieveData("ip")
    return ip.getStr()

# Procedure for getting the port of a server.
proc port*(self: Server): int =
    let port = self.retrieveData("port")
    return port.getInt()

# Procedure for getting the debug values of a server.
proc debug*(self: Server): ServerDebugValues =
    let data = self.retrieveData("debug")
    let debug = ServerDebugValues(
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
    return debug

# Procedure for getting the version of a server.
proc version*(self: Server): string =
    let version = self.retrieveData("version")
    return version.getStr()

# Procedure for getting the protocol of a server.
proc protocol*(self: Server): Option[int] =
    try:
        let protocol = self.retrieveData("protocol")
        return some(protocol.getInt())
    except DataError:
        return none(int)

# Procedure for getting the hostname of a server.
proc hostname*(self: Server): Option[string] =
    try:
        let hostname = self.retrieveData("hostname")
        return some(hostname.getStr())
    except DataError:
        return none(string)

# Procedure for getting the software of a server.
proc software*(self: Server): Option[string] =
    try:
        let software = self.retrieveData("software")
        return some(software.getStr())
    except DataError:
        return none(string)

# Procedure for getting the map of a server.
proc map*(self: Server): Option[string] =
    try:
        let map = self.retrieveData("map")
        return some(map.getStr())
    except DataError:
        return none(string)

# Procedure for getting the gamemode of a server.
proc gamemode*(self: Server): Option[string] =
    try:
        let gamemode = self.retrieveData("gamemode")
        return some(gamemode.getStr())
    except DataError:
        return none(string)

# Procedure for getting the ID of a server.
proc serverid*(self: Server): Option[string] =
    try:
        let serverid = self.retrieveData("serverid")
        return some(serverid.getStr())
    except DataError:
        return none(string)
