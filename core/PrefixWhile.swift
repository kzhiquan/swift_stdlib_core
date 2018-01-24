//===-- PrefixWhile.swift.gyb - Lazy views for prefix(while:) -*- swift -*-===//
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


//===--- Iterator & Sequence ----------------------------------------------===//

/// An iterator over the initial elements traversed by a base iterator that
/// satisfy a given predicate.
///
/// This is the associated iterator for the `LazyPrefixWhileSequence`,
/// `LazyPrefixWhileCollection`, and `LazyPrefixWhileBidirectionalCollection`
/// types.
@_fixed_layout // FIXME(sil-serialize-all)
public struct LazyPrefixWhileIterator<Base : IteratorProtocol> :
  IteratorProtocol, Sequence {

  @_inlineable // FIXME(sil-serialize-all)
  public mutating func next() -> Base.Element? {
    // Return elements from the base iterator until one fails the predicate.
    if !_predicateHasFailed, let nextElement = _base.next() {
      if _predicate(nextElement) {
        return nextElement
      } else {
        _predicateHasFailed = true
      }
    }
    return nil
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal init(_base: Base, predicate: @escaping (Base.Element) -> Bool) {
    self._base = _base
    self._predicate = predicate
  }

  @_versioned // FIXME(sil-serialize-all)
  internal var _predicateHasFailed = false
  @_versioned // FIXME(sil-serialize-all)
  internal var _base: Base
  @_versioned // FIXME(sil-serialize-all)
  internal let _predicate: (Base.Element) -> Bool
}

/// A sequence whose elements consist of the initial consecutive elements of
/// some base sequence that satisfy a given predicate.
@_fixed_layout // FIXME(sil-serialize-all)
public struct LazyPrefixWhileSequence<Base : Sequence> : LazySequenceProtocol {

  public typealias Elements = LazyPrefixWhileSequence

  @_inlineable // FIXME(sil-serialize-all)
  public func makeIterator() -> LazyPrefixWhileIterator<Base.Iterator> {
    return LazyPrefixWhileIterator(
      _base: _base.makeIterator(), predicate: _predicate)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal init(_base: Base, predicate: @escaping (Base.Element) -> Bool) {
    self._base = _base
    self._predicate = predicate
  }

  @_versioned // FIXME(sil-serialize-all)
  internal var _base: Base
  @_versioned // FIXME(sil-serialize-all)
  internal let _predicate: (Base.Element) -> Bool
}

extension LazySequenceProtocol {
  /// Returns a lazy sequence of the initial consecutive elements that satisfy
  /// `predicate`.
  ///
  /// - Parameter predicate: A closure that takes an element of the sequence as
  ///   its argument and returns `true` if the element should be included or
  ///   `false` otherwise. Once `predicate` returns `false` it will not be
  ///   called again.
  @_inlineable // FIXME(sil-serialize-all)
  public func prefix(
    while predicate: @escaping (Elements.Element) -> Bool
  ) -> LazyPrefixWhileSequence<Self.Elements> {
    return LazyPrefixWhileSequence(_base: self.elements, predicate: predicate)
  }
}

//===--- Collections ------------------------------------------------------===//

/// A position in the base collection of a `LazyPrefixWhileCollection` or the
/// end of that collection.
@_fixed_layout // FIXME(sil-serialize-all)
public enum _LazyPrefixWhileIndexRepresentation<Base : Collection> {
  case index(Base.Index)
  case pastEnd
}

/// A position in a `LazyPrefixWhileCollection` or
/// `LazyPrefixWhileBidirectionalCollection` instance.
@_fixed_layout // FIXME(sil-serialize-all)
public struct LazyPrefixWhileIndex<Base : Collection> : Comparable {
  /// The position corresponding to `self` in the underlying collection.
  @_versioned // FIXME(sil-serialize-all)
  internal let _value: _LazyPrefixWhileIndexRepresentation<Base>

  /// Creates a new index wrapper for `i`.
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal init(_ i: Base.Index) {
    self._value = .index(i)
  }

  /// Creates a new index that can represent the `endIndex` of a
  /// `LazyPrefixWhileCollection<Base>`. This is not the same as a wrapper
  /// around `Base.endIndex`.
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal init(endOf: Base) {
    self._value = .pastEnd
  }

  @_inlineable // FIXME(sil-serialize-all)
  public static func == (
    lhs: LazyPrefixWhileIndex, rhs: LazyPrefixWhileIndex
  ) -> Bool {
    switch (lhs._value, rhs._value) {
    case let (.index(l), .index(r)):
      return l == r
    case (.pastEnd, .pastEnd):
      return true
    default:
      return false
    }
  }

  @_inlineable // FIXME(sil-serialize-all)
  public static func < (
    lhs: LazyPrefixWhileIndex, rhs: LazyPrefixWhileIndex
  ) -> Bool {
    switch (lhs._value, rhs._value) {
    case let (.index(l), .index(r)):
      return l < r
    case (.index, .pastEnd):
      return true
    default:
      return false
    }
  }
}

extension LazyPrefixWhileIndex : Hashable where Base.Index : Hashable {
  public var hashValue: Int {
    switch _value {
    case .index(let value):
      return value.hashValue
    case .pastEnd:
      return .max
    }
  }
}


/// A lazy `Collection` wrapper that includes the initial consecutive
/// elements of an underlying collection that satisfy a predicate.
///
/// - Note: The performance of accessing `endIndex`, `last`, any methods that
///   depend on `endIndex`, or moving an index depends on how many elements
///   satisfy the predicate at the start of the collection, and may not offer
///   the usual performance given by the `Collection` protocol. Be aware,
///   therefore, that general operations on `LazyPrefixWhileCollection` instances may not have
///   the documented complexity.
@_fixed_layout // FIXME(sil-serialize-all)
public struct LazyPrefixWhileCollection<
  Base : Collection
> : LazyCollectionProtocol, Collection {

  public typealias Index = LazyPrefixWhileIndex<Base>

  @_inlineable // FIXME(sil-serialize-all)
  public var startIndex: Index {
    return LazyPrefixWhileIndex(_base.startIndex)
  }

  @_inlineable // FIXME(sil-serialize-all)
  public var endIndex: Index {
    // If the first element of `_base` satisfies the predicate, there is at
    // least one element in the lazy collection: Use the explicit `.pastEnd` index.
    if let first = _base.first, _predicate(first) {
      return LazyPrefixWhileIndex(endOf: _base)
    }

    // `_base` is either empty or `_predicate(_base.first!) == false`. In either
    // case, the lazy collection is empty, so `endIndex == startIndex`.
    return startIndex
  }

  @_inlineable // FIXME(sil-serialize-all)
  public func index(after i: Index) -> Index {
    _precondition(i != endIndex, "Can't advance past endIndex")
    guard case .index(let i) = i._value else {
      _preconditionFailure("Invalid index passed to index(after:)")
    }
    let nextIndex = _base.index(after: i)
    guard nextIndex != _base.endIndex && _predicate(_base[nextIndex]) else {
      return LazyPrefixWhileIndex(endOf: _base)
    }
    return LazyPrefixWhileIndex(nextIndex)
  }


  @_inlineable // FIXME(sil-serialize-all)
  public subscript(position: Index) -> Base.Element {
    switch position._value {
    case .index(let i):
      return _base[i]
    case .pastEnd:
      _preconditionFailure("Index out of range")
    }
  }

  @_inlineable // FIXME(sil-serialize-all)
  public func makeIterator() -> LazyPrefixWhileIterator<Base.Iterator> {
    return LazyPrefixWhileIterator(
      _base: _base.makeIterator(), predicate: _predicate)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal init(_base: Base, predicate: @escaping (Base.Element) -> Bool) {
    self._base = _base
    self._predicate = predicate
  }

  @_versioned // FIXME(sil-serialize-all)
  internal var _base: Base
  @_versioned // FIXME(sil-serialize-all)
  internal let _predicate: (Base.Element) -> Bool
}

extension LazyCollectionProtocol
{
  /// Returns a lazy collection of the initial consecutive elements that
  /// satisfy `predicate`.
  ///
  /// - Parameter predicate: A closure that takes an element of the collection
  ///   as its argument and returns `true` if the element should be included
  ///   or `false` otherwise. Once `predicate` returns `false` it will not be
  ///   called again.
  @_inlineable // FIXME(sil-serialize-all)
  public func prefix(
    while predicate: @escaping (Elements.Element) -> Bool
  ) -> LazyPrefixWhileCollection<Self.Elements> {
    return LazyPrefixWhileCollection(
      _base: self.elements, predicate: predicate)
  }
}


/// A lazy `BidirectionalCollection` wrapper that includes the initial consecutive
/// elements of an underlying collection that satisfy a predicate.
///
/// - Note: The performance of accessing `endIndex`, `last`, any methods that
///   depend on `endIndex`, or moving an index depends on how many elements
///   satisfy the predicate at the start of the collection, and may not offer
///   the usual performance given by the `Collection` protocol. Be aware,
///   therefore, that general operations on `LazyPrefixWhileBidirectionalCollection` instances may not have
///   the documented complexity.
@_fixed_layout // FIXME(sil-serialize-all)
public struct LazyPrefixWhileBidirectionalCollection<
  Base : BidirectionalCollection
> : LazyCollectionProtocol, BidirectionalCollection {

  public typealias Index = LazyPrefixWhileIndex<Base>

  @_inlineable // FIXME(sil-serialize-all)
  public var startIndex: Index {
    return LazyPrefixWhileIndex(_base.startIndex)
  }

  @_inlineable // FIXME(sil-serialize-all)
  public var endIndex: Index {
    // If the first element of `_base` satisfies the predicate, there is at
    // least one element in the lazy collection: Use the explicit `.pastEnd` index.
    if let first = _base.first, _predicate(first) {
      return LazyPrefixWhileIndex(endOf: _base)
    }

    // `_base` is either empty or `_predicate(_base.first!) == false`. In either
    // case, the lazy collection is empty, so `endIndex == startIndex`.
    return startIndex
  }

  @_inlineable // FIXME(sil-serialize-all)
  public func index(after i: Index) -> Index {
    _precondition(i != endIndex, "Can't advance past endIndex")
    guard case .index(let i) = i._value else {
      _preconditionFailure("Invalid index passed to index(after:)")
    }
    let nextIndex = _base.index(after: i)
    guard nextIndex != _base.endIndex && _predicate(_base[nextIndex]) else {
      return LazyPrefixWhileIndex(endOf: _base)
    }
    return LazyPrefixWhileIndex(nextIndex)
  }


  @_inlineable // FIXME(sil-serialize-all)
  public func index(before i: Index) -> Index {
    switch i._value {
    case .index(let i):
      _precondition(i != _base.startIndex, "Can't move before startIndex")
      return LazyPrefixWhileIndex(_base.index(before: i))
    case .pastEnd:
      // Look for the position of the last element in a non-empty
      // prefix(while:) collection by searching forward for a predicate
      // failure.

      // Safe to assume that `_base.startIndex != _base.endIndex`; if they
      // were equal, `_base.startIndex` would be used as the `endIndex` of
      // this collection.
      _sanityCheck(!_base.isEmpty)
      var result = _base.startIndex
      while true {
        let next = _base.index(after: result)
        if next == _base.endIndex || !_predicate(_base[next]) {
          break
        }
        result = next
      }
      return LazyPrefixWhileIndex(result)
    }
  }


  @_inlineable // FIXME(sil-serialize-all)
  public subscript(position: Index) -> Base.Element {
    switch position._value {
    case .index(let i):
      return _base[i]
    case .pastEnd:
      _preconditionFailure("Index out of range")
    }
  }

  @_inlineable // FIXME(sil-serialize-all)
  public func makeIterator() -> LazyPrefixWhileIterator<Base.Iterator> {
    return LazyPrefixWhileIterator(
      _base: _base.makeIterator(), predicate: _predicate)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal init(_base: Base, predicate: @escaping (Base.Element) -> Bool) {
    self._base = _base
    self._predicate = predicate
  }

  @_versioned // FIXME(sil-serialize-all)
  internal var _base: Base
  @_versioned // FIXME(sil-serialize-all)
  internal let _predicate: (Base.Element) -> Bool
}

extension LazyCollectionProtocol
  where
  Self : BidirectionalCollection,
  Elements : BidirectionalCollection
{
  /// Returns a lazy collection of the initial consecutive elements that
  /// satisfy `predicate`.
  ///
  /// - Parameter predicate: A closure that takes an element of the collection
  ///   as its argument and returns `true` if the element should be included
  ///   or `false` otherwise. Once `predicate` returns `false` it will not be
  ///   called again.
  @_inlineable // FIXME(sil-serialize-all)
  public func prefix(
    while predicate: @escaping (Elements.Element) -> Bool
  ) -> LazyPrefixWhileBidirectionalCollection<Self.Elements> {
    return LazyPrefixWhileBidirectionalCollection(
      _base: self.elements, predicate: predicate)
  }
}


// Local Variables:
// eval: (read-only-mode 1)
// End: