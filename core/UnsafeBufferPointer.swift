//===--- UnsafeBufferPointer.swift.gyb ------------------------*- swift -*-===//
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


/// A nonowning collection interface to a buffer of mutable
/// elements stored contiguously in memory.
///
/// You can use an `UnsafeMutableBufferPointer` instance in low level operations to eliminate
/// uniqueness checks and, in release mode, bounds checks. Bounds checks are
/// always performed in debug mode.
///
/// UnsafeMutableBufferPointer Semantics
/// =================
///
/// An `UnsafeMutableBufferPointer` instance is a view into memory and does not own the memory
/// that it references. Copying a value of type `UnsafeMutableBufferPointer` does not copy the
/// instances stored in the underlying memory. However, initializing another
/// collection with an `UnsafeMutableBufferPointer` instance copies the instances out of the
/// referenced memory and into the new collection.
// FIXME: rdar://18157434 - until this is fixed, this has to be fixed layout
// to avoid a hang in Foundation, which has the following setup:
// struct A { struct B { let x: UnsafeMutableBufferPointer<...> } let b: B }
@_fixed_layout
public struct UnsafeMutableBufferPointer<Element> {
  @_versioned
  let _position, _end: UnsafeMutablePointer<Element>?
}

extension UnsafeMutableBufferPointer {
  public typealias Iterator = UnsafeBufferPointer<Element>.Iterator
}

extension UnsafeMutableBufferPointer: Sequence {
  /// Returns an iterator over the elements of this buffer.
  ///
  /// - Returns: An iterator over the elements of this buffer.
  @_inlineable
  public func makeIterator() -> Iterator {
    return Iterator(_position: _position, _end: _end)
  }

  /// Initializes the memory at `destination.baseAddress` with elements of `self`,
  /// stopping when either `self` or `destination` is exhausted.
  ///
  /// - Returns: an iterator over any remaining elements of `self` and the
  ///   number of elements initialized.
  @_inlineable // FIXME(sil-serialize-all)
  public func _copyContents(
    initializing destination: UnsafeMutableBufferPointer<Element>
  ) -> (Iterator, UnsafeMutableBufferPointer<Element>.Index) {
    guard !isEmpty && !destination.isEmpty else { return (makeIterator(), 0) }
    let s = self.baseAddress._unsafelyUnwrappedUnchecked
    let d = destination.baseAddress._unsafelyUnwrappedUnchecked
    let n = Swift.min(destination.count, self.count)
    d.initialize(from: s, count: n)
    return (Iterator(_position: s + n, _end: _end), n)
  }
}

extension UnsafeMutableBufferPointer: MutableCollection, RandomAccessCollection {
  public typealias Index = Int
  public typealias Indices = CountableRange<Int>

  /// The index of the first element in a nonempty buffer.
  ///
  /// The `startIndex` property of an `UnsafeMutableBufferPointer` instance
  /// is always zero.
  @_inlineable
  public var startIndex: Int { return 0 }

  /// The "past the end" position---that is, the position one greater than the
  /// last valid subscript argument.
  ///
  /// The `endIndex` property of an `UnsafeMutableBufferPointer` instance is
  /// always identical to `count`.
  @_inlineable
  public var endIndex: Int { return count }

  @_inlineable
  public func index(after i: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return i + 1
  }

  @_inlineable
  public func formIndex(after i: inout Int) {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    i += 1
  }

  @_inlineable
  public func index(before i: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return i - 1
  }

  @_inlineable
  public func formIndex(before i: inout Int) {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    i -= 1
  }

  @_inlineable
  public func index(_ i: Int, offsetBy n: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return i + n
  }

  @_inlineable
  public func index(_ i: Int, offsetBy n: Int, limitedBy limit: Int) -> Int? {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    let l = limit - i
    if n > 0 ? l >= 0 && l < n : l <= 0 && n < l {
      return nil
    }
    return i + n
  }

