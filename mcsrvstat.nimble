# SPDX-License-Identifier: MIT


# Primary package information.
version       = "1.4.0"
author        = "HitBlast"
description   = "A hybrid and asynchronous Nim wrapper for the Minecraft Server Status API."
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["mcsrvstat"]


# Nim dependencies / required libraries.
requires "nim >= 1.6.10"
requires "argparse >= 4.0"
requires "illwill == 0.3.2"


# External dependencies.
when defined(nimdistros):
  import distros
  if detectOs(Ubuntu):
    foreignDep "libssl-dev"
  else:
    foreignDep "openssl"


# Tasks.
task release, "For building a release version of the project.":
 exec "nimble -d:ssl -d:release --accept build"
