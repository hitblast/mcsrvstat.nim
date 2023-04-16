<div align="center">

# <img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/nim/nim.png" height="35px"/> mcsrvstat.nim <br>

### A hybrid and asynchronous Nim wrapper for the [Minecraft Server Status API](https://mcsrvstat.us/).

[![Build](https://github.com/hitblast/mcsrvstat.nim/actions/workflows/builds.yml/badge.svg)](https://github.com/hitblast/mcsrvstat.nim/actions/workflows/builds.yml)
[![Deploy to Pages](https://github.com/hitblast/mcsrvstat.nim/actions/workflows/pages.yml/badge.svg)](https://github.com/hitblast/mcsrvstat.nim/actions/workflows/pages.yml)

<img src="https://github.com/hitblast/mcsrvstat.nim/blob/main/static/demo.png" alt="Demo Terminal Image">

</div>

## Table of Contents

- [Installation](#📦-installation)
- [Usage](#⚡-usage)
    - [as a CLI application](#as-a-cli-application)
    - [as a Nim library]()
- [Building]()
- [Contributing]()
- [Similar Projects]()
- [License]()

## 📦 Installation

- You can easily install this package using [Nimble]() for using it as both a command-line application and a Nim package. 

```bash
# requires Nim v1.6 or greater
$ nimble install mcsrvstat.nim
```

## ⚡ Usage

This package, AKA mcsrvstat.nim, is a [hybrid package](). Meaning that it can be used as both a Nim library and a standalone CLI application inside your terminal.

### ... as a CLI application

After installing the package from [the Installation section](#installation) section, the binary for mcsrvstat.nim should be in your PATH depending on how you've installed it. This means, a new `mcsrvstat` command will be added to your shell environment. Simply run it using the following commands:

```bash

# The default help command.
$ mcsrvstat --help  # -h also works

# Fetching a Minecraft: Java Edition server.
$ mcsrvstat hypixel.net

# Fetching a Minecraft: Bedrock Edition server.
$ mcsrvstat mco.mineplex.com --bedrock
```