  @_inlineable
  public func distance(from start: Int, to end: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return end - start
  }

  @_inlineable
  public func _failEarlyRangeCheck(_ index: Int, bounds: Range<Int>) {
    // NOTE: This method is a no-op for performance reasons.
  }

  @_inlineable
  public func _failEarlyRangeCheck(_ range: Range<Int>, bounds: Range<Int>) {
    // NOTE: This method is a no-op for performance reasons.
  }

  @_inlineable
  public var indices: Indices {
    return startIndex..<endIndex
  }

  /// The number of elements in the buffer.
  ///
  /// If the `baseAddress` of this buffer is `nil`, the count is zero. However,
  /// a buffer can have a `count` of zero even with a non-`nil` base address.
  @_inlineable
  public var count: Int {
    guard let start = _position, let end = _end else {
      return 0
    }
    
    return end - start
  }

  /// Accesses the element at the specified position.
  ///
  /// The following example uses the buffer pointer's subscript to access and
  /// modify the elements of a mutable buffer pointing to the contiguous
  /// contents of an array:
  ///
  ///     var numbers = [1, 2, 3, 4, 5]
  ///     numbers.withUnsafeMutableBufferPointer { buffer in
  ///         for i in stride(from: buffer.startIndex, to: buffer.endIndex - 1, by: 2) {
  ///             let x = buffer[i]
  ///             buffer[i + 1] = buffer[i]
  ///             buffer[i] = x
  ///         }
  ///     }
  ///     print(numbers)
  ///     // Prints "[2, 1, 4, 3, 5]"
  ///
  /// - Note: Bounds checks for `i` are performed only in debug mode.
  ///
  /// - Parameter i: The position of the element to access. `i` must be in the
  ///   range `0..<count`.
  @_inlineable
  public subscript(i: Int) -> Element {
    get {
      _debugPrecondition(i >= 0)
      _debugPrecondition(i < endIndex)
      return _position![i]
    }
    nonmutating set {
      _debugPrecondition(i >= 0)
      _debugPrecondition(i < endIndex)
      _position![i] = newValue
    }
  }

  @_inlineable
  public subscript(bounds: Range<Int>)
    -> Slice<UnsafeMutableBufferPointer<Element>>
  {
    get {
      _debugPrecondition(bounds.lowerBound >= startIndex)
      _debugPrecondition(bounds.upperBound <= endIndex)
      return Slice(
        base: self, bounds: bounds)
    }
    set {
      _debugPrecondition(bounds.lowerBound >= startIndex)
      _debugPrecondition(bounds.upperBound <= endIndex)
      // FIXME: swift-3-indexing-model: tests.
      _writeBackMutableSlice(&self, bounds: bounds, slice: newValue)
    }
  }
}

extension UnsafeMutableBufferPointer {
  /// Creates a new buffer pointer over the specified number of contiguous
  /// instances beginning at the given pointer.
  ///
  /// - Parameters:
  ///   - start: A pointer to the start of the buffer, or `nil`. If `start` is
  ///     `nil`, `count` must be zero. However, `count` may be zero even for a
  ///     non-`nil` `start`. The pointer passed as `start` must be aligned to
  ///     `MemoryLayout<Element>.alignment`.
  ///   - count: The number of instances in the buffer. `count` must not be
  ///     negative.
  @_inlineable
  public init(start: UnsafeMutablePointer<Element>?, count: Int) {
    _precondition(
      count >= 0, "UnsafeMutableBufferPointer with negative count")
    _precondition(
      count == 0 || start != nil,
      "UnsafeMutableBufferPointer has a nil start and nonzero count")
    _position = start
    _end = start.map { $0 + count }
  }

  /// Creates a buffer pointer starting at `start` and extending up to the last
  /// addressable pointer to `Element` in the memory space
  @_inlineable
  public init(_unboundedStartingAt start: UnsafeMutablePointer<Element>) {
    _position = start
    _end = type(of: start)._max
  }

