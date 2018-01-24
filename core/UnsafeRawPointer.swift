//===--- UnsafeRawPointer.swift.gyb ---------------------------*- swift -*-===//
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



/// A raw pointer for accessing and manipulating
/// untyped data.
///
/// The `UnsafeMutableRawPointer` type provides no automated memory management, no type safety,
/// and no alignment guarantees. You are responsible for handling the life
/// cycle of any memory you work with through unsafe pointers, to avoid leaks
/// or undefined behavior.
///
/// Memory that you manually manage can be either *untyped* or *bound* to a
/// specific type. You use the `UnsafeMutableRawPointer` type to access and
/// manage raw bytes in memory, whether or not that memory has been bound to a
/// specific type.
///
/// Understanding a Pointer's Memory State
/// ======================================
///
/// The memory referenced by an `UnsafeMutableRawPointer` instance can be in one of several
/// states. Many pointer operations must only be applied to pointers with
/// memory in a specific state---you must keep track of the state of the
/// memory you are working with and understand the changes to that state that
/// different operations perform. Memory can be untyped and uninitialized,
/// bound to a type and uninitialized, or bound to a type and initialized to a
/// value. Finally, memory that was allocated previously may have been
/// deallocated, leaving existing pointers referencing unallocated memory.
///
/// Raw, Uninitialized Memory
/// -------------------------
///
/// Raw memory that has just been allocated is in an *uninitialized, untyped*
/// state. Uninitialized memory must be initialized with values of a type
/// before it can be used with any typed operations.
///
/// You can use methods like `initializeMemory(as:from:)` and
/// `moveInitializeMemory(as:from:count:)` to bind raw memory to a type and
/// initialize it with a value or series of values. To bind uninitialized
/// memory to a type without initializing it, use the `bindMemory(to:count:)`
/// method. These methods all return typed pointers for further typed access
/// to the memory.
///
/// Typed Memory
/// ------------
///
/// Memory that has been bound to a type, whether it is initialized or
/// uninitialized, is typically accessed using typed pointers---instances of
/// `UnsafePointer` and `UnsafeMutablePointer`. Initialization, assignment,
/// and deinitialization can be performed using `UnsafeMutablePointer`
/// methods.
///
/// Memory that has been bound to a type can be rebound to a different type
/// only after it has been deinitialized or if the bound type is a *trivial
/// type*. Deinitializing typed memory does not unbind that memory's type. The
/// deinitialized memory can be reinitialized with values of the same type,
/// bound to a new type, or deallocated.
///
/// - Note: A trivial type can be copied bit for bit with no indirection or
///   reference-counting operations. Generally, native Swift types that do not
///   contain strong or weak references or other forms of indirection are
///   trivial, as are imported C structs and enumerations.
///
/// When reading from or writing to  memory as raw
/// bytes when that memory is bound to a type, you must ensure that you
/// satisfy any alignment requirements.
/// Writing to typed memory as raw bytes must only be performed when the bound
/// type is a trivial type.
///
/// Raw Pointer Arithmetic
/// ======================
///
/// Pointer arithmetic with raw pointers is performed at the byte level. When
/// you add to or subtract from a raw pointer, the result is a new raw pointer
/// offset by that number of bytes. The following example allocates four bytes
/// of memory and stores `0xFF` in all four bytes:
///
///     let bytesPointer = UnsafeMutableRawPointer.allocate(byteCount: 4, alignment: 1)
///     bytesPointer.storeBytes(of: 0xFFFF_FFFF, as: UInt32.self)
///
///     // Load a value from the memory referenced by 'bytesPointer'
///     let x = bytesPointer.load(as: UInt8.self)       // 255
///
///     // Load a value from the last two allocated bytes
///     let offsetPointer = bytesPointer + 2
///     let y = offsetPointer.load(as: UInt16.self)     // 65535
///
/// The code above stores the value `0xFFFF_FFFF` into the four newly allocated
/// bytes, and then loads the first byte as a `UInt8` instance and the third
/// and fourth bytes as a `UInt16` instance.
///
/// Always remember to deallocate any memory that you allocate yourself.
///
///     bytesPointer.deallocate()
///
/// Implicit Casting and Bridging
/// =============================
///
/// When calling a function or method with an `UnsafeMutableRawPointer` parameter, you can pass
/// an instance of that specific pointer type, pass an instance of a
/// compatible pointer type, or use Swift's implicit bridging to pass a
/// compatible pointer.
///
/// For example, the `print(address:as:)` function in the following code sample
/// takes an `UnsafeMutableRawPointer` instance as its first parameter:
///
///     func print<T>(address p: UnsafeMutableRawPointer, as type: T.Type) {
///         let value = p.load(as: type)
///         print(value)
///     }
///
/// As is typical in Swift, you can call the `print(address:as:)` function with
/// an `UnsafeMutableRawPointer` instance. This example passes `rawPointer` as the initial
/// parameter.
///
///     // 'rawPointer' points to memory initialized with `Int` values.
///     let rawPointer: UnsafeMutableRawPointer = ...
///     print(address: rawPointer, as: Int.self)
///     // Prints "42"
///
/// Because typed pointers can be implicitly cast to raw pointers when passed
/// as a parameter, you can also call `print(address:as:)` with any mutable
/// typed pointer instance.
///
///     let intPointer: UnsafeMutablePointer<Int> = ...
///     print(address: intPointer, as: Int.self)
///     // Prints "42"
///
/// Alternatively, you can use Swift's *implicit bridging* to pass a pointer to
/// an instance or to the elements of an array. Use inout syntax to implicitly
/// create a pointer to an instance of any type. The following example uses
/// implicit bridging to pass a pointer to `value` when calling
/// `print(address:as:)`:
///
///     var value: Int = 23
///     print(address: &value, as: Int.self)
///     // Prints "23"
///
/// A mutable pointer to the elements of an array is implicitly created when
/// you pass the array using inout syntax. This example uses implicit bridging
/// to pass a pointer to the elements of `numbers` when calling
/// `print(address:as:)`.
///
///     var numbers = [5, 10, 15, 20]
///     print(address: &numbers, as: Int.self)
///     // Prints "5"
///
/// - Important: The pointer created through implicit bridging of an instance
///   or of an array's elements is only valid during the execution of the
///   called function. Escaping the pointer to use after the execution of the
///   function is undefined behavior. In particular, do not use implicit
///   bridging when calling an `UnsafeMutableRawPointer` initializer.
///
///       var number = 5
///       let numberPointer = UnsafeMutableRawPointer(&number)
///       // Accessing 'numberPointer' is undefined behavior.
@_fixed_layout
public struct UnsafeMutableRawPointer: _Pointer {
  /// The underlying raw pointer.
  /// Implements conformance to the public protocol `_Pointer`.
  public let _rawValue: Builtin.RawPointer

