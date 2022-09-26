import 'package:flutter/foundation.dart';
import 'package:mc_rcon_dart/mc_rcon_dart.dart';

main() async {
  await createSocket("172.30.80.31", port: 25575); // Replace RCON server info.
  listen(onData);
  login("123"); // Replace password to the RCON server.
  sendCommand("time set 0"); // This can be any valid Minecraft console command.
  close();
}

void onData(Uint8List data) {
  print(String.fromCharCodes(data, 12));
}