  @_inlineable
  public init(_empty: ()) {
    _position = UnsafeMutablePointer._max
    _end = _position
  }


  /// Creates a mutable typed buffer pointer referencing the same memory as the 
  /// given immutable buffer pointer.
  ///
  /// - Parameter other: The immutable buffer pointer to convert.
  @_inlineable
  public init(mutating other: UnsafeBufferPointer<Element>) {
    _position = UnsafeMutablePointer<Element>(mutating: other._position)
    _end = UnsafeMutablePointer<Element>(mutating: other._end)
  }

  

  /// Creates a buffer over the same memory as the given buffer slice.
  ///
  /// The new buffer represents the same region of memory as `slice`, but is
  /// indexed starting at zero instead of sharing indices with the original
  /// buffer. For example:
  ///
  ///     let buffer = returnsABuffer()
  ///     let n = 5
  ///     let slice = buffer[n...]
  ///     let rebased = UnsafeMutableBufferPointer(rebasing: slice)
  ///
  /// After rebasing `slice` as the `rebased` buffer, the following are true:
  ///
  /// - `rebased.startIndex == 0`
  /// - `rebased[0] == slice[n]`
  /// - `rebased[0] == buffer[n]`
  /// - `rebased.count == slice.count`
  ///
  /// - Parameter slice: The buffer slice to rebase.
  @_inlineable
  public init(rebasing slice: Slice<UnsafeMutableBufferPointer<Element>>) {
    self.init(
      start: slice.base.baseAddress! + slice.startIndex,
      count: slice.count)
  }

  /// Deallocates the memory block previously allocated at this buffer pointer’s 
  /// base address. 
  ///
  /// This buffer pointer's `baseAddress` must be `nil` or a pointer to a memory 
  /// block previously returned by a Swift allocation method. If `baseAddress` is 
  /// `nil`, this function does nothing. Otherwise, the memory must not be initialized 
  /// or `Pointee` must be a trivial type. This buffer pointer's `count` must 
  /// be equal to the originally allocated size of the memory block.
  @_inlineable
  public func deallocate() {
    _position?.deallocate()
  }


  /// Allocates uninitialized memory for the specified number of instances of
  /// type `Element`.
  ///
  /// The resulting buffer references a region of memory that is bound to
  /// `Element` and is `count * MemoryLayout<Element>.stride` bytes in size.
  /// 
  /// The following example allocates a buffer that can store four `Int` 
  /// instances and then initializes that memory with the elements of a range:
  /// 
  ///     let buffer = UnsafeMutableBufferPointer<Int>.allocate(capacity: 4)
  ///     _ = buffer.initialize(from: 1...4)
  ///     print(buffer[2])
  ///     // Prints "3"
  ///
  /// When you allocate memory, always remember to deallocate once you're
  /// finished.
  ///
  ///     buffer.deallocate()
  ///
  /// - Parameter count: The amount of memory to allocate, counted in instances
  ///   of `Element`. 
  @_inlineable
  public static func allocate(capacity count: Int) 
    -> UnsafeMutableBufferPointer<Element> {
    let size = MemoryLayout<Element>.stride * count
    let raw  = Builtin.allocRaw(size._builtinWordValue, Builtin.alignof(Element.self))
    Builtin.bindMemory(raw, count._builtinWordValue, Element.self)
    return UnsafeMutableBufferPointer(
      start: UnsafeMutablePointer(raw), count: count)
  }
  
  /// Initializes every element in this buffer's memory to a copy of the given value.
  ///
  /// The destination memory must be uninitialized or the buffer's `Element`
  /// must be a trivial type. After a call to `initialize(repeating:)`, the
  /// entire region of memory referenced by this buffer is initialized.
  ///
  /// - Parameters:
  ///   - repeatedValue: The instance to initialize this buffer's memory with.
  @_inlineable
  public func initialize(repeating repeatedValue: Element) {
    guard let dstBase = _position else {
      return
    }

    dstBase.initialize(repeating: repeatedValue, count: _end! - dstBase)
  }
  
