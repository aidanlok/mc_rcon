A Dart SDK for interacting with a Minecraft server using the RCON protocol.
[Package on pub.dev](https://pub.dev/packages/mc_rcon_dart)

## Features

Provides an API to connect to, log in to, send commands to, and receive data from a Minecraft server via the RCON protocol.

## Getting started

Run `flutter pub add mc_rcon_dart` or `dart pub add mc_rcon_dart`.

Alternatively, add the following to your pubspec.yaml:
```
dependencies:
  mc_rcon_dart: ^1.1.0
```

## Usage
Full code example in [example.dart](example/example.dart).

To import the package:
```dart
import 'package:mc_rcon_dart/mc_rcon_dart.dart';
```

To create the socket (typically want to await on the completion):
```dart
createSocket("172.30.80.31", port: 25575);
```

To set a listener on the socket (note that the handler function must take a List<int> and a String as its only two parameters):
```dart
listen(onData);
```

To log in to the RCON server:
```dart
login("123");
```

To send any command:
```dart
sendCommand("time set 0");
```

To close the connection:
```dart
close();
```

## Additional information

* The RCON documentation is [here](https://wiki.vg/RCON).
* The documentation for Minecraft console commands is [here](https://minecraft.fandom.com/wiki/Commands).
* The documentation for Socket (as of Dart 2.18.1), which is used to communicate with the RCON server, is [here](https://api.dart.dev/stable/2.18.1/dart-io/Socket-class.html).
* Report bugs by making a new issue or send a merge request with the fix, but I'm pretty sure this is all working as is, and I don't expect the RCON protocol to change.