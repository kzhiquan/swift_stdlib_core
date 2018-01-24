//===--- FixedArray.swift.gyb ---------------------------------*- swift -*-===//
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
//
//  A helper struct to provide fixed-sized array like functionality
//
//===----------------------------------------------------------------------===//



@_versioned // FIXME(sil-serialize-all)
@_fixed_layout // FIXME(sil-serialize-all)
internal struct _FixedArray16<T> {
  // ABI TODO: The has assumptions about tuple layout in the ABI, namely that
  // they are laid out contiguously and individually addressable (i.e. strided).
  //
  @_versioned // FIXME(sil-serialize-all)
  internal var storage: (
    // A 16-wide tuple of type T
    T,
    T,
    T,
    T,
    T,
    T,
    T,
    T,
    T,
    T,
    T,
    T,
    T,
    T,
    T,
    T
  )

  @_versioned // FIXME(sil-serialize-all)
  var _count: Int8
}


extension _FixedArray16 {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal static var capacity: Int {
    @inline(__always) get { return 16 }
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal var capacity: Int {
    @inline(__always) get { return 16 }
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal var count : Int {
    @inline(__always) get { return Int(truncatingIfNeeded: _count) }
    @inline(__always) set { _count = Int8(newValue) }
  }
}

extension _FixedArray16 : RandomAccessCollection, MutableCollection {
  internal typealias Index = Int

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal var startIndex : Index {
    return 0
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal var endIndex : Index {
    return count
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal subscript(i: Index) -> T {
    @_versioned
    @inline(__always)
    get {
      let count = self.count // for exclusive access
      _sanityCheck(i >= 0 && i < count)
      var copy = storage
      let res: T = withUnsafeBytes(of: &copy) {
        (rawPtr : UnsafeRawBufferPointer) -> T in
        let stride = MemoryLayout<T>.stride
        _sanityCheck(rawPtr.count == 16*stride, "layout mismatch?")
        let bufPtr = UnsafeBufferPointer(
          start: rawPtr.baseAddress!.assumingMemoryBound(to: T.self),
          count: count)
        return bufPtr[i]
      }
      return res
    }
    @_versioned
    @inline(__always)
    set {
      _sanityCheck(i >= 0 && i < count)
      self.withUnsafeMutableBufferPointer { buffer in
        buffer[i] = newValue
      }
    }
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  @inline(__always)
  internal func index(after i: Index) -> Index {
    return i+1
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  @inline(__always)
  internal func index(before i: Index) -> Index {
    return i-1
  }
}

extension _FixedArray16 {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  internal mutating func append(_ newElement: T) {
    _sanityCheck(count < capacity)
    self[count] = newElement
    _count += 1
  }
}

extension _FixedArray16 where T : ExpressibleByIntegerLiteral {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  @inline(__always)
  internal init(count: Int) {
    _sanityCheck(count >= 0 && count <= _FixedArray16.capacity)
    self.storage = (
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0
    )
    self._count = Int8(truncatingIfNeeded: count)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  @inline(__always)
  internal init() {
    self.init(count: 0)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  @inline(__always)
  internal init(allZeros: ()) {
    self.init(count: 16)
  }
}

extension _FixedArray16 {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal mutating func withUnsafeMutableBufferPointer<R>(
    _ body: (UnsafeMutableBufferPointer<Element>) throws -> R
  ) rethrows -> R {
    let count = self.count // for exclusive access
    return try withUnsafeMutableBytes(of: &storage) { rawBuffer in
      _sanityCheck(rawBuffer.count == 16*MemoryLayout<T>.stride,
        "layout mismatch?")
      let buffer = UnsafeMutableBufferPointer<Element>(
        start: rawBuffer.baseAddress._unsafelyUnwrappedUnchecked
          .assumingMemoryBound(to: Element.self),
        count: count)
      return try body(buffer)
    }
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal mutating func withUnsafeBufferPointer<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R {
    let count = self.count // for exclusive access
    return try withUnsafeBytes(of: &storage) { rawBuffer in
      _sanityCheck(rawBuffer.count == 16*MemoryLayout<T>.stride,
        "layout mismatch?")
      let buffer = UnsafeBufferPointer<Element>(
        start: rawBuffer.baseAddress._unsafelyUnwrappedUnchecked
        .assumingMemoryBound(to: Element.self),
        count: count)
      return try body(buffer)
    }
  }
}