  /// Assigns every element in this buffer's memory to a copy of the given value.
  ///
  /// The buffer’s memory must be initialized or the buffer's `Element`
  /// must be a trivial type. 
  ///
  /// - Parameters:
  ///   - repeatedValue: The instance to assign this buffer's memory to.
  ///
  /// Warning: All buffer elements must be initialized before calling this. 
  /// Assigning to part of the buffer must be done using the `assign(repeating:count:)`` 
  /// method on the buffer’s `baseAddress`. 
  @_inlineable
  public func assign(repeating repeatedValue: Element) {
    guard let dstBase = _position else {
      return
    }

    dstBase.assign(repeating: repeatedValue, count: _end! - dstBase)
  }
  

  /// Executes the given closure while temporarily binding the memory referenced 
  /// by this buffer to the given type.
  ///
  /// Use this method when you have a buffer of memory bound to one type and
  /// you need to access that memory as a buffer of another type. Accessing
  /// memory as type `T` requires that the memory be bound to that type. A
  /// memory location may only be bound to one type at a time, so accessing
  /// the same memory as an unrelated type without first rebinding the memory
  /// is undefined.
  ///
  /// The entire region of memory referenced by this buffer must be initialized.
  /// 
  /// Because this buffer's memory is no longer bound to its `Element` type
  /// while the `body` closure executes, do not access memory using the
  /// original buffer from within `body`. Instead, use the `body` closure's
  /// buffer argument to access the values in memory as instances of type
  /// `T`.
  ///
  /// After executing `body`, this method rebinds memory back to the original
  /// `Element` type.
  ///
  /// - Note: Only use this method to rebind the buffer's memory to a type
  ///   with the same size and stride as the currently bound `Element` type.
  ///   To bind a region of memory to a type that is a different size, convert
  ///   the buffer to a raw buffer and use the `bindMemory(to:)` method.
  ///
  /// - Parameters:
  ///   - type: The type to temporarily bind the memory referenced by this
  ///     buffer. The type `T` must have the same size and be layout compatible
  ///     with the pointer's `Element` type.
  ///   - body: A closure that takes a mutable typed buffer to the
  ///     same memory as this buffer, only bound to type `T`. The buffer argument 
  ///     contains the same number of complete instances of `T` as the original  
  ///     buffer’s `count`. The closure's buffer argument is valid only for the 
  ///     duration of the closure's execution. If `body` has a return value, that 
  ///     value is also used as the return value for the `withMemoryRebound(to:_:)` 
  ///     method.
  /// - Returns: The return value, if any, of the `body` closure parameter.
  @_inlineable
  public func withMemoryRebound<T, Result>(
    to type: T.Type, _ body: (UnsafeMutableBufferPointer<T>) throws -> Result
  ) rethrows -> Result {
    if let base = _position {
      _debugPrecondition(MemoryLayout<Element>.stride == MemoryLayout<T>.stride)
      Builtin.bindMemory(base._rawValue, count._builtinWordValue, T.self)
      defer {
        Builtin.bindMemory(base._rawValue, count._builtinWordValue, Element.self)
      }

      return try body(UnsafeMutableBufferPointer<T>(
        start: UnsafeMutablePointer<T>(base._rawValue), count: count))
    }
    else {
      return try body(UnsafeMutableBufferPointer<T>(start: nil, count: 0))
    }
  }

  /// A pointer to the first element of the buffer.
  ///
  /// If the `baseAddress` of this buffer is `nil`, the count is zero. However,
  /// a buffer can have a `count` of zero even with a non-`nil` base address.
  @_inlineable
  public var baseAddress: UnsafeMutablePointer<Element>? {
    return _position
  }
}

