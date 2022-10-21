import 'dart:ffi';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:test/test.dart';
import 'dart:typed_data';
import 'package:mc_rcon_dart/mc_rcon_dart.dart' as mc_rcon;

Random rng = Random();

int lenOfU8L = 10;
int maxU8LLen = 50;
Uint8List errorList = Uint8List(4)
  ..[0] = -1
  ..[1] = -1
  ..[2] = -1
  ..[3] = -1;

void main() {
  testTesterHelpers();
  testU8LCopy4();
  testProcessToInt32();
  testProcessServerResponse();
}

void testTesterHelpers() {
  group("Helper function", () {
    test("_randomU8LLen returns an integer", () {
      // Ensures that _randomU8LLen returns an integer.
      expect(_randomU8LLen(), isA<int>());
    });
    test("_randomU8LLen returns >= 4", () {
      // Ensures that _randomU8LLen returns an integer.
      expect(_randomU8LLen(), greaterThanOrEqualTo(4));
    });
    test("_makeRandomU8L returns lists that are the random len specified", () {
      // Run _makeRandomU8L with random length from _randomU8LLen.
      int randLength = _randomU8LLen();
      List<List<int>> randLists = _makeRandomU8L(randLength);

      // Split the lists to make it cleaner for .length.
      List<int> intList = randLists[0];
      Uint8List u8L = randLists[1] as Uint8List;

      // Ensure that the lengths of the lists == the random length.
      expect(intList.length, equals(randLength));
      expect(u8L.length, equals(randLength));
      expect(intList.length, equals(u8L.length));
    });
    test("_makeRandomU8L returns a List<int> & Uint8List with same ints", () {
      // Make a random len set of lists.
      List<List<int>> randLists = _makeRandomU8L(_randomU8LLen());

      // Split the lists for easier access.
      List<int> intList = randLists[0];
      Uint8List u8L = randLists[1] as Uint8List;

      // Ensure that the lists have the same integers.
      expect(List<int>.from(u8L), equals(intList));
    });
  });
}

void testU8LCopy4() {
  group("u8LCopy4", () {
    test('returns an object of type Uint8List', () {
      // Makes a set of rand len rand int lists and splits for ease of access.
      int randLen = _randomU8LLen();
      List<List<int>> randLists = _makeRandomU8L(randLen);
      Uint8List randUi8L = randLists[1] as Uint8List;

      // Gets the function response.
      Uint8List fnResponse = mc_rcon.u8LCopy4(randUi8L);

      // Ensures that the function returns the 4 integers we know we chose.
      expect(fnResponse, isA<Uint8List>());
    });
    test('returns error list due to a list that is too short.', () {
      // Makes a random len (0-3) list with random integers.
      Uint8List shortUi8L = _makeRandomU8L(rng.nextInt(3))[1] as Uint8List;

      // Gets the function response.
      Uint8List fnResponse = mc_rcon.u8LCopy4(shortUi8L);

      // Ensures that the function returns the error list.
      expect(fnResponse, equals(errorList));
    });
    test('returns error list due to start being too large.', () {
      // Makes a new random len Uint8List.
      int u8LLen = _randomU8LLen();
      Uint8List randU8L = _makeRandomU8L(u8LLen)[1] as Uint8List;

      // Makes a random invalid starting point.
      int randStart = rng.nextInt(3) + (u8LLen - 3);

      // Gets the function response.
      Uint8List fnResponse = mc_rcon.u8LCopy4(randU8L, start: randStart);

      // Ensures that the function response is the error list.
      expect(fnResponse, equals(errorList));
    });
    test('returns error list because neither req is followed.', () {
      // Creates a random Uint8List that is too short.
      int u8LLen = rng.nextInt(3);
      Uint8List randU8L = _makeRandomU8L(u8LLen)[1] as Uint8List;

      // Get a random invalid starting point.
      int randStart = rng.nextInt(3) + (u8LLen - 3);

      // Get the function response.
      Uint8List fnResponse = mc_rcon.u8LCopy4(randU8L, start: randStart);

      // Ensure that the function respondd with the error list.
      expect(fnResponse, equals(errorList));
    });
    test('returns [0,0,0,0] because the source list is empty.', () {
      // Makes a rand len empty Uint8List.
      int randLen = _randomU8LLen();
      Uint8List emptyU8L = Uint8List(randLen);

      // Selects 4 random ints and creates the confirmation list.
      int randSelect = rng.nextInt(randLen - 4);
      Uint8List confirmList = Uint8List(4);
      for (int i = 0; i < 4; i++) {
        confirmList..[i] = 0;
      }

      // Gets the function response.
      Uint8List fnResponse = mc_rcon.u8LCopy4(emptyU8L, start: randSelect);

      // Confirms that the function gave us what we expected.
      expect(fnResponse, equals(confirmList));
    });
    test('returns the 4 copied numbers (full list of 1s).', () {
      // Makes a rand len full of 1s Uint8List.
      int randLen = _randomU8LLen();
      Uint8List randU8L = Uint8List(randLen);
      for (int i = 0; i < randU8L.length; i++) {
        randU8L..[i] = 1;
      }

      // Selects 4 random ints and creates the confirmation list.
      int randSelect = rng.nextInt(randLen - 4);
      Uint8List confirmList = Uint8List(4);
      for (int i = 0; i < 4; i++) {
        confirmList..[i] = randU8L[randSelect + i];
      }

      // Gets the function response.
      Uint8List fnResponse = mc_rcon.u8LCopy4(randU8L, start: randSelect);

      // Confirms that the function gave us what we expected.
      expect(fnResponse, equals(confirmList));
    });
    test('returns the 4 copied numbers (checkerboard start 0).', () {
      // Makes a rand len checkerboard start 0 Uint8List.
      int randLen = _randomU8LLen();
      Uint8List randU8L = Uint8List(randLen);
      for (int i = 0; i < randU8L.length; i++) {
        randU8L..[i] = i % 2;
      }

      // Selects 4 random ints and creates the confirmation list.
      int randSelect = rng.nextInt(randLen - 4);
      Uint8List confirmList = Uint8List(4);
      for (int i = 0; i < 4; i++) {
        confirmList..[i] = randU8L[randSelect + i];
      }

      // Gets the function response.
      Uint8List fnResponse = mc_rcon.u8LCopy4(randU8L, start: randSelect);

      // Confirms that the function gave us what we expected.
      expect(fnResponse, equals(confirmList));
    });
    test('returns the 4 copied numbers (checkerboard start 1).', () {
      // Makes a rand len checkerboard start 0 Uint8List.
      int randLen = _randomU8LLen();
      Uint8List randU8L = Uint8List(randLen);
      for (int i = 0; i < randU8L.length; i++) {
        if (i % 2 == 0) {
          randU8L..[i] = 1;
        } else {
          randU8L..[i] = 0;
        }
      }

      // Selects 4 random ints and creates the confirmation list.
      int randSelect = rng.nextInt(randLen - 4);
      Uint8List confirmList = Uint8List(4);
      for (int i = 0; i < 4; i++) {
        confirmList..[i] = randU8L[randSelect + i];
      }

      // Gets the function response.
      Uint8List fnResponse = mc_rcon.u8LCopy4(randU8L, start: randSelect);

      // Confirms that the function gave us what we expected.
      expect(fnResponse, equals(confirmList));
    });
    test('returns the 4 copied numbers (full random list).', () {
      // Makes a set of rand len rand int lists and splits for ease of access.
      int randLen = _randomU8LLen();
      List<List<int>> randLists = _makeRandomU8L(randLen);
      List<int> randomInts = randLists[0];
      Uint8List randUi8L = randLists[1] as Uint8List;

      // Gets a random set of 4 integers from the random ints.
      int randSelect = rng.nextInt(randLen - 4);
      Uint8List confirmList = Uint8List(4);
      for (int i = 0; i < 4; i++) {
        confirmList..[i] = randomInts[randSelect + i];
      }

      // Gets the function response.
      Uint8List fnResponse = mc_rcon.u8LCopy4(randUi8L, start: randSelect);

      // Ensures that the function returns the 4 integers we know we chose.
      expect(fnResponse, equals(confirmList));
    });
  });
}

