import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Decoder "../src/Decoder";
import Encoder "../src/Encoder";
import Iter "mo:base/Iter";
import Bool "mo:base/Bool";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import Types "../src/Types";

module {
  public func run() {
      // Nat
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7D, 0x00], #nat, #nat(0));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7D, 0x01], #nat, #nat(1));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7D, 0x7F], #nat, #nat(127));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7D, 0xE5, 0x8E, 0x26], #nat, #nat(624485));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7D, 0x80, 0x80, 0x98, 0xF4, 0xE9, 0xB5, 0xCA, 0x6A], #nat, #nat(60000000000000000));

    // Nat8
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7B, 0x00], #nat8, #nat8(0));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7B, 0x10], #nat8, #nat8(16));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7B, 0x63], #nat8, #nat8(99));

    // Nat16
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7A, 0x00, 0x00], #nat16, #nat16(0));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7A, 0x10, 0x00], #nat16, #nat16(16));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7A, 0xE7, 0x03], #nat16, #nat16(999));

    // Nat32
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x79, 0x00, 0x00, 0x00, 0x00], #nat32, #nat32(0));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x79, 0x10, 0x00, 0x00, 0x00], #nat32, #nat32(16));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x79, 0xEA, 0x49, 0x08, 0x00], #nat32, #nat32(543210));
    
    // Nat64
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x78, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], #nat64, #nat64(0));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x78, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], #nat64, #nat64(16));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x78, 0xEA, 0x49, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00], #nat64, #nat64(543210));

    // Int
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7C, 0x00], #int, #int(0));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7C, 0x10], #int, #int(16));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7C, 0x7C], #int, #int(-4));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7C, 0x71], #int, #int(-15));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7C, 0xBC, 0x7F], #int, #int(-68));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7C, 0xE5, 0x8E, 0x26], #int, #int(624485));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7C, 0xC0, 0xBB, 0x78], #int, #int(-123456));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7C, 0x80, 0x01], #int, #int(128));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7C, 0x80, 0x80, 0xE8, 0x8B, 0x96, 0xCA, 0xB5, 0x95, 0x7F], #int, #int(-60000000000000000));

    // Int8
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x77, 0x00], #int8, #int8(0));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x77, 0x10], #int8, #int8(16));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x77, 0x63], #int8, #int8(99));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x77, 0xF1], #int8, #int8(-15));
    
    // Int16
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x76, 0x00, 0x00], #int16, #int16(0));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x76, 0x10, 0x00], #int16, #int16(16));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x76, 0xF1, 0xFF], #int16, #int16(-15));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x76, 0x0F, 0x27], #int16, #int16(9999));

    // Int32
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x75, 0x00, 0x00, 0x00, 0x00], #int32, #int32(0));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x75, 0x10, 0x00, 0x00, 0x00], #int32, #int32(16));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x75, 0xF1, 0xFF, 0xFF, 0xFF], #int32, #int32(-15));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x75, 0xFF, 0xFF, 0x00, 0x00], #int32, #int32(65535));
    
    // Int64
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], #int64, #int64(0));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x74, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], #int64, #int64(16));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x74, 0xF1, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF], #int64, #int64(-15));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x74, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00], #int64, #int64(4294967295));

    // Float32
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x73, 0x00, 0x00, 0x80, 0x3F], #float32, #float32(1.0));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x73, 0x10, 0x06, 0x9E, 0x3F], #float32, #float32(1.23456));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x73, 0xB7, 0xE6, 0xC0, 0xC7], #float32, #float32(-98765.4321));

    // // Float64
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x72, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0x3F], #float64, #float64(1.0));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x72, 0x38, 0x32, 0x8F, 0xFC, 0xC1, 0xC0, 0xF3, 0x3F], #float64, #float64(1.23456));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x72, 0x8A, 0xB0, 0xE1, 0xE9, 0xD6, 0x1C, 0xF8, 0xC0], #float64, #float64(-98765.4321));
    
    // Bool
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7E, 0x01], #bool, #bool(true));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7E, 0x00], #bool, #bool(false));

    // Text
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x71, 0x00], #text, #text(""));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x71, 0x01, 0x41], #text, #text("A"));
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x71, 0x2B, 0x54, 0x68, 0x65, 0x20, 0x71, 0x75, 0x69, 0x63, 0x6B, 0x20, 0x62, 0x72, 0x6F, 0x77, 0x6E, 0x20, 0x66, 0x6F, 0x78, 0x20, 0x6A, 0x75, 0x6D, 0x70, 0x73, 0x20, 0x6F, 0x76, 0x65, 0x72, 0x20, 0x74, 0x68, 0x65, 0x20, 0x6C, 0x61, 0x7A, 0x79, 0x20, 0x64, 0x6F, 0x67], #text, #text("The quick brown fox jumps over the lazy dog"));

    // Null
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x7F], #_null, #_null);

    // Reserved
    test([0x44, 0x49, 0x44, 0x4C, 0x00, 0x01, 0x70], #reserved, #reserved);

    // Opt
    test([0x44, 0x49, 0x44, 0x4C, 0x01, 0x6E, 0x7C, 0x01, 0x00, 0x00], #opt(#int), #opt(null));
    test([0x44, 0x49, 0x44, 0x4C, 0x01, 0x6E, 0x7C, 0x01, 0x00, 0x01, 0x2A], #opt(#int), #opt(?#int(42)));
    test([0x44, 0x49, 0x44, 0x4C, 0x02, 0x6E, 0x7C, 0x6E, 0x00, 0x01, 0x01, 0x01, 0x01, 0x2A], #opt(#opt(#int)), #opt(?#opt(?#int(42))));

    // Vector
    test([0x44, 0x49, 0x44, 0x4C, 0x01, 0x6D, 0x7C, 0x01, 0x00, 0x00], #vector(#int), #vector([]));
    test([0x44, 0x49, 0x44, 0x4C, 0x01, 0x6D, 0x7C, 0x01, 0x00, 0x02, 0x01, 0x02], #vector(#int), #vector([#int(1), #int(2)]));

    // Record
    test([0x44, 0x49, 0x44, 0x4C, 0x01, 0x6C, 0x01, 0x01, 0x7C, 0x01, 0x00, 0x2A], #record([{tag=#hash(1); _type=#int}]), #record([{tag=#hash(1); value=#int(42)}]));
    test([0x44, 0x49, 0x44, 0x4C, 0x01, 0x6C, 0x02, 0x86, 0x8E, 0xB7, 0x02, 0x7C, 0xD3, 0xE3, 0xAA, 0x02, 0x7E, 0x01, 0x00, 0x01, 0x2A], #record([{tag=#name("foo"); _type=#int}, {tag=#name("bar"); _type=#bool}]), #record([{tag=#name("foo"); value=#int(42)}, {tag=#name("bar"); value=#bool(true)}]));
    test(
      [0x44, 0x49, 0x44, 0x4C, 0x02, 0x6E, 0x01, 0x6C, 0x01, 0xA7, 0x8A, 0x83, 0x99, 0x08, 0x00, 0x01, 0x01, 0x01, 0x00],
      #recursiveType({
        id="rec_1";
        _type=#record([
          {
            tag=#name("selfRef");
            _type=#opt(#recursiveReference("rec_1"))
          }
        ])
      }),
      #record([
        {
          tag=#name("selfRef");
          value=#opt(?#record([
            {
              tag=#name("selfRef");
              value=#opt(null)
            }
          ]))
        }
      ])
    );

    // Variant
    test([0x44, 0x49, 0x44, 0x4C, 0x03, 0x6C, 0x05, 0xC4, 0xA7, 0xC9, 0xA1, 0x01, 0x79, 0xDC, 0x8B, 0xD3, 0xF4, 0x01, 0x79, 0x8D, 0x98, 0xF3, 0xE7, 0x04, 0x7C, 0xE2, 0xD8, 0xDE, 0xFB, 0x0B, 0x79, 0x89, 0xFB, 0x97, 0xEB, 0x0E, 0x71, 0x6B, 0x01, 0xCF, 0xA0, 0xDE, 0xF2, 0x06, 0x7F, 0x6B, 0x02, 0x9C, 0xC2, 0x01, 0x00, 0xE5, 0x8E, 0xB4, 0x02, 0x01, 0x01, 0x02, 0x01, 0x00],
      #variant([
        {
          tag=#name("ok");
          _type=#record([
            {
              tag=#name("total");
              _type=#nat32
            },
            {
              tag=#name("desktop");
              _type=#nat32
            },
            {
              tag=#name("time");
              _type=#int
            },
            {
              tag=#name("mobile");
              _type=#nat32
            },
            {
              tag=#name("route");
              _type=#text
            }
          ])
        },
        {
          tag=#name("err");
          _type=#variant([
            {
              tag=#name("NotFound");
              _type=#_null
            }
          ])
        }
      ]),
      #variant({
        tag=#name("err");
        value=#variant({
          tag=#name("NotFound");
          value=#_null
        })
      })
    );

    // Func
    test(
      [],
      #_func({
        modes=[#_query,#oneWay];
        argTypes=#ordered([#int, #opt(#nat)]);
        returnTypes=#ordered([#vector(#int8)]);
      }),
      #_func(#transparent({
        method="ExecuteNNSFunction";
        service=#transparent(Principal.fromText(""))
      }))
    );
    // Service
    test(
      [],
      #service({
        methods=[
          (
            "ExecuteNNSFunction",
            {
              modes=[#_query,#oneWay];
              argTypes=#ordered([#int, #opt(#nat)]);
              returnTypes=#ordered([#vector(#int8)]);
            }
          )
        ]
      }),
      #service(#transparent(Principal.fromText("")))
    );

  };

  private func test(bytes: [Nat8], t : Types.TypeDef, arg: Types.Value) {
    let actualBytes: [Nat8] = Blob.toArray(Encoder.encode([t], [arg]));
    if (not areEqual(bytes, actualBytes)) {
        Debug.trap("Failed Byte Check.\nExpected Bytes: " # toHexString(bytes) # "\nActual Bytes:   " # toHexString(actualBytes) # "\nValue: " # debug_show(arg));
    };
    let args : ?[(Types.Value, Types.TypeDef)] = Decoder.decode(Blob.fromArray(bytes));
    switch(args){
      case (null) {
        Debug.trap("Failed decoding.\nExpected Type: " # debug_show(t) # "\nExpected Value: " # debug_show(arg) # "\nBytes: " # toHexString(bytes))
      };
      case (?args) {
        if (args.size() != 1) {
          Debug.trap("Too many args: " # Nat.toText(args.size()));
        };
        let (actualValue: Types.Value, actualType: Types.TypeDef) = args[0];
        if (not Types.typesAreEqual(t, actualType)) {
          Debug.trap("Failed Type Check.\nExpected Type: " # debug_show(t) # "\nActual Type: " # debug_show(actualType));
        };
        if (not Types.valuesAreEqual(arg, actualValue)) {
          Debug.trap("Failed Value Check.\nExpected Value: " # debug_show(arg) # "\nActual Value: " # debug_show(actualValue));
        };
      }
    };
  };

  private func areEqual(b1: [Nat8], b2: [Nat8]) : Bool {
    if (b1.size() != b2.size()) {
      return false;
    };
    for (i in Iter.range(0, b1.size() - 1)) {
      if (b1[i] != b2[i]) {
          return false;
      };
    };
    true;
  };

  private func toHexString(array : [Nat8]) : Text {
    Array.foldLeft<Nat8, Text>(array, "", func (accum, w8) {
      var pre = "";
      if(accum != ""){
          pre #= ", ";
      };
      accum # pre # encodeW8(w8);
    });
  };
  private let base : Nat8 = 0x10; 

  private let symbols = [
    '0', '1', '2', '3', '4', '5', '6', '7',
    '8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
  ];
  /**
  * Encode an unsigned 8-bit integer in hexadecimal format.
  */
  private func encodeW8(w8 : Nat8) : Text {
    let c1 = symbols[Nat8.toNat(w8 / base)];
    let c2 = symbols[Nat8.toNat(w8 % base)];
    "0x" # Char.toText(c1) # Char.toText(c2);
  };
}