extension UnsafeMutableBufferPointer : CustomDebugStringConvertible {
  /// A textual representation of the buffer, suitable for debugging.
  @_inlineable // FIXME(sil-serialize-all)
  public var debugDescription: String {
    return "UnsafeMutableBufferPointer"
      + "(start: \(_position.map(String.init(describing:)) ?? "nil"), count: \(count))"
  }
}
/// A nonowning collection interface to a buffer of 
/// elements stored contiguously in memory.
///
/// You can use an `UnsafeBufferPointer` instance in low level operations to eliminate
/// uniqueness checks and, in release mode, bounds checks. Bounds checks are
/// always performed in debug mode.
///
/// UnsafeBufferPointer Semantics
/// =================
///
/// An `UnsafeBufferPointer` instance is a view into memory and does not own the memory
/// that it references. Copying a value of type `UnsafeBufferPointer` does not copy the
/// instances stored in the underlying memory. However, initializing another
/// collection with an `UnsafeBufferPointer` instance copies the instances out of the
/// referenced memory and into the new collection.
// FIXME: rdar://18157434 - until this is fixed, this has to be fixed layout
// to avoid a hang in Foundation, which has the following setup:
// struct A { struct B { let x: UnsafeMutableBufferPointer<...> } let b: B }
@_fixed_layout
public struct UnsafeBufferPointer<Element> {
  @_versioned
  let _position, _end: UnsafePointer<Element>?
}

extension UnsafeBufferPointer {
  /// An iterator for the elements in the buffer referenced by an
  /// `UnsafeBufferPointer` or `UnsafeMutableBufferPointer` instance.
  @_fixed_layout
  public struct Iterator {
    @_versioned
    internal var _position, _end: UnsafePointer<Element>?

    @_inlineable
    public init(_position: UnsafePointer<Element>?, _end: UnsafePointer<Element>?) {
        self._position = _position
        self._end = _end
    }
  }
}

extension UnsafeBufferPointer.Iterator: IteratorProtocol {
  /// Advances to the next element and returns it, or `nil` if no next element
  /// exists.
  ///
  /// Once `nil` has been returned, all subsequent calls return `nil`.
  @_inlineable
  public mutating func next() -> Element? {
    if _position == _end { return nil }

    let result = _position!.pointee
    _position! += 1
    return result
  }
}

extension UnsafeBufferPointer: Sequence {
  /// Returns an iterator over the elements of this buffer.
  ///
  /// - Returns: An iterator over the elements of this buffer.
  @_inlineable
  public func makeIterator() -> Iterator {
    return Iterator(_position: _position, _end: _end)
  }

  /// Initializes the memory at `destination.baseAddress` with elements of `self`,
  /// stopping when either `self` or `destination` is exhausted.
  ///
  /// - Returns: an iterator over any remaining elements of `self` and the
  ///   number of elements initialized.
  @_inlineable // FIXME(sil-serialize-all)
  public func _copyContents(
    initializing destination: UnsafeMutableBufferPointer<Element>
  ) -> (Iterator, UnsafeMutableBufferPointer<Element>.Index) {
    guard !isEmpty && !destination.isEmpty else { return (makeIterator(), 0) }
    let s = self.baseAddress._unsafelyUnwrappedUnchecked
    let d = destination.baseAddress._unsafelyUnwrappedUnchecked
    let n = Swift.min(destination.count, self.count)
    d.initialize(from: s, count: n)
    return (Iterator(_position: s + n, _end: _end), n)
  }
}

extension UnsafeBufferPointer: Collection, RandomAccessCollection {
  public typealias Index = Int
  public typealias Indices = CountableRange<Int>

  /// The index of the first element in a nonempty buffer.
  ///
  /// The `startIndex` property of an `UnsafeBufferPointer` instance
  /// is always zero.
  @_inlineable
  public var startIndex: Int { return 0 }

  /// The "past the end" position---that is, the position one greater than the
  /// last valid subscript argument.
  ///
  /// The `endIndex` property of an `UnsafeBufferPointer` instance is
  /// always identical to `count`.
  @_inlineable
  public var endIndex: Int { return count }

