//===----------------------------------------------------------*- swift -*-===//
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
///
/// This file contains Swift wrappers for functions defined in the C++ runtime.
///
//===----------------------------------------------------------------------===//

import SwiftShims

//===----------------------------------------------------------------------===//
// Atomics
//===----------------------------------------------------------------------===//

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _stdlib_atomicCompareExchangeStrongPtr(
  object target: UnsafeMutablePointer<UnsafeRawPointer?>,
  expected: UnsafeMutablePointer<UnsafeRawPointer?>,
  desired: UnsafeRawPointer?) -> Bool {

  // We use Builtin.Word here because Builtin.RawPointer can't be nil.
  let (oldValue, won) = Builtin.cmpxchg_seqcst_seqcst_Word(
    target._rawValue,
    UInt(bitPattern: expected.pointee)._builtinWordValue,
    UInt(bitPattern: desired)._builtinWordValue)
  expected.pointee = UnsafeRawPointer(bitPattern: Int(oldValue))
  return Bool(won)
}

/// Atomic compare and exchange of `UnsafeMutablePointer<T>` with sequentially
/// consistent memory ordering.  Precise semantics are defined in C++11 or C11.
///
/// - Warning: This operation is extremely tricky to use correctly because of
///   writeback semantics.
///
/// It is best to use it directly on an
/// `UnsafeMutablePointer<UnsafeMutablePointer<T>>` that is known to point
/// directly to the memory where the value is stored.
///
/// In a call like this:
///
///     _stdlib_atomicCompareExchangeStrongPtr(&foo.property1.property2, ...)
///
/// you need to manually make sure that:
///
/// - all properties in the chain are physical (to make sure that no writeback
///   happens; the compare-and-exchange instruction should operate on the
///   shared memory); and
///
/// - the shared memory that you are accessing is located inside a heap
///   allocation (a class instance property, a `_HeapBuffer`, a pointer to
///   an `Array` element etc.)
///
/// If the conditions above are not met, the code will still compile, but the
/// compare-and-exchange instruction will operate on the writeback buffer, and
/// you will get a *race* while doing writeback into shared memory.
@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _stdlib_atomicCompareExchangeStrongPtr<T>(
  object target: UnsafeMutablePointer<UnsafeMutablePointer<T>>,
  expected: UnsafeMutablePointer<UnsafeMutablePointer<T>>,
  desired: UnsafeMutablePointer<T>
) -> Bool {
  let rawTarget = UnsafeMutableRawPointer(target).assumingMemoryBound(
    to: Optional<UnsafeRawPointer>.self)
  let rawExpected = UnsafeMutableRawPointer(expected).assumingMemoryBound(
    to: Optional<UnsafeRawPointer>.self)
  return _stdlib_atomicCompareExchangeStrongPtr(
    object: rawTarget,
    expected: rawExpected,
    desired: UnsafeRawPointer(desired))
}
/// Atomic compare and exchange of `UnsafeMutablePointer<T>` with sequentially
/// consistent memory ordering.  Precise semantics are defined in C++11 or C11.
///
/// - Warning: This operation is extremely tricky to use correctly because of
///   writeback semantics.
///
/// It is best to use it directly on an
/// `UnsafeMutablePointer<UnsafeMutablePointer<T>>` that is known to point
/// directly to the memory where the value is stored.
///
/// In a call like this:
///
///     _stdlib_atomicCompareExchangeStrongPtr(&foo.property1.property2, ...)
///
/// you need to manually make sure that:
///
/// - all properties in the chain are physical (to make sure that no writeback
///   happens; the compare-and-exchange instruction should operate on the
///   shared memory); and
///
/// - the shared memory that you are accessing is located inside a heap
///   allocation (a class instance property, a `_HeapBuffer`, a pointer to
///   an `Array` element etc.)
///
/// If the conditions above are not met, the code will still compile, but the
/// compare-and-exchange instruction will operate on the writeback buffer, and
/// you will get a *race* while doing writeback into shared memory.
@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _stdlib_atomicCompareExchangeStrongPtr<T>(
  object target: UnsafeMutablePointer<UnsafeMutablePointer<T>?>,
  expected: UnsafeMutablePointer<UnsafeMutablePointer<T>?>,
  desired: UnsafeMutablePointer<T>?
) -> Bool {
  let rawTarget = UnsafeMutableRawPointer(target).assumingMemoryBound(
    to: Optional<UnsafeRawPointer>.self)
  let rawExpected = UnsafeMutableRawPointer(expected).assumingMemoryBound(
    to: Optional<UnsafeRawPointer>.self)
  return _stdlib_atomicCompareExchangeStrongPtr(
    object: rawTarget,
    expected: rawExpected,
    desired: UnsafeRawPointer(desired))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
@discardableResult
public // @testable
func _stdlib_atomicInitializeARCRef(
  object target: UnsafeMutablePointer<AnyObject?>,
  desired: AnyObject) -> Bool {
  var expected: UnsafeRawPointer?
  let desiredPtr = Unmanaged.passRetained(desired).toOpaque()
  let rawTarget = UnsafeMutableRawPointer(target).assumingMemoryBound(
    to: Optional<UnsafeRawPointer>.self)
  let wonRace = _stdlib_atomicCompareExchangeStrongPtr(
    object: rawTarget, expected: &expected, desired: desiredPtr)
  if !wonRace {
    // Some other thread initialized the value.  Balance the retain that we
    // performed on 'desired'.
    Unmanaged.passUnretained(desired).release()
  }
  return wonRace
}


@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _stdlib_atomicCompareExchangeStrongUInt32(
  object target: UnsafeMutablePointer<UInt32>,
  expected: UnsafeMutablePointer<UInt32>,
  desired: UInt32) -> Bool {

  let (oldValue, won) = Builtin.cmpxchg_seqcst_seqcst_Int32(
    target._rawValue, expected.pointee._value, desired._value)
  expected.pointee._value = oldValue
  return Bool(won)
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _stdlib_atomicCompareExchangeStrongInt32(
  object target: UnsafeMutablePointer<Int32>,
  expected: UnsafeMutablePointer<Int32>,
  desired: Int32) -> Bool {

  let (oldValue, won) = Builtin.cmpxchg_seqcst_seqcst_Int32(
    target._rawValue, expected.pointee._value, desired._value)
  expected.pointee._value = oldValue
  return Bool(won)
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _swift_stdlib_atomicStoreUInt32(
  object target: UnsafeMutablePointer<UInt32>,
  desired: UInt32) {

  Builtin.atomicstore_seqcst_Int32(target._rawValue, desired._value)
}

@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _swift_stdlib_atomicStoreInt32(
  object target: UnsafeMutablePointer<Int32>,
  desired: Int32) {

  Builtin.atomicstore_seqcst_Int32(target._rawValue, desired._value)
}

@_inlineable // FIXME(sil-serialize-all)
public // @testable
func _swift_stdlib_atomicLoadUInt32(
  object target: UnsafeMutablePointer<UInt32>) -> UInt32 {

  let value = Builtin.atomicload_seqcst_Int32(target._rawValue)
  return UInt32(value)
}

@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _swift_stdlib_atomicLoadInt32(
  object target: UnsafeMutablePointer<Int32>) -> Int32 {

  let value = Builtin.atomicload_seqcst_Int32(target._rawValue)
  return Int32(value)
}

// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _swift_stdlib_atomicFetchAddUInt32(
  object target: UnsafeMutablePointer<UInt32>,
  operand: UInt32) -> UInt32 {

  let value = Builtin.atomicrmw_add_seqcst_Int32(
    target._rawValue, operand._value)

  return UInt32(value)
}

// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _swift_stdlib_atomicFetchAddInt32(
  object target: UnsafeMutablePointer<Int32>,
  operand: Int32) -> Int32 {

  let value = Builtin.atomicrmw_add_seqcst_Int32(
    target._rawValue, operand._value)

  return Int32(value)
}
// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _swift_stdlib_atomicFetchAndUInt32(
  object target: UnsafeMutablePointer<UInt32>,
  operand: UInt32) -> UInt32 {

  let value = Builtin.atomicrmw_and_seqcst_Int32(
    target._rawValue, operand._value)

  return UInt32(value)
}

// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _swift_stdlib_atomicFetchAndInt32(
  object target: UnsafeMutablePointer<Int32>,
  operand: Int32) -> Int32 {

  let value = Builtin.atomicrmw_and_seqcst_Int32(
    target._rawValue, operand._value)

  return Int32(value)
}
// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _swift_stdlib_atomicFetchOrUInt32(
  object target: UnsafeMutablePointer<UInt32>,
  operand: UInt32) -> UInt32 {

  let value = Builtin.atomicrmw_or_seqcst_Int32(
    target._rawValue, operand._value)

  return UInt32(value)
}

// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _swift_stdlib_atomicFetchOrInt32(
  object target: UnsafeMutablePointer<Int32>,
  operand: Int32) -> Int32 {

  let value = Builtin.atomicrmw_or_seqcst_Int32(
    target._rawValue, operand._value)

  return Int32(value)
}
// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _swift_stdlib_atomicFetchXorUInt32(
  object target: UnsafeMutablePointer<UInt32>,
  operand: UInt32) -> UInt32 {

  let value = Builtin.atomicrmw_xor_seqcst_Int32(
    target._rawValue, operand._value)

  return UInt32(value)
}

// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _swift_stdlib_atomicFetchXorInt32(
  object target: UnsafeMutablePointer<Int32>,
  operand: Int32) -> Int32 {

  let value = Builtin.atomicrmw_xor_seqcst_Int32(
    target._rawValue, operand._value)

  return Int32(value)
}


