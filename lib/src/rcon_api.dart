import 'dart:io';
import 'dart:typed_data';

import 'rcon_vars.dart';
import 'rcon_helpers.dart';

/// Creates and stores a socket connected to the RCON server
/// with the given host (IP/FQDN) and port. Port defaults to
/// 25575 if no port is specified.
Future<void> createSocket(String host, {int port = 25575}) async {
  // Creates the socket by connecting the socket to the specified
  // host and port.
  rconSck = await Socket.connect(host, port);
}

/// Closes the socket to the RCON server. Returns a bool that
/// specified whether the socket was successfully destroyed.
bool close() {
  // Checks to ensure that the RCON socket exists.
  if (rconSck == null) {
    return false;
  }

  // Destroys the socket, which also closes the connection.
  rconSck!.destroy();

  return true;
}

/// Send a message with the given message ID and message payload.
/// Returns a boolean that specifies if the command was successful.
bool sendMsg(int msgID, String payload) {
  // Ensures that the RCON socket exists.
  if (rconSck == null) {
    return false;
  }

  // Message length is the payload length + 10 to account
  // for the headers and suffix.
  int msgLen = 10 + payload.length;

  // Creates the full RCON message.
  Uint8List fullMsg = cM(msgLen, msgID, payload);

  // Add the RCON message to the socket stream.
  rconSck!.add(fullMsg);
  print("mc_rcon: sent payload ($fullMsg) on socket");

  return true;
}

/// Log in to the RCON server using the given socket and password.
/// Returns a boolean that specifies if the command was successful.
bool login(String password) {
  // Sends an RCON message with request ID = 3 (authenticate)
  // with the password as the payload.
  return sendMsg(3, password);
}

/// Send the provided command to the RCON server using the
/// Returns a boolean that specifies if the command was successful.
bool sendCommand(String command) {
  // Sends an RCON message with request ID = 2 (command)
  // with the String command as the payload.
  return sendMsg(2, command);
}

/// Starts listening on the socket for packets sent by the RCON
/// server. Returns a boolean that specifies if the socket has
/// started listening. Note: onData must accept a List<int> and
/// a String as the only parameters.
bool listen(Function onData) {
  // Checks to ensure that the RCON socket exists.
  if (rconSck == null) {
    return false;
  }

  // Starts listening on the RCON socket.
  // Calls the first handler if we receive data, calls onError
  // if there is an error on the stream, calls onDone when the
  // client or the server ends the connection.
  rconSck!.listen(
    (Uint8List data) {
      pSR(data, onData);
    },
    onError: (error) {
      print('mc_rcon: Error with the connection to the server: $error');
      rconSck!.destroy();
    },
    onDone: () {
      print('mc_rcon: The server has ended the connection.');
      rconSck!.destroy();
    },
    cancelOnError: false,
  );

  return true;
}
