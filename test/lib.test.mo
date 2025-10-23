import Bcs "../src/Bcs";
import Uleb "../src/Uleb";
import Debug "mo:base/Debug";
import Nat8 "mo:base/Nat8";

// Test helper functions
func assertArrayEqual(actual : [Nat8], expected : [Nat8], message : Text) {
  if (actual.size() != expected.size()) {
    Debug.trap("FAIL " # message # ": Expected length " # debug_show (expected.size()) # " but got " # debug_show (actual.size()));
  };

  var i = 0;
  while (i < actual.size()) {
    if (actual[i] != expected[i]) {
      Debug.trap("FAIL " # message # ": Mismatch at index " # debug_show (i) # " - expected " # debug_show (expected[i]) # " but got " # debug_show (actual[i]));
    };
    i += 1;
  };
};

// ULEB128 tests
assertArrayEqual(Uleb.ulebEncode(0), [0], "uleb(0)");
assertArrayEqual(Uleb.ulebEncode(127), [127], "uleb(127)");
assertArrayEqual(Uleb.ulebEncode(128), [0x80, 0x01], "uleb(128)");
assertArrayEqual(Uleb.ulebEncode(300), [0xAC, 0x02], "uleb(300)");

let r128 = Uleb.ulebDecode([0x80, 0x01]);
assert r128.value == 128;
assert r128.length == 2;

// Primitive serialization tests
assertArrayEqual(Bcs.serializeU8(255), [255], "u8(255)");
assertArrayEqual(Bcs.serializeU16(256), [0, 1], "u16(256)");
assertArrayEqual(Bcs.serializeU32(16909060), [4, 3, 2, 1], "u32(16909060)");
assertArrayEqual(Bcs.serializeBool(true), [1], "bool(true)");
assertArrayEqual(Bcs.serializeBool(false), [0], "bool(false)");
assertArrayEqual(Bcs.serializeString("a"), [1, 97], "string('a')");

// Primitive deserialization tests
assert Bcs.deserializeU8([255]) == 255;
assert Bcs.deserializeU16([0, 1]) == 256;
assert Bcs.deserializeU32([4, 3, 2, 1]) == 16909060;
assert Bcs.deserializeBool([1]) == true;
assert Bcs.deserializeBool([0]) == false;
assert Bcs.deserializeString([1, 97]) == "a";

// Vector tests
let vec1 = Bcs.serializeVector<Nat8>([1, 2, 3], Bcs.serializeU8);
assertArrayEqual(vec1, [3, 1, 2, 3], "vector<u8>([1, 2, 3])");

let vec2 = Bcs.deserializeVector<Nat8>([3, 1, 2, 3], func(reader) { reader.read8() });
assertArrayEqual(vec2, [1, 2, 3], "deserialize vector<u8>");

// Option tests
let opt1 : ?Nat8 = null;
assertArrayEqual(Bcs.serializeOption<Nat8>(opt1, Bcs.serializeU8), [0], "option(null)");

let opt2 : ?Nat8 = ?42;
assertArrayEqual(Bcs.serializeOption<Nat8>(opt2, Bcs.serializeU8), [1, 42], "option(?42)");

// Complex structure test (matching TypeScript reference)
let writer = Bcs.newWriter();
writer.write64(412412400000);
writer.writeULEB(14);
writer.writeBytes([66, 105, 103, 32, 87, 97, 108, 108, 101, 116, 32, 71, 117, 121]);
writer.write8(0);

let expected : [Nat8] = [128, 209, 177, 5, 96, 0, 0, 0, 14, 66, 105, 103, 32, 87, 97, 108, 108, 101, 116, 32, 71, 117, 121, 0];
assertArrayEqual(writer.toBytes(), expected, "complex struct");

Debug.print("All BCS tests passed!");
