//===--- UnsafeRawBufferPointer.swift.gyb ---------------------*- swift -*-===//
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



/// A mutable nonowning collection interface to the bytes in a
/// region of memory.
///
/// You can use an `UnsafeMutableRawBufferPointer` instance in low-level operations to eliminate
/// uniqueness checks and release mode bounds checks. Bounds checks are always
/// performed in debug mode.
///
/// An `UnsafeMutableRawBufferPointer` instance is a view of the raw bytes in a region of memory.
/// Each byte in memory is viewed as a `UInt8` value independent of the type
/// of values held in that memory. Reading from and writing to memory through
/// a raw buffer are untyped operations. Accessing this collection's bytes
/// does not bind the underlying memory to `UInt8`.
///
/// In addition to its collection interface, an `UnsafeMutableRawBufferPointer` instance also supports
/// the following methods provided by `UnsafeMutableRawPointer`, including
/// bounds checks in debug mode:
///
/// - `load(fromByteOffset:as:)`
/// - `storeBytes(of:toByteOffset:as:)`
/// - `copyMemory(from:)`
///
/// To access the underlying memory through typed operations, the memory must
/// be bound to a trivial type.
///
/// - Note: A *trivial type* can be copied bit for bit with no indirection
///   or reference-counting operations. Generally, native Swift types that do
///   not contain strong or weak references or other forms of indirection are
///   trivial, as are imported C structs and enums. Copying memory that
///   contains values of nontrivial types can only be done safely with a typed
///   pointer. Copying bytes directly from nontrivial, in-memory values does
///   not produce valid copies and can only be done by calling a C API, such as
///   `memmove()`.
///
/// UnsafeMutableRawBufferPointer Semantics
/// =================
///
/// An `UnsafeMutableRawBufferPointer` instance is a view into memory and does not own the memory
/// that it references. Copying a variable or constant of type `UnsafeMutableRawBufferPointer` does
/// not copy the underlying memory. However, initializing another collection
/// with an `UnsafeMutableRawBufferPointer` instance copies bytes out of the referenced memory and
/// into the new collection.
///
/// The following example uses `someBytes`, an `UnsafeMutableRawBufferPointer` instance, to
/// demonstrate the difference between assigning a buffer pointer and using a
/// buffer pointer as the source for another collection's elements. Here, the
/// assignment to `destBytes` creates a new, nonowning buffer pointer
/// covering the first `n` bytes of the memory that `someBytes`
/// references---nothing is copied:
///
///     var destBytes = someBytes[0..<n]
///
/// Next, the bytes referenced by `destBytes` are copied into `byteArray`, a
/// new `[UInt]` array, and then the remainder of `someBytes` is appended to
/// `byteArray`:
///
///     var byteArray: [UInt8] = Array(destBytes)
///     byteArray += someBytes[n..<someBytes.count]
///
/// Assigning into a ranged subscript of an `UnsafeMutableRawBufferPointer` instance copies bytes
/// into the memory. The next `n` bytes of the memory that `someBytes`
/// references are copied in this code:
///
///     destBytes[0..<n] = someBytes[n..<(n + n)]
@_fixed_layout
public struct UnsafeMutableRawBufferPointer {
  @_versioned
  internal let _position, _end: UnsafeMutableRawPointer?
}

extension UnsafeMutableRawBufferPointer {
  public typealias Iterator = UnsafeRawBufferPointer.Iterator
}

extension UnsafeMutableRawBufferPointer: Sequence {
  public typealias SubSequence = Slice<UnsafeMutableRawBufferPointer>

  /// Returns an iterator over the bytes of this sequence.
  @_inlineable
  public func makeIterator() -> Iterator {
    return Iterator(_position: _position, _end: _end)
  }
}

extension UnsafeMutableRawBufferPointer: MutableCollection {
  // TODO: Specialize `index` and `formIndex` and
  // `_failEarlyRangeCheck` as in `UnsafeBufferPointer`.
  public typealias Element = UInt8
  public typealias Index = Int
  public typealias Indices = CountableRange<Int>

  /// Always zero, which is the index of the first byte in a nonempty buffer.
  @_inlineable
  public var startIndex: Index {
    return 0
  }

  /// The "past the end" position---that is, the position one greater than the
  /// last valid subscript argument.
  ///
  /// The `endIndex` property of an `UnsafeMutableRawBufferPointer`
  /// instance is always identical to `count`.
  @_inlineable
  public var endIndex: Index {
    return count
  }

  @_inlineable
  public var indices: Indices {
    return startIndex..<endIndex
  }

  /// Accesses the byte at the given offset in the memory region as a `UInt8`
  /// value.
  ///
  /// - Parameter i: The offset of the byte to access. `i` must be in the range
  ///   `0..<count`.
  @_inlineable
  public subscript(i: Int) -> Element {
    get {
      _debugPrecondition(i >= 0)
      _debugPrecondition(i < endIndex)
      return _position!.load(fromByteOffset: i, as: UInt8.self)
    }
    nonmutating set {
      _debugPrecondition(i >= 0)
      _debugPrecondition(i < endIndex)
      _position!.storeBytes(of: newValue, toByteOffset: i, as: UInt8.self)
    }
  }