  /// Creates a new raw pointer from the given raw or typed pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeMutableRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The pointer to convert.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ other: UnsafeMutableRawPointer) {
    self = other
  }

  /// Creates a new raw pointer from the given raw or typed pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeMutableRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The pointer to convert. If `other` is `nil`, the
  ///   result is `nil`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init?(_ other: UnsafeMutableRawPointer?) {
    guard let unwrapped = other else { return nil }
    self = unwrapped
  }

  /// Creates a new raw pointer from a builtin raw pointer.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ _rawValue: Builtin.RawPointer) {
    self._rawValue = _rawValue
  }

  /// Creates a new raw pointer from the given opaque pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeMutableRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The opaque pointer to convert.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ other: OpaquePointer) {
    _rawValue = other._rawValue
  }

  /// Creates a new raw pointer from the given opaque pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeMutableRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The opaque pointer to convert. If `other` is `nil`,
  ///   the result is `nil`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init?(_ other: OpaquePointer?) {
    guard let unwrapped = other else { return nil }
    _rawValue = unwrapped._rawValue
  }

  /// Creates a new raw pointer from the given address, specified as a bit
  /// pattern.
  ///
  /// - Parameter bitPattern: A bit pattern to use for the address of the new
  ///   raw pointer. If `bitPattern` is zero, the result is `nil`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init?(bitPattern: Int) {
    if bitPattern == 0 { return nil }
    _rawValue = Builtin.inttoptr_Word(bitPattern._builtinWordValue)
  }

  /// Creates a new raw pointer from the given address, specified as a bit
  /// pattern.
  ///
  /// - Parameter bitPattern: A bit pattern to use for the address of the new
  ///   raw pointer. If `bitPattern` is zero, the result is `nil`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init?(bitPattern: UInt) {
    if bitPattern == 0 { return nil }
    _rawValue = Builtin.inttoptr_Word(bitPattern._builtinWordValue)
  }

  /// Creates a new raw pointer from the given typed pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeMutableRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The typed pointer to convert.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init<T>(_ other: UnsafeMutablePointer<T>) {
    _rawValue = other._rawValue
  }

  /// Creates a new raw pointer from the given typed pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeMutableRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The typed pointer to convert. If `other` is `nil`, the
  ///   result is `nil`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init?<T>(_ other: UnsafeMutablePointer<T>?) {
    guard let unwrapped = other else { return nil }
    _rawValue = unwrapped._rawValue
  }

  /// Creates a new mutable raw pointer from the given immutable raw pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeMutableRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The immutable raw pointer to convert.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(mutating other: UnsafeRawPointer) {
    _rawValue = other._rawValue
  }

  /// Creates a new mutable raw pointer from the given immutable raw pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeMutableRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The immutable raw pointer to convert. If `other` is
  ///   `nil`, the result is `nil`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init?(mutating other: UnsafeRawPointer?) {
    guard let unwrapped = other else { return nil }
    _rawValue = unwrapped._rawValue
  }


  @available(swift, deprecated: 4.1, obsoleted: 5.0.0, renamed: "allocate(byteCount:alignment:)")
  @_inlineable
  public static func allocate(
    bytes size: Int, alignedTo alignment: Int
  ) -> UnsafeMutableRawPointer {
    return UnsafeMutableRawPointer.allocate(byteCount: size, alignment: alignment)
  }

  /// Allocates uninitialized memory with the specified size and alignment.
  ///
  /// You are in charge of managing the allocated memory. Be sure to deallocate
  /// any memory that you manually allocate.
  ///
  /// The allocated memory is not bound to any specific type and must be bound
  /// before performing any typed operations. If you are using the memory for
  /// a specific type, allocate memory using the
  /// `UnsafeMutablePointer.allocate(capacity:)` static method instead.
  ///
  /// - Parameters:
  ///   - byteCount: The number of bytes to allocate. `byteCount` must not be negative.
  ///   - alignment: The alignment of the new region of allocated memory, in
  ///     bytes.
  /// - Returns: A pointer to a newly allocated region of memory. The memory is
  ///   allocated, but not initialized.
  @_inlineable
  public static func allocate(
    byteCount: Int, alignment: Int
  ) -> UnsafeMutableRawPointer {
    return UnsafeMutableRawPointer(Builtin.allocRaw(
        byteCount._builtinWordValue, alignment._builtinWordValue))
  }

  @available(swift, deprecated: 4.1, obsoleted: 5.0.0, message: "Swift currently only supports freeing entire heap blocks, use deallocate() instead")
  public func deallocate(bytes _: Int, alignedTo _: Int) { 
    self.deallocate()
  }

  /// Deallocates the previously allocated memory block referenced by this pointer.
  ///
  /// The memory to be deallocated must be uninitialized or initialized to a
  /// trivial type.
  @_inlineable
  public func deallocate() {
    Builtin.deallocRaw(_rawValue, (-1)._builtinWordValue, (-1)._builtinWordValue)
  }

  /// Binds the memory to the specified type and returns a typed pointer to the
  /// bound memory.
  ///
  /// Use the `bindMemory(to:capacity:)` method to bind the memory referenced
  /// by this pointer to the type `T`. The memory must be uninitialized or
  /// initialized to a type that is layout compatible with `T`. If the memory
  /// is uninitialized, it is still uninitialized after being bound to `T`.
  ///
  /// In this example, 100 bytes of raw memory are allocated for the pointer
  /// `bytesPointer`, and then the first four bytes are bound to the `Int8`
  /// type.
  ///
  ///     let count = 4
  ///     let bytesPointer = UnsafeMutableRawPointer.allocate(
  ///             bytes: 100,
  ///             alignedTo: MemoryLayout<Int8>.alignment)
  ///     let int8Pointer = bytesPointer.bindMemory(to: Int8.self, capacity: count)
  ///
  /// After calling `bindMemory(to:capacity:)`, the first four bytes of the
  /// memory referenced by `bytesPointer` are bound to the `Int8` type, though
  /// they remain uninitialized. The remainder of the allocated region is
  /// unbound raw memory. All 100 bytes of memory must eventually be
  /// deallocated.
  ///
  /// - Warning: A memory location may only be bound to one type at a time. The
  ///   behavior of accessing memory as a type unrelated to its bound type is
  ///   undefined.
  ///
  /// - Parameters:
  ///   - type: The type `T` to bind the memory to.
  ///   - count: The amount of memory to bind to type `T`, counted as instances
  ///     of `T`.
  /// - Returns: A typed pointer to the newly bound memory. The memory in this
  ///   region is bound to `T`, but has not been modified in any other way.
  ///   The number of bytes in this region is
  ///   `count * MemoryLayout<T>.stride`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  @discardableResult
  public func bindMemory<T>(
    to type: T.Type, capacity count: Int
  ) -> UnsafeMutablePointer<T> {
    Builtin.bindMemory(_rawValue, count._builtinWordValue, type)
    return UnsafeMutablePointer<T>(_rawValue)
  }

  /// Returns a typed pointer to the memory referenced by this pointer,
  /// assuming that the memory is already bound to the specified type.
  ///
  /// Use this method when you have a raw pointer to memory that has *already*
  /// been bound to the specified type. The memory starting at this pointer
  /// must be bound to the type `T`. Accessing memory through the returned
  /// pointer is undefined if the memory has not been bound to `T`. To bind
  /// memory to `T`, use `bindMemory(to:capacity:)` instead of this method.
  ///
  /// - Parameter to: The type `T` that the memory has already been bound to.
  /// - Returns: A typed pointer to the same memory as this raw pointer.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func assumingMemoryBound<T>(to: T.Type) -> UnsafeMutablePointer<T> {
    return UnsafeMutablePointer<T>(_rawValue)
  }


  @available(swift, deprecated: 4.1, obsoleted: 5.0.0, renamed: "initializeMemory(as:repeating:count:)")
  @discardableResult
  public func initializeMemory<T>(
    as type: T.Type, at offset: Int = 0, count: Int = 1, to repeatedValue: T
  ) -> UnsafeMutablePointer<T> { 
    return (self + offset * MemoryLayout<T>.stride).initializeMemory(
      as: type, repeating: repeatedValue, count: count)
  }
  
  /// Initializes the memory referenced by this pointer with the given value,
  /// binds the memory to the value's type, and returns a typed pointer to the
  /// initialized memory.
  ///
  /// The memory referenced by this pointer must be uninitialized or
  /// initialized to a trivial type, and must be properly aligned for
  /// accessing `T`.
  ///
  /// The following example allocates enough raw memory to hold four instances
  /// of `Int8`, and then uses the `initializeMemory(as:repeating:count:)` method
  /// to initialize the allocated memory.
  ///
  ///     let count = 4
  ///     let bytesPointer = UnsafeMutableRawPointer.allocate(
  ///             byteCount: count * MemoryLayout<Int8>.stride,
  ///             alignment: MemoryLayout<Int8>.alignment)
  ///     let int8Pointer = myBytes.initializeMemory(
  ///             as: Int8.self, repeating: 0, count: count)
  ///
  ///     // After using 'int8Pointer':
  ///     int8Pointer.deallocate()
  ///
  /// After calling this method on a raw pointer `p`, the region starting at
  /// `self` and continuing up to `p + count * MemoryLayout<T>.stride` is bound 
  /// to type `T` and initialized. If `T` is a nontrivial type, you must 
  /// eventually deinitialize or move from the values in this region to avoid leaks.
  ///
  /// - Parameters:
  ///   - type: The type to bind this memory to.
  ///   - repeatedValue: The instance to copy into memory.
  ///   - count: The number of copies of `value` to copy into memory. `count`
  ///     must not be negative. 
  /// - Returns: A typed pointer to the memory referenced by this raw pointer.
  @_inlineable
  @discardableResult
  public func initializeMemory<T>(
    as type: T.Type, repeating repeatedValue: T, count: Int
  ) -> UnsafeMutablePointer<T> {
    _debugPrecondition(count >= 0,
      "UnsafeMutableRawPointer.initializeMemory: negative count")

    Builtin.bindMemory(_rawValue, count._builtinWordValue, type)
    var nextPtr = self
    for _ in 0..<count {
      Builtin.initialize(repeatedValue, nextPtr._rawValue)
      nextPtr += MemoryLayout<T>.stride
    }
    return UnsafeMutablePointer(_rawValue)
  }

  /// Initializes the memory referenced by this pointer with the values
  /// starting at the given pointer, binds the memory to the values' type, and
  /// returns a typed pointer to the initialized memory.
  ///
  /// The memory referenced by this pointer must be uninitialized or
  /// initialized to a trivial type, and must be properly aligned for
  /// accessing `T`.
  ///
  /// The following example allocates enough raw memory to hold four instances
  /// of `Int8`, and then uses the `initializeMemory(as:from:count:)` method
  /// to initialize the allocated memory.
  ///
  ///     let count = 4
  ///     let bytesPointer = UnsafeMutableRawPointer.allocate(
  ///             bytes: count * MemoryLayout<Int8>.stride,
  ///             alignedTo: MemoryLayout<Int8>.alignment)
  ///     let values: [Int8] = [1, 2, 3, 4]
  ///     let int8Pointer = values.withUnsafeBufferPointer { buffer in
  ///         return bytesPointer.initializeMemory(as: Int8.self,
  ///                   from: buffer.baseAddress!,
  ///                   count: buffer.count)
  ///     }
  ///     // int8Pointer.pointee == 1
  ///     // (int8Pointer + 3).pointee == 4
  ///
  ///     // After using 'int8Pointer':
  ///     int8Pointer.deallocate(count)
  ///
  /// After calling this method on a raw pointer `p`, the region starting at
  /// `p` and continuing up to `p + count * MemoryLayout<T>.stride` is bound
  /// to type `T` and initialized. If `T` is a nontrivial type, you must
  /// eventually deinitialize or move from the values in this region to avoid
  /// leaks. The instances in the region `source..<(source + count)` are
  /// unaffected.
  ///
  /// - Parameters:
  ///   - type: The type to bind this memory to.
  ///   - source: A pointer to the values to copy. The memory in the region
  ///     `source..<(source + count)` must be initialized to type `T` and must
  ///     not overlap the destination region.
  ///   - count: The number of copies of `value` to copy into memory. `count`
  ///     must not be negative.
  /// - Returns: A typed pointer to the memory referenced by this raw pointer.
  @_inlineable
  @discardableResult
  public func initializeMemory<T>(
    as type: T.Type, from source: UnsafePointer<T>, count: Int
  ) -> UnsafeMutablePointer<T> {
    _debugPrecondition(
      count >= 0,
      "UnsafeMutableRawPointer.initializeMemory with negative count")
    _debugPrecondition(
      (UnsafeRawPointer(self + count * MemoryLayout<T>.stride)
        <= UnsafeRawPointer(source))
      || UnsafeRawPointer(source + count) <= UnsafeRawPointer(self),
      "UnsafeMutableRawPointer.initializeMemory overlapping range")

    Builtin.bindMemory(_rawValue, count._builtinWordValue, type)
    Builtin.copyArray(
      T.self, self._rawValue, source._rawValue, count._builtinWordValue)
    // This builtin is equivalent to:
    // for i in 0..<count {
    //   (self.assumingMemoryBound(to: T.self) + i).initialize(to: source[i])
    // }
    return UnsafeMutablePointer(_rawValue)
  }

  /// Initializes the memory referenced by this pointer with the values of the
  /// given collection, binds the memory to the values' type, and returns a
  /// typed pointer to the initialized memory.
  ///
  /// The memory referenced by this pointer must be uninitialized or
  /// initialized to a trivial type, and must be properly aligned for
  /// accessing `T`.
  ///
  /// The following example allocates enough raw memory to hold four instances
  /// of `Int8`, and then uses the `initializeMemory(as:from:)` method to
  /// initialize the allocated memory.
  ///
  ///     let count = 4
  ///     let bytesPointer = UnsafeMutableRawPointer.allocate(
  ///             bytes: count * MemoryLayout<Int8>.stride,
  ///             alignedTo: MemoryLayout<Int8>.alignment)
  ///     let values: [Int8] = [1, 2, 3, 4]
  ///     let int8Pointer = bytesPointer.initializeMemory(
  ///             as: Int8.self,
  ///             from: values)
  ///     // int8Pointer.pointee == 1
  ///     // (int8Pointer + 3).pointee == 4
  ///
  ///     // After using 'int8Pointer':
  ///     int8Pointer.deallocate(count)
  ///
  /// After calling this method on a raw pointer `p`, the region starting at
  /// `p` and continuing up to `p + count * MemoryLayout<T>.stride` is bound
  /// to type `T` and initialized. If `T` is a nontrivial type, you must
  /// eventually deinitialize or move from the values in this region to avoid
  /// leaks.
  ///
  /// - Parameters:
  ///   - type: The type to bind this memory to.
  ///   - source: A pointer to the values to copy. If `source` is an
  ///     `UnsafeBufferPointer` or `UnsafeMutableBufferPointer` instance, the
  ///     memory region referenced by `source` must not overlap the
  ///     destination region.
  /// - Returns: A typed pointer to the memory referenced by this raw pointer.
  // This is fundamentally unsafe since collections can underreport their count.
  @_inlineable
  @available(*, deprecated, message: "it will be removed in Swift 4.0.  Please use 'UnsafeMutableRawBufferPointer.initialize(from:)' instead")
  @discardableResult
  public func initializeMemory<C : Collection>(
    as type: C.Element.Type, from source: C
  ) -> UnsafeMutablePointer<C.Element> {
    // TODO: Optimize where `C` is a `ContiguousArrayBuffer`.
    // Initialize and bind each element of the container.
    var ptr = self
    for element in source {
      ptr.initializeMemory(as: C.Element.self, repeating: element, count: 1)
      ptr += MemoryLayout<C.Element>.stride
    }
    return UnsafeMutablePointer(_rawValue)
  }

  /// Initializes the memory referenced by this pointer with the values
  /// starting at the given pointer, binds the memory to the values' type,
  /// deinitializes the source memory, and returns a typed pointer to the
  /// newly initialized memory.
  ///
  /// The memory referenced by this pointer must be uninitialized or
  /// initialized to a trivial type, and must be properly aligned for
  /// accessing `T`.
  ///
  /// The memory in the region `source..<(source + count)` may overlap with the
  /// destination region. The `moveInitializeMemory(as:from:count:)` method
  /// automatically performs a forward or backward copy of all instances from
  /// the source region to their destination.
  ///
  /// After calling this method on a raw pointer `p`, the region starting at
  /// `p` and continuing up to `p + count * MemoryLayout<T>.stride` is bound
  /// to type `T` and initialized. If `T` is a nontrivial type, you must
  /// eventually deinitialize or move from the values in this region to avoid
  /// leaks. Any memory in the region `source..<(source + count)` that does
  /// not overlap with the destination region is returned to an uninitialized
  /// state.
  ///
  /// - Parameters:
  ///   - type: The type to bind this memory to.
  ///   - source: A pointer to the values to copy. The memory in the region
  ///     `source..<(source + count)` must be initialized to type `T`.
  ///   - count: The number of copies of `value` to copy into memory. `count`
  ///     must not be negative.
  /// - Returns: A typed pointer to the memory referenced by this raw pointer.
  @_inlineable
  @discardableResult
  public func moveInitializeMemory<T>(
    as type: T.Type, from source: UnsafeMutablePointer<T>, count: Int
  ) -> UnsafeMutablePointer<T> {
    _debugPrecondition(
      count >= 0,
      "UnsafeMutableRawPointer.moveInitializeMemory with negative count")

    Builtin.bindMemory(_rawValue, count._builtinWordValue, type)
    if self < UnsafeMutableRawPointer(source)
       || self >= UnsafeMutableRawPointer(source + count) {
      // initialize forward from a disjoint or following overlapping range.
      Builtin.takeArrayFrontToBack(
        T.self, self._rawValue, source._rawValue, count._builtinWordValue)
      // This builtin is equivalent to:
      // for i in 0..<count {
      //   (self.assumingMemoryBound(to: T.self) + i)
      //   .initialize(to: (source + i).move())
      // }
    }
    else {
      // initialize backward from a non-following overlapping range.
      Builtin.takeArrayBackToFront(
        T.self, self._rawValue, source._rawValue, count._builtinWordValue)
      // This builtin is equivalent to:
      // var src = source + count
      // var dst = self.assumingMemoryBound(to: T.self) + count
      // while dst != self {
      //   (--dst).initialize(to: (--src).move())
      // }
    }
    return UnsafeMutablePointer(_rawValue)
  }

  /// Returns a new instance of the given type, constructed from the raw memory
  /// at the specified offset.
  ///
  /// The memory at this pointer plus `offset` must be properly aligned for
  /// accessing `T` and initialized to `T` or another type that is layout
  /// compatible with `T`.
  ///
  /// - Parameters:
  ///   - offset: The offset from this pointer, in bytes. `offset` must be
  ///     nonnegative. The default is zero.
  ///   - type: The type of the instance to create.
  /// - Returns: A new instance of type `T`, read from the raw bytes at
  ///   `offset`. The returned instance is memory-managed and unassociated
  ///   with the value in the memory referenced by this pointer.
  @_inlineable
  public func load<T>(fromByteOffset offset: Int = 0, as type: T.Type) -> T {
    _debugPrecondition(0 == (UInt(bitPattern: self + offset)
        & (UInt(MemoryLayout<T>.alignment) - 1)),
      "load from misaligned raw pointer")

    return Builtin.loadRaw((self + offset)._rawValue)
  }

  /// Stores the given value's bytes into raw memory at the specified offset.
  ///
  /// The type `T` to be stored must be a trivial type. The memory at this
  /// pointer plus `offset` must be properly aligned for accessing `T`. The
  /// memory must also be uninitialized, initialized to `T`, or initialized to
  /// another trivial type that is layout compatible with `T`.
  ///
  /// After calling `storeBytes(of:toByteOffset:as:)`, the memory is
  /// initialized to the raw bytes of `value`. If the memory is bound to a
  /// type `U` that is layout compatible with `T`, then it contains a value of
  /// type `U`. Calling `storeBytes(of:toByteOffset:as:)` does not change the
  /// bound type of the memory.
  ///
  /// - Note: A trivial type can be copied with just a bit-for-bit copy without
  ///   any indirection or reference-counting operations. Generally, native
  ///   Swift types that do not contain strong or weak references or other
  ///   forms of indirection are trivial, as are imported C structs and enums.
  ///
  /// If you need to store a copy of a nontrivial value into memory, or to
  /// store a value into memory that contains a nontrivial value, you cannot
  /// use the `storeBytes(of:toByteOffset:as:)` method. Instead, you must know
  /// the type of value previously in memory and initialize or assign the
  /// memory. For example, to replace a value stored in a raw pointer `p`,
  /// where `U` is the current type and `T` is the new type, use a typed
  /// pointer to access and deinitialize the current value before initializing
  /// the memory with a new value.
  ///
  ///     let typedPointer = p.bindMemory(to: U.self, capacity: 1)
  ///     typedPointer.deinitialize(count: 1)
  ///     p.initializeMemory(as: T.self, to: newValue)
  ///
  /// - Parameters:
  ///   - value: The value to store as raw bytes.
  ///   - offset: The offset from this pointer, in bytes. `offset` must be
  ///     nonnegative. The default is zero.
  ///   - type: The type of `value`.
  @_inlineable
  public func storeBytes<T>(
    of value: T, toByteOffset offset: Int = 0, as type: T.Type
  ) {
    _debugPrecondition(0 == (UInt(bitPattern: self + offset)
        & (UInt(MemoryLayout<T>.alignment) - 1)),
      "storeBytes to misaligned raw pointer")

    var temp = value
    withUnsafeMutablePointer(to: &temp) { source in
      let rawSrc = UnsafeMutableRawPointer(source)._rawValue
      // FIXME: to be replaced by _memcpy when conversions are implemented.
      Builtin.int_memcpy_RawPointer_RawPointer_Int64(
        (self + offset)._rawValue, rawSrc, UInt64(MemoryLayout<T>.size)._value,
        /*alignment:*/ Int32()._value,
        /*volatile:*/ false._value)
    }
  }

  @available(swift, deprecated: 4.1, obsoleted: 5.0.0, renamed: "copyMemory(from:byteCount:)")
  public func copyBytes(from source: UnsafeRawPointer, count: Int) {
    copyMemory(from: source, byteCount: count)
  }
  
  /// Copies the specified number of bytes from the given raw pointer's memory
  /// into this pointer's memory.
  ///
  /// If the `byteCount` bytes of memory referenced by this pointer are bound to 
  /// a type `T`, then `T` must be a trivial type, this pointer and `source`
  /// must be properly aligned for accessing `T`, and `byteCount` must be a
  /// multiple of `MemoryLayout<T>.stride`.
  ///
  /// After calling `copyMemory(from:byteCount:)`, the `byteCount` bytes of memory
  /// referenced by this pointer are initialized to raw bytes. If the memory
  /// is bound to type `T`, then it contains values of type `T`.
  ///
  /// - Parameters:
  ///   - source: A pointer to the memory to copy bytes from. The memory in the
  ///     region `source..<(source + byteCount)` must be initialized to a trivial
  ///     type.
  ///   - byteCount: The number of bytes to copy. `byteCount` must not be negative.
  @_inlineable
  public func copyMemory(from source: UnsafeRawPointer, byteCount: Int) {
    _debugPrecondition(
      byteCount >= 0, "UnsafeMutableRawPointer.copyMemory with negative count")

    _memmove(dest: self, src: source, size: UInt(byteCount))
  }
}

