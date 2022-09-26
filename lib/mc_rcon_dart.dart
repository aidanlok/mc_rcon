library mc_rcon;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// The socket that is used to communicate with the RCON server.
/// Generated when createSocket() is run.
Socket? rconSck;

/// The randomly generated request ID that is sent with every message
/// to the RCON server. Used to ensure that the commands sent to and
/// received from the server are ours, and not another user's.
int requestID = Random().nextInt(2147483647);

/// Creates and stores a socket connected to the RCON server
/// with the given host (IP/FQDN) and port.
Future<void> createSocket(String host, {int port = 25575}) async {
  rconSck = await Socket.connect(host, port);
}

/// Closes the socket to the RCON server. Returns a bool that specified
/// whether the socket was successfully destroyed.
bool close() {
  if (rconSck == null) {
    return false;
  }
  rconSck!.destroy();
  return true;
}

/// Starts listening on the socket for packets sent by the RCON server.
/// Returns a boolean that specifies if the socket has started listening.
/// Note: onData must accept a Uint8List as the only parameter. The payload
/// of the message starts at element 12.
bool listen(Function onData) {
  if (rconSck == null) {
    return false;
  }

  rconSck!.listen(
    (Uint8List data) {
      Uint8List respReqIDInts = Uint8List(4)
        ..[0] = data[4]
        ..[1] = data[5]
        ..[2] = data[6]
        ..[3] = data[7];
      var blob = ByteData.sublistView(respReqIDInts);
      int respReqID = blob.getInt32(0, Endian.little);
      if (kDebugMode) {
        print("response id: $respReqID");
      }

      if (respReqID == requestID) {
        if (kDebugMode) {
          print("mc_rcon: Good packet received.");
        }
        onData(data);
      } else if (respReqID == -1) {
        if (kDebugMode) {
          print(
              "mc_rcon: Bad authentication. Incorrect password or you haven't logged in yet.");
        }
      } else {
        if (kDebugMode) {
          print("mc_rcon: Received unknown request ID.");
        }
      }
    },
    onError: (error) {
      if (kDebugMode) {
        print('mc_rcon: Error with the connection to the server: $error');
      }
      rconSck!.destroy();
    },
    onDone: () {
      if (kDebugMode) {
        print('mc_rcon: The server has ended the connection.');
      }
      rconSck!.destroy();
    },
    cancelOnError: false,
  );

  return true;
}

/// Send a message with the given message ID and message payload.
/// Returns a boolean that specifies if the command was successful.
bool sendMsg(int msgID, String msg) {
  if (rconSck == null) {
    return false;
  }

  // Example login data: (u__ refers to the type of unsigned integer)
  // 0d00 0000 | dec0 ad0b | 0300 0000 | 3132 3300 00
  //  len u32  |  pid u32  | cmdid u32 | payload/password u8

  int payloadLen = 10 + msg.length;

  Uint32List headerAs32 = Uint32List(3);
  var headerBD = ByteData.view(headerAs32.buffer);
  headerBD.setUint32(0, payloadLen, Endian.little);
  headerBD.setUint32(4, requestID, Endian.little);
  headerBD.setUint32(8, msgID, Endian.little);
  Uint8List header = headerAs32.buffer.asUint8List();

  Uint8List passwordAsIntList = Uint8List.fromList(msg.codeUnits);

  Uint8List suffix = Uint8List(2);
  var suffixBD = ByteData.view(suffix.buffer);
  suffixBD.setUint8(0, 0);
  suffixBD.setUint8(1, 0);

  BytesBuilder bBuilder = BytesBuilder();
  bBuilder.add(header);
  bBuilder.add(passwordAsIntList);
  bBuilder.add(suffix);
  Uint8List payload = bBuilder.toBytes();

  rconSck!.add(payload);
  if (kDebugMode) {
    print("mc_rcon: sent payload ($payload) on socket");
  }

  return true;
}

/// Log in to the RCON server using the given socket and password.
/// Returns a boolean that specifies if the command was successful.
bool login(String password) {
  return sendMsg(3, password);
}

/// Send the provided command to the RCON server using the
/// Returns a boolean that specifies if the command was successful.
bool sendCommand(String message) {
  return sendMsg(2, message);
}