  /// Accesses the bytes in the specified memory region.
  ///
  /// - Parameter bounds: The range of byte offsets to access. The upper and
  ///   lower bounds of the range must be in the range `0...count`.
  @_inlineable
  public subscript(bounds: Range<Int>) -> SubSequence {
    get {
      _debugPrecondition(bounds.lowerBound >= startIndex)
      _debugPrecondition(bounds.upperBound <= endIndex)
      return Slice(base: self, bounds: bounds)
    }
    nonmutating set {
      _debugPrecondition(bounds.lowerBound >= startIndex)
      _debugPrecondition(bounds.upperBound <= endIndex)
      _debugPrecondition(bounds.count == newValue.count)

      if !newValue.isEmpty {
        (baseAddress! + bounds.lowerBound).copyMemory(
          from: newValue.base.baseAddress! + newValue.startIndex,
          byteCount: newValue.count)
      }
    }
  }

  /// The number of bytes in the buffer.
  ///
  /// If the `baseAddress` of this buffer is `nil`, the count is zero. However,
  /// a buffer can have a `count` of zero even with a non-`nil` base address.
  @_inlineable
  public var count: Int {
    if let pos = _position {
      return _end! - pos
    }
    return 0
  }
}

extension UnsafeMutableRawBufferPointer: RandomAccessCollection { }

extension UnsafeMutableRawBufferPointer {
  @available(swift, deprecated: 4.1, obsoleted: 5.0.0, renamed: "allocate(byteCount:alignment:)")
  public static func allocate(count: Int) -> UnsafeMutableRawBufferPointer { 
    return UnsafeMutableRawBufferPointer.allocate(
      byteCount: count, alignment: MemoryLayout<UInt>.alignment)
  }

  /// Returns a newly allocated buffer with the given size, in bytes.
  ///
  /// The memory referenced by the new buffer is allocated, but not
  /// initialized.
  ///
  /// - Parameters:
  ///   - byteCount: The number of bytes to allocate.
  ///   - alignment: The alignment of the new region of allocated memory, in
  ///     bytes.
  /// - Returns: A buffer pointer to a newly allocated region of memory aligned 
  ///     to `alignment`.
  @_inlineable
  public static func allocate(
    byteCount: Int, alignment: Int
  ) -> UnsafeMutableRawBufferPointer {
    let base = UnsafeMutableRawPointer.allocate(
      byteCount: byteCount, alignment: alignment)
    return UnsafeMutableRawBufferPointer(start: base, count: byteCount)
  }

  /// Deallocates the memory block previously allocated at this buffer pointer’s 
  /// base address. 
  ///
  /// This buffer pointer's `baseAddress` must be `nil` or a pointer to a memory 
  /// block previously returned by a Swift allocation method. If `baseAddress` is 
  /// `nil`, this function does nothing. Otherwise, the memory must not be initialized 
  /// or `Pointee` must be a trivial type. This buffer pointer's byte `count` must 
  /// be equal to the originally allocated size of the memory block.
  @_inlineable
  public func deallocate() {
    _position?.deallocate()
  }

  /// Returns a new instance of the given type, read from the buffer pointer's
  /// raw memory at the specified byte offset.
  ///
  /// You can use this method to create new values from the buffer pointer's
  /// underlying bytes. The following example creates two new `Int32`
  /// instances from the memory referenced by the buffer pointer `someBytes`.
  /// The bytes for `a` are copied from the first four bytes of `someBytes`,
  /// and the bytes for `b` are copied from the next four bytes.
  ///
  ///     let a = someBytes.load(as: Int32.self)
  ///     let b = someBytes.load(fromByteOffset: 4, as: Int32.self)
  ///
  /// The memory to read for the new instance must not extend beyond the buffer
  /// pointer's memory region---that is, `offset + MemoryLayout<T>.size` must
  /// be less than or equal to the buffer pointer's `count`.
  ///
  /// - Parameters:
  ///   - offset: The offset, in bytes, into the buffer pointer's memory at
  ///     which to begin reading data for the new instance. The buffer pointer
  ///     plus `offset` must be properly aligned for accessing an instance of
  ///     type `T`. The default is zero.
  ///   - type: The type to use for the newly constructed instance. The memory
  ///     must be initialized to a value of a type that is layout compatible
  ///     with `type`.
  /// - Returns: A new instance of type `T`, copied from the buffer pointer's
  ///   memory.
  @_inlineable
  public func load<T>(fromByteOffset offset: Int = 0, as type: T.Type) -> T {
    _debugPrecondition(offset >= 0, "UnsafeMutableRawBufferPointer.load with negative offset")
    _debugPrecondition(offset + MemoryLayout<T>.size <= self.count,
      "UnsafeMutableRawBufferPointer.load out of bounds")
    return baseAddress!.load(fromByteOffset: offset, as: T.self)
  }

