<!-- SPDX-License-Identifier: MIT -->

<div align="center">

# <img src="https://raw.githubusercontent.com/nim-lang/assets/master/Art/logo-crown.png" height="30px"/> mcsrvstat.nim <br>

### A hybrid and asynchronous Nim wrapper for the [Minecraft Server Status API](https://mcsrvstat.us/).

[![Build](https://github.com/hitblast/mcsrvstat.nim/actions/workflows/builds.yml/badge.svg)](https://github.com/hitblast/mcsrvstat.nim/actions/workflows/builds.yml)
[![Deploy to Pages](https://github.com/hitblast/mcsrvstat.nim/actions/workflows/pages.yml/badge.svg)](https://github.com/hitblast/mcsrvstat.nim/actions/workflows/pages.yml)

<img src="https://github.com/hitblast/mcsrvstat.nim/blob/main/static/demo.png" alt="Demo Terminal Image">

</div>

> [!WARNING]
> This project has gone to maintenance mode as of May 2025.

## Table of Contents

- [Installation](#-installation)
- [Usage](#-usage)
    - [as a CLI application](#-as-a-cli-application)
    - [as a Nim library](#-as-a-nim-library)
- [Building](#-building)
- [Similar Projects](#-check-out-my-other-similar-projects)
- [License](#-license)

<br>

## 📦 Installation

- ### Nim (using [nimble](https://github.com/nim-lang/nimble))

```bash
# Requires Nim v2.0 or greater.
$ nimble install mcsrvstat.nim
```

- ### macOS (using [Homebrew](https://brew.sh))

```bash
# Tapping the formula.
$ brew tap hitblast/tap

# Installing it.
$ brew install mcsrvstat
```

- ### Binary Downloads
You can manually download the packages required from the latest release in the [Releases](https://github.com/hitblast/mcsrvstat.nim/releases) section. The [build artifacts](https://github.com/hitblast/mcsrvstat.nim/actions/workflows/builds.yml) are also stored for you to download as well.

<br>

## ⚡ Usage

This package, AKA mcsrvstat.nim, is a [hybrid package](https://github.com/nim-lang/nimble#hybrids). Meaning that it can be used as both a Nim library and a standalone CLI application inside your terminal. <br>

### ... as a CLI application

After installing the package [(see this section)](#-installation), the binary for mcsrvstat.nim should be in your `PATH` variable depending on how you've installed it. This means, a new `mcsrvstat` command will be added to your shell environment. Simply run it using the following command snippets:

```bash
# The default help command.
$ mcsrvstat --help  # -h also works

# Fetching a Minecraft: Java Edition server.
$ mcsrvstat hypixel.net

# Fetching a Minecraft: Bedrock Edition server.
$ mcsrvstat mco.mineplex.com --bedrock

# Fetching with auto-refreshing enabled.
$ mcsrvstat play.hivemc.com --autorefresh
```

### ... as a Nim library

Aside of the CLI binary, mcsrvstat.nim can also work as a Nim library as mentioned once before. You'll have to install the package using Nimble [(see this section)](#-installation) and then you're done. Here is some basic code for you to get started with:

```nim
# Imports.
import std/[
    asyncdispatch,
    strformat
]
import mcsrvstat/base

# Defining a Server object instance. This represents a Minecraft server.
let server = Server(
    address: "hypixel.net",
    platform: JAVA  # can also be BEDROCK (derives from the Platform enum, see documentation to learn more)
)

# The primary procedure.
proc main() {.async.} =
    await server.refreshData()  # Loads the server data into memory.

    if server.isOnline:
        echo fmt"Server running on: {server.ip} (port {server.port})"

        # Save the icon of the server.
        writeFile("server-icon.png", server.icon)
        echo "Server icon saved as an image!"

    else:
        echo "Server is offline!"

# Running it.
waitFor main()
```

For more use cases and detailed explanation, you can visit the [official documentation](https://hitblast.github.io/mcsrvstat.nim) and view the different types, examples and procedures. It's frequently updated with the package itself so any new features will directly modify the documentation alongside!

<br>

## 🔨 Building

```bash
# Prepare a release build.
# This uses the "release" task provided with the project.
$ nimble release
```

The various third-party libraries and dependancies used for developing this project are mentioned below:

- Internal dependencies:
    1. The [argparse](https://nimble.directory/pkg/argparse) library, for parsing command-line arguments for the CLI binary.
    2. The [illwill](https://nimble.directory/pkg/illwill) library, for the terminal user interface (TUI).

- External dependencies (noted in the [root .nimble](https://github.com/hitblast/mcsrvstat.nim/blob/main/mcsrvstat.nimble) file):
    1. [OpenSSL](https://www.openssl.org) for connection and making API calls.

<br>

## ✨ Check out my other similar projects!

The [api.mcsrvstat.py](https://github.com/hitblast/api.mcsrvstat.py) library is another asynchronous wrapper for the very same Minecraft Server Status API, but instead it's implemented in [Python](https://python.org). If you like this project and by chance if you're also a Python developer, then hopefully you'll have fun tinkering with api.mcsrvstat.py as well.

<br>

## 🔖 License

This project is licensed under the [MIT License](https://github.com/hitblast/mcsrvstat.nim/blob/main/LICENSE).
