# SPDX-License-Identifier: MIT


# Imports.
import std/[
    asyncdispatch,
    httpclient,
    json,
    options,
    sugar,
    sequtils,
    strutils,
    times
]


# Type declarations.
type
    Platform* {.pure.} = enum  ## Represents the platform / edition of a Minecraft server.
        JAVA
        BEDROCK

    Server* = ref object  ## Represents an object reference of a Minecraft server. You will primarily use this object to interact with the API.
        address*: string
        platform*: Platform
        data: Option[JsonNode]
        iconData: string

    ServerDebugValues* = object  ## Represents the debug values related to a Minecraft server.
        ping*, query*, srv*, querymismatch*, ipinsrv*, cnameinsrv*, animatedmotd*, cachehit*: bool
        cachetime*, cacheexpire*: string
        apiversion*: int

    ServerMap* = object  ## Represents the map name of a Minecraft server.
        raw*, clean*, html*: string

    ServerMOTD* = object  ## Represents the MOTD **(Message of The Day)** of a Minecraft server.
        raw*, clean*, html*: seq[string]

    ServerInfo* = object  ## Represents certain information related to a Minecraft server. Only included if the server uses player samples for gathering information.
        raw*, clean*, html*: seq[string]

    PlayerCount* = object  ## Represents the total amount of online players (and the maximum player capacity) of a Minecraft server.
        online*, max*: int

    Player* = object  ## Represents a player of a Minecraft server.
        name*, uuid*: string

    Plugin* = object  ## Represents a plugin of a Minecraft server.
        name*, version*: string

    Mod* = object  ## Represents a mod of a Minecraft server.
        name*, version*: string

    Protocol* = object  ## Represents the protocol of a Minecraft server.
        name*: string
        version*: int

# Custom exception objects for handling data-related errors.
type
    NotInitializedError* = object of KeyError  ## Raised when the data required is missing from an instance of the `Server` object. This typically happens when `Server.refreshData()` has not been executed anywhere before interacting with the package.
    DataError* = object of KeyError  ## An internal exception primarily related to the library itself. Raised when the given key for accessing a particular data is not found.
    ConnectionError* = object of HttpRequestError  ## Raised when an attempt to connect with the API has failed. This mainly happens when the user passes an incorrect IP address.
    QueryError* = object of DataError  ## Raised when a particular part of the data could not be queried properly depending on the server platforms and other factors.
    PlayerNotFoundError* = object of DataError  ## Raised when a player could not be found within the list of online players.


#[
    These are the primary and helper procedures for processing the data
    we get from performing a GET request to the API in general. Most of
    these (should) originate from the Server object.

    Note that exporting any of these procs without proper notice might
    cause a fair share of issues with the user experience.

    Thanks for keeping the code clean! :)
]#


proc refreshData*(self: Server): Future[void] {.async.} =
    ## Connect to the API and load the data related to the given Minecraft server into the `Server` object.

    let client = newAsyncHttpClient()
    let platform = if self.platform == Platform.JAVA: "3/" else: "bedrock/3/"

    let data = parseJson(await client.getContent("https://api.mcsrvstat.us/" & platform & self.address))

    if (
        data["debug"]{"error"}{"ping"}.getStr() == "No address to query"
    ):
        raise ConnectionError.newException("Incorrect server IP address passed")

    else:
        self.data = some(data)
        self.iconData = await client.getContent("https://api.mcsrvstat.us/icon/" & self.address)

        client.close()

proc retrieveData(self: Server, key: string): JsonNode =
    ## Internal procedure for retrieving the data requested through the given key and returning it as a `JsonNode` object.

    if not self.data.isSome:
        raise NotInitializedError.newException("Initialize the data with refreshData() first.")
    else:
        try:
            return self.data.get()[key]
        except KeyError:
            raise DataError.newException("Incorrect server platform / server is offline / invalid key")

proc retrieveOptionalStr(self: Server, key: string): Option[string] =
    ## Internal helper procedure for other procs based on `retrieveData()` with optional string return types.

    try:
        return some(self.retrieveData(key).getStr())
    except DataError:
        return none(string)

proc returnMappedStr(self: Server, key1, key2: string): seq[string] =
    ## Internal helper procedure for returning mapped iterations of the requested data.

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


proc icon*(self: Server): string =
    ## Returns the icon of the server in BASE64 string format.
    return self.iconData

proc isOnline*(self: Server): bool =
    ## Returns a boolean value depending on if the Minecraft server is online or not.
    return self.retrieveData("online").getBool()

proc isEulaBlocked*(self: Server): Option[bool] =
    ## **(Java-only)** Returns a boolean value depending on if the Minecraft server has blocked EULA or not.
    try:
        return some(self.retrieveData("eula_blocked").getBool())
    except DataError:
        return none(bool)

proc ip*(self: Server): string =
    ## Returns the IP address of the server.
    return self.retrieveData("ip").getStr()

proc port*(self: Server): int =
    ## Returns the port of the server.
    return self.retrieveData("port").getInt()

