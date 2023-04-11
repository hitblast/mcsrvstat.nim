# Package

version       = "0.1.0"
author        = "HitBlast"
description   = "An asynchronous Nim wrapper for the Minecraft Server Status API"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["mcsrvstat"]


# Dependencies

requires "nim >= 1.6"
requires "therapist >= 0.2.0"
requires "illwill >= 0.3.0"