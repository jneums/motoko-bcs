// Comprehensive BCS test cases with expected byte arrays from TypeScript reference
import Bcs "../src/Bcs";
import Uleb "../src/Uleb";
import Debug "mo:base/Debug";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Text "mo:base/Text";

// ============================================================================
// TEST HELPERS
// ============================================================================

func assertArrayEqual(actual : [Nat8], expected : [Nat8], testName : Text) {
  if (actual.size() != expected.size()) {
    Debug.print("❌ FAIL: " # testName);
    Debug.print("  Expected length: " # debug_show (expected.size()));
    Debug.print("  Actual length:   " # debug_show (actual.size()));
    Debug.print("  Expected bytes:  " # debug_show (expected));
    Debug.print("  Actual bytes:    " # debug_show (actual));
    assert (false);
  };

  var i = 0;
  while (i < actual.size()) {
    if (actual[i] != expected[i]) {
      Debug.print("❌ FAIL: " # testName);
      Debug.print("  Mismatch at index " # debug_show (i));
      Debug.print("  Expected byte: " # debug_show (expected[i]));
      Debug.print("  Actual byte:   " # debug_show (actual[i]));
      Debug.print("  Expected bytes: " # debug_show (expected));
      Debug.print("  Actual bytes:   " # debug_show (actual));
      assert (false);
    };
    i += 1;
  };
  Debug.print("✅ PASS: " # testName);
};

func assertEqualNat(actual : Nat, expected : Nat, testName : Text) {
  if (actual != expected) {
    Debug.print("❌ FAIL: " # testName);
    Debug.print("  Expected: " # debug_show (expected));
    Debug.print("  Actual:   " # debug_show (actual));
    assert (false);
  };
  Debug.print("✅ PASS: " # testName);
};

func assertEqualBool(actual : Bool, expected : Bool, testName : Text) {
  if (actual != expected) {
    Debug.print("❌ FAIL: " # testName);
    Debug.print("  Expected: " # debug_show (expected));
    Debug.print("  Actual:   " # debug_show (actual));
    assert (false);
  };
  Debug.print("✅ PASS: " # testName);
};

func assertEqualText(actual : Text, expected : Text, testName : Text) {
  if (actual != expected) {
    Debug.print("❌ FAIL: " # testName);
    Debug.print("  Expected: " # debug_show (expected));
    Debug.print("  Actual:   " # debug_show (actual));
    assert (false);
  };
  Debug.print("✅ PASS: " # testName);
};

func assertEqualOptNat8(actual : ?Nat8, expected : ?Nat8, testName : Text) {
  if (actual != expected) {
    Debug.print("❌ FAIL: " # testName);
    Debug.print("  Expected: " # debug_show (expected));
    Debug.print("  Actual:   " # debug_show (actual));
    assert (false);
  };
  Debug.print("✅ PASS: " # testName);
};

// ============================================================================
// ULEB128 COMPREHENSIVE TESTS
// ============================================================================

func testUlebComprehensive() {
  Debug.print("\n=== ULEB128 Encoding Tests ===");

  // Single byte values (0-127)
  assertArrayEqual(Uleb.ulebEncode(0), [0], "uleb(0)");
  assertArrayEqual(Uleb.ulebEncode(1), [1], "uleb(1)");
  assertArrayEqual(Uleb.ulebEncode(127), [127], "uleb(127)");

  // Two byte values (128-16383)
  assertArrayEqual(Uleb.ulebEncode(128), [0x80, 0x01], "uleb(128)");
  assertArrayEqual(Uleb.ulebEncode(129), [0x81, 0x01], "uleb(129)");
  assertArrayEqual(Uleb.ulebEncode(255), [0xFF, 0x01], "uleb(255)");
  assertArrayEqual(Uleb.ulebEncode(300), [0xAC, 0x02], "uleb(300)");
  assertArrayEqual(Uleb.ulebEncode(16383), [0xFF, 0x7F], "uleb(16383)");

  // Three byte values
  assertArrayEqual(Uleb.ulebEncode(16384), [0x80, 0x80, 0x01], "uleb(16384)");

  // Four byte values
  assertArrayEqual(Uleb.ulebEncode(2097152), [0x80, 0x80, 0x80, 0x01], "uleb(2097152)");

  // Five byte values
  assertArrayEqual(Uleb.ulebEncode(2147483648), [0x80, 0x80, 0x80, 0x80, 0x08], "uleb(2^31)");
  assertArrayEqual(Uleb.ulebEncode(4294967295), [0xFF, 0xFF, 0xFF, 0xFF, 0x0F], "uleb(2^32-1)");
  assertArrayEqual(Uleb.ulebEncode(4294967296), [0x80, 0x80, 0x80, 0x80, 0x10], "uleb(2^32)");

  Debug.print("\n=== ULEB128 Decoding Tests ===");

  // Decode tests
  let d0 = Uleb.ulebDecode([0]);
  assertEqualNat(d0.value, 0, "decode uleb(0) value");
  assertEqualNat(d0.length, 1, "decode uleb(0) length");

  let d128 = Uleb.ulebDecode([0x80, 0x01]);
  assertEqualNat(d128.value, 128, "decode uleb(128) value");
  assertEqualNat(d128.length, 2, "decode uleb(128) length");

  let d300 = Uleb.ulebDecode([0xAC, 0x02]);
  assertEqualNat(d300.value, 300, "decode uleb(300) value");
  assertEqualNat(d300.length, 2, "decode uleb(300) length");

  // Decode with extra bytes (should only consume what's needed)
  let dExtra = Uleb.ulebDecode([0x80, 0x01, 0xFF, 0xFF, 0xFF]);
  assertEqualNat(dExtra.value, 128, "decode uleb with extra bytes value");
  assertEqualNat(dExtra.length, 2, "decode uleb with extra bytes length");
};

// ============================================================================
// PRIMITIVE TYPES COMPREHENSIVE TESTS
// ============================================================================

func testPrimitivesComprehensive() {
  Debug.print("\n=== Primitive Type Serialization Tests ===");

  // u8 tests
  assertArrayEqual(Bcs.serializeU8(0), [0], "u8(0)");
  assertArrayEqual(Bcs.serializeU8(1), [1], "u8(1)");
  assertArrayEqual(Bcs.serializeU8(127), [127], "u8(127)");
  assertArrayEqual(Bcs.serializeU8(128), [128], "u8(128)");
  assertArrayEqual(Bcs.serializeU8(255), [255], "u8(255)");

  // u16 tests (little-endian)
  assertArrayEqual(Bcs.serializeU16(0), [0, 0], "u16(0)");
  assertArrayEqual(Bcs.serializeU16(1), [1, 0], "u16(1)");
  assertArrayEqual(Bcs.serializeU16(255), [255, 0], "u16(255)");
  assertArrayEqual(Bcs.serializeU16(256), [0, 1], "u16(256)");
  assertArrayEqual(Bcs.serializeU16(257), [1, 1], "u16(257)");
  assertArrayEqual(Bcs.serializeU16(65535), [255, 255], "u16(65535)");

  // u32 tests (little-endian)
  assertArrayEqual(Bcs.serializeU32(0), [0, 0, 0, 0], "u32(0)");
  assertArrayEqual(Bcs.serializeU32(1), [1, 0, 0, 0], "u32(1)");
  assertArrayEqual(Bcs.serializeU32(255), [255, 0, 0, 0], "u32(255)");
  assertArrayEqual(Bcs.serializeU32(256), [0, 1, 0, 0], "u32(256)");
  assertArrayEqual(Bcs.serializeU32(65536), [0, 0, 1, 0], "u32(65536)");
  assertArrayEqual(Bcs.serializeU32(16909060), [4, 3, 2, 1], "u32(16909060)");
  assertArrayEqual(Bcs.serializeU32(4294967295), [255, 255, 255, 255], "u32(2^32-1)");

  // u64 tests (little-endian)
  assertArrayEqual(Bcs.serializeU64(0), [0, 0, 0, 0, 0, 0, 0, 0], "u64(0)");
  assertArrayEqual(Bcs.serializeU64(1), [1, 0, 0, 0, 0, 0, 0, 0], "u64(1)");
  assertArrayEqual(Bcs.serializeU64(255), [255, 0, 0, 0, 0, 0, 0, 0], "u64(255)");
  assertArrayEqual(Bcs.serializeU64(256), [0, 1, 0, 0, 0, 0, 0, 0], "u64(256)");
  assertArrayEqual(
    Bcs.serializeU64(72623859790382856),
    [8, 7, 6, 5, 4, 3, 2, 1],
    "u64(72623859790382856)",
  );

  // u128 tests
  assertArrayEqual(
    Bcs.serializeU128(0),
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    "u128(0)",
  );
  assertArrayEqual(
    Bcs.serializeU128(1),
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    "u128(1)",
  );
  assertArrayEqual(
    Bcs.serializeU128(255),
    [255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    "u128(255)",
  );

  // u256 tests
  assertArrayEqual(
    Bcs.serializeU256(0),
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    "u256(0)",
  );
  assertArrayEqual(
    Bcs.serializeU256(1),
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    "u256(1)",
  );

  // bool tests
  assertArrayEqual(Bcs.serializeBool(false), [0], "bool(false)");
  assertArrayEqual(Bcs.serializeBool(true), [1], "bool(true)");

  // string tests
  assertArrayEqual(Bcs.serializeString(""), [0], "string('')");
  assertArrayEqual(Bcs.serializeString("a"), [1, 97], "string('a')");
  assertArrayEqual(Bcs.serializeString("ab"), [2, 97, 98], "string('ab')");
  assertArrayEqual(Bcs.serializeString("hello"), [5, 104, 101, 108, 108, 111], "string('hello')");
  assertArrayEqual(
    Bcs.serializeString("Big Wallet Guy"),
    [14, 66, 105, 103, 32, 87, 97, 108, 108, 101, 116, 32, 71, 117, 121],
    "string('Big Wallet Guy')",
  );

  // byte vector tests
  assertArrayEqual(Bcs.serializeByteVector([]), [0], "byteVector([])");
  assertArrayEqual(Bcs.serializeByteVector([1]), [1, 1], "byteVector([1])");
  assertArrayEqual(Bcs.serializeByteVector([1, 2, 3]), [3, 1, 2, 3], "byteVector([1,2,3])");
};

// ============================================================================
// VECTOR COMPREHENSIVE TESTS
// ============================================================================

func testVectorsComprehensive() {
  Debug.print("\n=== Vector Serialization Tests ===");

  // Empty vectors
  assertArrayEqual(
    Bcs.serializeVector<Nat8>([], Bcs.serializeU8),
    [0],
    "vector<u8>([])"
  );

  // Single element vectors
  assertArrayEqual(
    Bcs.serializeVector<Nat8>([42], Bcs.serializeU8),
    [1, 42],
    "vector<u8>([42])",
  );

  // Multiple element vectors
  assertArrayEqual(
    Bcs.serializeVector<Nat8>([1, 2, 3], Bcs.serializeU8),
    [3, 1, 2, 3],
    "vector<u8>([1,2,3])",
  );

  assertArrayEqual(
    Bcs.serializeVector<Nat8>([1, 2, 3, 4, 5], Bcs.serializeU8),
    [5, 1, 2, 3, 4, 5],
    "vector<u8>([1,2,3,4,5])",
  );

  // Vector of u16
  assertArrayEqual(
    Bcs.serializeVector<Nat16>([1, 2], Bcs.serializeU16),
    [2, 1, 0, 2, 0],
    "vector<u16>([1,2])",
  );

  // Vector of u32
  assertArrayEqual(
    Bcs.serializeVector<Nat32>([1, 2], Bcs.serializeU32),
    [2, 1, 0, 0, 0, 2, 0, 0, 0],
    "vector<u32>([1,2])",
  );

  // Vector of u64
  assertArrayEqual(
    Bcs.serializeVector<Nat64>([1, 2], Bcs.serializeU64),
    [2, 1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0],
    "vector<u64>([1,2])",
  );

  // Vector of bools
  assertArrayEqual(
    Bcs.serializeVector<Bool>([true, false, true], Bcs.serializeBool),
    [3, 1, 0, 1],
    "vector<bool>([true,false,true])",
  );

  // Nested vector (vector of vectors)
  // When serializing vector of vectors, each inner vector gets its own length prefix
  // Format: outer_length, inner1_length, inner1_data..., inner2_length, inner2_data...
  assertArrayEqual(
    Bcs.serializeVector<[Nat8]>([[1, 2], [3, 4]], Bcs.serializeByteVector),
    [2, 2, 1, 2, 2, 3, 4],
    "vector<vector<u8>>([[1,2],[3,4]])"
  );
};

// ============================================================================
// OPTION COMPREHENSIVE TESTS
// ============================================================================

func testOptionsComprehensive() {
  Debug.print("\n=== Option Serialization Tests ===");

  // None variants
  let none8 : ?Nat8 = null;
  assertArrayEqual(Bcs.serializeOption<Nat8>(none8, Bcs.serializeU8), [0], "option<u8>(None)");

  let none16 : ?Nat16 = null;
  assertArrayEqual(Bcs.serializeOption<Nat16>(none16, Bcs.serializeU16), [0], "option<u16>(None)");

  let none32 : ?Nat32 = null;
  assertArrayEqual(Bcs.serializeOption<Nat32>(none32, Bcs.serializeU32), [0], "option<u32>(None)");

  // Some variants with u8
  let some8 : ?Nat8 = ?0;
  assertArrayEqual(Bcs.serializeOption<Nat8>(some8, Bcs.serializeU8), [1, 0], "option<u8>(Some(0))");

  let some8_42 : ?Nat8 = ?42;
  assertArrayEqual(Bcs.serializeOption<Nat8>(some8_42, Bcs.serializeU8), [1, 42], "option<u8>(Some(42))");

  let some8_255 : ?Nat8 = ?255;
  assertArrayEqual(Bcs.serializeOption<Nat8>(some8_255, Bcs.serializeU8), [1, 255], "option<u8>(Some(255))");

  // Some variants with u16
  let some16 : ?Nat16 = ?256;
  assertArrayEqual(Bcs.serializeOption<Nat16>(some16, Bcs.serializeU16), [1, 0, 1], "option<u16>(Some(256))");

  // Some variants with u32
  let some32 : ?Nat32 = ?1000;
  assertArrayEqual(Bcs.serializeOption<Nat32>(some32, Bcs.serializeU32), [1, 232, 3, 0, 0], "option<u32>(Some(1000))");

  // Some variants with bool
  let someBoolT : ?Bool = ?true;
  assertArrayEqual(Bcs.serializeOption<Bool>(someBoolT, Bcs.serializeBool), [1, 1], "option<bool>(Some(true))");

  let someBoolF : ?Bool = ?false;
  assertArrayEqual(Bcs.serializeOption<Bool>(someBoolF, Bcs.serializeBool), [1, 0], "option<bool>(Some(false))");
};

// ============================================================================
// TUPLE COMPREHENSIVE TESTS
// ============================================================================

func testTuplesComprehensive() {
  Debug.print("\n=== Tuple Serialization Tests ===");

  // Tuple2 tests
  assertArrayEqual(
    Bcs.serializeTuple2<Nat8, Nat8>((1, 2), Bcs.serializeU8, Bcs.serializeU8),
    [1, 2],
    "tuple<u8,u8>((1,2))",
  );

  assertArrayEqual(
    Bcs.serializeTuple2<Nat8, Nat16>((1, 256), Bcs.serializeU8, Bcs.serializeU16),
    [1, 0, 1],
    "tuple<u8,u16>((1,256))",
  );

  assertArrayEqual(
    Bcs.serializeTuple2<Nat16, Nat32>((256, 65536), Bcs.serializeU16, Bcs.serializeU32),
    [0, 1, 0, 0, 1, 0],
    "tuple<u16,u32>((256,65536))",
  );

  assertArrayEqual(
    Bcs.serializeTuple2<Bool, Nat8>((true, 42), Bcs.serializeBool, Bcs.serializeU8),
    [1, 42],
    "tuple<bool,u8>((true,42))",
  );

  // Tuple3 tests
  assertArrayEqual(
    Bcs.serializeTuple3<Nat8, Nat8, Nat8>((1, 2, 3), Bcs.serializeU8, Bcs.serializeU8, Bcs.serializeU8),
    [1, 2, 3],
    "tuple<u8,u8,u8>((1,2,3))",
  );

  assertArrayEqual(
    Bcs.serializeTuple3<Nat8, Nat16, Bool>((42, 300, true), Bcs.serializeU8, Bcs.serializeU16, Bcs.serializeBool),
    [42, 44, 1, 1],
    "tuple<u8,u16,bool>((42,300,true))",
  );

  assertArrayEqual(
    Bcs.serializeTuple3<Bool, Bool, Bool>((true, false, true), Bcs.serializeBool, Bcs.serializeBool, Bcs.serializeBool),
    [1, 0, 1],
    "tuple<bool,bool,bool>((true,false,true))",
  );
};

// ============================================================================
// COMPLEX STRUCT TESTS (Matching TypeScript Examples)
// ============================================================================

func testComplexStructs() {
  Debug.print("\n=== Complex Structure Tests ===");

  // Test 1: Coin struct from TypeScript test
  // struct Coin { value: u64, owner: string, is_locked: bool }
  // Expected base64: "gNGxBWAAAAAOQmlnIFdhbGxldCBHdXkA"
  let writer1 = Bcs.newWriter();
  writer1.write64(412412400000); // value
  writer1.writeULEB(14); // string length
  writer1.writeBytes([66, 105, 103, 32, 87, 97, 108, 108, 101, 116, 32, 71, 117, 121]); // "Big Wallet Guy"
  writer1.write8(0); // is_locked = false

  let expected1 : [Nat8] = [
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
  assertArrayEqual(writer1.toBytes(), expected1, "Coin struct");

  // Test 2: Nested struct with vector
  let writer2 = Bcs.newWriter();
  writer2.write8(1); // id
  writer2.writeULEB(3); // vector length
  writer2.write32(100);
  writer2.write32(200);
  writer2.write32(300);

  let expected2 : [Nat8] = [
    1, // id
    3, // vector length
    100,
    0,
    0,
    0, // 100
    200,
    0,
    0,
    0, // 200
    44,
    1,
    0,
    0 // 300
  ];
  assertArrayEqual(writer2.toBytes(), expected2, "Nested struct with vector");

  // Test 3: Struct with option field
  let writer3 = Bcs.newWriter();
  writer3.write32(42);
  writer3.write8(1); // Some variant
  writer3.write64(999);

  let expected3 : [Nat8] = [
    42,
    0,
    0,
    0, // u32: 42
    1, // Some
    231,
    3,
    0,
    0,
    0,
    0,
    0,
    0 // u64: 999
  ];
  assertArrayEqual(writer3.toBytes(), expected3, "Struct with option field");
};

// ============================================================================
// DESERIALIZATION ROUND-TRIP TESTS
// ============================================================================

func testDeserializationRoundTrips() {
  Debug.print("\n=== Deserialization Round-Trip Tests ===");

  // u8 round-trips
  assertEqualNat(Nat8.toNat(Bcs.deserializeU8(Bcs.serializeU8(0))), 0, "u8(0) round-trip");
  assertEqualNat(Nat8.toNat(Bcs.deserializeU8(Bcs.serializeU8(127))), 127, "u8(127) round-trip");
  assertEqualNat(Nat8.toNat(Bcs.deserializeU8(Bcs.serializeU8(255))), 255, "u8(255) round-trip");

  // u16 round-trips
  assertEqualNat(Nat16.toNat(Bcs.deserializeU16(Bcs.serializeU16(0))), 0, "u16(0) round-trip");
  assertEqualNat(Nat16.toNat(Bcs.deserializeU16(Bcs.serializeU16(256))), 256, "u16(256) round-trip");
  assertEqualNat(Nat16.toNat(Bcs.deserializeU16(Bcs.serializeU16(65535))), 65535, "u16(65535) round-trip");

  // u32 round-trips
  assertEqualNat(Nat32.toNat(Bcs.deserializeU32(Bcs.serializeU32(0))), 0, "u32(0) round-trip");
  assertEqualNat(Nat32.toNat(Bcs.deserializeU32(Bcs.serializeU32(16909060))), 16909060, "u32(16909060) round-trip");
  assertEqualNat(Nat32.toNat(Bcs.deserializeU32(Bcs.serializeU32(4294967295))), 4294967295, "u32(max) round-trip");

  // u64 round-trips
  assertEqualNat(Nat64.toNat(Bcs.deserializeU64(Bcs.serializeU64(0))), 0, "u64(0) round-trip");
  assertEqualNat(Nat64.toNat(Bcs.deserializeU64(Bcs.serializeU64(1000000))), 1000000, "u64(1000000) round-trip");

  // bool round-trips
  assertEqualBool(Bcs.deserializeBool(Bcs.serializeBool(true)), true, "bool(true) round-trip");
  assertEqualBool(Bcs.deserializeBool(Bcs.serializeBool(false)), false, "bool(false) round-trip");

  // string round-trips
  assertEqualText(Bcs.deserializeString(Bcs.serializeString("")), "", "string('') round-trip");
  assertEqualText(Bcs.deserializeString(Bcs.serializeString("a")), "a", "string('a') round-trip");
  assertEqualText(Bcs.deserializeString(Bcs.serializeString("hello")), "hello", "string('hello') round-trip");
  assertEqualText(
    Bcs.deserializeString(Bcs.serializeString("Big Wallet Guy")),
    "Big Wallet Guy",
    "string('Big Wallet Guy') round-trip",
  );

  // vector round-trips
  let vec1 = Bcs.deserializeVector<Nat8>(
    Bcs.serializeVector<Nat8>([1, 2, 3], Bcs.serializeU8),
    func(r) { r.read8() },
  );
  assertArrayEqual(vec1, [1, 2, 3], "vector<u8> round-trip");

  let vec2 = Bcs.deserializeVector<Nat8>(
    Bcs.serializeVector<Nat8>([], Bcs.serializeU8),
    func(r) { r.read8() },
  );
  assertArrayEqual(vec2, [], "empty vector<u8> round-trip");

  // option round-trips
  let opt1 : ?Nat8 = null;
  let opt1Result = Bcs.deserializeOption<Nat8>(
    Bcs.serializeOption<Nat8>(opt1, Bcs.serializeU8),
    func(r) { r.read8() },
  );
  assertEqualOptNat8(opt1Result, null, "option<u8>(None) round-trip");

  let opt2 : ?Nat8 = ?42;
  let opt2Result = Bcs.deserializeOption<Nat8>(
    Bcs.serializeOption<Nat8>(opt2, Bcs.serializeU8),
    func(r) { r.read8() },
  );
  assertEqualOptNat8(opt2Result, ?42, "option<u8>(Some(42)) round-trip");
};

// ============================================================================
// MAIN TEST RUNNER
// ============================================================================

Debug.print("\n╔════════════════════════════════════════════════════════════════╗");
Debug.print("║  BCS Comprehensive Test Suite                                  ║");
Debug.print("║  Testing byte-for-byte parity with TypeScript implementation  ║");
Debug.print("╚════════════════════════════════════════════════════════════════╝");

testUlebComprehensive();
testPrimitivesComprehensive();
testVectorsComprehensive();
testOptionsComprehensive();
testTuplesComprehensive();
testComplexStructs();
testDeserializationRoundTrips();

Debug.print("\n╔════════════════════════════════════════════════════════════════╗");
Debug.print("║  ✅ ALL COMPREHENSIVE TESTS PASSED!                           ║");
Debug.print("║  Motoko BCS implementation verified byte-for-byte compatible  ║");
Debug.print("╚════════════════════════════════════════════════════════════════╝\n");
