# Package

version       = "1.3.0"
author        = "HitBlast"
description   = "A hybrid and asynchronous Nim wrapper for the Minecraft Server Status API."
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["mcsrvstat"]


# Dependencies

requires "nim >= 1.6", "argparse >= 4.0", "illwill >= 0.3"


# External dependencies

when defined(nimdistros):
  import distros
  if detectOs(Ubuntu):
    foreignDep "libssl-dev"
  else:
    foreignDep "openssl"


# Tasks

task release, "Builds a production executable for the package.":
  exec "nimble build -d:ssl -d:release --hints:off --accept"