  /// Stores a value's bytes into the buffer pointer's raw memory at the
  /// specified byte offset.
  ///
  /// The type `T` to be stored must be a trivial type. The memory must also be
  /// uninitialized, initialized to `T`, or initialized to another trivial
  /// type that is layout compatible with `T`.
  ///
  /// The memory written to must not extend beyond the buffer pointer's memory
  /// region---that is, `offset + MemoryLayout<T>.size` must be less than or
  /// equal to the buffer pointer's `count`.
  ///
  /// After calling `storeBytes(of:toByteOffset:as:)`, the memory is
  /// initialized to the raw bytes of `value`. If the memory is bound to a
  /// type `U` that is layout compatible with `T`, then it contains a value of
  /// type `U`. Calling `storeBytes(of:toByteOffset:as:)` does not change the
  /// bound type of the memory.
  ///
  /// - Parameters:
  ///   - offset: The offset in bytes into the buffer pointer's memory to begin
  ///     reading data for the new instance. The buffer pointer plus `offset`
  ///     must be properly aligned for accessing an instance of type `T`. The
  ///     default is zero.
  ///   - type: The type to use for the newly constructed instance. The memory
  ///     must be initialized to a value of a type that is layout compatible
  ///     with `type`.
  @_inlineable
  public func storeBytes<T>(
    of value: T, toByteOffset offset: Int = 0, as: T.Type
  ) {
    _debugPrecondition(offset >= 0, "UnsafeMutableRawBufferPointer.storeBytes with negative offset")
    _debugPrecondition(offset + MemoryLayout<T>.size <= self.count,
      "UnsafeMutableRawBufferPointer.storeBytes out of bounds")

    baseAddress!.storeBytes(of: value, toByteOffset: offset, as: T.self)
  }

  @available(swift, deprecated: 4.1, obsoleted: 5.0.0, renamed: "copyMemory(from:)")
  public func copyBytes(from source: UnsafeRawBufferPointer) {
    copyMemory(from: source)
  }
  /// Copies the bytes from the given buffer to this buffer's memory.
  ///
  /// If the `source.count` bytes of memory referenced by this buffer are bound
  /// to a type `T`, then `T` must be a trivial type, the underlying pointer
  /// must be properly aligned for accessing `T`, and `source.count` must be a
  /// multiple of `MemoryLayout<T>.stride`.
  ///
  /// After calling `copyMemory(from:)`, the first `source.count` bytes of
  /// memory referenced by this buffer are initialized to raw bytes. If the
  /// memory is bound to type `T`, then it contains values of type `T`.
  ///
  /// - Parameter source: A buffer of raw bytes from which to copy.
  ///   `source.count` must be less than or equal to this buffer's `count`.
  @_inlineable
  public func copyMemory(from source: UnsafeRawBufferPointer) {
    _debugPrecondition(source.count <= self.count,
      "UnsafeMutableRawBufferPointer.copyMemory source has too many elements")
    baseAddress?.copyMemory(from: source.baseAddress!, byteCount: source.count)
  }

  /// Copies from a collection of `UInt8` into this buffer's memory.
  ///
  /// If the `source.count` bytes of memory referenced by this buffer are bound
  /// to a type `T`, then `T` must be a trivial type, the underlying pointer
  /// must be properly aligned for accessing `T`, and `source.count` must be a
  /// multiple of `MemoryLayout<T>.stride`.
  ///
  /// After calling `copyBytes(from:)`, the `source.count` bytes of memory
  /// referenced by this buffer are initialized to raw bytes. If the memory is
  /// bound to type `T`, then it contains values of type `T`.
  ///
  /// - Parameter source: A collection of `UInt8` elements. `source.count` must
  ///   be less than or equal to this buffer's `count`.
  @_inlineable
  public func copyBytes<C : Collection>(from source: C
  ) where C.Element == UInt8 {
    _debugPrecondition(source.count <= self.count,
      "UnsafeMutableRawBufferPointer.copyBytes source has too many elements")
    guard let position = _position else {
      return
    }
    for (index, byteValue) in source.enumerated() {
      position.storeBytes(
        of: byteValue, toByteOffset: index, as: UInt8.self)
    }
  }

  /// Creates a buffer over the specified number of contiguous bytes starting
  /// at the given pointer.
  ///
  /// - Parameters:
  ///   - start: The address of the memory that starts the buffer. If `starts`
  ///     is `nil`, `count` must be zero. However, `count` may be zero even
  ///     for a non-`nil` `start`.
  ///   - count: The number of bytes to include in the buffer. `count` must not
  ///     be negative.
  @_inlineable
  public init(start: UnsafeMutableRawPointer?, count: Int) {
    _precondition(count >= 0, "UnsafeMutableRawBufferPointer with negative count")
    _precondition(count == 0 || start != nil,
      "UnsafeMutableRawBufferPointer has a nil start and nonzero count")
    _position = start
    _end = start.map { $0 + count }
  }

  /// Creates a new buffer over the same memory as the given buffer.
  ///
  /// - Parameter bytes: The buffer to convert.
  @_inlineable
  public init(_ bytes: UnsafeMutableRawBufferPointer) {
    self.init(start: bytes.baseAddress, count: bytes.count)
  }

  /// Creates a new mutable buffer over the same memory as the given buffer.
  ///
  /// - Parameter bytes: The buffer to convert.
  @_inlineable
  public init(mutating bytes: UnsafeRawBufferPointer) {
    self.init(start: UnsafeMutableRawPointer(mutating: bytes.baseAddress),
      count: bytes.count)
  }