  @_inlineable
  public func index(after i: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return i + 1
  }

  @_inlineable
  public func formIndex(after i: inout Int) {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    i += 1
  }

  @_inlineable
  public func index(before i: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return i - 1
  }

  @_inlineable
  public func formIndex(before i: inout Int) {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    i -= 1
  }

  @_inlineable
  public func index(_ i: Int, offsetBy n: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return i + n
  }

  @_inlineable
  public func index(_ i: Int, offsetBy n: Int, limitedBy limit: Int) -> Int? {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    let l = limit - i
    if n > 0 ? l >= 0 && l < n : l <= 0 && n < l {
      return nil
    }
    return i + n
  }

  @_inlineable
  public func distance(from start: Int, to end: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return end - start
  }

  @_inlineable
  public func _failEarlyRangeCheck(_ index: Int, bounds: Range<Int>) {
    // NOTE: This method is a no-op for performance reasons.
  }

  @_inlineable
  public func _failEarlyRangeCheck(_ range: Range<Int>, bounds: Range<Int>) {
    // NOTE: This method is a no-op for performance reasons.
  }

  @_inlineable
  public var indices: Indices {
    return startIndex..<endIndex
  }

  /// The number of elements in the buffer.
  ///
  /// If the `baseAddress` of this buffer is `nil`, the count is zero. However,
  /// a buffer can have a `count` of zero even with a non-`nil` base address.
  @_inlineable
  public var count: Int {
    guard let start = _position, let end = _end else {
      return 0
    }
    
    return end - start
  }

  /// Accesses the element at the specified position.
  ///
  /// The following example uses the buffer pointer's subscript to access every
  /// other element of the buffer:
  ///
  ///     let numbers = [1, 2, 3, 4, 5]
  ///     let sum = numbers.withUnsafeBufferPointer { buffer -> Int in
  ///         var result = 0
  ///         for i in stride(from: buffer.startIndex, to: buffer.endIndex, by: 2) {
  ///             result += buffer[i]
  ///         }
  ///         return result
  ///     }
  ///     // 'sum' == 9
  ///
  /// - Note: Bounds checks for `i` are performed only in debug mode.
  ///
  /// - Parameter i: The position of the element to access. `i` must be in the
  ///   range `0..<count`.
  @_inlineable
  public subscript(i: Int) -> Element {
    get {
      _debugPrecondition(i >= 0)
      _debugPrecondition(i < endIndex)
      return _position![i]
    }
  }

  @_inlineable
  public subscript(bounds: Range<Int>)
    -> Slice<UnsafeBufferPointer<Element>>
  {
    get {
      _debugPrecondition(bounds.lowerBound >= startIndex)
      _debugPrecondition(bounds.upperBound <= endIndex)
      return Slice(
        base: self, bounds: bounds)
    }
  }
}

extension UnsafeBufferPointer {
  /// Creates a new buffer pointer over the specified number of contiguous
  /// instances beginning at the given pointer.
  ///
  /// - Parameters:
  ///   - start: A pointer to the start of the buffer, or `nil`. If `start` is
  ///     `nil`, `count` must be zero. However, `count` may be zero even for a
  ///     non-`nil` `start`. The pointer passed as `start` must be aligned to
  ///     `MemoryLayout<Element>.alignment`.
  ///   - count: The number of instances in the buffer. `count` must not be
  ///     negative.
  @_inlineable
  public init(start: UnsafePointer<Element>?, count: Int) {
    _precondition(
      count >= 0, "UnsafeBufferPointer with negative count")
    _precondition(
      count == 0 || start != nil,
      "UnsafeBufferPointer has a nil start and nonzero count")
    _position = start
    _end = start.map { $0 + count }
  }

  /// Creates a buffer pointer starting at `start` and extending up to the last
  /// addressable pointer to `Element` in the memory space
  @_inlineable
  public init(_unboundedStartingAt start: UnsafePointer<Element>) {
    _position = start
    _end = type(of: start)._max
  }

