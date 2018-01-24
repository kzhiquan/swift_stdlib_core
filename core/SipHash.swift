//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
/// This file implements SipHash-2-4 and SipHash-1-3
/// (https://131002.net/siphash/).
///
/// This file is based on the reference C implementation, which was released
/// to public domain by:
///
/// * Jean-Philippe Aumasson <jeanphilippe.aumasson@gmail.com>
/// * Daniel J. Bernstein <djb@cr.yp.to>
//===----------------------------------------------------------------------===//

@_fixed_layout // FIXME(sil-serialize-all)
@_versioned
internal enum _SipHashDetail {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  @inline(__always)
  internal static func _rotate(_ x: UInt64, leftBy amount: Int) -> UInt64 {
    return (x &<< UInt64(amount)) | (x &>> UInt64(64 - amount))
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  @inline(__always)
  internal static func _loadUnalignedUInt64LE(
    from p: UnsafeRawPointer
  ) -> UInt64 {
    // FIXME(integers): split into multiple expressions to speed up the
    // typechecking
    var result =
      UInt64(p.load(fromByteOffset: 0, as: UInt8.self))
    result |=
      (UInt64(p.load(fromByteOffset: 1, as: UInt8.self)) &<< (8 as UInt64))
    result |=
      (UInt64(p.load(fromByteOffset: 2, as: UInt8.self)) &<< (16 as UInt64))
    result |=
      (UInt64(p.load(fromByteOffset: 3, as: UInt8.self)) &<< (24 as UInt64))
    result |=
      (UInt64(p.load(fromByteOffset: 4, as: UInt8.self)) &<< (32 as UInt64))
    result |=
      (UInt64(p.load(fromByteOffset: 5, as: UInt8.self)) &<< (40 as UInt64))
    result |=
      (UInt64(p.load(fromByteOffset: 6, as: UInt8.self)) &<< (48 as UInt64))
    result |=
      (UInt64(p.load(fromByteOffset: 7, as: UInt8.self)) &<< (56 as UInt64))
    return result
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  @inline(__always)
  internal static func _loadPartialUnalignedUInt64LE(
    from p: UnsafeRawPointer,
    byteCount: Int
  ) -> UInt64 {
    _sanityCheck((0..<8).contains(byteCount))
    var result: UInt64 = 0
    if byteCount >= 1 { result |= UInt64(p.load(fromByteOffset: 0, as: UInt8.self)) }
    if byteCount >= 2 { result |= UInt64(p.load(fromByteOffset: 1, as: UInt8.self)) &<< (8 as UInt64) }
    if byteCount >= 3 { result |= UInt64(p.load(fromByteOffset: 2, as: UInt8.self)) &<< (16 as UInt64) }
    if byteCount >= 4 { result |= UInt64(p.load(fromByteOffset: 3, as: UInt8.self)) &<< (24 as UInt64) }
    if byteCount >= 5 { result |= UInt64(p.load(fromByteOffset: 4, as: UInt8.self)) &<< (32 as UInt64) }
    if byteCount >= 6 { result |= UInt64(p.load(fromByteOffset: 5, as: UInt8.self)) &<< (40 as UInt64) }
    if byteCount >= 7 { result |= UInt64(p.load(fromByteOffset: 6, as: UInt8.self)) &<< (48 as UInt64) }
    return result
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  @inline(__always)
  internal static func _sipRound(
    v0: inout UInt64,
    v1: inout UInt64,
    v2: inout UInt64,
    v3: inout UInt64
  ) {
    v0 = v0 &+ v1
    v1 = _rotate(v1, leftBy: 13)
    v1 ^= v0
    v0 = _rotate(v0, leftBy: 32)
    v2 = v2 &+ v3
    v3 = _rotate(v3, leftBy: 16)
    v3 ^= v2
    v0 = v0 &+ v3
    v3 = _rotate(v3, leftBy: 21)
    v3 ^= v0
    v2 = v2 &+ v1
    v1 = _rotate(v1, leftBy: 17)
    v1 ^= v2
    v2 = _rotate(v2, leftBy: 32)
  }
}


@_fixed_layout // FIXME(sil-serialize-all)
public // @testable
struct _SipHash24Context {
  // "somepseudorandomlygeneratedbytes"
  @_versioned
  internal var v0: UInt64 = 0x736f6d6570736575

  @_versioned
  internal var v1: UInt64 = 0x646f72616e646f6d

  @_versioned
  internal var v2: UInt64 = 0x6c7967656e657261

  @_versioned
  internal var v3: UInt64 = 0x7465646279746573

  @_versioned
  internal var hashedByteCount: UInt64 = 0

  @_versioned
  internal var dataTail: UInt64 = 0

  @_versioned
  internal var dataTailByteCount: Int = 0

  @_versioned
  internal var finalizedHash: UInt64?

  @_inlineable // FIXME(sil-serialize-all)
  public init(key: (UInt64, UInt64)) {
    v3 ^= key.1
    v2 ^= key.0
    v1 ^= key.1
    v0 ^= key.0
  }

  // FIXME(ABI)#62 (UnsafeRawBufferPointer): Use UnsafeRawBufferPointer.
  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  mutating func append(_ data: UnsafeRawPointer, byteCount: Int) {
    _append_alwaysInline(data, byteCount: byteCount)
  }

  // FIXME(ABI)#63 (UnsafeRawBufferPointer): Use UnsafeRawBufferPointer.
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  @inline(__always)
  internal mutating func _append_alwaysInline(
    _ data: UnsafeRawPointer,
    byteCount: Int
  ) {
    precondition(finalizedHash == nil)
    _sanityCheck((0..<8).contains(dataTailByteCount))

    let dataEnd = data + byteCount

    var data = data
    var byteCount = byteCount
    if dataTailByteCount != 0 {
      let restByteCount = min(
        MemoryLayout<UInt64>.size - dataTailByteCount,
        byteCount)
      let rest = _SipHashDetail._loadPartialUnalignedUInt64LE(
        from: data,
        byteCount: restByteCount)
      dataTail |= rest &<< UInt64(dataTailByteCount * 8)
      dataTailByteCount += restByteCount
      data += restByteCount
      byteCount -= restByteCount
    }

    if dataTailByteCount == MemoryLayout<UInt64>.size {
      _appendDirectly(dataTail)
      dataTail = 0
      dataTailByteCount = 0
    } else if dataTailByteCount != 0 {
      _sanityCheck(data == dataEnd)
      return
    }

    let endOfWords =
      data + byteCount - (byteCount % MemoryLayout<UInt64>.size)
    while data != endOfWords {
      _appendDirectly(_SipHashDetail._loadUnalignedUInt64LE(from: data))
      data += 8
      // No need to update `byteCount`, it is not used beyond this point.
    }

    if data != dataEnd {
      dataTailByteCount = dataEnd - data
      dataTail = _SipHashDetail._loadPartialUnalignedUInt64LE(
        from: data,
        byteCount: dataTailByteCount)
    }
  }

  /// This function mixes in the given word directly into the state,
  /// ignoring `dataTail`.
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  @inline(__always)
  internal mutating func _appendDirectly(_ m: UInt64) {
    v3 ^= m
    for _ in 0..<2 {
      _SipHashDetail._sipRound(v0: &v0, v1: &v1, v2: &v2, v3: &v3)
    }
    v0 ^= m
    hashedByteCount += 8
  }

  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  mutating func append(_ data: UInt) {
    var data = data
    _append_alwaysInline(&data, byteCount: MemoryLayout.size(ofValue: data))
  }
  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  mutating func append(_ data: Int) {
    var data = data
    _append_alwaysInline(&data, byteCount: MemoryLayout.size(ofValue: data))
  }
  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  mutating func append(_ data: UInt64) {
    var data = data
    _append_alwaysInline(&data, byteCount: MemoryLayout.size(ofValue: data))
  }
  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  mutating func append(_ data: Int64) {
    var data = data
    _append_alwaysInline(&data, byteCount: MemoryLayout.size(ofValue: data))
  }
  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  mutating func append(_ data: UInt32) {
    var data = data
    _append_alwaysInline(&data, byteCount: MemoryLayout.size(ofValue: data))
  }
  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  mutating func append(_ data: Int32) {
    var data = data
    _append_alwaysInline(&data, byteCount: MemoryLayout.size(ofValue: data))
  }

  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  mutating func finalizeAndReturnHash() -> UInt64 {
    return _finalizeAndReturnHash_alwaysInline()
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  @inline(__always)
  internal mutating func _finalizeAndReturnHash_alwaysInline() -> UInt64 {
    if let finalizedHash = finalizedHash {
      return finalizedHash
    }

    _sanityCheck((0..<8).contains(dataTailByteCount))

    hashedByteCount += UInt64(dataTailByteCount)
    let b: UInt64 = (hashedByteCount << 56) | dataTail

    v3 ^= b
    for _ in 0..<2 {
      _SipHashDetail._sipRound(v0: &v0, v1: &v1, v2: &v2, v3: &v3)
    }
    v0 ^= b

    v2 ^= 0xff

    for _ in 0..<4 {
      _SipHashDetail._sipRound(v0: &v0, v1: &v1, v2: &v2, v3: &v3)
    }

    finalizedHash = v0 ^ v1 ^ v2 ^ v3
    return finalizedHash!
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal mutating func _finalizeAndReturnIntHash() -> Int {
    let hash: UInt64 = finalizeAndReturnHash()
#if arch(i386) || arch(arm)
    return Int(truncatingIfNeeded: hash)
#elseif arch(x86_64) || arch(arm64) || arch(powerpc64) || arch(powerpc64le) || arch(s390x)
    return Int(Int64(bitPattern: hash))
#endif
  }

  // FIXME(ABI)#64 (UnsafeRawBufferPointer): Use UnsafeRawBufferPointer.
  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  static func hash(
    data: UnsafeRawPointer,
    dataByteCount: Int,
    key: (UInt64, UInt64)
  ) -> UInt64 {
    return _SipHash24Context._hash_alwaysInline(
      data: data,
      dataByteCount: dataByteCount,
      key: key)
  }

  // FIXME(ABI)#65 (UnsafeRawBufferPointer): Use UnsafeRawBufferPointer.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public // @testable
  static func _hash_alwaysInline(
    data: UnsafeRawPointer,
    dataByteCount: Int,
    key: (UInt64, UInt64)
  ) -> UInt64 {
    var context = _SipHash24Context(key: key)
    context._append_alwaysInline(data, byteCount: dataByteCount)
    return context._finalizeAndReturnHash_alwaysInline()
  }
}

@_fixed_layout // FIXME(sil-serialize-all)
public // @testable
struct _SipHash13Context {
  // "somepseudorandomlygeneratedbytes"
  @_versioned
  internal var v0: UInt64 = 0x736f6d6570736575

  @_versioned
  internal var v1: UInt64 = 0x646f72616e646f6d

  @_versioned
  internal var v2: UInt64 = 0x6c7967656e657261

  @_versioned
  internal var v3: UInt64 = 0x7465646279746573

  @_versioned
  internal var hashedByteCount: UInt64 = 0

  @_versioned
  internal var dataTail: UInt64 = 0

  @_versioned
  internal var dataTailByteCount: Int = 0

  @_versioned
  internal var finalizedHash: UInt64?

  @_inlineable // FIXME(sil-serialize-all)
  public init(key: (UInt64, UInt64)) {
    v3 ^= key.1
    v2 ^= key.0
    v1 ^= key.1
    v0 ^= key.0
  }

  // FIXME(ABI)#62 (UnsafeRawBufferPointer): Use UnsafeRawBufferPointer.
  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  mutating func append(_ data: UnsafeRawPointer, byteCount: Int) {
    _append_alwaysInline(data, byteCount: byteCount)
  }

  // FIXME(ABI)#63 (UnsafeRawBufferPointer): Use UnsafeRawBufferPointer.
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  @inline(__always)
  internal mutating func _append_alwaysInline(
    _ data: UnsafeRawPointer,
    byteCount: Int
  ) {
    precondition(finalizedHash == nil)
    _sanityCheck((0..<8).contains(dataTailByteCount))

    let dataEnd = data + byteCount

    var data = data
    var byteCount = byteCount
    if dataTailByteCount != 0 {
      let restByteCount = min(
        MemoryLayout<UInt64>.size - dataTailByteCount,
        byteCount)
      let rest = _SipHashDetail._loadPartialUnalignedUInt64LE(
        from: data,
        byteCount: restByteCount)
      dataTail |= rest &<< UInt64(dataTailByteCount * 8)
      dataTailByteCount += restByteCount
      data += restByteCount
      byteCount -= restByteCount
    }

    if dataTailByteCount == MemoryLayout<UInt64>.size {
      _appendDirectly(dataTail)
      dataTail = 0
      dataTailByteCount = 0
    } else if dataTailByteCount != 0 {
      _sanityCheck(data == dataEnd)
      return
    }

    let endOfWords =
      data + byteCount - (byteCount % MemoryLayout<UInt64>.size)
    while data != endOfWords {
      _appendDirectly(_SipHashDetail._loadUnalignedUInt64LE(from: data))
      data += 8
      // No need to update `byteCount`, it is not used beyond this point.
    }

    if data != dataEnd {
      dataTailByteCount = dataEnd - data
      dataTail = _SipHashDetail._loadPartialUnalignedUInt64LE(
        from: data,
        byteCount: dataTailByteCount)
    }
  }

  /// This function mixes in the given word directly into the state,
  /// ignoring `dataTail`.
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  @inline(__always)
  internal mutating func _appendDirectly(_ m: UInt64) {
    v3 ^= m
    for _ in 0..<1 {
      _SipHashDetail._sipRound(v0: &v0, v1: &v1, v2: &v2, v3: &v3)
    }
    v0 ^= m
    hashedByteCount += 8
  }

  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  mutating func append(_ data: UInt) {
    var data = data
    _append_alwaysInline(&data, byteCount: MemoryLayout.size(ofValue: data))
  }
  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  mutating func append(_ data: Int) {
    var data = data
    _append_alwaysInline(&data, byteCount: MemoryLayout.size(ofValue: data))
  }
  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  mutating func append(_ data: UInt64) {
    var data = data
    _append_alwaysInline(&data, byteCount: MemoryLayout.size(ofValue: data))
  }
  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  mutating func append(_ data: Int64) {
    var data = data
    _append_alwaysInline(&data, byteCount: MemoryLayout.size(ofValue: data))
  }
  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  mutating func append(_ data: UInt32) {
    var data = data
    _append_alwaysInline(&data, byteCount: MemoryLayout.size(ofValue: data))
  }
  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  mutating func append(_ data: Int32) {
    var data = data
    _append_alwaysInline(&data, byteCount: MemoryLayout.size(ofValue: data))
  }

  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  mutating func finalizeAndReturnHash() -> UInt64 {
    return _finalizeAndReturnHash_alwaysInline()
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  @inline(__always)
  internal mutating func _finalizeAndReturnHash_alwaysInline() -> UInt64 {
    if let finalizedHash = finalizedHash {
      return finalizedHash
    }

    _sanityCheck((0..<8).contains(dataTailByteCount))

    hashedByteCount += UInt64(dataTailByteCount)
    let b: UInt64 = (hashedByteCount << 56) | dataTail

    v3 ^= b
    for _ in 0..<1 {
      _SipHashDetail._sipRound(v0: &v0, v1: &v1, v2: &v2, v3: &v3)
    }
    v0 ^= b

    v2 ^= 0xff

    for _ in 0..<3 {
      _SipHashDetail._sipRound(v0: &v0, v1: &v1, v2: &v2, v3: &v3)
    }

    finalizedHash = v0 ^ v1 ^ v2 ^ v3
    return finalizedHash!
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal mutating func _finalizeAndReturnIntHash() -> Int {
    let hash: UInt64 = finalizeAndReturnHash()
#if arch(i386) || arch(arm)
    return Int(truncatingIfNeeded: hash)
#elseif arch(x86_64) || arch(arm64) || arch(powerpc64) || arch(powerpc64le) || arch(s390x)
    return Int(Int64(bitPattern: hash))
#endif
  }

  // FIXME(ABI)#64 (UnsafeRawBufferPointer): Use UnsafeRawBufferPointer.
  @_inlineable // FIXME(sil-serialize-all)
  public // @testable
  static func hash(
    data: UnsafeRawPointer,
    dataByteCount: Int,
    key: (UInt64, UInt64)
  ) -> UInt64 {
    return _SipHash13Context._hash_alwaysInline(
      data: data,
      dataByteCount: dataByteCount,
      key: key)
  }

  // FIXME(ABI)#65 (UnsafeRawBufferPointer): Use UnsafeRawBufferPointer.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public // @testable
  static func _hash_alwaysInline(
    data: UnsafeRawPointer,
    dataByteCount: Int,
    key: (UInt64, UInt64)
  ) -> UInt64 {
    var context = _SipHash13Context(key: key)
    context._append_alwaysInline(data, byteCount: dataByteCount)
    return context._finalizeAndReturnHash_alwaysInline()
  }
}