  /// Creates a raw buffer over the contiguous bytes in the given typed buffer.
  ///
  /// - Parameter buffer: The typed buffer to convert to a raw buffer. The
  ///   buffer's type `T` must be a trivial type.
  @_inlineable
  public init<T>(_ buffer: UnsafeMutableBufferPointer<T>) {
    self.init(start: buffer.baseAddress!,
      count: buffer.count * MemoryLayout<T>.stride)
  }



  /// Creates a raw buffer over the same memory as the given raw buffer slice,
  /// with the indices rebased to zero.
  ///
  /// The new buffer represents the same region of memory as the slice, but its
  /// indices start at zero instead of at the beginning of the slice in the
  /// original buffer. The following code creates `slice`, a slice covering
  /// part of an existing buffer instance, then rebases it into a new `rebased`
  /// buffer.
  ///
  ///     let slice = buffer[n...]
  ///     let rebased = UnsafeRawBufferPointer(rebasing: slice)
  ///
  /// After this code has executed, the following are true:
  ///
  /// - `rebased.startIndex == 0`
  /// - `rebased[0] == slice[n]`
  /// - `rebased[0] == buffer[n]`
  /// - `rebased.count == slice.count`
  ///
  /// - Parameter slice: The raw buffer slice to rebase.
  @_inlineable
  public init(rebasing slice: Slice<UnsafeMutableRawBufferPointer>) {
    self.init(start: slice.base.baseAddress! + slice.startIndex,
      count: slice.count)
  }

  /// A pointer to the first byte of the buffer.
  ///
  /// If the `baseAddress` of this buffer is `nil`, the count is zero. However,
  /// a buffer can have a `count` of zero even with a non-`nil` base address.
  @_inlineable
  public var baseAddress: UnsafeMutableRawPointer? {
    return _position
  }

  
  /// Initializes the memory referenced by this buffer with the given value,
  /// binds the memory to the value's type, and returns a typed buffer of the
  /// initialized memory.
  ///
  /// The memory referenced by this buffer must be uninitialized or
  /// initialized to a trivial type, and must be properly aligned for
  /// accessing `T`.
  ///
  /// After calling this method on a raw buffer with non-nil `baseAddress` `b`, 
  /// the region starting at `b` and continuing up to
  /// `b + self.count - self.count % MemoryLayout<T>.stride` is bound to type `T` and
  /// initialized. If `T` is a nontrivial type, you must eventually deinitialize
  /// or move the values in this region to avoid leaks. If `baseAddress` is 
  /// `nil`, this function does nothing and returns an empty buffer pointer.
  ///
  /// - Parameters:
  ///   - type: The type to bind this buffer’s memory to.
  ///   - repeatedValue: The instance to copy into memory.
  /// - Returns: A typed buffer of the memory referenced by this raw buffer. 
  ///     The typed buffer contains `self.count / MemoryLayout<T>.stride` 
  ///     instances of `T`.
  @_inlineable
  @discardableResult
  public func initializeMemory<T>(as type: T.Type, repeating repeatedValue: T)
    -> UnsafeMutableBufferPointer<T> {
    guard let base = _position else {
      return UnsafeMutableBufferPointer<T>(start: nil, count: 0)
    }
    
    let count = (_end! - base) / MemoryLayout<T>.stride
    let typed = base.initializeMemory(
      as: type, repeating: repeatedValue, count: count)
    return UnsafeMutableBufferPointer<T>(start: typed, count: count)
  }

  /// Initializes the buffer's memory with the given elements, binding the
  /// initialized memory to the elements' type.
  ///
  /// When calling the `initializeMemory(as:from:)` method on a buffer `b`,
  /// the memory referenced by `b` must be uninitialized or initialized to a
  /// trivial type, and must be properly aligned for accessing `S.Element`.
  /// The buffer must contain sufficient memory to accommodate
  /// `source.underestimatedCount`.
  ///
  /// This method initializes the buffer with elements from `source` until
  /// `source` is exhausted or, if `source` is a sequence but not a
  /// collection, the buffer has no more room for its elements. After calling
  /// `initializeMemory(as:from:)`, the memory referenced by the returned
  /// `UnsafeMutableBufferPointer` instance is bound and initialized to type
  /// `S.Element`.
  ///
  /// - Parameters:
  ///   - type: The type of the elements to bind the buffer's memory to.
  ///   - source: A sequence of elements with which to initialize the buffer.
  /// - Returns: An iterator to any elements of `source` that didn't fit in the
  ///   buffer, and a typed buffer of the written elements. The returned
  ///   buffer references memory starting at the same base address as this
  ///   buffer.
  @_inlineable
  public func initializeMemory<S: Sequence>(
    as type: S.Element.Type, from source: S
  ) -> (unwritten: S.Iterator, initialized: UnsafeMutableBufferPointer<S.Element>) {
    // TODO: Optimize where `C` is a `ContiguousArrayBuffer`.

    var it = source.makeIterator()
    var idx = startIndex
    let elementStride = MemoryLayout<S.Element>.stride
    
    // This has to be a debug precondition due to the cost of walking over some collections.
    _debugPrecondition(source.underestimatedCount <= (count / elementStride),
      "insufficient space to accommodate source.underestimatedCount elements")
    guard let base = baseAddress else {
      // this can be a precondition since only an invalid argument should be costly
      _precondition(source.underestimatedCount == 0, 
        "no memory available to initialize from source")
      return (it, UnsafeMutableBufferPointer(start: nil, count: 0))
    }  

    for p in stride(from: base, 
      // only advance to as far as the last element that will fit
      to: base + count - elementStride + 1, 
      by: elementStride
    ) {
      // underflow is permitted -- e.g. a sequence into
      // the spare capacity of an Array buffer
      guard let x = it.next() else { break }
      p.initializeMemory(as: S.Element.self, repeating: x, count: 1)
      formIndex(&idx, offsetBy: elementStride)
    }

    return (it, UnsafeMutableBufferPointer(
                  start: base.assumingMemoryBound(to: S.Element.self), 
                  count: idx / elementStride))
  }