extension UnsafeMutableRawPointer: Strideable {
  /// Returns the distance from this pointer to the given pointer.
  ///
  /// With pointers `p` and `q`, the result of `p.distance(to: q)` is
  /// equivalent to `q - p`.
  ///
  /// - Parameter x: The pointer to calculate the distance to.
  /// - Returns: The distance from this pointer to `x`, in bytes.
  @_inlineable
  public func distance(to x: UnsafeMutableRawPointer) -> Int {
    return Int(Builtin.sub_Word(Builtin.ptrtoint_Word(x._rawValue),
        Builtin.ptrtoint_Word(_rawValue)))
  }

  /// Returns a pointer offset from this pointer by the specified number of
  /// bytes.
  ///
  /// With pointer `p` and distance `n`, the result of `p.advanced(by: n)` is
  /// equivalent to `p + n`.
  ///
  /// The resulting pointer must be within the bounds of the same allocation as
  /// this pointer.
  ///
  /// - Parameter n: The number of bytes to offset this pointer. `n` may be
  ///   positive, negative, or zero.
  /// - Returns: A pointer offset from this pointer by `n` bytes.
  @_inlineable
  public func advanced(by n: Int) -> UnsafeMutableRawPointer {
    return UnsafeMutableRawPointer(Builtin.gepRaw_Word(_rawValue, n._builtinWordValue))
  }
}

extension UnsafeMutableRawPointer: Equatable {
  // - Note: This may be more efficient than Strideable's implementation
  //   calling UnsafeMutableRawPointer.distance().
  /// Returns a Boolean value indicating whether two pointers are equal.
  ///
  /// - Parameters:
  ///   - lhs: A pointer.
  ///   - rhs: Another pointer.
  /// - Returns: `true` if `lhs` and `rhs` reference the same memory address;
  ///   otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func == (lhs: UnsafeMutableRawPointer, rhs: UnsafeMutableRawPointer) -> Bool {
    return Bool(Builtin.cmp_eq_RawPointer(lhs._rawValue, rhs._rawValue))
  }
}

extension UnsafeMutableRawPointer: Comparable {
  // - Note: This is an unsigned comparison unlike Strideable's
  //   implementation.
  /// Returns a Boolean value indicating whether the first pointer references
  /// an earlier memory location than the second pointer.
  ///
  /// - Parameters:
  ///   - lhs: A pointer.
  ///   - rhs: Another pointer.
  /// - Returns: `true` if `lhs` references a memory address earlier than
  ///   `rhs`; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func < (lhs: UnsafeMutableRawPointer, rhs: UnsafeMutableRawPointer) -> Bool {
    return Bool(Builtin.cmp_ult_RawPointer(lhs._rawValue, rhs._rawValue))
  }
}