@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _stdlib_atomicCompareExchangeStrongUInt64(
  object target: UnsafeMutablePointer<UInt64>,
  expected: UnsafeMutablePointer<UInt64>,
  desired: UInt64) -> Bool {

  let (oldValue, won) = Builtin.cmpxchg_seqcst_seqcst_Int64(
    target._rawValue, expected.pointee._value, desired._value)
  expected.pointee._value = oldValue
  return Bool(won)
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _stdlib_atomicCompareExchangeStrongInt64(
  object target: UnsafeMutablePointer<Int64>,
  expected: UnsafeMutablePointer<Int64>,
  desired: Int64) -> Bool {

  let (oldValue, won) = Builtin.cmpxchg_seqcst_seqcst_Int64(
    target._rawValue, expected.pointee._value, desired._value)
  expected.pointee._value = oldValue
  return Bool(won)
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _swift_stdlib_atomicStoreUInt64(
  object target: UnsafeMutablePointer<UInt64>,
  desired: UInt64) {

  Builtin.atomicstore_seqcst_Int64(target._rawValue, desired._value)
}

@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _swift_stdlib_atomicStoreInt64(
  object target: UnsafeMutablePointer<Int64>,
  desired: Int64) {

  Builtin.atomicstore_seqcst_Int64(target._rawValue, desired._value)
}

@_inlineable // FIXME(sil-serialize-all)
public // @testable
func _swift_stdlib_atomicLoadUInt64(
  object target: UnsafeMutablePointer<UInt64>) -> UInt64 {

  let value = Builtin.atomicload_seqcst_Int64(target._rawValue)
  return UInt64(value)
}

@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _swift_stdlib_atomicLoadInt64(
  object target: UnsafeMutablePointer<Int64>) -> Int64 {

  let value = Builtin.atomicload_seqcst_Int64(target._rawValue)
  return Int64(value)
}

// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _swift_stdlib_atomicFetchAddUInt64(
  object target: UnsafeMutablePointer<UInt64>,
  operand: UInt64) -> UInt64 {

  let value = Builtin.atomicrmw_add_seqcst_Int64(
    target._rawValue, operand._value)

  return UInt64(value)
}

// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _swift_stdlib_atomicFetchAddInt64(
  object target: UnsafeMutablePointer<Int64>,
  operand: Int64) -> Int64 {

  let value = Builtin.atomicrmw_add_seqcst_Int64(
    target._rawValue, operand._value)

  return Int64(value)
}
// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _swift_stdlib_atomicFetchAndUInt64(
  object target: UnsafeMutablePointer<UInt64>,
  operand: UInt64) -> UInt64 {

  let value = Builtin.atomicrmw_and_seqcst_Int64(
    target._rawValue, operand._value)

  return UInt64(value)
}

// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _swift_stdlib_atomicFetchAndInt64(
  object target: UnsafeMutablePointer<Int64>,
  operand: Int64) -> Int64 {

  let value = Builtin.atomicrmw_and_seqcst_Int64(
    target._rawValue, operand._value)

  return Int64(value)
}
// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _swift_stdlib_atomicFetchOrUInt64(
  object target: UnsafeMutablePointer<UInt64>,
  operand: UInt64) -> UInt64 {

  let value = Builtin.atomicrmw_or_seqcst_Int64(
    target._rawValue, operand._value)

  return UInt64(value)
}

// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _swift_stdlib_atomicFetchOrInt64(
  object target: UnsafeMutablePointer<Int64>,
  operand: Int64) -> Int64 {

  let value = Builtin.atomicrmw_or_seqcst_Int64(
    target._rawValue, operand._value)

  return Int64(value)
}
// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _swift_stdlib_atomicFetchXorUInt64(
  object target: UnsafeMutablePointer<UInt64>,
  operand: UInt64) -> UInt64 {

  let value = Builtin.atomicrmw_xor_seqcst_Int64(
    target._rawValue, operand._value)

  return UInt64(value)
}

// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _swift_stdlib_atomicFetchXorInt64(
  object target: UnsafeMutablePointer<Int64>,
  operand: Int64) -> Int64 {

  let value = Builtin.atomicrmw_xor_seqcst_Int64(
    target._rawValue, operand._value)

  return Int64(value)
}


@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _stdlib_atomicCompareExchangeStrongInt(
  object target: UnsafeMutablePointer<Int>,
  expected: UnsafeMutablePointer<Int>,
  desired: Int) -> Bool {
#if arch(i386) || arch(arm)
  let (oldValue, won) = Builtin.cmpxchg_seqcst_seqcst_Int32(
    target._rawValue, expected.pointee._value, desired._value)
#elseif arch(x86_64) || arch(arm64) || arch(powerpc64) || arch(powerpc64le) || arch(s390x)
  let (oldValue, won) = Builtin.cmpxchg_seqcst_seqcst_Int64(
    target._rawValue, expected.pointee._value, desired._value)
#endif
  expected.pointee._value = oldValue
  return Bool(won)
}

@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _swift_stdlib_atomicStoreInt(
  object target: UnsafeMutablePointer<Int>,
  desired: Int) {
#if arch(i386) || arch(arm)
  Builtin.atomicstore_seqcst_Int32(target._rawValue, desired._value)
#elseif arch(x86_64) || arch(arm64) || arch(powerpc64) || arch(powerpc64le) || arch(s390x)
  Builtin.atomicstore_seqcst_Int64(target._rawValue, desired._value)
#endif
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _swift_stdlib_atomicLoadInt(
  object target: UnsafeMutablePointer<Int>) -> Int {
#if arch(i386) || arch(arm)
  let value = Builtin.atomicload_seqcst_Int32(target._rawValue)
  return Int(value)
#elseif arch(x86_64) || arch(arm64) || arch(powerpc64) || arch(powerpc64le) || arch(s390x)
  let value = Builtin.atomicload_seqcst_Int64(target._rawValue)
  return Int(value)
#endif
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public // @testable
func _stdlib_atomicLoadARCRef(
  object target: UnsafeMutablePointer<AnyObject?>
) -> AnyObject? {
  let value = Builtin.atomicload_seqcst_Word(target._rawValue)
  if let unwrapped = UnsafeRawPointer(bitPattern: Int(value)) {
    return Unmanaged<AnyObject>.fromOpaque(unwrapped).takeUnretainedValue()
  }
  return nil
}

// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
public func _swift_stdlib_atomicFetchAddInt(
  object target: UnsafeMutablePointer<Int>,
  operand: Int) -> Int {
  let rawTarget = UnsafeMutableRawPointer(target)
#if arch(i386) || arch(arm)
  let value = _swift_stdlib_atomicFetchAddInt32(
    object: rawTarget.assumingMemoryBound(to: Int32.self),
    operand: Int32(operand))
#elseif arch(x86_64) || arch(arm64) || arch(powerpc64) || arch(powerpc64le) || arch(s390x)
  let value = _swift_stdlib_atomicFetchAddInt64(
    object: rawTarget.assumingMemoryBound(to: Int64.self),
    operand: Int64(operand))
#endif
  return Int(value)
}
// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
public func _swift_stdlib_atomicFetchAndInt(
  object target: UnsafeMutablePointer<Int>,
  operand: Int) -> Int {
  let rawTarget = UnsafeMutableRawPointer(target)
#if arch(i386) || arch(arm)
  let value = _swift_stdlib_atomicFetchAndInt32(
    object: rawTarget.assumingMemoryBound(to: Int32.self),
    operand: Int32(operand))
#elseif arch(x86_64) || arch(arm64) || arch(powerpc64) || arch(powerpc64le) || arch(s390x)
  let value = _swift_stdlib_atomicFetchAndInt64(
    object: rawTarget.assumingMemoryBound(to: Int64.self),
    operand: Int64(operand))
#endif
  return Int(value)
}
// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
public func _swift_stdlib_atomicFetchOrInt(
  object target: UnsafeMutablePointer<Int>,
  operand: Int) -> Int {
  let rawTarget = UnsafeMutableRawPointer(target)
#if arch(i386) || arch(arm)
  let value = _swift_stdlib_atomicFetchOrInt32(
    object: rawTarget.assumingMemoryBound(to: Int32.self),
    operand: Int32(operand))
#elseif arch(x86_64) || arch(arm64) || arch(powerpc64) || arch(powerpc64le) || arch(s390x)
  let value = _swift_stdlib_atomicFetchOrInt64(
    object: rawTarget.assumingMemoryBound(to: Int64.self),
    operand: Int64(operand))
#endif
  return Int(value)
}
// Warning: no overflow checking.
@_inlineable // FIXME(sil-serialize-all)
public func _swift_stdlib_atomicFetchXorInt(
  object target: UnsafeMutablePointer<Int>,
  operand: Int) -> Int {
  let rawTarget = UnsafeMutableRawPointer(target)
#if arch(i386) || arch(arm)
  let value = _swift_stdlib_atomicFetchXorInt32(
    object: rawTarget.assumingMemoryBound(to: Int32.self),
    operand: Int32(operand))
#elseif arch(x86_64) || arch(arm64) || arch(powerpc64) || arch(powerpc64le) || arch(s390x)
  let value = _swift_stdlib_atomicFetchXorInt64(
    object: rawTarget.assumingMemoryBound(to: Int64.self),
    operand: Int64(operand))
#endif
  return Int(value)
}

@_fixed_layout // FIXME(sil-serialize-all)
public final class _stdlib_AtomicInt {
  @_versioned // FIXME(sil-serialize-all)
  internal var _value: Int

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal var _valuePtr: UnsafeMutablePointer<Int> {
    return _getUnsafePointerToStoredProperties(self).assumingMemoryBound(
      to: Int.self)
  }

  @_inlineable // FIXME(sil-serialize-all)
  public init(_ value: Int = 0) {
    _value = value
  }

  @_inlineable // FIXME(sil-serialize-all)
  deinit {}

  @_inlineable // FIXME(sil-serialize-all)
  public func store(_ desired: Int) {
    return _swift_stdlib_atomicStoreInt(object: _valuePtr, desired: desired)
  }

  @_inlineable // FIXME(sil-serialize-all)
  public func load() -> Int {
    return _swift_stdlib_atomicLoadInt(object: _valuePtr)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @discardableResult
  public func fetchAndAdd(_ operand: Int) -> Int {
    return _swift_stdlib_atomicFetchAddInt(
      object: _valuePtr,
      operand: operand)
  }

  @_inlineable // FIXME(sil-serialize-all)
  public func addAndFetch(_ operand: Int) -> Int {
    return fetchAndAdd(operand) + operand
  }
  @_inlineable // FIXME(sil-serialize-all)
  @discardableResult
  public func fetchAndAnd(_ operand: Int) -> Int {
    return _swift_stdlib_atomicFetchAndInt(
      object: _valuePtr,
      operand: operand)
  }

  @_inlineable // FIXME(sil-serialize-all)
  public func andAndFetch(_ operand: Int) -> Int {
    return fetchAndAnd(operand) & operand
  }
  @_inlineable // FIXME(sil-serialize-all)
  @discardableResult
  public func fetchAndOr(_ operand: Int) -> Int {
    return _swift_stdlib_atomicFetchOrInt(
      object: _valuePtr,
      operand: operand)
  }

  @_inlineable // FIXME(sil-serialize-all)
  public func orAndFetch(_ operand: Int) -> Int {
    return fetchAndOr(operand) | operand
  }
  @_inlineable // FIXME(sil-serialize-all)
  @discardableResult
  public func fetchAndXor(_ operand: Int) -> Int {
    return _swift_stdlib_atomicFetchXorInt(
      object: _valuePtr,
      operand: operand)
  }

  @_inlineable // FIXME(sil-serialize-all)
  public func xorAndFetch(_ operand: Int) -> Int {
    return fetchAndXor(operand) ^ operand
  }

  @_inlineable // FIXME(sil-serialize-all)
  public func compareExchange(expected: inout Int, desired: Int) -> Bool {
    var expectedVar = expected
    let result = _stdlib_atomicCompareExchangeStrongInt(
      object: _valuePtr,
      expected: &expectedVar,
      desired: desired)
    expected = expectedVar
    return result
  }
}

//===----------------------------------------------------------------------===//
// Conversion of primitive types to `String`
//===----------------------------------------------------------------------===//

/// A 32 byte buffer.
@_fixed_layout // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal struct _Buffer32 {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal init() {}
  @_versioned // FIXME(sil-serialize-all)
  internal var _x0: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x1: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x2: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x3: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x4: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x5: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x6: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x7: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x8: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x9: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x10: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x11: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x12: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x13: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x14: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x15: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x16: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x17: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x18: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x19: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x20: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x21: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x22: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x23: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x24: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x25: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x26: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x27: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x28: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x29: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x30: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x31: UInt8 = 0

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal mutating func withBytes<Result>(
    _ body: (UnsafeMutablePointer<UInt8>) throws -> Result
  ) rethrows -> Result
  {
    return try withUnsafeMutablePointer(to: &self) {
      try body(UnsafeMutableRawPointer($0).assumingMemoryBound(to: UInt8.self))
    }
  }
}

/// A 72 byte buffer.
@_fixed_layout // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal struct _Buffer72 {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal init() {}
  @_versioned // FIXME(sil-serialize-all)
  internal var _x0: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x1: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x2: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x3: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x4: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x5: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x6: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x7: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x8: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x9: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x10: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x11: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x12: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x13: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x14: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x15: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x16: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x17: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x18: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x19: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x20: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x21: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x22: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x23: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x24: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x25: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x26: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x27: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x28: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x29: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x30: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x31: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x32: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x33: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x34: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x35: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x36: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x37: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x38: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x39: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x40: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x41: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x42: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x43: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x44: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x45: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x46: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x47: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x48: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x49: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x50: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x51: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x52: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x53: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x54: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x55: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x56: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x57: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x58: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x59: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x60: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x61: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x62: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x63: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x64: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x65: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x66: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x67: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x68: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x69: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x70: UInt8 = 0
  @_versioned // FIXME(sil-serialize-all)
  internal var _x71: UInt8 = 0

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal mutating func withBytes<Result>(
    _ body: (UnsafeMutablePointer<UInt8>) throws -> Result
  ) rethrows -> Result
  {
    return try withUnsafeMutablePointer(to: &self) {
      try body(UnsafeMutableRawPointer($0).assumingMemoryBound(to: UInt8.self))
    }
  }
}



@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
@_silgen_name("swift_float32ToString")
internal func _float32ToStringImpl(
  _ buffer: UnsafeMutablePointer<UTF8.CodeUnit>,
  _ bufferLength: UInt, _ value: Float32,
  _ debug: Bool
) -> UInt

@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _float32ToString(
  _ value: Float32, debug: Bool
) -> String {

  if !value.isFinite {
    let significand = value.significandBitPattern
    if significand == 0 {
      // Infinity
      return value.sign == .minus ? "-inf" : "inf"
    }
    else {
      // NaN
      if !debug {
        return "nan"
      }
      let isSignaling = (significand & Float32._quietNaNMask) == 0
      let payload = significand & ((Float32._quietNaNMask >> 1) - 1)
      // FIXME(performance): Inefficient String manipulation. We could move
      // this to C function.
      return
        (value.sign == .minus ? "-" : "")
        + (isSignaling ? "snan" : "nan")
        + (payload == 0 ? "" : ("(0x" + String(payload, radix: 16) + ")"))
    }
  }

  _sanityCheck(MemoryLayout<_Buffer32>.size == 32)
  _sanityCheck(MemoryLayout<_Buffer72>.size == 72)

  var buffer = _Buffer32()
  return buffer.withBytes { (bufferPtr) in
    let actualLength = _float32ToStringImpl(bufferPtr, 32, value, debug)
    return String._fromWellFormedCodeUnitSequence(
      UTF8.self,
      input: UnsafeBufferPointer(start: bufferPtr, count: Int(actualLength)))
  }
}




@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
@_silgen_name("swift_float64ToString")
internal func _float64ToStringImpl(
  _ buffer: UnsafeMutablePointer<UTF8.CodeUnit>,
  _ bufferLength: UInt, _ value: Float64,
  _ debug: Bool
) -> UInt

@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _float64ToString(
  _ value: Float64, debug: Bool
) -> String {

  if !value.isFinite {
    let significand = value.significandBitPattern
    if significand == 0 {
      // Infinity
      return value.sign == .minus ? "-inf" : "inf"
    }
    else {
      // NaN
      if !debug {
        return "nan"
      }
      let isSignaling = (significand & Float64._quietNaNMask) == 0
      let payload = significand & ((Float64._quietNaNMask >> 1) - 1)
      // FIXME(performance): Inefficient String manipulation. We could move
      // this to C function.
      return
        (value.sign == .minus ? "-" : "")
        + (isSignaling ? "snan" : "nan")
        + (payload == 0 ? "" : ("(0x" + String(payload, radix: 16) + ")"))
    }
  }

  _sanityCheck(MemoryLayout<_Buffer32>.size == 32)
  _sanityCheck(MemoryLayout<_Buffer72>.size == 72)

  var buffer = _Buffer32()
  return buffer.withBytes { (bufferPtr) in
    let actualLength = _float64ToStringImpl(bufferPtr, 32, value, debug)
    return String._fromWellFormedCodeUnitSequence(
      UTF8.self,
      input: UnsafeBufferPointer(start: bufferPtr, count: Int(actualLength)))
  }
}



#if !os(Windows) && (arch(i386) || arch(x86_64))

@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
@_silgen_name("swift_float80ToString")
internal func _float80ToStringImpl(
  _ buffer: UnsafeMutablePointer<UTF8.CodeUnit>,
  _ bufferLength: UInt, _ value: Float80,
  _ debug: Bool
) -> UInt

@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _float80ToString(
  _ value: Float80, debug: Bool
) -> String {

  if !value.isFinite {
    let significand = value.significandBitPattern
    if significand == 0 {
      // Infinity
      return value.sign == .minus ? "-inf" : "inf"
    }
    else {
      // NaN
      if !debug {
        return "nan"
      }
      let isSignaling = (significand & Float80._quietNaNMask) == 0
      let payload = significand & ((Float80._quietNaNMask >> 1) - 1)
      // FIXME(performance): Inefficient String manipulation. We could move
      // this to C function.
      return
        (value.sign == .minus ? "-" : "")
        + (isSignaling ? "snan" : "nan")
        + (payload == 0 ? "" : ("(0x" + String(payload, radix: 16) + ")"))
    }
  }

  _sanityCheck(MemoryLayout<_Buffer32>.size == 32)
  _sanityCheck(MemoryLayout<_Buffer72>.size == 72)

  var buffer = _Buffer32()
  return buffer.withBytes { (bufferPtr) in
    let actualLength = _float80ToStringImpl(bufferPtr, 32, value, debug)
    return String._fromWellFormedCodeUnitSequence(
      UTF8.self,
      input: UnsafeBufferPointer(start: bufferPtr, count: Int(actualLength)))
  }
}

#endif


@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
@_silgen_name("swift_int64ToString")
internal func _int64ToStringImpl(
  _ buffer: UnsafeMutablePointer<UTF8.CodeUnit>,
  _ bufferLength: UInt, _ value: Int64,
  _ radix: Int64, _ uppercase: Bool
) -> UInt

@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal func _int64ToString(
  _ value: Int64, radix: Int64 = 10, uppercase: Bool = false
) -> String {
  if radix >= 10 {
    var buffer = _Buffer32()
    return buffer.withBytes { (bufferPtr) in
      let actualLength
      = _int64ToStringImpl(bufferPtr, 32, value, radix, uppercase)
      return String._fromWellFormedCodeUnitSequence(
        UTF8.self,
        input: UnsafeBufferPointer(start: bufferPtr, count: Int(actualLength)))
    }
  } else {
    var buffer = _Buffer72()
    return buffer.withBytes { (bufferPtr) in
      let actualLength
      = _int64ToStringImpl(bufferPtr, 72, value, radix, uppercase)
      return String._fromWellFormedCodeUnitSequence(
        UTF8.self,
        input: UnsafeBufferPointer(start: bufferPtr, count: Int(actualLength)))
    }
  }
}

@_inlineable // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
@_silgen_name("swift_uint64ToString")
internal func _uint64ToStringImpl(
  _ buffer: UnsafeMutablePointer<UTF8.CodeUnit>,
  _ bufferLength: UInt, _ value: UInt64, _ radix: Int64, _ uppercase: Bool
) -> UInt

@_inlineable // FIXME(sil-serialize-all)
public // @testable
func _uint64ToString(
    _ value: UInt64, radix: Int64 = 10, uppercase: Bool = false
) -> String {
  if radix >= 10 {
    var buffer = _Buffer32()
    return buffer.withBytes { (bufferPtr) in
      let actualLength
      = _uint64ToStringImpl(bufferPtr, 32, value, radix, uppercase)
      return String._fromWellFormedCodeUnitSequence(
        UTF8.self,
        input: UnsafeBufferPointer(start: bufferPtr, count: Int(actualLength)))
    }
  } else {
    var buffer = _Buffer72()
    return buffer.withBytes { (bufferPtr) in
      let actualLength
      = _uint64ToStringImpl(bufferPtr, 72, value, radix, uppercase)
      return String._fromWellFormedCodeUnitSequence(
        UTF8.self,
        input: UnsafeBufferPointer(start: bufferPtr, count: Int(actualLength)))
    }
  }
}

@_inlineable
@_versioned
internal func _rawPointerToString(_ value: Builtin.RawPointer) -> String {
  var result = _uint64ToString(
    UInt64(
      UInt(bitPattern: UnsafeRawPointer(value))),
      radix: 16,
      uppercase: false
    )
  for _ in 0..<(2 * MemoryLayout<UnsafeRawPointer>.size - result.utf16.count) {
    result = "0" + result
  }
  return "0x" + result
}

#if _runtime(_ObjC)
// At runtime, these classes are derived from `_SwiftNativeNSXXXBase`,
// which are derived from `NSXXX`.
//
// The @swift_native_objc_runtime_base attribute
// allows us to subclass an Objective-C class and still use the fast Swift
// memory allocator.

@_fixed_layout // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
@objc @_swift_native_objc_runtime_base(_SwiftNativeNSArrayBase)
internal class _SwiftNativeNSArray {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal init() {}
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  deinit {}
}

@_fixed_layout // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
@objc @_swift_native_objc_runtime_base(_SwiftNativeNSDictionaryBase)
internal class _SwiftNativeNSDictionary {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  @objc
  internal init() {}
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  deinit {}
}

@_fixed_layout // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
@objc @_swift_native_objc_runtime_base(_SwiftNativeNSSetBase)
internal class _SwiftNativeNSSet {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  @objc
  internal init() {}
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  deinit {}
}

@_fixed_layout // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
@objc @_swift_native_objc_runtime_base(_SwiftNativeNSEnumeratorBase)
internal class _SwiftNativeNSEnumerator {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  @objc
  internal init() {}
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  deinit {}
}

// FIXME(ABI)#60 : move into the Foundation overlay and remove 'open'
@_fixed_layout // FIXME(sil-serialize-all)
@objc @_swift_native_objc_runtime_base(_SwiftNativeNSDataBase)
open class _SwiftNativeNSData {
  @_inlineable // FIXME(sil-serialize-all)
  @objc public init() {}
  @_inlineable // FIXME(sil-serialize-all)
  deinit {}
}

//===----------------------------------------------------------------------===//
// Support for reliable testing of the return-autoreleased optimization
//===----------------------------------------------------------------------===//

@_fixed_layout // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
@objc
internal class _stdlib_ReturnAutoreleasedDummy {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  @objc
  internal init() {}

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  deinit {}

  // Use 'dynamic' to force Objective-C dispatch, which uses the
  // return-autoreleased call sequence.
  @objc
  internal dynamic func returnsAutoreleased(_ x: AnyObject) -> AnyObject {
    return x
  }

  // Use 'dynamic' to prevent this call to be duplicated into other modules.
  @objc
  internal dynamic func initializeReturnAutoreleased() {
    // On x86_64 it is sufficient to perform one cycle of return-autoreleased
    // call sequence in order to initialize all required PLT entries.
    _ = self.returnsAutoreleased(self)
  }
}

/// This function ensures that the return-autoreleased optimization works.
///
/// On some platforms (for example, x86_64), the first call to
/// `objc_autoreleaseReturnValue` will always autorelease because it would fail
/// to verify the instruction sequence in the caller.  On x86_64 certain PLT
/// entries would be still pointing to the resolver function, and sniffing
/// the call sequence would fail.
///
/// This code should live in the core stdlib dylib because PLT tables are
/// separate for each dylib.
///
/// Call this function in a fresh autorelease pool.
@_inlineable // FIXME(sil-serialize-all)
public func _stdlib_initializeReturnAutoreleased() {
//  _stdlib_initializeReturnAutoreleasedImpl()
#if arch(x86_64)
  _stdlib_ReturnAutoreleasedDummy().initializeReturnAutoreleased()
#endif
}
#else

@_fixed_layout // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal class _SwiftNativeNSArray {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal init() {}
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  deinit {}
}
@_fixed_layout // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal class _SwiftNativeNSDictionary {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal init() {}
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  deinit {}
}
@_fixed_layout // FIXME(sil-serialize-all)
@_versioned // FIXME(sil-serialize-all)
internal class _SwiftNativeNSSet {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal init() {}
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  deinit {}
}

#endif