  /// Binds this buffer’s memory to the specified type and returns a typed buffer 
  /// of the bound memory.
  ///
  /// Use the `bindMemory(to:)` method to bind the memory referenced
  /// by this buffer to the type `T`. The memory must be uninitialized or
  /// initialized to a type that is layout compatible with `T`. If the memory
  /// is uninitialized, it is still uninitialized after being bound to `T`.
  ///
  /// - Warning: A memory location may only be bound to one type at a time. The
  ///   behavior of accessing memory as a type unrelated to its bound type is
  ///   undefined.
  ///
  /// - Parameters:
  ///   - type: The type `T` to bind the memory to.
  /// - Returns: A typed buffer of the newly bound memory. The memory in this
  ///   region is bound to `T`, but has not been modified in any other way.
  ///   The typed buffer references `self.count / MemoryLayout<T>.stride` instances of `T`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  @discardableResult
  public func bindMemory<T>(
    to type: T.Type
  ) -> UnsafeMutableBufferPointer<T> {
    guard let base = _position else {
      return UnsafeMutableBufferPointer<T>(start: nil, count: 0)
    }

    let capacity = count / MemoryLayout<T>.stride
    Builtin.bindMemory(base._rawValue, capacity._builtinWordValue, type)
    return UnsafeMutableBufferPointer<T>(
      start: UnsafeMutablePointer<T>(base._rawValue), count: capacity)
  }
}

extension UnsafeMutableRawBufferPointer : CustomDebugStringConvertible {
  /// A textual representation of the buffer, suitable for debugging.
  @_inlineable // FIXME(sil-serialize-all)
  public var debugDescription: String {
    return "UnsafeMutableRawBufferPointer"
      + "(start: \(_position.map(String.init(describing:)) ?? "nil"), count: \(count))"
  }
}

extension UnsafeMutableRawBufferPointer {
  @_inlineable // FIXME(sil-serialize-all)
  @available(*, unavailable, 
    message: "use 'UnsafeMutableRawBufferPointer(rebasing:)' to convert a slice into a zero-based raw buffer.")
  public subscript(bounds: Range<Int>) -> UnsafeMutableRawBufferPointer {
    get { return UnsafeMutableRawBufferPointer(start: nil, count: 0) }
    nonmutating set {}
  }

  @available(*, unavailable, 
    message: "use 'UnsafeRawBufferPointer(rebasing:)' to convert a slice into a zero-based raw buffer.")
  public subscript(bounds: Range<Int>) -> UnsafeRawBufferPointer {
    get { return UnsafeRawBufferPointer(start: nil, count: 0) }
    nonmutating set {}
  }
}


/// A  nonowning collection interface to the bytes in a
/// region of memory.
///
/// You can use an `UnsafeRawBufferPointer` instance in low-level operations to eliminate
/// uniqueness checks and release mode bounds checks. Bounds checks are always
/// performed in debug mode.
///
/// An `UnsafeRawBufferPointer` instance is a view of the raw bytes in a region of memory.
/// Each byte in memory is viewed as a `UInt8` value independent of the type
/// of values held in that memory. Reading from memory through a raw buffer is
/// an untyped operation.
///
/// In addition to its collection interface, an `UnsafeRawBufferPointer` instance also supports
/// the `load(fromByteOffset:as:)` method provided by `UnsafeRawPointer`,
/// including bounds checks in debug mode.
///
/// To access the underlying memory through typed operations, the memory must
/// be bound to a trivial type.
///
/// - Note: A *trivial type* can be copied bit for bit with no indirection
///   or reference-counting operations. Generally, native Swift types that do
///   not contain strong or weak references or other forms of indirection are
///   trivial, as are imported C structs and enums. Copying memory that
///   contains values of nontrivial types can only be done safely with a typed
///   pointer. Copying bytes directly from nontrivial, in-memory values does
///   not produce valid copies and can only be done by calling a C API, such as
///   `memmove()`.
///
/// UnsafeRawBufferPointer Semantics
/// =================
///
/// An `UnsafeRawBufferPointer` instance is a view into memory and does not own the memory
/// that it references. Copying a variable or constant of type `UnsafeRawBufferPointer` does
/// not copy the underlying memory. However, initializing another collection
/// with an `UnsafeRawBufferPointer` instance copies bytes out of the referenced memory and
/// into the new collection.
///
/// The following example uses `someBytes`, an `UnsafeRawBufferPointer` instance, to
/// demonstrate the difference between assigning a buffer pointer and using a
/// buffer pointer as the source for another collection's elements. Here, the
/// assignment to `destBytes` creates a new, nonowning buffer pointer
/// covering the first `n` bytes of the memory that `someBytes`
/// references---nothing is copied:
///
///     var destBytes = someBytes[0..<n]
///
/// Next, the bytes referenced by `destBytes` are copied into `byteArray`, a
/// new `[UInt]` array, and then the remainder of `someBytes` is appended to
/// `byteArray`:
///
///     var byteArray: [UInt8] = Array(destBytes)
///     byteArray += someBytes[n..<someBytes.count]
@_fixed_layout
public struct UnsafeRawBufferPointer {
  @_versioned
  internal let _position, _end: UnsafeRawPointer?
}

