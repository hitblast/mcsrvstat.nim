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
        data: Option[JsonNode]
        iconData: string

    Icon* = ref object
        ## Represents the icon of a Minecraft server.
        base64: string

    ServerDebugValues* = object
        ## Represents the debug values related to a Minecraft server.
        ping*, query*, srv*, querymismatch*, ipinsrv*, cnameinsrv*, animatedmotd*: bool
        cachetime*, cacheexpire*, apiversion*: int

    Construct3Attr = object
        ## Constructor object for child objects with the following attributes: raw, clean, html
        raw*, clean*, html*: seq[string]

    Construct2Attr = object
        ## Constructor object for child objects with the following attributes: names, raw
        names*, raw*: seq[string]

    ServerMOTD* = ref Construct3Attr  ## Represents the MOTD (Message of The Day) of a Minecraft server.
    ServerInfo* = ref Construct3Attr  ## Represents certain information related to a Minecraft server. Only included if the server uses player samples for gathering information.
    ServerPlugins* = ref Construct2Attr  ## Represents the plugins used on a Minecraft server.
    ServerMods* = ref Construct2Attr  ## Represents the mods installed on a Minecraft server.

    PlayerCount* = object
        ## Represents the total amount of online players (and the maximum player capacity) of a Minecraft server.
        online*, max*: int

    Player* = object
        ## Represents a player of a Minecraft server.
        name*, uuid*: string


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
    let platform = if self.platform == Platform.JAVA: "2/" else: "bedrock/2/"

    let data = parseJson(await client.getContent(
            fmt"https://api.mcsrvstat.us/{platform}{self.address}"))

    if (
        data["debug"]{"error"}{"ping"}.getStr() == "No address to query"
    ):
        raise ConnectionError.newException("Make sure you have passed the correct IP address for the server.")

    else:
        self.data = some(data)
        self.iconData = await client.getContent(fmt"https://api.mcsrvstat.us/icon/{self.address}")

        client.close()

proc retrieveData(self: Server, key: string): JsonNode =
    ## Internal procedure for retrieving the data requested through the given key and returning it as a `JsonNode` object.

    if not self.data.isSome:
        raise NotInitializedError.newException("You did not initialize the Server object using the refreshData() procedure first.")
    else:
        try:
            return self.data.get()[key]
        except KeyError:
            raise DataError.newException("Key invalid / offline / bad server IP.")

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


proc online*(self: Server): bool =
    ## Returns a boolean value depending on if the Minecraft server is online or not.

    return self.retrieveData("online").getBool()

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
        cachetime: data["cachetime"].getInt(),
        cacheexpire: data["cacheexpire"].getInt(),
        apiversion: data["apiversion"].getInt()
    )

proc version*(self: Server): string =
    ## Returns the version of software used for running the Minecraft server. This can include multiple versions or additional text depending on the server.
    return self.retrieveData("version").getStr()

proc protocol*(self: Server): Option[int] =
    ## (Optional) Returns the protocol of the server. Only returned if `ping` is set to `True` within the debug values.
    try:
        let protocol = self.retrieveData("protocol")
        return some(protocol.getInt())
    except DataError:
        return none(int)

proc hostname*(self: Server): Option[string] =
    ## (If detected) Returns the hostname of the server.
    return self.retrieveOptionalStr("hostname")

proc software*(self: Server): Option[string] =
    ## (If detected) Returns the software used for the server.
    return self.retrieveOptionalStr("software")

proc map*(self: Server): Option[string] =
    ## (If detected) Returns the map name of the server.
    return self.retrieveOptionalStr("map")

proc gamemode*(self: Server): Option[string] =
    ## (Bedrock-only, Optional) Returns the game mode used inside the server (Survival / Creative / Adventure).
    return self.retrieveOptionalStr("gamemode")

proc serverid*(self: Server): Option[string] =
    ## (Bedrock-only, Optional) Returns the ID of the server.
    return self.retrieveOptionalStr("serverid")

proc motd*(self: Server): Option[ServerMOTD] =
    ## (If any) Returns a `ServerMOTD` object representing the MOTD (Message of the Day) for the server.
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

proc plugins*(self: Server): Option[ServerPlugins] =
    ## (If detected) Returns a `ServerPlugins` object representing the plugins used on the server.
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

proc mods*(self: Server): Option[ServerMods] =
    ## (If detected) Returns a `ServerMods` object representing the mods currently installed on the server.
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

proc info*(self: Server): Option[ServerInfo] =
    ## (Optional) Returns a `ServerInfo` object representing some extra bits of information related to the server.
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
    ## (Optional) Returns a `PlayerCount` object representing the total amount of active players (and the maximum player capacity) of the server.
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

proc getPlayers*(self: Server): seq[Player] =
    ## (Query-dependant) Returns a sequence of `Player` objects representing currently online (and queried) players on the server.
    
    try:
        let data = self.retrieveData("players")
        var players: seq[Player]

        for player in data["uuid"]:
            players.add(
                Player(
                    name: player["name"].getStr(),
                    uuid: player["uuid"].getStr()
                )
            )

        return players

    except KeyError, DataError:
        raise QueryError.newException("Could not query for server players list.")

proc getPlayerByName*(self: Server, name: string): Player =
    ## (Query-dependant) Returns the data associated with a player through a `Player` object.
    
    try:
        let
            data = self.retrieveData("players")
            players = data["uuid"]
            uuid = players{name}.getStr()

        if uuid != "":
            return Player(
                name: name,
                uuid: uuid
            )

        else:
            raise PlayerNotFoundError.newException(fmt"Player '{name}' could not be found online.")

    except KeyError, DataError:
        raise QueryError.newException("Could not query for server players list.")


#[
    This is an additional part for the server icon endpoint of the API.
    The code below is written in conjunction with both:
        1. The Server object, and
        2. The Icon object.
]#


proc icon*(self: Server): Icon =
    ## Returns an `Icon` object containing the icon of the Minecraft server.
    
    return Icon(
        base64: self.iconData
    )

proc save*(self: Icon, filename: string): void =
    ## Writes the icon of a server into the local drive with the given file name.
    ## (Note: Tou don't need to provide any extensions, the program automatically saves them in a `.png` format!)

    writeFile(fmt"{filename}.png", self.base64)