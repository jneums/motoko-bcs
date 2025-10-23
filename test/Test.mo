import Bcs "../src/Bcs";
import Uleb "../src/Uleb";
import Debug "mo:base/Debug";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Array "mo:base/Array";
import Iter "mo:base/Iter";

// Test helper functions
func assertEqual<T>(actual : T, expected : T, message : Text) {
  if (actual != expected) {
    Debug.print("FAIL: " # message);
    Debug.print("Expected: " # debug_show (expected));
    Debug.print("Actual: " # debug_show (actual));
    assert (false);
  };
};

func assertArrayEqual(actual : [Nat8], expected : [Nat8], message : Text) {
  if (actual.size() != expected.size()) {
    Debug.print("FAIL: " # message);
    Debug.print("Expected length: " # debug_show (expected.size()));
    Debug.print("Actual length: " # debug_show (actual.size()));
    Debug.print("Expected: " # debug_show (expected));
    Debug.print("Actual: " # debug_show (actual));
    assert (false);
  };

  var i = 0;
  while (i < actual.size()) {
    if (actual[i] != expected[i]) {
      Debug.print("FAIL: " # message);
      Debug.print("Mismatch at index " # debug_show (i));
      Debug.print("Expected: " # debug_show (expected));
      Debug.print("Actual: " # debug_show (actual));
      assert (false);
    };
    i += 1;
  };
};

func testUlebEncoding() {
  Debug.print("Testing ULEB128 encoding...");

  // Test 0
  assertArrayEqual(Uleb.ulebEncode(0), [0], "uleb(0)");

  // Test 1
  assertArrayEqual(Uleb.ulebEncode(1), [1], "uleb(1)");

  // Test 127
  assertArrayEqual(Uleb.ulebEncode(127), [127], "uleb(127)");

  // Test 128
  assertArrayEqual(Uleb.ulebEncode(128), [0x80, 0x01], "uleb(128)");

  // Test 129
  assertArrayEqual(Uleb.ulebEncode(129), [0x81, 0x01], "uleb(129)");

  // Test 255
  assertArrayEqual(Uleb.ulebEncode(255), [0xFF, 0x01], "uleb(255)");

  // Test 300
  assertArrayEqual(Uleb.ulebEncode(300), [0xAC, 0x02], "uleb(300)");

  // Test 16384 (2^14)
  assertArrayEqual(Uleb.ulebEncode(16384), [0x80, 0x80, 0x01], "uleb(16384)");

  // Test 2097152 (2^21)
  assertArrayEqual(Uleb.ulebEncode(2097152), [0x80, 0x80, 0x80, 0x01], "uleb(2097152)");

  Debug.print("✓ ULEB128 encoding tests passed");
};

func testUlebDecoding() {
  Debug.print("Testing ULEB128 decoding...");

  // Test 0
  let r0 = Uleb.ulebDecode([0]);
  assertEqual(r0.value, 0, "uleb decode 0 value");
  assertEqual(r0.length, 1, "uleb decode 0 length");

  // Test 128
  let r128 = Uleb.ulebDecode([0x80, 0x01]);
  assertEqual(r128.value, 128, "uleb decode 128 value");
  assertEqual(r128.length, 2, "uleb decode 128 length");

  // Test 300
  let r300 = Uleb.ulebDecode([0xAC, 0x02]);
  assertEqual(r300.value, 300, "uleb decode 300 value");
  assertEqual(r300.length, 2, "uleb decode 300 length");

  // Test with extra bytes
  let rExtra = Uleb.ulebDecode([0x80, 0x01, 0xFF, 0xFF]);
  assertEqual(rExtra.value, 128, "uleb decode with extra bytes value");
  assertEqual(rExtra.length, 2, "uleb decode with extra bytes length");

  Debug.print("✓ ULEB128 decoding tests passed");
};

func testPrimitivesSerialization() {
  Debug.print("Testing primitive types serialization...");

  // Test u8
  assertArrayEqual(Bcs.serializeU8(255), [255], "u8(255)");
  assertArrayEqual(Bcs.serializeU8(0), [0], "u8(0)");
  assertArrayEqual(Bcs.serializeU8(42), [42], "u8(42)");

  // Test u16 (little-endian)
  assertArrayEqual(Bcs.serializeU16(255), [255, 0], "u16(255)");
  assertArrayEqual(Bcs.serializeU16(256), [0, 1], "u16(256)");
  assertArrayEqual(Bcs.serializeU16(65535), [255, 255], "u16(65535)");

  // Test u32 (little-endian)
  assertArrayEqual(Bcs.serializeU32(4294967295), [255, 255, 255, 255], "u32(4294967295)");
  assertArrayEqual(Bcs.serializeU32(16909060), [4, 3, 2, 1], "u32(16909060)");

  // Test u64 (little-endian)
  assertArrayEqual(
    Bcs.serializeU64(72623859790382856),
    [8, 7, 6, 5, 4, 3, 2, 1],
    "u64(72623859790382856)",
  );

  // Test bool
  assertArrayEqual(Bcs.serializeBool(true), [1], "bool(true)");
  assertArrayEqual(Bcs.serializeBool(false), [0], "bool(false)");

  // Test string
  let strBytes = Bcs.serializeString("a");
  assertArrayEqual(strBytes, [1, 97], "string('a')");

  let strBytes2 = Bcs.serializeString("hello");
  assertArrayEqual(strBytes2, [5, 104, 101, 108, 108, 111], "string('hello')");

  // Test byte vector
  let vecBytes = Bcs.serializeByteVector([1, 2, 3]);
  assertArrayEqual(vecBytes, [3, 1, 2, 3], "byteVector([1, 2, 3])");

  Debug.print("✓ Primitive types serialization tests passed");
};

func testPrimitivesDeserialization() {
  Debug.print("Testing primitive types deserialization...");

  // Test u8
  assertEqual(Bcs.deserializeU8([255]), 255, "deserialize u8(255)");
  assertEqual(Bcs.deserializeU8([42]), 42, "deserialize u8(42)");

  // Test u16
  assertEqual(Bcs.deserializeU16([255, 0]), 255, "deserialize u16(255)");
  assertEqual(Bcs.deserializeU16([0, 1]), 256, "deserialize u16(256)");

  // Test u32
  assertEqual(Bcs.deserializeU32([255, 255, 255, 255]), 4294967295, "deserialize u32(max)");

  // Test u64
  assertEqual(
    Bcs.deserializeU64([8, 7, 6, 5, 4, 3, 2, 1]),
    72623859790382856,
    "deserialize u64",
  );

  // Test bool
  assertEqual(Bcs.deserializeBool([1]), true, "deserialize bool(true)");
  assertEqual(Bcs.deserializeBool([0]), false, "deserialize bool(false)");

  // Test string
  assertEqual(Bcs.deserializeString([1, 97]), "a", "deserialize string('a')");
  assertEqual(
    Bcs.deserializeString([5, 104, 101, 108, 108, 111]),
    "hello",
    "deserialize string('hello')",
  );

  Debug.print("✓ Primitive types deserialization tests passed");
};

func testVectorSerialization() {
  Debug.print("Testing vector serialization...");

  // Test vector of u8
  let vec1 = Bcs.serializeVector<Nat8>([1, 2, 3], Bcs.serializeU8);
  assertArrayEqual(vec1, [3, 1, 2, 3], "vector<u8>([1, 2, 3])");

  // Test empty vector
  let vec2 = Bcs.serializeVector<Nat8>([], Bcs.serializeU8);
  assertArrayEqual(vec2, [0], "vector<u8>([])");

  // Test vector of u32
  let vec3 = Bcs.serializeVector<Nat32>(
    [1, 2],
    Bcs.serializeU32,
  );
  assertArrayEqual(
    vec3,
    [2, 1, 0, 0, 0, 2, 0, 0, 0],
    "vector<u32>([1, 2])",
  );

  Debug.print("✓ Vector serialization tests passed");
};

func testVectorDeserialization() {
  Debug.print("Testing vector deserialization...");

  // Test vector of u8
  let vec1 = Bcs.deserializeVector<Nat8>(
    [3, 1, 2, 3],
    func(reader) { reader.read8() },
  );
  assertArrayEqual(vec1, [1, 2, 3], "deserialize vector<u8>");

  // Test empty vector
  let vec2 = Bcs.deserializeVector<Nat8>(
    [0],
    func(reader) { reader.read8() },
  );
  assertArrayEqual(vec2, [], "deserialize empty vector<u8>");

  Debug.print("✓ Vector deserialization tests passed");
};

func testOptionSerialization() {
  Debug.print("Testing option serialization...");

  // Test None
  let opt1 = Bcs.serializeOption<?Nat8>(null, Bcs.serializeU8);
  assertArrayEqual(opt1, [0], "option<u8>(null)");

  // Test Some
  let opt2 = Bcs.serializeOption<?Nat8>(?42, Bcs.serializeU8);
  assertArrayEqual(opt2, [1, 42], "option<u8>(?42)");

  Debug.print("✓ Option serialization tests passed");
};

func testOptionDeserialization() {
  Debug.print("Testing option deserialization...");

  // Test None
  let opt1 = Bcs.deserializeOption<Nat8>(
    [0],
    func(reader) { reader.read8() },
  );
  assertEqual(opt1, null, "deserialize option<u8>(null)");

  // Test Some
  let opt2 = Bcs.deserializeOption<Nat8>(
    [1, 42],
    func(reader) { reader.read8() },
  );
  assertEqual(opt2, ?42, "deserialize option<u8>(?42)");

  Debug.print("✓ Option deserialization tests passed");
};

func testTupleSerialization() {
  Debug.print("Testing tuple serialization...");

  // Test tuple of (u8, u16)
  let tuple1 = Bcs.serializeTuple2<Nat8, Nat16>(
    (1, 256),
    Bcs.serializeU8,
    Bcs.serializeU16,
  );
  assertArrayEqual(tuple1, [1, 0, 1], "tuple<u8, u16>((1, 256))");

  // Test tuple of (u8, u16, bool)
  let tuple2 = Bcs.serializeTuple3<Nat8, Nat16, Bool>(
    (42, 300, true),
    Bcs.serializeU8,
    Bcs.serializeU16,
    Bcs.serializeBool,
  );
  assertArrayEqual(tuple2, [42, 44, 1, 1], "tuple<u8, u16, bool>((42, 300, true))");

  Debug.print("✓ Tuple serialization tests passed");
};

func testComplexStructure() {
  Debug.print("Testing complex structure serialization...");

  // Simulating a struct: { value: u64, owner: string, is_locked: bool }
  // Expected base64 from Rust: "gNGxBWAAAAAOQmlnIFdhbGxldCBHdXkA"
  // This decodes to bytes representing: value=412412400000, owner="Big Wallet Guy", is_locked=false

  let writer = Bcs.newWriter();

  // Write u64 value (412412400000 = 0x6000B1D180)
  writer.write64(412412400000);

  // Write string "Big Wallet Guy" (length-prefixed)
  writer.writeULEB(14); // length of "Big Wallet Guy"
  let ownerBytes = [66, 105, 103, 32, 87, 97, 108, 108, 101, 116, 32, 71, 117, 121]; // "Big Wallet Guy"
  writer.writeBytes(ownerBytes);

  // Write bool false
  writer.write8(0);

  let bytes = writer.toBytes();

  // Expected bytes from base64 "gNGxBWAAAAAOQmlnIFdhbGxldCBHdXkA"
  let expected : [Nat8] = [
    128,
    209,
    177,
    5,
    96,
    0,
    0,
    0, // u64: 412412400000
    14, // string length
    66,
    105,
    103,
    32,
    87,
    97,
    108,
    108,
    101,
    116,
    32,
    71,
    117,
    121, // "Big Wallet Guy"
    0 // bool: false
  ];

  assertArrayEqual(bytes, expected, "complex struct serialization");

  Debug.print("✓ Complex structure serialization test passed");
};

// Run all tests
Debug.print("\n========================================");
Debug.print("Running BCS Library Tests");
Debug.print("========================================\n");

testUlebEncoding();
testUlebDecoding();
testPrimitivesSerialization();
testPrimitivesDeserialization();
testVectorSerialization();
testVectorDeserialization();
testOptionSerialization();
testOptionDeserialization();
testTupleSerialization();
testComplexStructure();

Debug.print("\n========================================");
Debug.print("All tests passed! ✓");
Debug.print("========================================\n");