proc debug*(self: Server): ServerDebugValues =
    ## Returns the debug values related to the Minecraft server.
    let data = self.retrieveData("debug")

    return ServerDebugValues(
        ping: data["ping"].getBool(),
        query: data["query"].getBool(),
        srv: data["srv"].getBool(),
        querymismatch: data["querymismatch"].getBool(),
        ipinsrv: data["ipinsrv"].getBool(),
        cnameinsrv: data["cnameinsrv"].getBool(),
        animatedmotd: data["animatedmotd"].getBool(),
        cachehit: data["cachehit"].getBool(),
        cachetime: fromUnix(data["cachetime"].getInt()).format("yyyy-MM-dd HH:mm:ss"),
        cacheexpire: fromUnix(data["cacheexpire"].getInt()).format("yyyy-MM-dd HH:mm:ss"),
        apiversion: data["apiversion"].getInt()
    )

proc version*(self: Server): string =
    ## Returns the version of software used for running the Minecraft server. This can include multiple versions or additional text depending on the server.
    return self.retrieveData("version").getStr()

proc protocol*(self: Server): Option[Protocol] =
    ## **(Optional)** Returns the protocol of the server. Only returned if `ping` is set to `True` within the debug values.
    
    try:
        if not self.debug.ping:
            raise QueryError.newException("Protocol data is not available for this server.")

        let protocol = self.retrieveData("protocol")

        return some(
            Protocol(
                name: protocol{"name"}.getStr(),
                version: protocol{"version"}.getInt()
            )
        )
    except DataError:
        return none(Protocol)
    

proc hostname*(self: Server): Option[string] =
    ## **(If detected)** Returns the hostname of the server.
    return self.retrieveOptionalStr("hostname")

proc software*(self: Server): Option[string] =
    ## **(If detected)** Returns the software used for the server.
    return self.retrieveOptionalStr("software")

proc gamemode*(self: Server): Option[string] =
    ## **(Bedrock-only)** Returns the game mode used inside the server (Survival / Creative / Adventure).
    return self.retrieveOptionalStr("gamemode")

proc serverid*(self: Server): Option[string] =
    ## **(Bedrock-only)** Returns the ID of the server.
    return self.retrieveOptionalStr("serverid")

proc map*(self: Server): Option[ServerMap] =
    ## **(If detected)** Returns a `ServerMap` object representing the map name of the server.
    try:
        let data = self.retrieveData("map")

        return some(
            ServerMap(
                raw: data["raw"].getStr(),
                clean: data["clean"].getStr(),
                html: data["html"].getStr()
            )
        )
    
    except KeyError, DataError:
        return none(ServerMap)

proc plugins*(self: Server): Option[seq[Plugin]] =
    ## **(If detected)** Returns a sequence of `Plugin` objects, representing the plugins currently installed on the server.
    try:
        let 
            data = self.retrieveData("plugins")
            plugins: seq[Plugin] = collect:
                for plugin in data:
                    Plugin(
                        name: plugin["name"].getStr(),
                        version: plugin["version"].getStr()
                    )
        return some(plugins)

    except DataError:
        return none(seq[Plugin])

proc mods*(self: Server): Option[seq[Mod]] =
    ## **(If detected)** Returns a sequence of `Mod` objects, representing the mods currently in use on the server.
    try:
        let
            data = self.retrieveData("mods")
            mods: seq[Mod] = collect:
                for moditem in data:
                    Mod(
                        name: moditem["name"].getStr(),
                        version: moditem["version"].getStr()
                    )
        return some(mods)

    except DataError:
        return none(seq[Mod])

proc motd*(self: Server): Option[ServerMOTD] =
    ## **(If detected)** Returns a `ServerMOTD` object representing the MOTD (Message of the Day) for the server.
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

proc info*(self: Server): Option[ServerInfo] =
    ## **(If detected)** Returns a `ServerInfo` object representing some extra bits of information related to the server.
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
    ## **(If detected)** Returns a `PlayerCount` object representing the total amount of active players (and the maximum player capacity) of the server.
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

proc players*(self: Server): Option[seq[Player]] =
    ## Returns a sequence of `Player` objects representing currently online (and queried) players on the server.
    try:
        let 
            data = self.retrieveData("players")["list"]
            players: seq[Player] = collect:
                for player in data:
                    Player(
                        name: player["name"].getStr(),
                        uuid: player["uuid"].getStr()
                    )

        return some(players)

    except KeyError, DataError:
        return none(seq[Player])

proc getPlayerByName*(self: Server, name: string): seq[Player] =
    ## **(Query-dependant)** Returns a sequence of players currently online on the server matching the name given.
    
    try:
        let players = self.players.get()
        return players.filter(proc(player: Player): bool = player.name == name)

    except UnpackDefect:
        raise QueryError.newException("Player data not found for this server.")

proc getPlayerByUUID*(self: Server, uuid: string): Player =
    ## **(Query-dependant)** Returns the data associated with a player through a `Player` object.
    
    try:
        let players = self.players.get()
        
        for player in players:
            if player.uuid == uuid:
                return player

        raise PlayerNotFoundError.newException("Player with UUID " & uuid & " not found online.")

    except UnpackDefect:
        raise QueryError.newException("Player data not found for this server.")