extension UnsafeRawBufferPointer {
  /// An iterator over the bytes viewed by a raw buffer pointer.
  @_fixed_layout
  public struct Iterator {
    @_versioned
    internal var _position, _end: UnsafeRawPointer?

    @_versioned
    @_inlineable
    internal init(_position: UnsafeRawPointer?, _end: UnsafeRawPointer?) {
      self._position = _position
      self._end = _end
    }
  }
}

extension UnsafeRawBufferPointer.Iterator: IteratorProtocol, Sequence {
  /// Advances to the next byte and returns it, or `nil` if no next byte
  /// exists.
  ///
  /// Once `nil` has been returned, all subsequent calls return `nil`.
  ///
  /// - Returns: The next sequential byte in the raw buffer if another byte
  ///   exists; otherwise, `nil`.
  @_inlineable
  public mutating func next() -> UInt8? {
    if _position == _end { return nil }

    let result = _position!.load(as: UInt8.self)
    _position! += 1
    return result
  }
}

extension UnsafeRawBufferPointer: Sequence {
  public typealias SubSequence = Slice<UnsafeRawBufferPointer>

  /// Returns an iterator over the bytes of this sequence.
  @_inlineable
  public func makeIterator() -> Iterator {
    return Iterator(_position: _position, _end: _end)
  }
}

extension UnsafeRawBufferPointer: Collection {
  // TODO: Specialize `index` and `formIndex` and
  // `_failEarlyRangeCheck` as in `UnsafeBufferPointer`.
  public typealias Element = UInt8
  public typealias Index = Int
  public typealias Indices = CountableRange<Int>

  /// Always zero, which is the index of the first byte in a nonempty buffer.
  @_inlineable
  public var startIndex: Index {
    return 0
  }

  /// The "past the end" position---that is, the position one greater than the
  /// last valid subscript argument.
  ///
  /// The `endIndex` property of an `UnsafeRawBufferPointer`
  /// instance is always identical to `count`.
  @_inlineable
  public var endIndex: Index {
    return count
  }

  @_inlineable
  public var indices: Indices {
    return startIndex..<endIndex
  }

  /// Accesses the byte at the given offset in the memory region as a `UInt8`
  /// value.
  ///
  /// - Parameter i: The offset of the byte to access. `i` must be in the range
  ///   `0..<count`.
  @_inlineable
  public subscript(i: Int) -> Element {
    get {
      _debugPrecondition(i >= 0)
      _debugPrecondition(i < endIndex)
      return _position!.load(fromByteOffset: i, as: UInt8.self)
    }
  }

  /// Accesses the bytes in the specified memory region.
  ///
  /// - Parameter bounds: The range of byte offsets to access. The upper and
  ///   lower bounds of the range must be in the range `0...count`.
  @_inlineable
  public subscript(bounds: Range<Int>) -> SubSequence {
    get {
      _debugPrecondition(bounds.lowerBound >= startIndex)
      _debugPrecondition(bounds.upperBound <= endIndex)
      return Slice(base: self, bounds: bounds)
    }
  }

  /// The number of bytes in the buffer.
  ///
  /// If the `baseAddress` of this buffer is `nil`, the count is zero. However,
  /// a buffer can have a `count` of zero even with a non-`nil` base address.
  @_inlineable
  public var count: Int {
    if let pos = _position {
      return _end! - pos
    }
    return 0
  }
}

extension UnsafeRawBufferPointer: RandomAccessCollection { }

extension UnsafeRawBufferPointer {

  /// Deallocates the memory block previously allocated at this buffer pointer’s 
  /// base address. 
  ///
  /// This buffer pointer's `baseAddress` must be `nil` or a pointer to a memory 
  /// block previously returned by a Swift allocation method. If `baseAddress` is 
  /// `nil`, this function does nothing. Otherwise, the memory must not be initialized 
  /// or `Pointee` must be a trivial type. This buffer pointer's byte `count` must 
  /// be equal to the originally allocated size of the memory block.
  @_inlineable
  public func deallocate() {
    _position?.deallocate()
  }