extension UnsafeMutableRawPointer: Hashable {
  /// The pointer's hash value.
  ///
  /// The hash value is not guaranteed to be stable across different
  /// invocations of the same program.  Do not persist the hash value across
  /// program runs.
  @_inlineable
  public var hashValue: Int {
    return Int(bitPattern: self)
  }
}

extension UnsafeMutableRawPointer : CustomDebugStringConvertible {
  /// A textual representation of the pointer, suitable for debugging.
  @_inlineable // FIXME(sil-serialize-all)
  public var debugDescription: String {
    return _rawPointerToString(_rawValue)
  }
}

extension UnsafeMutableRawPointer : CustomReflectable {
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    let ptrValue = UInt64(
      bitPattern: Int64(Int(Builtin.ptrtoint_Word(_rawValue))))
    return Mirror(self, children: ["pointerValue": ptrValue])
  }
}

extension UnsafeMutableRawPointer : CustomPlaygroundQuickLookable {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal var summary: String {
    let selfType = "UnsafeMutableRawPointer"
    let ptrValue = UInt64(
      bitPattern: Int64(Int(Builtin.ptrtoint_Word(_rawValue))))
    return ptrValue == 0
    ? "\(selfType)(nil)"
    : "\(selfType)(0x\(_uint64ToString(ptrValue, radix:16, uppercase:true)))"
  }

  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .text(summary)
  }
}

extension OpaquePointer {
  @_inlineable
  public init(_ from: UnsafeMutableRawPointer) {
    self._rawValue = from._rawValue
  }

  @_inlineable
  public init?(_ from: UnsafeMutableRawPointer?) {
    guard let unwrapped = from else { return nil }
    self._rawValue = unwrapped._rawValue
  }
}

extension Int {
  /// Creates a new value with the bit pattern of the given pointer.
  ///
  /// The new value represents the address of the pointer passed as `pointer`.
  /// If `pointer` is `nil`, the result is `0`.
  ///
  /// - Parameter pointer: The pointer to use as the source for the new
  ///   integer.
  @_inlineable
  public init(bitPattern pointer: UnsafeMutableRawPointer?) {
    if let pointer = pointer {
      self = Int(Builtin.ptrtoint_Word(pointer._rawValue))
    } else {
      self = 0
    }
  }
}