void testProcessToInt32() {
  group("processToInt32", () {
    test("returns an object of type int", () {
      // Make a random len random integer Uint8List
      int randLen = _randomU8LLen();
      Uint8List randU8L = _makeRandomU8L(randLen)[1] as Uint8List;

      // Select a random valid starting point.
      int randStart = rng.nextInt(randLen - 4);

      // Get the function response.
      int fnResponse = mc_rcon.processToInt32(randU8L, randStart);

      // Ensure that function gave us an int.
      expect(fnResponse, isA<int>());
    });
    test("returns -1 because less than 4 Uint8s were provided.", () {
      // Make a random len random integer Uint8List
      int randLen = rng.nextInt(3);
      Uint8List randU8L = _makeRandomU8L(randLen)[1] as Uint8List;

      // Get the function response.
      int fnResponse = mc_rcon.processToInt32(randU8L, 0);

      // Ensure that function gave us an int.
      expect(fnResponse, isA<int>());
    });
  });
}

void testProcessServerResponse() {
  group("processServerResponse", () {
    test("calls the handler function with a List<int> and String", () {
      dynamic fnHeaders = [];
      dynamic fnPayload = "";

      Uint8List msg = mc_rcon.createMessage(10, 1, "");
      mc_rcon.processServerResponse(msg, (List<int> headers, String payload) {
        fnHeaders = headers;
        fnPayload = payload;
      });

      expect(fnHeaders, isA<List<int>>());
      expect(fnPayload, isA<String>());

      Uint8List msgNum2 = mc_rcon.cM(10, 1, "");
      mc_rcon.pSR(msgNum2, (List<int> headers, String payload) {
        fnHeaders = headers;
        fnPayload = payload;
      });

      expect(fnHeaders, isA<List<int>>());
      expect(fnPayload, isA<String>());
    });
    dynamic fnHeaders = [];
    test("fails because bad/no auth", () {
      dynamic fnPayload = "";

      Uint8List msg = mc_rcon.createMessage(10, 99999, "", -1);
      mc_rcon.processServerResponse(msg, (List<int> headers, String payload) {
        fnHeaders = headers;
        fnPayload = payload;
      });

      expect(fnHeaders, isEmpty);
      expect(fnPayload, isEmpty);
    });
    test("fails because unknown request ID", () {
      dynamic fnHeaders = [];
      dynamic fnPayload = "";

      Uint8List msg = mc_rcon.createMessage(
          10, 99999, "", rng.nextInt(99999999) - rng.nextInt(99999));
      mc_rcon.processServerResponse(msg, (List<int> headers, String payload) {
        fnHeaders = headers;
        fnPayload = payload;
      });

      expect(fnHeaders, isEmpty);
      expect(fnPayload, isEmpty);
    });
  });
}

int _randomU8LLen() {
  return rng.nextInt(maxU8LLen) + 5;
}

List<List<int>> _makeRandomU8L(int length) {
  List<int> randomInts = [];
  while (randomInts.length < length) {
    randomInts.add(rng.nextInt(255));
  }

  Uint8List uint8list = Uint8List(length);
  for (int i = 0; i < uint8list.length; i++) {
    uint8list..[i] = randomInts[i];
  }

  return [randomInts, uint8list];
}
