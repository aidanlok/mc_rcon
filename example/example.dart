import 'dart:typed_data';
import 'package:mc_rcon_dart/mc_rcon_dart.dart';

main() async {
  await createSocket("172.30.80.31", port: 25575); // Replace RCON server info.
  listen(onData);
  login("123"); // Replace password to the RCON server.
  sendCommand("time set 0"); // This can be any valid Minecraft console command.
  close();
}

void onData(List<int> header, String payload) {
  print("Message length: ${header[0]}");
  print("Response ID: ${header[1]}");
  print("Command ID: ${header[2]}");
  print("Response payload: $payload");
}