extension UInt {
  /// Creates a new value with the bit pattern of the given pointer.
  ///
  /// The new value represents the address of the pointer passed as `pointer`.
  /// If `pointer` is `nil`, the result is `0`.
  ///
  /// - Parameter pointer: The pointer to use as the source for the new
  ///   integer.
  @_inlineable
  public init(bitPattern pointer: UnsafeMutableRawPointer?) {
    if let pointer = pointer {
      self = UInt(Builtin.ptrtoint_Word(pointer._rawValue))
    } else {
      self = 0
    }
  }
}


/// A raw pointer for accessing 
/// untyped data.
///
/// The `UnsafeRawPointer` type provides no automated memory management, no type safety,
/// and no alignment guarantees. You are responsible for handling the life
/// cycle of any memory you work with through unsafe pointers, to avoid leaks
/// or undefined behavior.
///
/// Memory that you manually manage can be either *untyped* or *bound* to a
/// specific type. You use the `UnsafeRawPointer` type to access and
/// manage raw bytes in memory, whether or not that memory has been bound to a
/// specific type.
///
/// Understanding a Pointer's Memory State
/// ======================================
///
/// The memory referenced by an `UnsafeRawPointer` instance can be in one of several
/// states. Many pointer operations must only be applied to pointers with
/// memory in a specific state---you must keep track of the state of the
/// memory you are working with and understand the changes to that state that
/// different operations perform. Memory can be untyped and uninitialized,
/// bound to a type and uninitialized, or bound to a type and initialized to a
/// value. Finally, memory that was allocated previously may have been
/// deallocated, leaving existing pointers referencing unallocated memory.
///
/// Raw, Uninitialized Memory
/// -------------------------
///
/// Raw memory that has just been allocated is in an *uninitialized, untyped*
/// state. Uninitialized memory must be initialized with values of a type
/// before it can be used with any typed operations.
///
/// To bind uninitialized memory to a type without initializing it, use the
/// `bindMemory(to:count:)` method. This method returns a typed pointer
/// for further typed access to the memory.
///
/// Typed Memory
/// ------------
///
/// Memory that has been bound to a type, whether it is initialized or
/// uninitialized, is typically accessed using typed pointers---instances of
/// `UnsafePointer` and `UnsafeMutablePointer`. Initialization, assignment,
/// and deinitialization can be performed using `UnsafeMutablePointer`
/// methods.
///
/// Memory that has been bound to a type can be rebound to a different type
/// only after it has been deinitialized or if the bound type is a *trivial
/// type*. Deinitializing typed memory does not unbind that memory's type. The
/// deinitialized memory can be reinitialized with values of the same type,
/// bound to a new type, or deallocated.
///
/// - Note: A trivial type can be copied bit for bit with no indirection or
///   reference-counting operations. Generally, native Swift types that do not
///   contain strong or weak references or other forms of indirection are
///   trivial, as are imported C structs and enumerations.
///
/// When reading from  memory as raw
/// bytes when that memory is bound to a type, you must ensure that you
/// satisfy any alignment requirements.
///
/// Raw Pointer Arithmetic
/// ======================
///
/// Pointer arithmetic with raw pointers is performed at the byte level. When
/// you add to or subtract from a raw pointer, the result is a new raw pointer
/// offset by that number of bytes. The following example allocates four bytes
/// of memory and stores `0xFF` in all four bytes:
///
///     let bytesPointer = UnsafeMutableRawPointer.allocate(byteCount: 4, alignment: 1)
///     bytesPointer.storeBytes(of: 0xFFFF_FFFF, as: UInt32.self)
///
///     // Load a value from the memory referenced by 'bytesPointer'
///     let x = bytesPointer.load(as: UInt8.self)       // 255
///
///     // Load a value from the last two allocated bytes
///     let offsetPointer = bytesPointer + 2
///     let y = offsetPointer.load(as: UInt16.self)     // 65535
///
/// The code above stores the value `0xFFFF_FFFF` into the four newly allocated
/// bytes, and then loads the first byte as a `UInt8` instance and the third
/// and fourth bytes as a `UInt16` instance.
///
/// Always remember to deallocate any memory that you allocate yourself.
///
///     bytesPointer.deallocate()
///
/// Implicit Casting and Bridging
/// =============================
///
/// When calling a function or method with an `UnsafeRawPointer` parameter, you can pass
/// an instance of that specific pointer type, pass an instance of a
/// compatible pointer type, or use Swift's implicit bridging to pass a
/// compatible pointer.
///
/// For example, the `print(address:as:)` function in the following code sample
/// takes an `UnsafeRawPointer` instance as its first parameter:
///
///     func print<T>(address p: UnsafeRawPointer, as type: T.Type) {
///         let value = p.load(as: type)
///         print(value)
///     }
///
/// As is typical in Swift, you can call the `print(address:as:)` function with
/// an `UnsafeRawPointer` instance. This example passes `rawPointer` as the initial
/// parameter.
///
///     // 'rawPointer' points to memory initialized with `Int` values.
///     let rawPointer: UnsafeRawPointer = ...
///     print(address: rawPointer, as: Int.self)
///     // Prints "42"
///
/// Because typed pointers can be implicitly cast to raw pointers when passed
/// as a parameter, you can also call `print(address:as:)` with any mutable or
/// immutable typed pointer instance.
///
///     let intPointer: UnsafePointer<Int> = ...
///     print(address: intPointer, as: Int.self)
///     // Prints "42"
///
///     let mutableIntPointer = UnsafeMutablePointer(mutating: intPointer)
///     print(address: mutableIntPointer, as: Int.self)
///     // Prints "42"
///
/// Alternatively, you can use Swift's *implicit bridging* to pass a pointer to
/// an instance or to the elements of an array. Use inout syntax to implicitly
/// create a pointer to an instance of any type. The following example uses
/// implicit bridging to pass a pointer to `value` when calling
/// `print(address:as:)`:
///
///     var value: Int = 23
///     print(address: &value, as: Int.self)
///     // Prints "23"
///
/// An immutable pointer to the elements of an array is implicitly created when
/// you pass the array as an argument. This example uses implicit bridging to
/// pass a pointer to the elements of `numbers` when calling
/// `print(address:as:)`.
///
///     let numbers = [5, 10, 15, 20]
///     print(address: numbers, as: Int.self)
///     // Prints "5"
///
/// You can also use inout syntax to pass a mutable pointer to the elements of
/// an array. Because `print(address:as:)` requires an immutable pointer,
/// although this is syntactically valid, it isn't necessary.
///
///     var mutableNumbers = numbers
///     print(address: &mutableNumbers, as: Int.self)
///
/// - Important: The pointer created through implicit bridging of an instance
///   or of an array's elements is only valid during the execution of the
///   called function. Escaping the pointer to use after the execution of the
///   function is undefined behavior. In particular, do not use implicit
///   bridging when calling an `UnsafeRawPointer` initializer.
///
///       var number = 5
///       let numberPointer = UnsafeRawPointer(&number)
///       // Accessing 'numberPointer' is undefined behavior.
@_fixed_layout
public struct UnsafeRawPointer: _Pointer {
  /// The underlying raw pointer.
  /// Implements conformance to the public protocol `_Pointer`.
  public let _rawValue: Builtin.RawPointer

