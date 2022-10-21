import 'dart:io';
import 'dart:math';

/// The socket that is used to communicate with the RCON server.
/// Generated when createSocket() is run.
Socket? rconSck;

/// The randomly generated request ID that is sent with every
/// message to the RCON server. Used to ensure that the commands
/// sent to and received from the server are ours, and not another
/// user's.
int requestID = Random().nextInt(2147483647);
