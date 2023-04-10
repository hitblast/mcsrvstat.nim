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
        JAVA = "2/"
        BEDROCK = "bedrock/2/"

    Server* = ref object
        address*: string
        platform*: Platform
        data*: Option[JsonNode]

    ServerDebugValues* = object
        ping*, query*, srv*, querymismatch*, ipinsrv*, cnameinsrv*, animatedmotd*: bool
        cachetime*, cacheexpire*, apiversion*: int

    ServerMOTD* = object
        raw*, clean*, html*: seq[string]


# Custom exception objects for handling data-related errors.
type
    NotInitializedError* = object of KeyError
    DataError* = object of KeyError
    ConnectionError* = object of HttpRequestError


#[
    These are the primary and helper procedures for processing the data
    we get from performing a GET request to the API in general.

    Note that exporting any of these procs without proper notice might
    cause a fair share of issues with the user experience.

    Thanks for keeping the code clean! :)
]#


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
    let
        data = self.retrieveData("debug")
        debug = ServerDebugValues(
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

            motd = ServerMOTD(
                raw: raw,
                clean: clean,
                html: html
            )

        return some(motd)

    except DataError:
        return none(ServerMOTD)