  @_inlineable
  public init(_empty: ()) {
    _position = UnsafePointer._max
    _end = _position
  }


  /// Creates an immutable typed buffer pointer referencing the same memory as the 
  /// given mutable buffer pointer.
  ///
  /// - Parameter other: The mutable buffer pointer to convert.
  @_inlineable
  public init(_ other: UnsafeMutableBufferPointer<Element>) {
    _position = UnsafePointer<Element>(other._position)
    _end = UnsafePointer<Element>(other._end)
  }

  

  /// Creates a buffer over the same memory as the given buffer slice.
  ///
  /// The new buffer represents the same region of memory as `slice`, but is
  /// indexed starting at zero instead of sharing indices with the original
  /// buffer. For example:
  ///
  ///     let buffer = returnsABuffer()
  ///     let n = 5
  ///     let slice = buffer[n...]
  ///     let rebased = UnsafeBufferPointer(rebasing: slice)
  ///
  /// After rebasing `slice` as the `rebased` buffer, the following are true:
  ///
  /// - `rebased.startIndex == 0`
  /// - `rebased[0] == slice[n]`
  /// - `rebased[0] == buffer[n]`
  /// - `rebased.count == slice.count`
  ///
  /// - Parameter slice: The buffer slice to rebase.
  @_inlineable
  public init(rebasing slice: Slice<UnsafeBufferPointer<Element>>) {
    self.init(start: slice.base.baseAddress! + slice.startIndex,
      count: slice.count)
  }


  /// Creates a buffer over the same memory as the given buffer slice.
  ///
  /// The new buffer represents the same region of memory as `slice`, but is
  /// indexed starting at zero instead of sharing indices with the original
  /// buffer. For example:
  ///
  ///     let buffer = returnsABuffer()
  ///     let n = 5
  ///     let slice = buffer[n...]
  ///     let rebased = UnsafeBufferPointer(rebasing: slice)
  ///
  /// After rebasing `slice` as the `rebased` buffer, the following are true:
  ///
  /// - `rebased.startIndex == 0`
  /// - `rebased[0] == slice[n]`
  /// - `rebased[0] == buffer[n]`
  /// - `rebased.count == slice.count`
  ///
  /// - Parameter slice: The buffer slice to rebase.
  @_inlineable
  public init(rebasing slice: Slice<UnsafeMutableBufferPointer<Element>>) {
    self.init(
      start: slice.base.baseAddress! + slice.startIndex,
      count: slice.count)
  }

  /// Deallocates the memory block previously allocated at this buffer pointer’s 
  /// base address. 
  ///
  /// This buffer pointer's `baseAddress` must be `nil` or a pointer to a memory 
  /// block previously returned by a Swift allocation method. If `baseAddress` is 
  /// `nil`, this function does nothing. Otherwise, the memory must not be initialized 
  /// or `Pointee` must be a trivial type. This buffer pointer's `count` must 
  /// be equal to the originally allocated size of the memory block.
  @_inlineable
  public func deallocate() {
    _position?.deallocate()
  }