  /// Creates a new raw pointer from the given raw or typed pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The pointer to convert.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ other: UnsafeRawPointer) {
    self = other
  }

  /// Creates a new raw pointer from the given raw or typed pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The pointer to convert. If `other` is `nil`, the
  ///   result is `nil`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init?(_ other: UnsafeRawPointer?) {
    guard let unwrapped = other else { return nil }
    self = unwrapped
  }

  /// Creates a new raw pointer from a builtin raw pointer.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ _rawValue: Builtin.RawPointer) {
    self._rawValue = _rawValue
  }

  /// Creates a new raw pointer from the given opaque pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The opaque pointer to convert.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ other: OpaquePointer) {
    _rawValue = other._rawValue
  }

  /// Creates a new raw pointer from the given opaque pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The opaque pointer to convert. If `other` is `nil`,
  ///   the result is `nil`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init?(_ other: OpaquePointer?) {
    guard let unwrapped = other else { return nil }
    _rawValue = unwrapped._rawValue
  }

  /// Creates a new raw pointer from the given address, specified as a bit
  /// pattern.
  ///
  /// - Parameter bitPattern: A bit pattern to use for the address of the new
  ///   raw pointer. If `bitPattern` is zero, the result is `nil`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init?(bitPattern: Int) {
    if bitPattern == 0 { return nil }
    _rawValue = Builtin.inttoptr_Word(bitPattern._builtinWordValue)
  }

  /// Creates a new raw pointer from the given address, specified as a bit
  /// pattern.
  ///
  /// - Parameter bitPattern: A bit pattern to use for the address of the new
  ///   raw pointer. If `bitPattern` is zero, the result is `nil`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init?(bitPattern: UInt) {
    if bitPattern == 0 { return nil }
    _rawValue = Builtin.inttoptr_Word(bitPattern._builtinWordValue)
  }

  /// Creates a new raw pointer from the given typed pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The typed pointer to convert.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init<T>(_ other: UnsafePointer<T>) {
    _rawValue = other._rawValue
  }

  /// Creates a new raw pointer from the given typed pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The typed pointer to convert. If `other` is `nil`, the
  ///   result is `nil`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init?<T>(_ other: UnsafePointer<T>?) {
    guard let unwrapped = other else { return nil }
    _rawValue = unwrapped._rawValue
  }

  /// Creates a new raw pointer from the given mutable raw pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The mutable raw pointer to convert.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ other: UnsafeMutableRawPointer) {
    _rawValue = other._rawValue
  }

  /// Creates a new raw pointer from the given mutable raw pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The mutable raw pointer to convert. If `other` is
  ///   `nil`, the result is `nil`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init?(_ other: UnsafeMutableRawPointer?) {
    guard let unwrapped = other else { return nil }
    _rawValue = unwrapped._rawValue
  }

  /// Creates a new raw pointer from the given typed pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The typed pointer to convert.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init<T>(_ other: UnsafeMutablePointer<T>) {
    _rawValue = other._rawValue
  }

  /// Creates a new raw pointer from the given typed pointer.
  ///
  /// Use this initializer to explicitly convert `other` to an `UnsafeRawPointer`
  /// instance. This initializer creates a new pointer to the same address as
  /// `other` and performs no allocation or copying.
  ///
  /// - Parameter other: The typed pointer to convert. If `other` is `nil`, the
  ///   result is `nil`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init?<T>(_ other: UnsafeMutablePointer<T>?) {
    guard let unwrapped = other else { return nil }
    _rawValue = unwrapped._rawValue
  }


  @available(swift, deprecated: 4.1, obsoleted: 5.0.0, message: "Swift currently only supports freeing entire heap blocks, use deallocate() instead")
  public func deallocate(bytes _: Int, alignedTo _: Int) { 
    self.deallocate()
  }

  /// Deallocates the previously allocated memory block referenced by this pointer.
  ///
  /// The memory to be deallocated must be uninitialized or initialized to a
  /// trivial type.
  @_inlineable
  public func deallocate() {
    Builtin.deallocRaw(_rawValue, (-1)._builtinWordValue, (-1)._builtinWordValue)
  }

  /// Binds the memory to the specified type and returns a typed pointer to the
  /// bound memory.
  ///
  /// Use the `bindMemory(to:capacity:)` method to bind the memory referenced
  /// by this pointer to the type `T`. The memory must be uninitialized or
  /// initialized to a type that is layout compatible with `T`. If the memory
  /// is uninitialized, it is still uninitialized after being bound to `T`.
  ///
  /// In this example, 100 bytes of raw memory are allocated for the pointer
  /// `bytesPointer`, and then the first four bytes are bound to the `Int8`
  /// type.
  ///
  ///     let count = 4
  ///     let bytesPointer = UnsafeMutableRawPointer.allocate(
  ///             bytes: 100,
  ///             alignedTo: MemoryLayout<Int8>.alignment)
  ///     let int8Pointer = bytesPointer.bindMemory(to: Int8.self, capacity: count)
  ///
  /// After calling `bindMemory(to:capacity:)`, the first four bytes of the
  /// memory referenced by `bytesPointer` are bound to the `Int8` type, though
  /// they remain uninitialized. The remainder of the allocated region is
  /// unbound raw memory. All 100 bytes of memory must eventually be
  /// deallocated.
  ///
  /// - Warning: A memory location may only be bound to one type at a time. The
  ///   behavior of accessing memory as a type unrelated to its bound type is
  ///   undefined.
  ///
  /// - Parameters:
  ///   - type: The type `T` to bind the memory to.
  ///   - count: The amount of memory to bind to type `T`, counted as instances
  ///     of `T`.
  /// - Returns: A typed pointer to the newly bound memory. The memory in this
  ///   region is bound to `T`, but has not been modified in any other way.
  ///   The number of bytes in this region is
  ///   `count * MemoryLayout<T>.stride`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  @discardableResult
  public func bindMemory<T>(
    to type: T.Type, capacity count: Int
  ) -> UnsafePointer<T> {
    Builtin.bindMemory(_rawValue, count._builtinWordValue, type)
    return UnsafePointer<T>(_rawValue)
  }

  /// Returns a typed pointer to the memory referenced by this pointer,
  /// assuming that the memory is already bound to the specified type.
  ///
  /// Use this method when you have a raw pointer to memory that has *already*
  /// been bound to the specified type. The memory starting at this pointer
  /// must be bound to the type `T`. Accessing memory through the returned
  /// pointer is undefined if the memory has not been bound to `T`. To bind
  /// memory to `T`, use `bindMemory(to:capacity:)` instead of this method.
  ///
  /// - Parameter to: The type `T` that the memory has already been bound to.
  /// - Returns: A typed pointer to the same memory as this raw pointer.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func assumingMemoryBound<T>(to: T.Type) -> UnsafePointer<T> {
    return UnsafePointer<T>(_rawValue)
  }


  /// Returns a new instance of the given type, constructed from the raw memory
  /// at the specified offset.
  ///
  /// The memory at this pointer plus `offset` must be properly aligned for
  /// accessing `T` and initialized to `T` or another type that is layout
  /// compatible with `T`.
  ///
  /// - Parameters:
  ///   - offset: The offset from this pointer, in bytes. `offset` must be
  ///     nonnegative. The default is zero.
  ///   - type: The type of the instance to create.
  /// - Returns: A new instance of type `T`, read from the raw bytes at
  ///   `offset`. The returned instance is memory-managed and unassociated
  ///   with the value in the memory referenced by this pointer.
  @_inlineable
  public func load<T>(fromByteOffset offset: Int = 0, as type: T.Type) -> T {
    _debugPrecondition(0 == (UInt(bitPattern: self + offset)
        & (UInt(MemoryLayout<T>.alignment) - 1)),
      "load from misaligned raw pointer")

    return Builtin.loadRaw((self + offset)._rawValue)
  }

}

