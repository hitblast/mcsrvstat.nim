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
requires "simpleparseopt >= 1.1.1"
requires "illwill >= 0.3.0"