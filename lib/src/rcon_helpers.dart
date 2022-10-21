import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'rcon_vars.dart';

/// Returns a Uint8Lit that contains only 4 integers starting
/// from original[start]. Start defaults to 0 if not set. If
/// 4 integers cannot be copied from the list (e.g. list length
/// is less than 4 or start is too large to copy 4 integers), a
/// list of [-1, -1, -1, -1] will be returned. Returns 0 in place
/// of any integer if that location is empty in the source list.
Uint8List _u8LCopy4(Uint8List original, {int start = 0}) {
  // Ensure that the Uint8List is at least len 4 and that
  // start is list.length-4 or less
  if (original.length < 4 || start + 3 > original.length - 1) {
    // If not, return a list that is all -1.
    Uint8List errorList = Uint8List(4)
      ..[0] = -1
      ..[1] = -1
      ..[2] = -1
      ..[3] = -1;

    return errorList;
  }

  // Creates a new length 4 Uint8List and sets each of the
  // values to a value from the original list.
  Uint8List copiedUint8s = Uint8List(4)
    ..[0] = original[start]
    ..[1] = original[start + 1]
    ..[2] = original[start + 2]
    ..[3] = original[start + 3];

  return copiedUint8s;
}

/// Returns a Uint8Lit that contains only 4 integers starting
/// from original[start]. Start defaults to 0 if not set. If
/// 4 integers cannot be copied from the list (e.g. list length
/// is less than 4 or start is too large to copy 4 integers), a
/// list of [-1, -1, -1, -1] will be returned. Returns 0 in place
/// of any integer if that location is empty in the source list.
@visibleForTesting
Uint8List u8LCopy4(Uint8List original, {int start = 0}) {
  return _u8LCopy4(original, start: start);
}

/// Returns a little Endian int32 interpreted from 4 Uint8s
/// retrieved from data (Uint8List) starting at an index of
/// start (int). The Uint8list length must be at least 4 and
/// start must be data.length - 4 or smaller. Returns -1
/// if processing has failed.
int _processToInt32(Uint8List data, int start) {
  // Checks to ensure that the Uint8List is longer than 4
  // and that the starting index is valid to parse out a
  // 32-bit integer.
  if (data.length < 4 || start > (data.length - 4)) {
    return -1;
  }

  // Copies the 4 uint8s we need to parse the int32.
  Uint8List copiedUint8s = _u8LCopy4(data, start: start);

  // I don't know what this does. But it gives me access
  // to the list and the ability to parse out a 32-bit int.
  var blob = ByteData.sublistView(copiedUint8s);

  // Process out the 32-bit integer assuming little Endian
  // (which is what the RCON protocol uses).
  int processedInt32 = blob.getInt32(0, Endian.little);

  return processedInt32;
}

/// Returns a little Endian int32 interpreted from 4 Uint8s
/// retrieved from data (Uint8List) starting at an index of
/// start (int). The Uint8list length must be at least 4 and
/// start must be data.length - 4 or smaller. Returns -1
/// if processing has failed.
@visibleForTesting
int processToInt32(Uint8List data, int start) {
  return _processToInt32(data, start);
}

/// Returns a List<int> that contains the 3 header integers
/// processed from the Uint8List of data.
List<int> _processHeaders(Uint8List data) {
  // Processes out each of the 3 header integers.
  int msgLength = _processToInt32(data, 0);
  int respReqID = _processToInt32(data, 4);
  int commandID = _processToInt32(data, 8);

  // Creates a list made of the header integers.
  List<int> msgHeader = [msgLength, respReqID, commandID];

  return msgHeader;
}

/// Returns a List<int> that contains the 3 header integers
/// processed from the Uint8List of data.
// @visibleForTesting
// List<int> processHeaders(Uint8List data) {
//   return _processHeaders(data);
// }

/// Returns a boolean that represents whether the response ID
/// represents a good packet. Good packet means response
/// ID == original request ID. Bad auth packet means response
/// ID == -1.
bool _processResponseID(int respID) {
  if (respID == requestID) {
    // If the response ID == original request ID,
    // we received a good packet.
    print("mc_rcon: Good packet received.");
    return true;
  } else if (respID == -1) {
    // If the response ID == -1, we haven't authenticated
    // properly, which can mean we sent the wrong password
    // or we haven't authenticated yet.
    print(
        "mc_rcon: Bad authentication. Incorrect password or you haven't logged in yet.");
    return false;
  } else {
    // Catch-all for all other response IDs. Should never trigger.
    print("mc_rcon: Received unknown request ID.");
    return false;
  }
}

/// Returns a boolean that represents whether the response ID
/// represents a good packet. Good packet means response
/// ID == original request ID. Bad auth packet means response
/// ID == -1.
// @visibleForTesting
// bool processResponseID(int respID) {
//   return _processResponseID(respID);
// }

/// Processes the server response (represented as a Uint8List)
/// and calls onData handler if we have received a good packet.
void _processServerResponse(Uint8List data, Function onData) {
  // Parses out the message headers and payload.
  List<int> rconHeaders = _processHeaders(data);
  String payload = String.fromCharCodes(data, 12);

  // Pulls out the messsage length to ensure the integrity
  // of the message and the response ID to print.
  int messageLen = rconHeaders[0];
  int responseID = rconHeaders[1];
  print("mc_rcon: Server response id: $responseID");

  // Ensures that the data we recieved is the same
  // as what the length of the message is supposed to be.
  bool badMessage = (data.length == messageLen);

  // Sends the headers and payload to the user handler function
  // if the response is good (we receive our own request ID).
  if (!badMessage && _processResponseID(responseID)) {
    onData(rconHeaders, payload);
  }
}