  /// Returns a new instance of the given type, read from the buffer pointer's
  /// raw memory at the specified byte offset.
  ///
  /// You can use this method to create new values from the buffer pointer's
  /// underlying bytes. The following example creates two new `Int32`
  /// instances from the memory referenced by the buffer pointer `someBytes`.
  /// The bytes for `a` are copied from the first four bytes of `someBytes`,
  /// and the bytes for `b` are copied from the next four bytes.
  ///
  ///     let a = someBytes.load(as: Int32.self)
  ///     let b = someBytes.load(fromByteOffset: 4, as: Int32.self)
  ///
  /// The memory to read for the new instance must not extend beyond the buffer
  /// pointer's memory region---that is, `offset + MemoryLayout<T>.size` must
  /// be less than or equal to the buffer pointer's `count`.
  ///
  /// - Parameters:
  ///   - offset: The offset, in bytes, into the buffer pointer's memory at
  ///     which to begin reading data for the new instance. The buffer pointer
  ///     plus `offset` must be properly aligned for accessing an instance of
  ///     type `T`. The default is zero.
  ///   - type: The type to use for the newly constructed instance. The memory
  ///     must be initialized to a value of a type that is layout compatible
  ///     with `type`.
  /// - Returns: A new instance of type `T`, copied from the buffer pointer's
  ///   memory.
  @_inlineable
  public func load<T>(fromByteOffset offset: Int = 0, as type: T.Type) -> T {
    _debugPrecondition(offset >= 0, "UnsafeRawBufferPointer.load with negative offset")
    _debugPrecondition(offset + MemoryLayout<T>.size <= self.count,
      "UnsafeRawBufferPointer.load out of bounds")
    return baseAddress!.load(fromByteOffset: offset, as: T.self)
  }


  /// Creates a buffer over the specified number of contiguous bytes starting
  /// at the given pointer.
  ///
  /// - Parameters:
  ///   - start: The address of the memory that starts the buffer. If `starts`
  ///     is `nil`, `count` must be zero. However, `count` may be zero even
  ///     for a non-`nil` `start`.
  ///   - count: The number of bytes to include in the buffer. `count` must not
  ///     be negative.
  @_inlineable
  public init(start: UnsafeRawPointer?, count: Int) {
    _precondition(count >= 0, "UnsafeRawBufferPointer with negative count")
    _precondition(count == 0 || start != nil,
      "UnsafeRawBufferPointer has a nil start and nonzero count")
    _position = start
    _end = start.map { $0 + count }
  }

  /// Creates a new buffer over the same memory as the given buffer.
  ///
  /// - Parameter bytes: The buffer to convert.
  @_inlineable
  public init(_ bytes: UnsafeMutableRawBufferPointer) {
    self.init(start: bytes.baseAddress, count: bytes.count)
  }

  /// Creates a new buffer over the same memory as the given buffer.
  ///
  /// - Parameter bytes: The buffer to convert.
  @_inlineable
  public init(_ bytes: UnsafeRawBufferPointer) {
    self.init(start: bytes.baseAddress, count: bytes.count)
  }

  /// Creates a raw buffer over the contiguous bytes in the given typed buffer.
  ///
  /// - Parameter buffer: The typed buffer to convert to a raw buffer. The
  ///   buffer's type `T` must be a trivial type.
  @_inlineable
  public init<T>(_ buffer: UnsafeMutableBufferPointer<T>) {
    self.init(start: buffer.baseAddress!,
      count: buffer.count * MemoryLayout<T>.stride)
  }

  /// Creates a raw buffer over the contiguous bytes in the given typed buffer.
  ///
  /// - Parameter buffer: The typed buffer to convert to a raw buffer. The
  ///   buffer's type `T` must be a trivial type.
  @_inlineable
  public init<T>(_ buffer: UnsafeBufferPointer<T>) {
    self.init(start: buffer.baseAddress!,
      count: buffer.count * MemoryLayout<T>.stride)
  }

  /// Creates a raw buffer over the same memory as the given raw buffer slice,
  /// with the indices rebased to zero.
  ///
  /// The new buffer represents the same region of memory as the slice, but its
  /// indices start at zero instead of at the beginning of the slice in the
  /// original buffer. The following code creates `slice`, a slice covering
  /// part of an existing buffer instance, then rebases it into a new `rebased`
  /// buffer.
  ///
  ///     let slice = buffer[n...]
  ///     let rebased = UnsafeRawBufferPointer(rebasing: slice)
  ///
  /// After this code has executed, the following are true:
  ///
  /// - `rebased.startIndex == 0`
  /// - `rebased[0] == slice[n]`
  /// - `rebased[0] == buffer[n]`
  /// - `rebased.count == slice.count`
  ///
  /// - Parameter slice: The raw buffer slice to rebase.
  @_inlineable
  public init(rebasing slice: Slice<UnsafeRawBufferPointer>) {
    self.init(start: slice.base.baseAddress! + slice.startIndex,
      count: slice.count)
  }

  /// Creates a raw buffer over the same memory as the given raw buffer slice,
  /// with the indices rebased to zero.
  ///
  /// The new buffer represents the same region of memory as the slice, but its
  /// indices start at zero instead of at the beginning of the slice in the
  /// original buffer. The following code creates `slice`, a slice covering
  /// part of an existing buffer instance, then rebases it into a new `rebased`
  /// buffer.
  ///
  ///     let slice = buffer[n...]
  ///     let rebased = UnsafeRawBufferPointer(rebasing: slice)
  ///
  /// After this code has executed, the following are true:
  ///
  /// - `rebased.startIndex == 0`
  /// - `rebased[0] == slice[n]`
  /// - `rebased[0] == buffer[n]`
  /// - `rebased.count == slice.count`
  ///
  /// - Parameter slice: The raw buffer slice to rebase.
  @_inlineable
  public init(rebasing slice: Slice<UnsafeMutableRawBufferPointer>) {
    self.init(start: slice.base.baseAddress! + slice.startIndex,
      count: slice.count)
  }

