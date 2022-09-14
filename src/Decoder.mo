import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import FloatX "mo:xtendedNumbers/FloatX";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import IntX "mo:xtendedNumbers/IntX";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import NatX "mo:xtendedNumbers/NatX";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";
import TrieSet "mo:base/TrieSet";
import Value "./Value";
import Type "./Type";
import Tag "./Tag";
import InternalTypes "./InternalTypes";
import TransparencyState "./TransparencyState";
import FuncMode "./FuncMode";
import Arg "./Arg";

module {

  type ShallowCompoundType<T> = InternalTypes.ShallowCompoundType<T>;
  type Tag = Tag.Tag;
  type ReferenceType = InternalTypes.ReferenceType;

  public func decode(candidBytes: Blob) : ?[Arg.Arg] {
    do ? {
      let bytes : Iter.Iter<Nat8> = Iter.fromArray(Blob.toArray(candidBytes));
      let prefix1: Nat8 = bytes.next()!;
      let prefix2: Nat8 = bytes.next()!;
      let prefix3: Nat8 = bytes.next()!;
      let prefix4: Nat8 = bytes.next()!;

      // Check "DIDL" prefix
      if ((prefix1, prefix2, prefix3, prefix4) != (0x44, 0x49, 0x44, 0x4c)) {
        return null;
      };
      let (compoundTypes: [ShallowCompoundType<ReferenceType>], argTypes: [Int]) = decodeTypes(bytes)!;
      let types : [Type.Type] = buildTypes(compoundTypes, argTypes)!;
      let values: [Value.Value] = decodeValues(bytes, types)!;
      var i = 0;
      let valueTypes = Buffer.Buffer<Arg.Arg>(types.size());
      for (t in Iter.fromArray(types)) {
        let v = values[i];
        valueTypes.add({value=v; _type=t});
        i += 1;
      };
      valueTypes.toArray();
    };
  };

  private func decodeValues(bytes: Iter.Iter<Nat8>, types: [Type.Type]) : ?[Value.Value] {
    do ? {
      let valueBuffer = Buffer.Buffer<Value.Value>(types.size());
      let referencedTypes = TrieMap.TrieMap<Text, Type.Type>(Text.equal, Text.hash);
      for (t in Iter.fromArray(types)) {
        addReferenceTypes(t, referencedTypes);
      };
      for (t in Iter.fromArray(types)) {
        let v = decodeValue(bytes, t, referencedTypes)!;
        valueBuffer.add(v);
      };
      valueBuffer.toArray();
    };
  };

  private func addReferenceTypes(t: Type.Type, referencedTypes: TrieMap.TrieMap<Text, Type.Type>) {
    switch (t) {
      case (#opt(o)) {
        addReferenceTypes(o, referencedTypes);
      };
      case (#variant(options)) {
        for (option in Iter.fromArray(options)) {
          addReferenceTypes(option._type, referencedTypes);
        };
      };
      case (#record(fields)) {
        for (field in Iter.fromArray(fields)) {
          addReferenceTypes(field._type, referencedTypes);
        };
      };
      case (#recursiveType(rT)) {
        referencedTypes.put(rT.id, rT._type);
        addReferenceTypes(rT._type, referencedTypes)
      };
      case (_) {};
    }
  };

  private func decodeValue(bytes: Iter.Iter<Nat8>, t: Type.Type, referencedTypes: TrieMap.TrieMap<Text, Type.Type>) : ?Value.Value {
    do ? {
      switch (t) {
        case (#int) #int(IntX.decodeInt(bytes, #signedLEB128)!);
        case (#int8) #int8(IntX.decodeInt8(bytes, #lsb)!);
        case (#int16) #int16(IntX.decodeInt16(bytes, #lsb)!);
        case (#int32) #int32(IntX.decodeInt32(bytes, #lsb)!);
        case (#int64) #int64(IntX.decodeInt64(bytes, #lsb)!);
        case (#nat) #nat(NatX.decodeNat(bytes, #unsignedLEB128)!);
        case (#nat8) #nat8(NatX.decodeNat8(bytes, #lsb)!);
        case (#nat16) #nat16(NatX.decodeNat16(bytes, #lsb)!);
        case (#nat32) #nat32(NatX.decodeNat32(bytes, #lsb)!);
        case (#nat64) #nat64(NatX.decodeNat64(bytes, #lsb)!);
        case (#_null) #_null;
        case (#bool) {
          let nextByte: Nat8 = bytes.next()!;
          #bool(nextByte != 0x00);
        };
        case (#float32) {
          let fX = FloatX.decode(bytes, #f32, #lsb)!;
          let f = FloatX.toFloat(fX);
          #float32(f);
        };
        case (#float64) {
          let fX = FloatX.decode(bytes, #f64, #lsb)!;
          let f = FloatX.toFloat(fX);
          #float64(f);
        };
        case (#text) {
          let t: Text = decodeText(bytes)!;
          #text(t);
        };
        case (#reserved) #reserved;
        case (#empty) #empty;
        case (#principal) {
          let p: TransparencyState.TransparencyState<Principal> = decodeReference(bytes, decodePrincipal)!;
          #principal(p);
        };
        case (#opt(o)) {
          let optionalByte = bytes.next()!;
          switch (optionalByte) {
            case (0x00) #opt(null);
            case (0x01) {
              let innerType: Type.Type = switch (t) {
                case (#opt(o)) o;
                case (_) return null; // type definition doesnt match
              };
              let v = decodeValue(bytes, innerType, referencedTypes)!;
              #opt(?v);
            };
            case (_) return null;
          };
        };
        case (#vector(v)) {
          let length : Nat = NatX.decodeNat(bytes, #unsignedLEB128)!;
          let buffer = Buffer.Buffer<Value.Value>(length);
          let innerType: Type.Type = switch (t) {
            case (#vector(vv)) vv;
            case (_) return null; // type definition doesnt match
          };
          for (i in Iter.range(0, length - 1)) {
            let innerValue: Value.Value = decodeValue(bytes, innerType, referencedTypes)!;
            buffer.add(innerValue);
          };
          #vector(buffer.toArray());
        };
        case (#record(r)) {
          let innerTypes: [Type.RecordFieldType] = switch (t) {
            case (#record(vv)) Array.sort(vv, InternalTypes.tagObjCompare); // Order fields by tag
            case (_) return null; // type definition doesnt match
          };
          let buffer = Buffer.Buffer<Value.RecordFieldValue>(innerTypes.size());
          for (innerType in Iter.fromArray(innerTypes)) {
            let innerValue: Value.Value = decodeValue(bytes, innerType._type, referencedTypes)!;
            buffer.add({tag=innerType.tag; value=innerValue});
          };
          #record(buffer.toArray());
        };
        case (#_func(f)) {
          let f = decodeReference(bytes, decodeFunc)!;
          #_func(f);
        };
        case (#service(s)) {
          let principal: TransparencyState.TransparencyState<Principal> = decodeReference(bytes, decodePrincipal)!;
          #service(principal);
        };
        case (#variant(v)) {
          let innerTypes: [Type.VariantOptionType] = switch (t) {
            case (#variant(vv)) Array.sort(vv, InternalTypes.tagObjCompare); // Order fields by tag
            case (_) return null; // type definition doesnt match
          };
          let optionIndex = NatX.decodeNat(bytes, #unsignedLEB128)!; // Get index of option chosen
          let innerType: Type.VariantOptionType = innerTypes[optionIndex];
          let innerValue: Value.Value = decodeValue(bytes, innerType._type, referencedTypes)!; // Get value of option chosen
          #variant({tag=innerType.tag; value=innerValue});
        };
        case (#recursiveType(rT)) {
          decodeValue(bytes, rT._type, referencedTypes)!;
        };
        case (#recursiveReference(rI)) {
          let rType: Type.Type = referencedTypes.get(rI)!;
          decodeValue(bytes, rType, referencedTypes)!;
        };
      };
    };
  };

  private func decodeFunc(bytes: Iter.Iter<Nat8>): ?Value.Func {
    do ? {
      let service = decodeReference(bytes, decodePrincipal)!;
      let methodName = decodeText(bytes)!;
      { service=service; method=methodName; }
    }
  };

  private func decodePrincipal(bytes: Iter.Iter<Nat8>) : ?Principal {
    do ? {
      let length : Nat = NatX.decodeNat(bytes, #unsignedLEB128)!;
      let principalBytes = takeBytes(bytes, length)!;
      Principal.fromBlob(Blob.fromArray(principalBytes));
    }
  };

  private func decodeReference<T>(bytes: Iter.Iter<Nat8>, innerDecode: (Iter.Iter<Nat8>) -> ?T) : ?TransparencyState.TransparencyState<T> {
    do ? {
      let transparentByte = bytes.next()!;
      switch (transparentByte) {
        case (0x00) #opaque;
        case (0x01) {
          let v: T = innerDecode(bytes)!;
          #transparent(v);
        };
        case (_) return null;
      };
    }
  };

  private func decodeText(bytes: Iter.Iter<Nat8>) : ?Text {
    do ? {
      let length : Nat = NatX.decodeNat(bytes, #unsignedLEB128)!;
      let textBytes: [Nat8] = takeBytes(bytes, length)!; 
      Text.decodeUtf8(Blob.fromArray(textBytes))!;
    };
  };

  private func takeBytes(bytes: Iter.Iter<Nat8>, length: Nat) : ?[Nat8] {
    do ? {
      let buffer = Buffer.Buffer<Nat8>(length);
      for (i in Iter.range(0, length - 1)) {
        buffer.add(bytes.next()!);
      };
      buffer.toArray();
    }
  };

  private func buildTypes(compoundTypes: [ShallowCompoundType<ReferenceType>], argTypes: [Int]) : ?[Type.Type] {
    do ? {
      let types = Buffer.Buffer<Type.Type>(argTypes.size());
      for (argType in Iter.fromArray(argTypes)) {
        let t: Type.Type = buildType(argType, compoundTypes, TrieMap.TrieMap<Nat, (Text, Bool)>(Nat.equal, hashNat))!;
        types.add(t);
      };
      types.toArray();
    }
  };

  private func hashNat(n: Nat) : Hash.Hash {
    Nat32.fromIntWrap(n) // Convert to Nat32 with overflow
  };

  private func buildType(indexOrCode: Int, compoundTypes: [ShallowCompoundType<ReferenceType>], parentTypes: TrieMap.TrieMap<Nat, (Text, Bool)>) : ?Type.Type {
    do ? {
      switch (indexOrCode) {
        case (-1) #_null;
        case (-2) #bool;
        case (-3) #nat;
        case (-4) #int;
        case (-5) #nat8;
        case (-6) #nat16;
        case (-7) #nat32;
        case (-8) #nat64;
        case (-9) #int8;
        case (-10) #int16;
        case (-11) #int32;
        case (-12) #int64;
        case (-13) #float32;
        case (-14) #float64;
        case (-15) #text;
        case (-16) #reserved;
        case (-17) #empty;
        case (-24) #principal;
        case (i) {
          if (i < 0) {
            return null; // Invalid, all negatives are listed
          };
          // Positives are indices for compound types
          let index: Nat = Int.abs(indexOrCode);


          
          // Check to see if a parent type is being referenced (cycle)
          switch (parentTypes.get(index)) {
            case (null) ();
            case (?recursiveId) {
              parentTypes.put(index, (recursiveId.0, true));
              return ?#recursiveReference(recursiveId.0); // Stop and return recursive reference
            };
          };

          let recursiveId = "μ" # Nat.toText(index);
          parentTypes.put(index, (recursiveId, false));
          let refType = compoundTypes[index];
          let t: Type.CompoundType = switch (refType) {
            case (#opt(o)) {
              let inner: Type.Type = buildType(o, compoundTypes, parentTypes)!;
              #opt(inner);
            };
            case (#vector(ve)) {
              let inner: Type.Type = buildType(ve, compoundTypes, parentTypes)!;
              #vector(inner);
            };
            case (#record(r)) {
              let fields = Buffer.Buffer<Type.RecordFieldType>(r.size());
              for (fieldRefType in Iter.fromArray(r)) {
                let fieldType: Type.Type = buildType(fieldRefType._type, compoundTypes, parentTypes)!;
                fields.add({tag=fieldRefType.tag; _type=fieldType});
              };
              #record(fields.toArray());
            };
            case (#variant(va)) {
              let options = Buffer.Buffer<Type.VariantOptionType>(va.size());
              for (optionRefType in Iter.fromArray(va)) {
                let optionType: Type.Type = buildType(optionRefType._type, compoundTypes, parentTypes)!;
                options.add({tag=optionRefType.tag; _type=optionType});
              };
              #variant(options.toArray());
            };
            case (#_func(f)) {
              let modes: [FuncMode.FuncMode] = f.modes;
              let map = func (a: [ReferenceType]) : ?[Type.Type] {
                do ? {
                  let newO = Buffer.Buffer<Type.Type>(a.size());
                  for (item in Iter.fromArray(a)) {
                    let t: Type.Type = buildType(item, compoundTypes, parentTypes)!;
                    newO.add(t);
                  };
                  newO.toArray();
                }
              };
              let argTypes: [Type.Type] = map(f.argTypes)!;
              let returnTypes: [Type.Type] = map(f.returnTypes)!;
              #_func({
                argTypes=argTypes;
                modes=modes;
                returnTypes=returnTypes;
              });
            };
            case (#service(s)) {
              let methods = Buffer.Buffer<(Text, Type.FuncType)>(s.methods.size());
              for (method in Iter.fromArray(s.methods)) {
                let t: Type.Type = buildType(method.1, compoundTypes, parentTypes)!;
                switch (t) {
                  case (#_func(f)) {
                    methods.add((method.0, f));
                  };
                  case (_) return null;
                }
              };
              #service({
                methods=methods.toArray();
              });
            };
          };
          let isRecursive = parentTypes.get(index)!.1;
          if (isRecursive) {
            #recursiveType({
              id=recursiveId;
              _type=t
            })
          } else {
            t
          }
        };
      }
    };
  };
  
  private func decodeTypes(bytes: Iter.Iter<Nat8>) : ?([ShallowCompoundType<ReferenceType>], [Int]) {
    do ? {
      let compoundTypeLength: Nat = NatX.decodeNat(bytes, #unsignedLEB128)!;
      let types = Buffer.Buffer<ShallowCompoundType<ReferenceType>>(compoundTypeLength);
      for (i in Iter.range(0, compoundTypeLength - 1)) {
        let t = decodeType(bytes)!;
        types.add(t);
      };
      let codeLength = NatX.decodeNat(bytes, #unsignedLEB128)!;
      let indicesOrCodes = Buffer.Buffer<Int>(codeLength);
      for (i in Iter.range(0, codeLength - 1)) {
        let indexOrCode: Int = IntX.decodeInt(bytes, #signedLEB128)!;
        indicesOrCodes.add(indexOrCode);
      };

      (types.toArray(), indicesOrCodes.toArray());
    }
  };

  private func decodeType(bytes: Iter.Iter<Nat8>) : ?InternalTypes.ShallowCompoundType<ReferenceType> {
    do ? {
      let referenceType: ReferenceType = decodeReferenceType(bytes)!;
      switch(referenceType) {
        // opt
        case (-18) {
          let innerRef = decodeReferenceType(bytes)!;
          #opt(innerRef);
        };
        // vector
        case (-19) {
          let innerRef = decodeReferenceType(bytes)!;
          #vector(innerRef);
        };
        // record
        case (-20) {
          let fields: [InternalTypes.RecordFieldReferenceType<ReferenceType>] = decodeTypeMulti(bytes, decodeTaggedType)!;
          #record(fields);
        };
        // variant
        case (-21) {
          let options: [InternalTypes.VariantOptionReferenceType<ReferenceType>] = decodeTypeMulti(bytes, decodeTaggedType)!;
          #variant(options);
        };
        // func
        case (-22) {
          let argTypes: [ReferenceType] = decodeTypeMulti(bytes, decodeReferenceType)!;
          let returnTypes: [ReferenceType] = decodeTypeMulti(bytes, decodeReferenceType)!;
          let modes: [FuncMode.FuncMode] = decodeTypeMulti(bytes, decodeFuncMode)!;
          #_func({
            modes=modes;
            argTypes=argTypes;
            returnTypes=returnTypes;
          });
        };
        // service
        case (-23) {
          let methods: [(Text, ReferenceType)] = decodeTypeMulti(bytes, decodeMethod)!;
          #service({
            methods=methods;
          });
        };
        case (_) return null;
      };
    };
  };

  private func decodeFuncMode(bytes: Iter.Iter<Nat8>): ?FuncMode.FuncMode {
    do ? {
      let modeByte = bytes.next()!;
      switch(modeByte) {
        case (0x01) #_query;
        case (0x02) #oneWay;
        case (_) return null;
      }
    }
  };

  private func decodeReferenceType(bytes: Iter.Iter<Nat8>): ?Int {
    IntX.decodeInt(bytes, #signedLEB128);
  };

  private func decodeMethod(bytes: Iter.Iter<Nat8>): ?(Text, ReferenceType) {
    do ? {
      let methodName: Text = decodeText(bytes)!;
      let innerType: Int = decodeReferenceType(bytes)!;
      (methodName, innerType);
    }
  };

  private func decodeTaggedType(bytes: Iter.Iter<Nat8>): ?{_type: ReferenceType; tag: Tag.Tag} {
    do ? {
      let tag = Nat32.fromNat(NatX.decodeNat(bytes, #unsignedLEB128)!);
      let innerRef = decodeReferenceType(bytes)!;
      {_type=innerRef; tag=#hash(tag)};
    }
  };

  private func decodeTypeMulti<T>(bytes: Iter.Iter<Nat8>, decodeType: (Iter.Iter<Nat8>) -> ?T): ?[T] {
    do ? {
      let optionCount = NatX.decodeNat(bytes, #unsignedLEB128)!;
      let options = Buffer.Buffer<T>(optionCount);
      for (i in Iter.range(0, optionCount - 1)) {
        let item = decodeType(bytes)!;
        options.add(item);
      };
      options.toArray();
    }
  }
};