  /// Executes the given closure while temporarily binding the memory referenced 
  /// by this buffer to the given type.
  ///
  /// Use this method when you have a buffer of memory bound to one type and
  /// you need to access that memory as a buffer of another type. Accessing
  /// memory as type `T` requires that the memory be bound to that type. A
  /// memory location may only be bound to one type at a time, so accessing
  /// the same memory as an unrelated type without first rebinding the memory
  /// is undefined.
  ///
  /// The entire region of memory referenced by this buffer must be initialized.
  /// 
  /// Because this buffer's memory is no longer bound to its `Element` type
  /// while the `body` closure executes, do not access memory using the
  /// original buffer from within `body`. Instead, use the `body` closure's
  /// buffer argument to access the values in memory as instances of type
  /// `T`.
  ///
  /// After executing `body`, this method rebinds memory back to the original
  /// `Element` type.
  ///
  /// - Note: Only use this method to rebind the buffer's memory to a type
  ///   with the same size and stride as the currently bound `Element` type.
  ///   To bind a region of memory to a type that is a different size, convert
  ///   the buffer to a raw buffer and use the `bindMemory(to:)` method.
  ///
  /// - Parameters:
  ///   - type: The type to temporarily bind the memory referenced by this
  ///     buffer. The type `T` must have the same size and be layout compatible
  ///     with the pointer's `Element` type.
  ///   - body: A closure that takes a  typed buffer to the
  ///     same memory as this buffer, only bound to type `T`. The buffer argument 
  ///     contains the same number of complete instances of `T` as the original  
  ///     buffer’s `count`. The closure's buffer argument is valid only for the 
  ///     duration of the closure's execution. If `body` has a return value, that 
  ///     value is also used as the return value for the `withMemoryRebound(to:_:)` 
  ///     method.
  /// - Returns: The return value, if any, of the `body` closure parameter.
  @_inlineable
  public func withMemoryRebound<T, Result>(
    to type: T.Type, _ body: (UnsafeBufferPointer<T>) throws -> Result
  ) rethrows -> Result {
    if let base = _position {
      _debugPrecondition(MemoryLayout<Element>.stride == MemoryLayout<T>.stride)
      Builtin.bindMemory(base._rawValue, count._builtinWordValue, T.self)
      defer {
        Builtin.bindMemory(base._rawValue, count._builtinWordValue, Element.self)
      }

      return try body(UnsafeBufferPointer<T>(
        start: UnsafePointer<T>(base._rawValue), count: count))
    }
    else {
      return try body(UnsafeBufferPointer<T>(start: nil, count: 0))
    }
  }

  /// A pointer to the first element of the buffer.
  ///
  /// If the `baseAddress` of this buffer is `nil`, the count is zero. However,
  /// a buffer can have a `count` of zero even with a non-`nil` base address.
  @_inlineable
  public var baseAddress: UnsafePointer<Element>? {
    return _position
  }
}

extension UnsafeBufferPointer : CustomDebugStringConvertible {
  /// A textual representation of the buffer, suitable for debugging.
  @_inlineable // FIXME(sil-serialize-all)
  public var debugDescription: String {
    return "UnsafeBufferPointer"
      + "(start: \(_position.map(String.init(describing:)) ?? "nil"), count: \(count))"
  }
}


extension UnsafeMutableBufferPointer {
  /// Initializes the buffer's memory with the given elements.
  ///
  /// When calling the `initialize(from:)` method on a buffer `b`, the memory
  /// referenced by `b` must be uninitialized or the `Element` type must be a
  /// trivial type. After the call, the memory referenced by this buffer up
  /// to, but not including, the returned index is initialized. The buffer
  /// must contain sufficient memory to accommodate
  /// `source.underestimatedCount`.
  ///
  /// The returned index is the position of the element in the buffer one past
  /// the last element written. If `source` contains no elements, the returned
  /// index is equal to the buffer's `startIndex`. If `source` contains an
  /// equal or greater number of elements than the buffer can hold, the
  /// returned index is equal to the buffer's `endIndex`.
  ///
  /// - Parameter source: A sequence of elements with which to initializer the
  ///   buffer.
  /// - Returns: An iterator to any elements of `source` that didn't fit in the
  ///   buffer, and an index to the point in the buffer one past the last
  ///   element written.
  @_inlineable
  public func initialize<S: Sequence>(from source: S) -> (S.Iterator, Index)
    where S.Element == Element {
    return source._copyContents(initializing: self)
  }
}

@available(*, deprecated, renamed: "UnsafeBufferPointer.Iterator")
public typealias UnsafeBufferPointerIterator<T> = UnsafeBufferPointer<T>.Iterator

// Local Variables:
// eval: (read-only-mode 1)
// End:
