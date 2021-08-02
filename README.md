# setup-flutter

[![Flutter](https://github.com/flutter/setup-flutter/workflows/Flutter/badge.svg)](https://github.com/flutter/setup-flutter/actions?query=workflow%3A%22Flutter%22+branch%3Amain)

This [GitHub Action](https://github.com/flutter/setup-flutter) installs and sets up a Flutter SDK for use in actions by:

* Downloading the Flutter SDK
* Adding the [`flutter`](https://flutter.dev/docs/reference/flutter-cli) command to path
* Adding the [`dart`](https://dart.dev/tools/dart-tool) command to path
* Anding the `pub` cache to path (for [pub globals](https://dart.dev/tools/pub/cmd/pub-global))

# Usage

## Inputs

The action takes the following inputs:

  * `channel`: Which Flutter [SDK channel](https://github.com/flutter/flutter/wiki/Flutter-build-release-channels) to setup.
    * Available channels are `stable`, `beta`, `dev`. If omited, `main` is the default.
    * Alternatively, to get the latest engineering build use `main`.

  * `version`: Which SDK version to setup. Can be specified using one of two forms:
    1. The latest version (`latest`) from the specified channel (this is the default if the `version` input is omited).
    1. A specific SDK version, e.g. `2.2.1` or `1.21.0-9.1.pre`.
    * Note: You cannot specify a version when using the `main` channel.

## Basic example

Install the latest stable SDK, and run `flutter help`.

```yml
name: Flutter

on:
  push:
    branches: [ master ]
  pull_request:
    branches: [ master ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2
      - uses: flutter/setup-flutter@v0.1
      - name: Flutter help
        run: flutter help
```

## Check static analysis, formatting, and run tests

Various static checks:

  1) Check code follows Dart idiomatic formatting
  2) Check static analysis with the Dart analyzer
  3) Check that tests pass

```yml
...
    steps:

      - name: Install dependencies
        run: flutter pub get

      - name: Verify formatting
        run: flutter format --set-exit-if-changed .

      - name: Analyze project source
        run: flutter analyze

      - name: Run tests
        run: flutter test
```

## Matrix testing example

You can create matrix jobs that run tests on multiple operating systems, and
multiple versions of the Flutter SDK.

The following example create a double matrix across two dimensions:

  - All three major operating systems: Linux, macOS, and Windows.
  - Two Flutter SDKs: Latest stable and beta.

```yml
name: Dart

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        channel: [stable, beta]
    steps:
      - uses: actions/checkout@v2
      - uses: flutter/setup-flutter@v0.1
        with:
          channel: ${{ matrix.channel }}

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test
```


# Version history

## v0.1

  * Initial version.

# License

See the [`LICENSE`](LICENSE) file.
