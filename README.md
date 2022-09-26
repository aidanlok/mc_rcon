A Dart SDK for interacting with a Minecraft server using the RCON protocol.

## Features

Provides an API to connect to, log in to, send commands to, and receive data from a Minecraft server via the RCON protocol.

## Getting started

Run `flutter pub add mc_rcon` or add the following to your pubspec.yaml:
```
dependencies:
  mc_rcon: <current_version>^
```

## Usage
See the example below. Full code example also in [example.dart](example/dart_example.dart).

```dart
import 'package:flutter/foundation.dart';
import 'package:mc_rcon/mc_rcon.dart';

main() async {
  await createSocket("172.30.80.31", port: 25575);
  listen(onData);
  login("123");
  sendCommand("time set 0");
  close();
}

void onData(Uint8List data) {
  print(String.fromCharCodes(data, 12));
}
```

## Additional information

* The RCON documentation is [here](https://wiki.vg/RCON).
* The documentation for Minecraft console commands is [here](https://minecraft.fandom.com/wiki/Commands).
* The documentation for Socket (as of 2.18.1), which is used to communicate with the RCON server, is [here](https://api.dart.dev/stable/2.18.1/dart-io/Socket-class.html).
* Report bugs by making a new issue or send a merge request with the fix, but I'm pretty sure this is all working as is, and I don't expect the RCON protocol to change.