/// Processes the server response (represented as a Uint8List)
/// and calls onData handler if we have received a good packet.
@visibleForTesting
void processServerResponse(Uint8List data, Function onData) {
  return _processServerResponse(data, onData);
}

/// Processes the server response (represented as a Uint8List)
/// and calls onData handler if we have received a good packet.
@protected
void pSR(Uint8List data, Function onData) {
  return _processServerResponse(data, onData);
}

/// Sets every int in dataList to the Uint32List using a ByteData buffer.
void _setUint32s(Uint32List int32List, List<int> dataList) {
  // Views the buffer of the Uint32list.
  ByteData bd = ByteData.view(int32List.buffer);

  // Used to offset the bytes assigned to the ByteData.
  // Otherwise we will overwrite the already written bytes.
  int bdByteOffset = 0;

  // Loops through every int data and assigns it as a little
  // Endian Uint32 to the Uint32list's ByteData buffer.
  for (int data in dataList) {
    bd.setUint32(bdByteOffset, data, Endian.little);
    bdByteOffset += 4;
  }
}

/// Sets every int in dataList to the Uint32List using a ByteData buffer.
// @visibleForTesting
// void setUint32s(Uint32List int32List, List<int> dataList) {
//   return _setUint32s(int32List, dataList);
// }

/// Returns a Uint8List that represents the header of
/// the RCON message. Assembles the header with the
/// specified length and message ID (i.e. type of message).
Uint8List _assembleHeader(int payloadLen, int msgID, [int? overrideReqID]) {
  // Creates a new, length 3, Uint32List.
  Uint32List headerAs32 = Uint32List(3);

  // Sets the three Uint32s to the proper header integers.
  _setUint32s(headerAs32, [
    payloadLen,
    overrideReqID != null ? overrideReqID : requestID,
    msgID,
  ]);

  // Transforms the header Uint32List into a Uint8List
  // for transmission.
  Uint8List header = headerAs32.buffer.asUint8List();

  return header;
}

/// Returns a Uint8List that represents the header of
/// the RCON message. Assembles the header with the
/// specified length and message ID (i.e. type of message).
// @visibleForTesting
// Uint8List assembleHeader(int payloadLen, int msgID) {
//   return _assembleHeader(payloadLen, msgID);
// }

/// Returns a Uint8List that represents the suffix of
/// the RCON message. The suffix is two NULLs in ASCII,
/// one to end the payload, and one to end the message.
Uint8List _assembleSuffix() {
  // Creates a new, length 2, Uint8List.
  Uint8List suffix = Uint8List(2);

  // Views the buffer of the list so we can add to the list.
  ByteData suffixBD = ByteData.view(suffix.buffer);

  // Adds the two NULLs to the Uint8List.
  suffixBD.setUint8(0, 0);
  suffixBD.setUint8(1, 0);

  return suffix;
}

/// Returns a Uint8List that represents the suffix of
/// the RCON message. The suffix is two NULLs in ASCII,
/// one to end the payload, and one to end the message.
// @visibleForTesting
// Uint8List assembleSuffix() {
//   return _assembleSuffix();
// }

/// Assembles a list of Uint8Lists into one Uint8List.
Uint8List _assembleUint8Lists(List<Uint8List> msgParts) {
  // Creates a new BytesBuilder to assemble the ints.
  BytesBuilder bBuilder = BytesBuilder();

  // Adds every list of Uint8s to the BB.
  // This automatically compiles the list of ints.
  for (Uint8List part in msgParts) {
    bBuilder.add(part);
  }

  // Returns the BB's data as a Uint8list.
  return bBuilder.toBytes();
}

/// Assembles a list of Uint8Lists into one Uint8List.
// @visibleForTesting
// Uint8List assembleUint8Lists(List<Uint8List> msgParts) {
//   return _assembleUint8Lists(msgParts);
// }

/// Returns the whole RCON message as a Uint8List. Requires the
/// message length, message ID, and the payload.
Uint8List _createMessage(int msgLen, int msgID, String payload,
    [int? overrideReqID]) {
  // Example login data: (u__ refers to the type of unsigned integer)
  // 0d00 0000 | dec0 ad0b | 0300 0000 | 3132 3300 00
  //  len u32  |  pID u32  | cmdID u32 | payload/password u8

  // Creates the 3 parts of the message using their respective
  // constructors (2 are self-written, one built into Uint8List).
  Uint8List header = _assembleHeader(msgLen, msgID, overrideReqID);
  Uint8List msgAsIntList = Uint8List.fromList(payload.codeUnits);
  Uint8List suffix = _assembleSuffix();

  // Assembles the 3 parts into 1 Uint8List to return;
  Uint8List fullMsg = _assembleUint8Lists([header, msgAsIntList, suffix]);

  return fullMsg;
}

/// Returns the whole RCON message as a Uint8List. Requires the
/// message length, message ID, and the payload.
@visibleForTesting
Uint8List createMessage(int msgLen, int msgID, String payload,
    [int? overrideReqID]) {
  return _createMessage(msgLen, msgID, payload, overrideReqID);
}

/// Returns the whole RCON message as a Uint8List. Requires the
/// message length, message ID, and the payload.
@protected
Uint8List cM(int msgLen, int msgID, String payload) {
  return _createMessage(msgLen, msgID, payload);
}
