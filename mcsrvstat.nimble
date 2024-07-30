# SPDX-License-Identifier: MIT


# Primary package information.
version       = "1.5"
author        = "HitBlast"
description   = "A hybrid and asynchronous Nim wrapper for the Minecraft Server Status API."
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["mcsrvstat"]


# Nim dependencies / required libraries.
requires "nim >= 2.0.0"
requires "argparse >= 4.0"
requires "illwill >= 0.4.0"


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