extension UnsafeRawPointer: Strideable {
  /// Returns the distance from this pointer to the given pointer.
  ///
  /// With pointers `p` and `q`, the result of `p.distance(to: q)` is
  /// equivalent to `q - p`.
  ///
  /// - Parameter x: The pointer to calculate the distance to.
  /// - Returns: The distance from this pointer to `x`, in bytes.
  @_inlineable
  public func distance(to x: UnsafeRawPointer) -> Int {
    return Int(Builtin.sub_Word(Builtin.ptrtoint_Word(x._rawValue),
        Builtin.ptrtoint_Word(_rawValue)))
  }

  /// Returns a pointer offset from this pointer by the specified number of
  /// bytes.
  ///
  /// With pointer `p` and distance `n`, the result of `p.advanced(by: n)` is
  /// equivalent to `p + n`.
  ///
  /// The resulting pointer must be within the bounds of the same allocation as
  /// this pointer.
  ///
  /// - Parameter n: The number of bytes to offset this pointer. `n` may be
  ///   positive, negative, or zero.
  /// - Returns: A pointer offset from this pointer by `n` bytes.
  @_inlineable
  public func advanced(by n: Int) -> UnsafeRawPointer {
    return UnsafeRawPointer(Builtin.gepRaw_Word(_rawValue, n._builtinWordValue))
  }
}

extension UnsafeRawPointer: Equatable {
  // - Note: This may be more efficient than Strideable's implementation
  //   calling UnsafeRawPointer.distance().
  /// Returns a Boolean value indicating whether two pointers are equal.
  ///
  /// - Parameters:
  ///   - lhs: A pointer.
  ///   - rhs: Another pointer.
  /// - Returns: `true` if `lhs` and `rhs` reference the same memory address;
  ///   otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func == (lhs: UnsafeRawPointer, rhs: UnsafeRawPointer) -> Bool {
    return Bool(Builtin.cmp_eq_RawPointer(lhs._rawValue, rhs._rawValue))
  }
}

extension UnsafeRawPointer: Comparable {
  // - Note: This is an unsigned comparison unlike Strideable's
  //   implementation.
  /// Returns a Boolean value indicating whether the first pointer references
  /// an earlier memory location than the second pointer.
  ///
  /// - Parameters:
  ///   - lhs: A pointer.
  ///   - rhs: Another pointer.
  /// - Returns: `true` if `lhs` references a memory address earlier than
  ///   `rhs`; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func < (lhs: UnsafeRawPointer, rhs: UnsafeRawPointer) -> Bool {
    return Bool(Builtin.cmp_ult_RawPointer(lhs._rawValue, rhs._rawValue))
  }
}

extension UnsafeRawPointer: Hashable {
  /// The pointer's hash value.
  ///
  /// The hash value is not guaranteed to be stable across different
  /// invocations of the same program.  Do not persist the hash value across
  /// program runs.
  @_inlineable
  public var hashValue: Int {
    return Int(bitPattern: self)
  }
}

extension UnsafeRawPointer : CustomDebugStringConvertible {
  /// A textual representation of the pointer, suitable for debugging.
  @_inlineable // FIXME(sil-serialize-all)
  public var debugDescription: String {
    return _rawPointerToString(_rawValue)
  }
}

extension UnsafeRawPointer : CustomReflectable {
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    let ptrValue = UInt64(
      bitPattern: Int64(Int(Builtin.ptrtoint_Word(_rawValue))))
    return Mirror(self, children: ["pointerValue": ptrValue])
  }
}

extension UnsafeRawPointer : CustomPlaygroundQuickLookable {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal var summary: String {
    let selfType = "UnsafeRawPointer"
    let ptrValue = UInt64(
      bitPattern: Int64(Int(Builtin.ptrtoint_Word(_rawValue))))
    return ptrValue == 0
    ? "\(selfType)(nil)"
    : "\(selfType)(0x\(_uint64ToString(ptrValue, radix:16, uppercase:true)))"
  }

  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .text(summary)
  }
}

extension OpaquePointer {
  @_inlineable
  public init(_ from: UnsafeRawPointer) {
    self._rawValue = from._rawValue
  }

  @_inlineable
  public init?(_ from: UnsafeRawPointer?) {
    guard let unwrapped = from else { return nil }
    self._rawValue = unwrapped._rawValue
  }
}

extension Int {
  /// Creates a new value with the bit pattern of the given pointer.
  ///
  /// The new value represents the address of the pointer passed as `pointer`.
  /// If `pointer` is `nil`, the result is `0`.
  ///
  /// - Parameter pointer: The pointer to use as the source for the new
  ///   integer.
  @_inlineable
  public init(bitPattern pointer: UnsafeRawPointer?) {
    if let pointer = pointer {
      self = Int(Builtin.ptrtoint_Word(pointer._rawValue))
    } else {
      self = 0
    }
  }
}

extension UInt {
  /// Creates a new value with the bit pattern of the given pointer.
  ///
  /// The new value represents the address of the pointer passed as `pointer`.
  /// If `pointer` is `nil`, the result is `0`.
  ///
  /// - Parameter pointer: The pointer to use as the source for the new
  ///   integer.
  @_inlineable
  public init(bitPattern pointer: UnsafeRawPointer?) {
    if let pointer = pointer {
      self = UInt(Builtin.ptrtoint_Word(pointer._rawValue))
    } else {
      self = 0
    }
  }
}


extension UnsafeMutableRawPointer {
  @available(*, unavailable, renamed: "init(mutating:)")
  public init(_ from : UnsafeRawPointer) { Builtin.unreachable() }

  @available(*, unavailable, renamed: "init(mutating:)")
  public init?(_ from : UnsafeRawPointer?) { Builtin.unreachable(); return nil }

  @available(*, unavailable, renamed: "init(mutating:)")
  public init<T>(_ from : UnsafePointer<T>) { Builtin.unreachable() }

  @available(*, unavailable, renamed: "init(mutating:)")
  public init?<T>(_ from : UnsafePointer<T>?) { Builtin.unreachable(); return nil }
}