  /// A pointer to the first byte of the buffer.
  ///
  /// If the `baseAddress` of this buffer is `nil`, the count is zero. However,
  /// a buffer can have a `count` of zero even with a non-`nil` base address.
  @_inlineable
  public var baseAddress: UnsafeRawPointer? {
    return _position
  }


  /// Binds this buffer’s memory to the specified type and returns a typed buffer 
  /// of the bound memory.
  ///
  /// Use the `bindMemory(to:)` method to bind the memory referenced
  /// by this buffer to the type `T`. The memory must be uninitialized or
  /// initialized to a type that is layout compatible with `T`. If the memory
  /// is uninitialized, it is still uninitialized after being bound to `T`.
  ///
  /// - Warning: A memory location may only be bound to one type at a time. The
  ///   behavior of accessing memory as a type unrelated to its bound type is
  ///   undefined.
  ///
  /// - Parameters:
  ///   - type: The type `T` to bind the memory to.
  /// - Returns: A typed buffer of the newly bound memory. The memory in this
  ///   region is bound to `T`, but has not been modified in any other way.
  ///   The typed buffer references `self.count / MemoryLayout<T>.stride` instances of `T`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  @discardableResult
  public func bindMemory<T>(
    to type: T.Type
  ) -> UnsafeBufferPointer<T> {
    guard let base = _position else {
      return UnsafeBufferPointer<T>(start: nil, count: 0)
    }

    let capacity = count / MemoryLayout<T>.stride
    Builtin.bindMemory(base._rawValue, capacity._builtinWordValue, type)
    return UnsafeBufferPointer<T>(
      start: UnsafePointer<T>(base._rawValue), count: capacity)
  }
}

extension UnsafeRawBufferPointer : CustomDebugStringConvertible {
  /// A textual representation of the buffer, suitable for debugging.
  @_inlineable // FIXME(sil-serialize-all)
  public var debugDescription: String {
    return "UnsafeRawBufferPointer"
      + "(start: \(_position.map(String.init(describing:)) ?? "nil"), count: \(count))"
  }
}

extension UnsafeRawBufferPointer {
  @_inlineable // FIXME(sil-serialize-all)
  @available(*, unavailable, 
    message: "use 'UnsafeRawBufferPointer(rebasing:)' to convert a slice into a zero-based raw buffer.")
  public subscript(bounds: Range<Int>) -> UnsafeRawBufferPointer {
    get { return UnsafeRawBufferPointer(start: nil, count: 0) }
  }

}


/// Invokes the given closure with a mutable buffer pointer covering the raw
/// bytes of the given argument.
///
/// The buffer pointer argument to the `body` closure provides a collection
/// interface to the raw bytes of `arg`. The buffer is the size of the
/// instance passed as `arg` and does not include any remote storage.
///
/// - Parameters:
///   - arg: An instance to temporarily access through a mutable raw buffer
///     pointer.
///   - body: A closure that takes a raw buffer pointer to the bytes of `arg`
///     as its sole argument. If the closure has a return value, that value is
///     also used as the return value of the `withUnsafeMutableBytes(of:_:)`
///     function. The buffer pointer argument is valid only for the duration
///     of the closure's execution.
/// - Returns: The return value, if any, of the `body` closure.
@_inlineable
public func withUnsafeMutableBytes<T, Result>(
  of arg: inout T,
  _ body: (UnsafeMutableRawBufferPointer) throws -> Result
) rethrows -> Result
{
  return try withUnsafeMutablePointer(to: &arg) {
    return try body(UnsafeMutableRawBufferPointer(
        start: $0, count: MemoryLayout<T>.size))
  }
}

/// Invokes the given closure with a buffer pointer covering the raw bytes of
/// the given argument.
///
/// The buffer pointer argument to the `body` closure provides a collection
/// interface to the raw bytes of `arg`. The buffer is the size of the
/// instance passed as `arg` and does not include any remote storage.
///
/// - Parameters:
///   - arg: An instance to temporarily access through a raw buffer pointer.
///   - body: A closure that takes a raw buffer pointer to the bytes of `arg`
///     as its sole argument. If the closure has a return value, that value is
///     also used as the return value of the `withUnsafeBytes(of:_:)`
///     function. The buffer pointer argument is valid only for the duration
///     of the closure's execution.
/// - Returns: The return value, if any, of the `body` closure.
@_inlineable
public func withUnsafeBytes<T, Result>(
  of arg: inout T,
  _ body: (UnsafeRawBufferPointer) throws -> Result
) rethrows -> Result
{
  return try withUnsafePointer(to: &arg) {
    try body(UnsafeRawBufferPointer(start: $0, count: MemoryLayout<T>.size))
  }
}

// @available(*, deprecated, renamed: "UnsafeRawBufferPointer.Iterator")
public typealias UnsafeRawBufferPointerIterator<T> = UnsafeBufferPointer<T>.Iterator

// @available(*, deprecated, renamed: "UnsafeRawBufferPointer.Iterator")
public typealias UnsafeMutableRawBufferPointerIterator<T> = UnsafeBufferPointer<T>.Iterator
