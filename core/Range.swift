//===--- Range.swift.gyb --------------------------------------*- swift -*-===//
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

/// A type that can be used to slice a collection.
///
/// A type that conforms to `RangeExpression` can convert itself to a
/// `Range<Bound>` of indices within a given collection.
public protocol RangeExpression {
  /// The type for which the expression describes a range.
  associatedtype Bound: Comparable

  /// Returns the range of indices described by this range expression within
  /// the given collection.
  ///
  /// You can use the `relative(to:)` method to convert a range expression,
  /// which could be missing one or both of its endpoints, into a concrete
  /// range that is bounded on both sides. The following example uses this
  /// method to convert a partial range up to `4` into a half-open range,
  /// using an array instance to add the range's lower bound.
  ///
  ///     let numbers = [10, 20, 30, 40, 50, 60, 70]
  ///     let upToFour = ..<4
  ///
  ///     let r1 = upToFour.relative(to: numbers)
  ///     // r1 == 0..<4
  ///
  /// The `r1` range is bounded on the lower end by `0` because that is the
  /// starting index of the `numbers` array. When the collection passed to
  /// `relative(to:)` starts with a different index, that index is used as the
  /// lower bound instead. The next example creates a slice of `numbers`
  /// starting at index `2`, and then uses the slice with `relative(to:)` to
  /// convert `upToFour` to a concrete range.
  ///
  ///     let numbersSuffix = numbers[2...]
  ///     // numbersSuffix == [30, 40, 50, 60, 70]
  ///
  ///     let r2 = upToFour.relative(to: numbersSuffix)
  ///     // r2 == 2..<4
  ///
  /// Use this method only if you need the concrete range it produces. To
  /// access a slice of a collection using a range expression, use the
  /// collection's generic subscript that uses a range expression as its
  /// parameter.
  ///
  ///     let numbersPrefix = numbers[upToFour]
  ///     // numbersPrefix == [10, 20, 30, 40]
  ///
  /// - Parameter collection: The collection to evaluate this range expression
  ///   in relation to.
  /// - Returns: A range suitable for slicing `collection`. The returned range
  ///   is *not* guaranteed to be inside the bounds of `collection`. Callers
  ///   should apply the same preconditions to the return value as they would
  ///   to a range provided directly by the user.
  func relative<C: Collection>(
    to collection: C
  ) -> Range<Bound> where C.Index == Bound
  
  /// Returns a Boolean value indicating whether the given element is contained
  /// within the range expression.
  ///
  /// - Parameter element: The element to check for containment.
  /// - Returns: `true` if `element` is contained in the range expression;
  ///   otherwise, `false`.
  func contains(_ element: Bound) -> Bool
}

extension RangeExpression {
  @_inlineable
  public static func ~= (pattern: Self, value: Bound) -> Bool {
    return pattern.contains(value)
  }  
}

/// A half-open range that forms a collection of consecutive values.
///
/// You create a `CountableRange` instance by using the half-open range
/// operator (`..<`).
///
///     let upToFive = 0..<5
///
/// The associated `Bound` type is both the element and index type of
/// `CountableRange`. Each element of the range is its own corresponding
/// index. The lower bound of a `CountableRange` instance is its start index,
/// and the upper bound is its end index.
///
///     print(upToFive.contains(3))         // Prints "true"
///     print(upToFive.contains(10))        // Prints "false"
///     print(upToFive.contains(5))         // Prints "false"
///
/// If the `Bound` type has a maximal value, it can serve as an upper bound but
/// can never be contained in a `CountableRange<Bound>` instance. For example,
/// a `CountableRange<Int8>` instance can use `Int8.max` as its upper bound,
/// but it can't represent a range that includes `Int8.max`.
///
///     let maximumRange = Int8.min..<Int8.max
///     print(maximumRange.contains(Int8.max))
///     // Prints "false"
///
/// If you need to create a range that includes the maximal value of its
/// `Bound` type, see the `CountableClosedRange` type.
///
/// You can create a countable range over any type that conforms to the
/// `Strideable` protocol and uses an integer as its associated `Stride` type.
/// By default, Swift's integer and pointer types are usable as the bounds of
/// a countable range.
///
/// Because floating-point types such as `Float` and `Double` are their own
/// `Stride` types, they cannot be used as the bounds of a countable range. If
/// you need to test whether values are contained within an interval bound by
/// floating-point values, see the `Range` type. If you need to iterate over
/// consecutive floating-point values, see the `stride(from:to:by:)` function.
///
/// Integer Index Ambiguity
/// -----------------------
///
/// Because each element of a `CountableRange` instance is its own index, for
/// the range `(-99..<100)` the element at index `0` is `0`. This is an
/// unexpected result for those accustomed to zero-based collection indices,
/// who might expect the result to be `-99`. To prevent this confusion, in a
/// context where `Bound` is known to be an integer type, subscripting
/// directly is a compile-time error:
///
///     // error: ambiguous use of 'subscript'
///     print((-99..<100)[0])
///
/// However, subscripting that range still works in a generic context:
///
///     func brackets<T>(_ x: CountableRange<T>, _ i: T) -> T {
///         return x[i] // Just forward to subscript
///     }
///     print(brackets(-99..<100, 0))
///     // Prints "0"
@_fixed_layout
public struct CountableRange<Bound>
where Bound : Strideable, Bound.Stride : SignedInteger {
  /// The range's lower bound.
  ///
  /// In an empty range, `lowerBound` is equal to `upperBound`.
  public let lowerBound: Bound

  /// The range's upper bound.
  ///
  /// `upperBound` is not a valid subscript argument and is always
  /// reachable from `lowerBound` by zero or more applications of
  /// `index(after:)`.
  ///
  /// In an empty range, `upperBound` is equal to `lowerBound`.
  public let upperBound: Bound

  /// Creates an instance with the given bounds.
  ///
  /// Because this initializer does not perform any checks, it should be used
  /// as an optimization only when you are absolutely certain that `lower` is
  /// less than or equal to `upper`. Using the half-open range operator
  /// (`..<`) to form `CountableRange` instances is preferred.
  ///
  /// - Parameter bounds: A tuple of the lower and upper bounds of the range.
  @_inlineable
  public init(uncheckedBounds bounds: (lower: Bound, upper: Bound)) {
    self.lowerBound = bounds.lower
    self.upperBound = bounds.upper
  }
}

extension CountableRange: RandomAccessCollection {

  /// The bound type of the range.
  public typealias Element = Bound

  /// A type that represents a position in the range.
  public typealias Index = Element
  public typealias Indices = CountableRange<Bound>
  public typealias SubSequence = CountableRange<Bound>

  @_inlineable
  public var startIndex: Index {
    return lowerBound
  }

  @_inlineable
  public var endIndex: Index {
    return upperBound
  }

  @_inlineable
  public func index(after i: Index) -> Index {
    _failEarlyRangeCheck(i, bounds: startIndex..<endIndex)

    return i.advanced(by: 1)
  }

  @_inlineable
  public func index(before i: Index) -> Index {
    _precondition(i > lowerBound)
    _precondition(i <= upperBound)

    return i.advanced(by: -1)
  }

  @_inlineable
  public func index(_ i: Index, offsetBy n: Int) -> Index {
    let r = i.advanced(by: numericCast(n))
    _precondition(r >= lowerBound)
    _precondition(r <= upperBound)
    return r
  }

  @_inlineable
  public func distance(from start: Index, to end: Index) -> Int {
    return numericCast(start.distance(to: end))
  }

  /// Accesses the subsequence bounded by the given range.
  ///
  /// - Parameter bounds: A range of the range's indices. The upper and lower
  ///   bounds of the `bounds` range must be valid indices of the collection.
  @_inlineable
  public subscript(bounds: Range<Index>) -> SubSequence {
    return CountableRange(bounds)
  }

  /// Accesses the subsequence bounded by the given range.
  ///
  /// - Parameter bounds: A range of the range's indices. The upper and lower
  ///   bounds of the `bounds` range must be valid indices of the collection.
  @_inlineable
  public subscript(bounds: CountableRange<Bound>) -> CountableRange<Bound> {
    return self[Range(bounds)]
  }

  /// The indices that are valid for subscripting the range, in ascending
  /// order.
  @_inlineable
  public var indices: Indices {
    return self
  }

  @_inlineable
  public func _customContainsEquatableElement(_ element: Element) -> Bool? {
    return lowerBound <= element && element < upperBound
  }

  /// A Boolean value indicating whether the range contains no elements.
  ///
  /// An empty range has equal lower and upper bounds.
  ///
  ///     let empty = 10..<10
  ///     print(empty.isEmpty)
  ///     // Prints "true"
  @_inlineable
  public var isEmpty: Bool {
    return lowerBound == upperBound
  }

  /// Returns a Boolean value indicating whether the given element is contained
  /// within the range.
  ///
  /// Because `CountableRange` represents a half-open range, a `CountableRange`
  /// instance does not contain its upper bound. `element` is contained in the
  /// range if it is greater than or equal to the lower bound and less than
  /// the upper bound.
  ///
  /// - Parameter element: The element to check for containment.
  /// - Returns: `true` if `element` is contained in the range; otherwise,
  ///   `false`.
  @_inlineable
  public func contains(_ element: Bound) -> Bool {
    return lowerBound <= element && element < upperBound
  }
}

//===--- Protection against 0-based indexing assumption -------------------===//
// The following two extensions provide subscript overloads that
// create *intentional* ambiguities to prevent the use of integers as
// indices for ranges, outside a generic context.  This prevents mistakes
// such as x = r[0], which will trap unless 0 happens to be contained in the
// range r.
//
// FIXME(ABI)#56 (Statically Unavailable/Dynamically Available): remove this
// code, it creates an ABI burden on the library.
extension CountableRange {
  /// Accesses the element at specified position.
  ///
  /// You can subscript a collection with any valid index other than the
  /// collection's end index. The end index refers to the position one past
  /// the last element of a collection, so it doesn't correspond with an
  /// element.
  ///
  /// - Parameter position: The position of the element to access. `position`
  ///   must be a valid index of the range, and must not equal the range's end
  ///   index.
  @_inlineable
  public subscript(position: Index) -> Element {
    // FIXME: swift-3-indexing-model: tests for the range check.
    _debugPrecondition(self.contains(position), "Index out of range")
    return position
  }

  @_inlineable // FIXME(sil-serialize-all)
  public subscript(_position: Bound._DisabledRangeIndex) -> Element {
    fatalError("uncallable")
  }
}

extension CountableRange
where
  Bound._DisabledRangeIndex : Strideable,
  Bound._DisabledRangeIndex.Stride : SignedInteger {

  @_inlineable // FIXME(sil-serialize-all)
  public subscript(
    _bounds: Range<Bound._DisabledRangeIndex>
  ) -> CountableRange<Bound> {
    fatalError("uncallable")
  }

  @_inlineable // FIXME(sil-serialize-all)
  public subscript(
    _bounds: CountableRange<Bound._DisabledRangeIndex>
  ) -> CountableRange<Bound> {
    fatalError("uncallable")
  }

  @_inlineable // FIXME(sil-serialize-all)
  public subscript(
    _bounds: ClosedRange<Bound._DisabledRangeIndex>
  ) -> CountableRange<Bound> {
    fatalError("uncallable")
  }

  @_inlineable // FIXME(sil-serialize-all)
  public subscript(
    _bounds: CountableClosedRange<Bound._DisabledRangeIndex>
  ) -> CountableRange<Bound> {
    fatalError("uncallable")
  }

  /// Accesses the subsequence bounded by the given range.
  ///
  /// - Parameter bounds: A range of the collection's indices. The upper and
  ///   lower bounds of the `bounds` range must be valid indices of the
  ///   collection and `bounds.upperBound` must be less than the collection's
  ///   end index.
  @_inlineable
  public subscript(bounds: ClosedRange<Bound>) -> CountableRange<Bound> {
    return self[bounds.lowerBound..<(bounds.upperBound.advanced(by: 1))]
  }

  /// Accesses the subsequence bounded by the given range.
  ///
  /// - Parameter bounds: A range of the collection's indices. The upper and
  ///   lower bounds of the `bounds` range must be valid indices of the
  ///   collection and `bounds.upperBound` must be less than the collection's
  ///   end index.
  @_inlineable
  public subscript(
    bounds: CountableClosedRange<Bound>
  ) -> CountableRange<Bound> {
    return self[ClosedRange(bounds)]
  }
}

//===--- End 0-based indexing protection ----------------------------------===//

/// A half-open interval over a comparable type, from a lower bound up to, but
/// not including, an upper bound.
///
/// You create `Range` instances by using the half-open range operator (`..<`).
///
///     let underFive = 0.0..<5.0
///
/// You can use a `Range` instance to quickly check if a value is contained in
/// a particular range of values. For example:
///
///     print(underFive.contains(3.14))     // Prints "true"
///     print(underFive.contains(6.28))     // Prints "false"
///     print(underFive.contains(5.0))      // Prints "false"
///
/// `Range` instances can represent an empty interval, unlike `ClosedRange`.
///
///     let empty = 0.0..<0.0
///     print(empty.contains(0.0))          // Prints "false"
///     print(empty.isEmpty)                // Prints "true"
@_fixed_layout
public struct Range<Bound : Comparable> {
  /// The range's lower bound.
  ///
  /// In an empty range, `lowerBound` is equal to `upperBound`.
  public let lowerBound: Bound

  /// The range's upper bound.
  ///
  /// In an empty range, `upperBound` is equal to `lowerBound`. A `Range`
  /// instance does not contain its upper bound.
  public let upperBound: Bound

  /// Creates an instance with the given bounds.
  ///
  /// Because this initializer does not perform any checks, it should be used
  /// as an optimization only when you are absolutely certain that `lower` is
  /// less than or equal to `upper`. Using the half-open range operator
  /// (`..<`) to form `Range` instances is preferred.
  ///
  /// - Parameter bounds: A tuple of the lower and upper bounds of the range.
  @_inlineable
  public init(uncheckedBounds bounds: (lower: Bound, upper: Bound)) {
    self.lowerBound = bounds.lower
    self.upperBound = bounds.upper
  }

  /// Returns a Boolean value indicating whether the given element is contained
  /// within the range.
  ///
  /// Because `Range` represents a half-open range, a `Range` instance does not
  /// contain its upper bound. `element` is contained in the range if it is
  /// greater than or equal to the lower bound and less than the upper bound.
  ///
  /// - Parameter element: The element to check for containment.
  /// - Returns: `true` if `element` is contained in the range; otherwise,
  ///   `false`.
  @_inlineable
  public func contains(_ element: Bound) -> Bool {
    return lowerBound <= element && element < upperBound
  }

  /// A Boolean value indicating whether the range contains no elements.
  ///
  /// An empty `Range` instance has equal lower and upper bounds.
  ///
  ///     let empty: Range = 10..<10
  ///     print(empty.isEmpty)
  ///     // Prints "true"
  @_inlineable
  public var isEmpty: Bool {
    return lowerBound == upperBound
  }
}


extension Range
{
  /// Creates an instance equivalent to the given range.

  ///
  /// - Parameter other: A range to convert to a `Range` instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init(_ other: Range<Bound>) {
    let upperBound = other.upperBound
    self.init(
      uncheckedBounds: (lower: other.lowerBound, upper: upperBound)
    )
  }
}

extension Range
{
  /// Returns a Boolean value indicating whether this range and the given range
  /// contain an element in common.
  ///
  /// This example shows two overlapping ranges:
  ///
  ///     let x: Range = 0..<20
  ///     print(x.overlaps(10..<1000 as Range))
  ///     // Prints "true"
  ///
  /// Because a half-open range does not include its upper bound, the ranges
  /// in the following example do not overlap:
  ///
  ///     let y: Range = 20..<30
  ///     print(x.overlaps(y))
  ///     // Prints "false"
  ///
  /// - Parameter other: A range to check for elements in common.
  /// - Returns: `true` if this range and `other` have at least one element in
  ///   common; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func overlaps(_ other: Range<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(lowerBound))
  }
}
extension Range
  where
  Bound : Strideable, Bound.Stride : SignedInteger
{
  /// Creates an instance equivalent to the given range.

  ///
  /// - Parameter other: A range to convert to a `Range` instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init(_ other: CountableRange<Bound>) {
    let upperBound = other.upperBound
    self.init(
      uncheckedBounds: (lower: other.lowerBound, upper: upperBound)
    )
  }
}

extension Range
  where
  Bound : Strideable, Bound.Stride : SignedInteger
{
  /// Returns a Boolean value indicating whether this range and the given range
  /// contain an element in common.
  ///
  /// This example shows two overlapping ranges:
  ///
  ///     let x: Range = 0..<20
  ///     print(x.overlaps(10..<1000 as CountableRange))
  ///     // Prints "true"
  ///
  /// Because a half-open range does not include its upper bound, the ranges
  /// in the following example do not overlap:
  ///
  ///     let y: CountableRange = 20..<30
  ///     print(x.overlaps(y))
  ///     // Prints "false"
  ///
  /// - Parameter other: A range to check for elements in common.
  /// - Returns: `true` if this range and `other` have at least one element in
  ///   common; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func overlaps(_ other: CountableRange<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(lowerBound))
  }
}
extension Range
  where
  Bound : Strideable, Bound.Stride : SignedInteger
{
  /// Creates an instance equivalent to the given range.
  ///
  /// An equivalent range must be representable as an instance of `Range`.
  /// For example, passing a closed range with an upper bound of `Int.max`
  /// triggers a runtime error, because the resulting half-open range would
  /// require an upper bound of `Int.max + 1`, which is not representable as
  /// an `Int`.
  ///
  /// - Parameter other: A range to convert to a `Range` instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init(_ other: ClosedRange<Bound>) {
    let upperBound = other.upperBound.advanced(by: 1)
    self.init(
      uncheckedBounds: (lower: other.lowerBound, upper: upperBound)
    )
  }
}

extension Range
{
  /// Returns a Boolean value indicating whether this range and the given range
  /// contain an element in common.
  ///
  /// This example shows two overlapping ranges:
  ///
  ///     let x: Range = 0..<20
  ///     print(x.overlaps(10...1000 as ClosedRange))
  ///     // Prints "true"
  ///
  /// Because a half-open range does not include its upper bound, the ranges
  /// in the following example do not overlap:
  ///
  ///     let y: ClosedRange = 20..<30
  ///     print(x.overlaps(y))
  ///     // Prints "false"
  ///
  /// - Parameter other: A range to check for elements in common.
  /// - Returns: `true` if this range and `other` have at least one element in
  ///   common; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func overlaps(_ other: ClosedRange<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(lowerBound))
  }
}
extension Range
  where
  Bound : Strideable, Bound.Stride : SignedInteger
{
  /// Creates an instance equivalent to the given range.
  ///
  /// An equivalent range must be representable as an instance of `Range`.
  /// For example, passing a closed range with an upper bound of `Int.max`
  /// triggers a runtime error, because the resulting half-open range would
  /// require an upper bound of `Int.max + 1`, which is not representable as
  /// an `Int`.
  ///
  /// - Parameter other: A range to convert to a `Range` instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init(_ other: CountableClosedRange<Bound>) {
    let upperBound = other.upperBound.advanced(by: 1)
    self.init(
      uncheckedBounds: (lower: other.lowerBound, upper: upperBound)
    )
  }
}

extension Range
  where
  Bound : Strideable, Bound.Stride : SignedInteger
{
  /// Returns a Boolean value indicating whether this range and the given range
  /// contain an element in common.
  ///
  /// This example shows two overlapping ranges:
  ///
  ///     let x: Range = 0..<20
  ///     print(x.overlaps(10...1000 as CountableClosedRange))
  ///     // Prints "true"
  ///
  /// Because a half-open range does not include its upper bound, the ranges
  /// in the following example do not overlap:
  ///
  ///     let y: CountableClosedRange = 20..<30
  ///     print(x.overlaps(y))
  ///     // Prints "false"
  ///
  /// - Parameter other: A range to check for elements in common.
  /// - Returns: `true` if this range and `other` have at least one element in
  ///   common; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func overlaps(_ other: CountableClosedRange<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(lowerBound))
  }
}

extension Range {
  /// Returns a copy of this range clamped to the given limiting range.
  ///
  /// The bounds of the result are always limited to the bounds of `limits`.
  /// For example:
  ///
  ///     let x: Range = 0..<20
  ///     print(x.clamped(to: 10..<1000))
  ///     // Prints "10..<20"
  ///
  /// If the two ranges do not overlap, the result is an empty range within the
  /// bounds of `limits`.
  ///
  ///     let y: Range = 0..<5
  ///     print(y.clamped(to: 10..<1000))
  ///     // Prints "10..<10"
  ///
  /// - Parameter limits: The range to clamp the bounds of this range.
  /// - Returns: A new range clamped to the bounds of `limits`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func clamped(to limits: Range) -> Range {
    return Range(
      uncheckedBounds: (
        lower:
        limits.lowerBound > self.lowerBound ? limits.lowerBound
          : limits.upperBound < self.lowerBound ? limits.upperBound
          : self.lowerBound,
        upper:
          limits.upperBound < self.upperBound ? limits.upperBound
          : limits.lowerBound > self.upperBound ? limits.lowerBound
          : self.upperBound
      )
    )
  }
}

extension Range: RangeExpression {
  @_inlineable // FIXME(sil-serialize-all)
  public func relative<C: Collection>(to collection: C) -> Range<Bound>
  where C.Index == Bound {
    return Range(uncheckedBounds: (lower: lowerBound, upper: upperBound))
  }
}

extension Range : CustomStringConvertible {
  /// A textual representation of the range.
  @_inlineable // FIXME(sil-serialize-all)
  public var description: String {
    return "\(lowerBound)..<\(upperBound)"
  }
}

extension Range : CustomDebugStringConvertible {
  /// A textual representation of the range, suitable for debugging.
  @_inlineable // FIXME(sil-serialize-all)
  public var debugDescription: String {
    return "Range(\(String(reflecting: lowerBound))"
    + "..<\(String(reflecting: upperBound)))"
  }
}

extension Range : CustomReflectable {
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(
      self, children: ["lowerBound": lowerBound, "upperBound": upperBound])
  }
}

extension Range : Equatable {
  /// Returns a Boolean value indicating whether two ranges are equal.
  ///
  /// Two ranges are equal when they have the same lower and upper bounds.
  /// That requirement holds even for empty ranges.
  ///
  ///     let x: Range = 5..<15
  ///     print(x == 5..<15)
  ///     // Prints "true"
  ///
  ///     let y: Range = 5..<5
  ///     print(y == 15..<15)
  ///     // Prints "false"
  ///
  /// - Parameters:
  ///   - lhs: A range to compare.
  ///   - rhs: Another range to compare.
  @_inlineable
  public static func == (lhs: Range<Bound>, rhs: Range<Bound>) -> Bool {
    return
      lhs.lowerBound == rhs.lowerBound &&
      lhs.upperBound == rhs.upperBound
  }

  /// Returns a Boolean value indicating whether a value is included in a
  /// range.
  ///
  /// You can use this pattern matching operator (`~=`) to test whether a value
  /// is included in a range. The following example uses the `~=` operator to
  /// test whether an integer is included in a range of single-digit numbers.
  ///
  ///     let chosenNumber = 3
  ///     if 0..<10 ~= chosenNumber {
  ///         print("\(chosenNumber) is a single digit.")
  ///     }
  ///     // Prints "3 is a single digit."
  ///
  /// The `~=` operator is used internally in `case` statements for pattern
  /// matching. When you match against a range in a `case` statement, this
  /// operator is called behind the scenes.
  ///
  ///     switch chosenNumber {
  ///     case 0..<10:
  ///         print("\(chosenNumber) is a single digit.")
  ///     case Int.min..<0:
  ///         print("\(chosenNumber) is negative.")
  ///     default:
  ///         print("\(chosenNumber) is positive.")
  ///     }
  ///     // Prints "3 is a single digit."
  ///
  /// - Parameters:
  ///   - lhs: A range.
  ///   - rhs: A value to match against `lhs`.
  @_inlineable
  public static func ~= (pattern: Range<Bound>, value: Bound) -> Bool {
    return pattern.contains(value)
  }
}
extension CountableRange
{
  /// Creates an instance equivalent to the given range.

  ///
  /// - Parameter other: A range to convert to a `CountableRange` instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init(_ other: Range<Bound>) {
    let upperBound = other.upperBound
    self.init(
      uncheckedBounds: (lower: other.lowerBound, upper: upperBound)
    )
  }
}

extension CountableRange
{
  /// Returns a Boolean value indicating whether this range and the given range
  /// contain an element in common.
  ///
  /// This example shows two overlapping ranges:
  ///
  ///     let x: CountableRange = 0..<20
  ///     print(x.overlaps(10..<1000 as Range))
  ///     // Prints "true"
  ///
  /// Because a half-open range does not include its upper bound, the ranges
  /// in the following example do not overlap:
  ///
  ///     let y: Range = 20..<30
  ///     print(x.overlaps(y))
  ///     // Prints "false"
  ///
  /// - Parameter other: A range to check for elements in common.
  /// - Returns: `true` if this range and `other` have at least one element in
  ///   common; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func overlaps(_ other: Range<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(lowerBound))
  }
}
extension CountableRange
{
  /// Creates an instance equivalent to the given range.

  ///
  /// - Parameter other: A range to convert to a `CountableRange` instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init(_ other: CountableRange<Bound>) {
    let upperBound = other.upperBound
    self.init(
      uncheckedBounds: (lower: other.lowerBound, upper: upperBound)
    )
  }
}

extension CountableRange
{
  /// Returns a Boolean value indicating whether this range and the given range
  /// contain an element in common.
  ///
  /// This example shows two overlapping ranges:
  ///
  ///     let x: CountableRange = 0..<20
  ///     print(x.overlaps(10..<1000 as CountableRange))
  ///     // Prints "true"
  ///
  /// Because a half-open range does not include its upper bound, the ranges
  /// in the following example do not overlap:
  ///
  ///     let y: CountableRange = 20..<30
  ///     print(x.overlaps(y))
  ///     // Prints "false"
  ///
  /// - Parameter other: A range to check for elements in common.
  /// - Returns: `true` if this range and `other` have at least one element in
  ///   common; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func overlaps(_ other: CountableRange<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(lowerBound))
  }
}
extension CountableRange
{
  /// Creates an instance equivalent to the given range.
  ///
  /// An equivalent range must be representable as an instance of `CountableRange`.
  /// For example, passing a closed range with an upper bound of `Int.max`
  /// triggers a runtime error, because the resulting half-open range would
  /// require an upper bound of `Int.max + 1`, which is not representable as
  /// an `Int`.
  ///
  /// - Parameter other: A range to convert to a `CountableRange` instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init(_ other: ClosedRange<Bound>) {
    let upperBound = other.upperBound.advanced(by: 1)
    self.init(
      uncheckedBounds: (lower: other.lowerBound, upper: upperBound)
    )
  }
}

extension CountableRange
{
  /// Returns a Boolean value indicating whether this range and the given range
  /// contain an element in common.
  ///
  /// This example shows two overlapping ranges:
  ///
  ///     let x: CountableRange = 0..<20
  ///     print(x.overlaps(10...1000 as ClosedRange))
  ///     // Prints "true"
  ///
  /// Because a half-open range does not include its upper bound, the ranges
  /// in the following example do not overlap:
  ///
  ///     let y: ClosedRange = 20..<30
  ///     print(x.overlaps(y))
  ///     // Prints "false"
  ///
  /// - Parameter other: A range to check for elements in common.
  /// - Returns: `true` if this range and `other` have at least one element in
  ///   common; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func overlaps(_ other: ClosedRange<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(lowerBound))
  }
}
extension CountableRange
{
  /// Creates an instance equivalent to the given range.
  ///
  /// An equivalent range must be representable as an instance of `CountableRange`.
  /// For example, passing a closed range with an upper bound of `Int.max`
  /// triggers a runtime error, because the resulting half-open range would
  /// require an upper bound of `Int.max + 1`, which is not representable as
  /// an `Int`.
  ///
  /// - Parameter other: A range to convert to a `CountableRange` instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init(_ other: CountableClosedRange<Bound>) {
    let upperBound = other.upperBound.advanced(by: 1)
    self.init(
      uncheckedBounds: (lower: other.lowerBound, upper: upperBound)
    )
  }
}

extension CountableRange
{
  /// Returns a Boolean value indicating whether this range and the given range
  /// contain an element in common.
  ///
  /// This example shows two overlapping ranges:
  ///
  ///     let x: CountableRange = 0..<20
  ///     print(x.overlaps(10...1000 as CountableClosedRange))
  ///     // Prints "true"
  ///
  /// Because a half-open range does not include its upper bound, the ranges
  /// in the following example do not overlap:
  ///
  ///     let y: CountableClosedRange = 20..<30
  ///     print(x.overlaps(y))
  ///     // Prints "false"
  ///
  /// - Parameter other: A range to check for elements in common.
  /// - Returns: `true` if this range and `other` have at least one element in
  ///   common; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func overlaps(_ other: CountableClosedRange<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(lowerBound))
  }
}

extension CountableRange {
  /// Returns a copy of this range clamped to the given limiting range.
  ///
  /// The bounds of the result are always limited to the bounds of `limits`.
  /// For example:
  ///
  ///     let x: CountableRange = 0..<20
  ///     print(x.clamped(to: 10..<1000))
  ///     // Prints "10..<20"
  ///
  /// If the two ranges do not overlap, the result is an empty range within the
  /// bounds of `limits`.
  ///
  ///     let y: CountableRange = 0..<5
  ///     print(y.clamped(to: 10..<1000))
  ///     // Prints "10..<10"
  ///
  /// - Parameter limits: The range to clamp the bounds of this range.
  /// - Returns: A new range clamped to the bounds of `limits`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func clamped(to limits: CountableRange) -> CountableRange {
    return CountableRange(
      uncheckedBounds: (
        lower:
        limits.lowerBound > self.lowerBound ? limits.lowerBound
          : limits.upperBound < self.lowerBound ? limits.upperBound
          : self.lowerBound,
        upper:
          limits.upperBound < self.upperBound ? limits.upperBound
          : limits.lowerBound > self.upperBound ? limits.lowerBound
          : self.upperBound
      )
    )
  }
}

extension CountableRange: RangeExpression {
  @_inlineable // FIXME(sil-serialize-all)
  public func relative<C: Collection>(to collection: C) -> Range<Bound>
  where C.Index == Bound {
    return Range(uncheckedBounds: (lower: lowerBound, upper: upperBound))
  }
}

extension CountableRange : CustomStringConvertible {
  /// A textual representation of the range.
  @_inlineable // FIXME(sil-serialize-all)
  public var description: String {
    return "\(lowerBound)..<\(upperBound)"
  }
}

extension CountableRange : CustomDebugStringConvertible {
  /// A textual representation of the range, suitable for debugging.
  @_inlineable // FIXME(sil-serialize-all)
  public var debugDescription: String {
    return "CountableRange(\(String(reflecting: lowerBound))"
    + "..<\(String(reflecting: upperBound)))"
  }
}

extension CountableRange : CustomReflectable {
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(
      self, children: ["lowerBound": lowerBound, "upperBound": upperBound])
  }
}

extension CountableRange : Equatable {
  /// Returns a Boolean value indicating whether two ranges are equal.
  ///
  /// Two ranges are equal when they have the same lower and upper bounds.
  /// That requirement holds even for empty ranges.
  ///
  ///     let x: CountableRange = 5..<15
  ///     print(x == 5..<15)
  ///     // Prints "true"
  ///
  ///     let y: CountableRange = 5..<5
  ///     print(y == 15..<15)
  ///     // Prints "false"
  ///
  /// - Parameters:
  ///   - lhs: A range to compare.
  ///   - rhs: Another range to compare.
  @_inlineable
  public static func == (lhs: CountableRange<Bound>, rhs: CountableRange<Bound>) -> Bool {
    return
      lhs.lowerBound == rhs.lowerBound &&
      lhs.upperBound == rhs.upperBound
  }

  /// Returns a Boolean value indicating whether a value is included in a
  /// range.
  ///
  /// You can use this pattern matching operator (`~=`) to test whether a value
  /// is included in a range. The following example uses the `~=` operator to
  /// test whether an integer is included in a range of single-digit numbers.
  ///
  ///     let chosenNumber = 3
  ///     if 0..<10 ~= chosenNumber {
  ///         print("\(chosenNumber) is a single digit.")
  ///     }
  ///     // Prints "3 is a single digit."
  ///
  /// The `~=` operator is used internally in `case` statements for pattern
  /// matching. When you match against a range in a `case` statement, this
  /// operator is called behind the scenes.
  ///
  ///     switch chosenNumber {
  ///     case 0..<10:
  ///         print("\(chosenNumber) is a single digit.")
  ///     case Int.min..<0:
  ///         print("\(chosenNumber) is negative.")
  ///     default:
  ///         print("\(chosenNumber) is positive.")
  ///     }
  ///     // Prints "3 is a single digit."
  ///
  /// - Parameters:
  ///   - lhs: A range.
  ///   - rhs: A value to match against `lhs`.
  @_inlineable
  public static func ~= (pattern: CountableRange<Bound>, value: Bound) -> Bool {
    return pattern.contains(value)
  }
}
extension ClosedRange
  where
  Bound : Strideable, Bound.Stride : SignedInteger
{
  /// Creates an instance equivalent to the given range.
  ///
  /// An equivalent range must be representable as an instance of `ClosedRange`.
  /// For example, passing an empty range as `other` triggers a runtime error,
  /// because an empty range cannot be represented by a `ClosedRange` instance.
  ///
  /// - Parameter other: A range to convert to a `ClosedRange` instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init(_ other: Range<Bound>) {
    _precondition(!other.isEmpty, "Can't form an empty closed range")
    let upperBound = other.upperBound.advanced(by: -1)
    self.init(
      uncheckedBounds: (lower: other.lowerBound, upper: upperBound)
    )
  }
}

extension ClosedRange
{
  /// Returns a Boolean value indicating whether this range and the given range
  /// contain an element in common.
  ///
  /// This example shows two overlapping ranges:
  ///
  ///     let x: ClosedRange = 0...20
  ///     print(x.overlaps(10..<1000 as Range))
  ///     // Prints "true"
  ///
  /// Because a closed range includes its upper bound, the ranges in the
  /// following example also overlap:
  ///
  ///     let y: Range = 20...30
  ///     print(x.overlaps(y))
  ///     // Prints "true"
  ///
  /// - Parameter other: A range to check for elements in common.
  /// - Returns: `true` if this range and `other` have at least one element in
  ///   common; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func overlaps(_ other: Range<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(lowerBound))
  }
}
extension ClosedRange
  where
  Bound : Strideable, Bound.Stride : SignedInteger
{
  /// Creates an instance equivalent to the given range.
  ///
  /// An equivalent range must be representable as an instance of `ClosedRange`.
  /// For example, passing an empty range as `other` triggers a runtime error,
  /// because an empty range cannot be represented by a `ClosedRange` instance.
  ///
  /// - Parameter other: A range to convert to a `ClosedRange` instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init(_ other: CountableRange<Bound>) {
    _precondition(!other.isEmpty, "Can't form an empty closed range")
    let upperBound = other.upperBound.advanced(by: -1)
    self.init(
      uncheckedBounds: (lower: other.lowerBound, upper: upperBound)
    )
  }
}

extension ClosedRange
  where
  Bound : Strideable, Bound.Stride : SignedInteger
{
  /// Returns a Boolean value indicating whether this range and the given range
  /// contain an element in common.
  ///
  /// This example shows two overlapping ranges:
  ///
  ///     let x: ClosedRange = 0...20
  ///     print(x.overlaps(10..<1000 as CountableRange))
  ///     // Prints "true"
  ///
  /// Because a closed range includes its upper bound, the ranges in the
  /// following example also overlap:
  ///
  ///     let y: CountableRange = 20...30
  ///     print(x.overlaps(y))
  ///     // Prints "true"
  ///
  /// - Parameter other: A range to check for elements in common.
  /// - Returns: `true` if this range and `other` have at least one element in
  ///   common; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func overlaps(_ other: CountableRange<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(lowerBound))
  }
}
extension ClosedRange
  where
  Bound : Strideable, Bound.Stride : SignedInteger
{
  /// Creates an instance equivalent to the given range.

  ///
  /// - Parameter other: A range to convert to a `ClosedRange` instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init(_ other: ClosedRange<Bound>) {
    let upperBound = other.upperBound
    self.init(
      uncheckedBounds: (lower: other.lowerBound, upper: upperBound)
    )
  }
}

extension ClosedRange
{
  /// Returns a Boolean value indicating whether this range and the given range
  /// contain an element in common.
  ///
  /// This example shows two overlapping ranges:
  ///
  ///     let x: ClosedRange = 0...20
  ///     print(x.overlaps(10...1000 as ClosedRange))
  ///     // Prints "true"
  ///
  /// Because a closed range includes its upper bound, the ranges in the
  /// following example also overlap:
  ///
  ///     let y: ClosedRange = 20...30
  ///     print(x.overlaps(y))
  ///     // Prints "true"
  ///
  /// - Parameter other: A range to check for elements in common.
  /// - Returns: `true` if this range and `other` have at least one element in
  ///   common; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func overlaps(_ other: ClosedRange<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(lowerBound))
  }
}
extension ClosedRange
  where
  Bound : Strideable, Bound.Stride : SignedInteger
{
  /// Creates an instance equivalent to the given range.

  ///
  /// - Parameter other: A range to convert to a `ClosedRange` instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init(_ other: CountableClosedRange<Bound>) {
    let upperBound = other.upperBound
    self.init(
      uncheckedBounds: (lower: other.lowerBound, upper: upperBound)
    )
  }
}

extension ClosedRange
  where
  Bound : Strideable, Bound.Stride : SignedInteger
{
  /// Returns a Boolean value indicating whether this range and the given range
  /// contain an element in common.
  ///
  /// This example shows two overlapping ranges:
  ///
  ///     let x: ClosedRange = 0...20
  ///     print(x.overlaps(10...1000 as CountableClosedRange))
  ///     // Prints "true"
  ///
  /// Because a closed range includes its upper bound, the ranges in the
  /// following example also overlap:
  ///
  ///     let y: CountableClosedRange = 20...30
  ///     print(x.overlaps(y))
  ///     // Prints "true"
  ///
  /// - Parameter other: A range to check for elements in common.
  /// - Returns: `true` if this range and `other` have at least one element in
  ///   common; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func overlaps(_ other: CountableClosedRange<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(lowerBound))
  }
}

extension ClosedRange {
  /// Returns a copy of this range clamped to the given limiting range.
  ///
  /// The bounds of the result are always limited to the bounds of `limits`.
  /// For example:
  ///
  ///     let x: ClosedRange = 0...20
  ///     print(x.clamped(to: 10...1000))
  ///     // Prints "10...20"
  ///
  /// If the two ranges do not overlap, the result is a single-element range at
  /// the upper or lower bound of `limits`.
  ///
  ///     let y: ClosedRange = 0...5
  ///     print(y.clamped(to: 10...1000))
  ///     // Prints "10...10"
  ///
  /// - Parameter limits: The range to clamp the bounds of this range.
  /// - Returns: A new range clamped to the bounds of `limits`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func clamped(to limits: ClosedRange) -> ClosedRange {
    return ClosedRange(
      uncheckedBounds: (
        lower:
        limits.lowerBound > self.lowerBound ? limits.lowerBound
          : limits.upperBound < self.lowerBound ? limits.upperBound
          : self.lowerBound,
        upper:
          limits.upperBound < self.upperBound ? limits.upperBound
          : limits.lowerBound > self.upperBound ? limits.lowerBound
          : self.upperBound
      )
    )
  }
}

extension ClosedRange: RangeExpression {
  @_inlineable // FIXME(sil-serialize-all)
  public func relative<C: Collection>(to collection: C) -> Range<Bound>
  where C.Index == Bound {
    return Range(
      uncheckedBounds: (
        lower: lowerBound, upper: collection.index(after: self.upperBound)))
  }
}

extension ClosedRange : CustomStringConvertible {
  /// A textual representation of the range.
  @_inlineable // FIXME(sil-serialize-all)
  public var description: String {
    return "\(lowerBound)...\(upperBound)"
  }
}

extension ClosedRange : CustomDebugStringConvertible {
  /// A textual representation of the range, suitable for debugging.
  @_inlineable // FIXME(sil-serialize-all)
  public var debugDescription: String {
    return "ClosedRange(\(String(reflecting: lowerBound))"
    + "...\(String(reflecting: upperBound)))"
  }
}

extension ClosedRange : CustomReflectable {
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(
      self, children: ["lowerBound": lowerBound, "upperBound": upperBound])
  }
}

extension ClosedRange : Equatable {
  /// Returns a Boolean value indicating whether two ranges are equal.
  ///
  /// Two ranges are equal when they have the same lower and upper bounds.
  ///
  ///     let x: ClosedRange = 5...15
  ///     print(x == 5...15)
  ///     // Prints "true"
  ///     print(x == 10...20)
  ///     // Prints "false"
  ///
  /// - Parameters:
  ///   - lhs: A range to compare.
  ///   - rhs: Another range to compare.
  @_inlineable
  public static func == (lhs: ClosedRange<Bound>, rhs: ClosedRange<Bound>) -> Bool {
    return
      lhs.lowerBound == rhs.lowerBound &&
      lhs.upperBound == rhs.upperBound
  }

  /// Returns a Boolean value indicating whether a value is included in a
  /// range.
  ///
  /// You can use this pattern matching operator (`~=`) to test whether a value
  /// is included in a range. The following example uses the `~=` operator to
  /// test whether an integer is included in a range of single-digit numbers.
  ///
  ///     let chosenNumber = 3
  ///     if 0...9 ~= chosenNumber {
  ///         print("\(chosenNumber) is a single digit.")
  ///     }
  ///     // Prints "3 is a single digit."
  ///
  /// The `~=` operator is used internally in `case` statements for pattern
  /// matching. When you match against a range in a `case` statement, this
  /// operator is called behind the scenes.
  ///
  ///     switch chosenNumber {
  ///     case 0...9:
  ///         print("\(chosenNumber) is a single digit.")
  ///     case Int.min..<0:
  ///         print("\(chosenNumber) is negative.")
  ///     default:
  ///         print("\(chosenNumber) is positive.")
  ///     }
  ///     // Prints "3 is a single digit."
  ///
  /// - Parameters:
  ///   - lhs: A range.
  ///   - rhs: A value to match against `lhs`.
  @_inlineable
  public static func ~= (pattern: ClosedRange<Bound>, value: Bound) -> Bool {
    return pattern.contains(value)
  }
}
extension CountableClosedRange
{
  /// Creates an instance equivalent to the given range.
  ///
  /// An equivalent range must be representable as an instance of `CountableClosedRange`.
  /// For example, passing an empty range as `other` triggers a runtime error,
  /// because an empty range cannot be represented by a `CountableClosedRange` instance.
  ///
  /// - Parameter other: A range to convert to a `CountableClosedRange` instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init(_ other: Range<Bound>) {
    _precondition(!other.isEmpty, "Can't form an empty closed range")
    let upperBound = other.upperBound.advanced(by: -1)
    self.init(
      uncheckedBounds: (lower: other.lowerBound, upper: upperBound)
    )
  }
}

extension CountableClosedRange
{
  /// Returns a Boolean value indicating whether this range and the given range
  /// contain an element in common.
  ///
  /// This example shows two overlapping ranges:
  ///
  ///     let x: CountableClosedRange = 0...20
  ///     print(x.overlaps(10..<1000 as Range))
  ///     // Prints "true"
  ///
  /// Because a closed range includes its upper bound, the ranges in the
  /// following example also overlap:
  ///
  ///     let y: Range = 20...30
  ///     print(x.overlaps(y))
  ///     // Prints "true"
  ///
  /// - Parameter other: A range to check for elements in common.
  /// - Returns: `true` if this range and `other` have at least one element in
  ///   common; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func overlaps(_ other: Range<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(lowerBound))
  }
}
extension CountableClosedRange
{
  /// Creates an instance equivalent to the given range.
  ///
  /// An equivalent range must be representable as an instance of `CountableClosedRange`.
  /// For example, passing an empty range as `other` triggers a runtime error,
  /// because an empty range cannot be represented by a `CountableClosedRange` instance.
  ///
  /// - Parameter other: A range to convert to a `CountableClosedRange` instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init(_ other: CountableRange<Bound>) {
    _precondition(!other.isEmpty, "Can't form an empty closed range")
    let upperBound = other.upperBound.advanced(by: -1)
    self.init(
      uncheckedBounds: (lower: other.lowerBound, upper: upperBound)
    )
  }
}

extension CountableClosedRange
{
  /// Returns a Boolean value indicating whether this range and the given range
  /// contain an element in common.
  ///
  /// This example shows two overlapping ranges:
  ///
  ///     let x: CountableClosedRange = 0...20
  ///     print(x.overlaps(10..<1000 as CountableRange))
  ///     // Prints "true"
  ///
  /// Because a closed range includes its upper bound, the ranges in the
  /// following example also overlap:
  ///
  ///     let y: CountableRange = 20...30
  ///     print(x.overlaps(y))
  ///     // Prints "true"
  ///
  /// - Parameter other: A range to check for elements in common.
  /// - Returns: `true` if this range and `other` have at least one element in
  ///   common; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func overlaps(_ other: CountableRange<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(lowerBound))
  }
}
extension CountableClosedRange
{
  /// Creates an instance equivalent to the given range.

  ///
  /// - Parameter other: A range to convert to a `CountableClosedRange` instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init(_ other: ClosedRange<Bound>) {
    let upperBound = other.upperBound
    self.init(
      uncheckedBounds: (lower: other.lowerBound, upper: upperBound)
    )
  }
}

extension CountableClosedRange
{
  /// Returns a Boolean value indicating whether this range and the given range
  /// contain an element in common.
  ///
  /// This example shows two overlapping ranges:
  ///
  ///     let x: CountableClosedRange = 0...20
  ///     print(x.overlaps(10...1000 as ClosedRange))
  ///     // Prints "true"
  ///
  /// Because a closed range includes its upper bound, the ranges in the
  /// following example also overlap:
  ///
  ///     let y: ClosedRange = 20...30
  ///     print(x.overlaps(y))
  ///     // Prints "true"
  ///
  /// - Parameter other: A range to check for elements in common.
  /// - Returns: `true` if this range and `other` have at least one element in
  ///   common; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func overlaps(_ other: ClosedRange<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(lowerBound))
  }
}
extension CountableClosedRange
{
  /// Creates an instance equivalent to the given range.

  ///
  /// - Parameter other: A range to convert to a `CountableClosedRange` instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init(_ other: CountableClosedRange<Bound>) {
    let upperBound = other.upperBound
    self.init(
      uncheckedBounds: (lower: other.lowerBound, upper: upperBound)
    )
  }
}

extension CountableClosedRange
{
  /// Returns a Boolean value indicating whether this range and the given range
  /// contain an element in common.
  ///
  /// This example shows two overlapping ranges:
  ///
  ///     let x: CountableClosedRange = 0...20
  ///     print(x.overlaps(10...1000 as CountableClosedRange))
  ///     // Prints "true"
  ///
  /// Because a closed range includes its upper bound, the ranges in the
  /// following example also overlap:
  ///
  ///     let y: CountableClosedRange = 20...30
  ///     print(x.overlaps(y))
  ///     // Prints "true"
  ///
  /// - Parameter other: A range to check for elements in common.
  /// - Returns: `true` if this range and `other` have at least one element in
  ///   common; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func overlaps(_ other: CountableClosedRange<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(lowerBound))
  }
}

extension CountableClosedRange {
  /// Returns a copy of this range clamped to the given limiting range.
  ///
  /// The bounds of the result are always limited to the bounds of `limits`.
  /// For example:
  ///
  ///     let x: CountableClosedRange = 0...20
  ///     print(x.clamped(to: 10...1000))
  ///     // Prints "10...20"
  ///
  /// If the two ranges do not overlap, the result is a single-element range at
  /// the upper or lower bound of `limits`.
  ///
  ///     let y: CountableClosedRange = 0...5
  ///     print(y.clamped(to: 10...1000))
  ///     // Prints "10...10"
  ///
  /// - Parameter limits: The range to clamp the bounds of this range.
  /// - Returns: A new range clamped to the bounds of `limits`.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public func clamped(to limits: CountableClosedRange) -> CountableClosedRange {
    return CountableClosedRange(
      uncheckedBounds: (
        lower:
        limits.lowerBound > self.lowerBound ? limits.lowerBound
          : limits.upperBound < self.lowerBound ? limits.upperBound
          : self.lowerBound,
        upper:
          limits.upperBound < self.upperBound ? limits.upperBound
          : limits.lowerBound > self.upperBound ? limits.lowerBound
          : self.upperBound
      )
    )
  }
}

extension CountableClosedRange: RangeExpression {
  @_inlineable // FIXME(sil-serialize-all)
  public func relative<C: Collection>(to collection: C) -> Range<Bound>
  where C.Index == Bound {
    return Range(
      uncheckedBounds: (
        lower: lowerBound, upper: collection.index(after: self.upperBound)))
  }
}

extension CountableClosedRange : CustomStringConvertible {
  /// A textual representation of the range.
  @_inlineable // FIXME(sil-serialize-all)
  public var description: String {
    return "\(lowerBound)...\(upperBound)"
  }
}

extension CountableClosedRange : CustomDebugStringConvertible {
  /// A textual representation of the range, suitable for debugging.
  @_inlineable // FIXME(sil-serialize-all)
  public var debugDescription: String {
    return "CountableClosedRange(\(String(reflecting: lowerBound))"
    + "...\(String(reflecting: upperBound)))"
  }
}

extension CountableClosedRange : CustomReflectable {
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(
      self, children: ["lowerBound": lowerBound, "upperBound": upperBound])
  }
}

extension CountableClosedRange : Equatable {
  /// Returns a Boolean value indicating whether two ranges are equal.
  ///
  /// Two ranges are equal when they have the same lower and upper bounds.
  ///
  ///     let x: CountableClosedRange = 5...15
  ///     print(x == 5...15)
  ///     // Prints "true"
  ///     print(x == 10...20)
  ///     // Prints "false"
  ///
  /// - Parameters:
  ///   - lhs: A range to compare.
  ///   - rhs: Another range to compare.
  @_inlineable
  public static func == (lhs: CountableClosedRange<Bound>, rhs: CountableClosedRange<Bound>) -> Bool {
    return
      lhs.lowerBound == rhs.lowerBound &&
      lhs.upperBound == rhs.upperBound
  }

  /// Returns a Boolean value indicating whether a value is included in a
  /// range.
  ///
  /// You can use this pattern matching operator (`~=`) to test whether a value
  /// is included in a range. The following example uses the `~=` operator to
  /// test whether an integer is included in a range of single-digit numbers.
  ///
  ///     let chosenNumber = 3
  ///     if 0...9 ~= chosenNumber {
  ///         print("\(chosenNumber) is a single digit.")
  ///     }
  ///     // Prints "3 is a single digit."
  ///
  /// The `~=` operator is used internally in `case` statements for pattern
  /// matching. When you match against a range in a `case` statement, this
  /// operator is called behind the scenes.
  ///
  ///     switch chosenNumber {
  ///     case 0...9:
  ///         print("\(chosenNumber) is a single digit.")
  ///     case Int.min..<0:
  ///         print("\(chosenNumber) is negative.")
  ///     default:
  ///         print("\(chosenNumber) is positive.")
  ///     }
  ///     // Prints "3 is a single digit."
  ///
  /// - Parameters:
  ///   - lhs: A range.
  ///   - rhs: A value to match against `lhs`.
  @_inlineable
  public static func ~= (pattern: CountableClosedRange<Bound>, value: Bound) -> Bool {
    return pattern.contains(value)
  }
}

// FIXME(ABI)#57 (Conditional Conformance): replace this extension with a
// conditional conformance.
// rdar://problem/17144340
/// Ranges whose `Bound` is `Strideable` with `Integer` `Stride` have all
/// the capabilities of `RandomAccessCollection`s, just like
/// `CountableRange` and `CountableClosedRange`.
///
/// Unfortunately, we can't forward the full collection API, so we are
/// forwarding a few select APIs.
extension Range where Bound : Strideable, Bound.Stride : SignedInteger {
  /// The number of values contained in the range.
  @_inlineable
  public var count: Bound.Stride {
    let distance = lowerBound.distance(to: upperBound)
    return distance
  }
}
// FIXME(ABI)#57 (Conditional Conformance): replace this extension with a
// conditional conformance.
// rdar://problem/17144340
/// Ranges whose `Bound` is `Strideable` with `Integer` `Stride` have all
/// the capabilities of `RandomAccessCollection`s, just like
/// `CountableRange` and `CountableClosedRange`.
///
/// Unfortunately, we can't forward the full collection API, so we are
/// forwarding a few select APIs.
extension ClosedRange where Bound : Strideable, Bound.Stride : SignedInteger {
  /// The number of values contained in the range.
  @_inlineable
  public var count: Bound.Stride {
    let distance = lowerBound.distance(to: upperBound)
    return distance + 1
  }
}

/// A partial half-open interval up to, but not including, an upper bound.
///
/// You create `PartialRangeUpTo` instances by using the prefix half-open range
/// operator (prefix `..<`).
///
///     let upToFive = ..<5.0
///
/// You can use a `PartialRangeUpTo` instance to quickly check if a value is
/// contained in a particular range of values. For example:
///
///     upToFive.contains(3.14)       // true
///     upToFive.contains(6.28)       // false
///     upToFive.contains(5.0)        // false
///
/// You can use a `PartialRangeUpTo` instance of a collection's indices to
/// represent the range from the start of the collection up to, but not
/// including, the partial range's upper bound.
///
///     let numbers = [10, 20, 30, 40, 50, 60, 70]
///     print(numbers[..<3])
///     // Prints "[10, 20, 30]"
@_fixed_layout
public struct PartialRangeUpTo<Bound: Comparable> {
  public let upperBound: Bound
  
  @_inlineable // FIXME(sil-serialize-all)
  public init(_ upperBound: Bound) { self.upperBound = upperBound }
}

extension PartialRangeUpTo: RangeExpression {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func relative<C: Collection>(to collection: C) -> Range<Bound>
  where C.Index == Bound {
    return collection.startIndex..<self.upperBound
  }
  
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func contains(_ element: Bound) -> Bool {
    return element < upperBound
  }
}

/// A partial half-open interval up to, and including, an upper bound.
///
/// You create `PartialRangeThrough` instances by using the prefix closed range
/// operator (prefix `...`).
///
///     let throughFive = ...5.0
///
/// You can use a `PartialRangeThrough` instance to quickly check if a value is
/// contained in a particular range of values. For example:
///
///     throughFive.contains(4.0)     // true
///     throughFive.contains(5.0)     // true
///     throughFive.contains(6.0)     // false
///
/// You can use a `PartialRangeThrough` instance of a collection's indices to
/// represent the range from the start of the collection up to, and including,
/// the partial range's upper bound.
///
///     let numbers = [10, 20, 30, 40, 50, 60, 70]
///     print(numbers[...3])
///     // Prints "[10, 20, 30, 40]"
@_fixed_layout
public struct PartialRangeThrough<Bound: Comparable> {  
  public let upperBound: Bound
  
  @_inlineable // FIXME(sil-serialize-all)
  public init(_ upperBound: Bound) { self.upperBound = upperBound }
}

extension PartialRangeThrough: RangeExpression {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func relative<C: Collection>(to collection: C) -> Range<Bound>
  where C.Index == Bound {
    return collection.startIndex..<collection.index(after: self.upperBound)
  }
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func contains(_ element: Bound) -> Bool {
    return element <= upperBound
  }
}

/// A partial interval extending upward from a lower bound.
///
/// You create `PartialRangeFrom` instances by using the postfix range
/// operator (postfix `...`).
///
///     let atLeastFive = 5.0...
///
/// You can use a `PartialRangeFrom` instance to quickly check if a value is
/// contained in a particular range of values. For example:
///
///     atLeastFive.contains(4.0)     // false
///     atLeastFive.contains(5.0)     // true
///     atLeastFive.contains(6.0)     // true
///
/// You can use a `PartialRangeFrom` instance of a collection's indices to
/// represent the range from the partial range's lower bound up to the end
/// of the collection.
///
///     let numbers = [10, 20, 30, 40, 50, 60, 70]
///     print(numbers[3...])
///     // Prints "[40, 50, 60, 70]"
@_fixed_layout
public struct PartialRangeFrom<Bound: Comparable> {
  public let lowerBound: Bound

  @_inlineable // FIXME(sil-serialize-all)
  public init(_ lowerBound: Bound) { self.lowerBound = lowerBound }
}

extension PartialRangeFrom: RangeExpression {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func relative<C: Collection>(to collection: C) -> Range<Bound>
  where C.Index == Bound {
    return self.lowerBound..<collection.endIndex
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func contains(_ element: Bound) -> Bool {
    return lowerBound <= element
  }
}

/// A partial interval extending upward from a lower bound that forms a
/// sequence of increasing values.
///
/// You create `CountablePartialRangeFrom` instances by using the postfix range
/// operator (postfix `...`).
///
///     let atLeastFive = 5...
///
/// You can use a countable partial range to quickly check if a value is
/// contained in a particular range of values. For example:
///
///     atLeastFive.contains(4)     // false
///     atLeastFive.contains(5)     // true
///     atLeastFive.contains(6)     // true
///
/// You can use a countable partial range of a collection's indices to
/// represent the range from the partial range's lower bound up to the end of
/// the collection.
///
///     let numbers = [10, 20, 30, 40, 50, 60, 70]
///     print(numbers[3...])
///     // Prints "[40, 50, 60, 70]"
///
/// You can create a countable partial range over any type that conforms to the
/// `Strideable` protocol and uses an integer as its associated `Stride` type.
/// By default, Swift's integer and pointer types are usable as the bounds of
/// a countable range.
///
/// Using a Partial Range as a Sequence
/// ===================================
///
/// You can iterate over a countable partial range using a `for`-`in` loop, or
/// call any sequence method that doesn't require that the sequence is finite.
///
///     func isTheMagicNumber(_ x: Int) -> Bool {
///         return x == 3
///     }
///
///     for x in 1... {
///         if isTheMagicNumber(x) {
///             print("\(x) is the magic number!")
///             break
///         } else {
///             print("\(x) wasn't it...")
///         }
///     }
///     // "1 wasn't it..."
///     // "2 wasn't it..."
///     // "3 is the magic number!"
///
/// Because a `CountablePartialRangeFrom` sequence counts upward indefinitely,
/// do not use one with methods that read the entire sequence before
/// returning, such as `map(_:)`, `filter(_:)`, or `suffix(_:)`. It is safe to
/// use operations that put an upper limit on the number of elements they
/// access, such as `prefix(_:)` or `dropFirst(_:)`, and operations that you
/// can guarantee will terminate, such as passing a closure you know will
/// eventually return `true` to `first(where:)`.
///
/// In the following example, the `asciiTable` sequence is made by zipping
/// together the characters in the `alphabet` string with a partial range
/// starting at 65, the ASCII value of the capital letter A. Iterating over
/// two zipped sequences continues only as long as the shorter of the two
/// sequences, so the iteration stops at the end of `alphabet`.
///
///     let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
///     let asciiTable = zip(65..., alphabet)
///     for (code, letter) in asciiTable {
///         print(code, letter)
///     }
///     // "65 A"
///     // "66 B"
///     // "67 C"
///     // ...
///     // "89 Y"
///     // "90 Z"
///
/// The behavior of incrementing indefinitely is determined by the type of
/// `Bound`. For example, iterating over an instance of
/// `CountablePartialRangeFrom<Int>` traps when the sequence's next value
/// would be above `Int.max`.
@_fixed_layout
public struct CountablePartialRangeFrom<Bound: Strideable>
where Bound.Stride : SignedInteger  {
  public let lowerBound: Bound

  @_inlineable // FIXME(sil-serialize-all)
  public init(_ lowerBound: Bound) { self.lowerBound = lowerBound }
}

extension CountablePartialRangeFrom: RangeExpression {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func relative<C: Collection>(
    to collection: C
  ) -> Range<Bound> where C.Index == Bound {
    return self.lowerBound..<collection.endIndex
  }
  @_inlineable // FIXME(sil-serialize-all)
  public func contains(_ element: Bound) -> Bool {
    return lowerBound <= element
  }
}

extension CountablePartialRangeFrom: Sequence {
  @_fixed_layout
  public struct Iterator: IteratorProtocol {
    @_versioned
    internal var _current: Bound
    @_inlineable
    public init(_current: Bound) { self._current = _current }
    @_inlineable
    public mutating func next() -> Bound? {
      defer { _current = _current.advanced(by: 1) }
      return _current
    }
  }
  @_inlineable
  public func makeIterator() -> Iterator { 
    return Iterator(_current: lowerBound) 
  }
}

extension Comparable {
  /// Returns a half-open range that contains its lower bound but not its upper
  /// bound.
  ///
  /// Use the half-open range operator (`..<`) to create a range of any type that
  /// conforms to the `Comparable` protocol. This example creates a
  /// `Range<Double>` from zero up to, but not including, 5.0.
  ///
  ///     let lessThanFive = 0.0..<5.0
  ///     print(lessThanFive.contains(3.14))  // Prints "true"
  ///     print(lessThanFive.contains(5.0))   // Prints "false"
  ///
  /// - Parameters:
  ///   - minimum: The lower bound for the range.
  ///   - maximum: The upper bound for the range.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func ..< (minimum: Self, maximum: Self) -> Range<Self> {
    _precondition(minimum <= maximum,
      "Can't form Range with upperBound < lowerBound")
    return Range(uncheckedBounds: (lower: minimum, upper: maximum))
  }

  /// Returns a partial range up to, but not including, its upper bound.
  ///
  /// Use the prefix half-open range operator (prefix `..<`) to create a
  /// partial range of any type that conforms to the `Comparable` protocol.
  /// This example creates a `PartialRangeUpTo<Double>` instance that includes
  /// any value less than `5.0`.
  ///
  ///     let upToFive = ..<5.0
  ///
  ///     upToFive.contains(3.14)       // true
  ///     upToFive.contains(6.28)       // false
  ///     upToFive.contains(5.0)        // false
  ///
  /// You can use this type of partial range of a collection's indices to
  /// represent the range from the start of the collection up to, but not
  /// including, the partial range's upper bound.
  ///
  ///     let numbers = [10, 20, 30, 40, 50, 60, 70]
  ///     print(numbers[..<3])
  ///     // Prints "[10, 20, 30]"
  ///
  /// - Parameter maximum: The upper bound for the range.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static prefix func ..< (maximum: Self) -> PartialRangeUpTo<Self> {
    return PartialRangeUpTo(maximum)
  }

  /// Returns a partial range up to, and including, its upper bound.
  ///
  /// Use the prefix closed range operator (prefix `...`) to create a partial
  /// range of any type that conforms to the `Comparable` protocol. This
  /// example creates a `PartialRangeThrough<Double>` instance that includes
  /// any value less than or equal to `5.0`.
  ///
  ///     let throughFive = ...5.0
  ///
  ///     throughFive.contains(4.0)     // true
  ///     throughFive.contains(5.0)     // true
  ///     throughFive.contains(6.0)     // false
  ///
  /// You can use this type of partial range of a collection's indices to
  /// represent the range from the start of the collection up to, and
  /// including, the partial range's upper bound.
  ///
  ///     let numbers = [10, 20, 30, 40, 50, 60, 70]
  ///     print(numbers[...3])
  ///     // Prints "[10, 20, 30, 40]"
  ///
  /// - Parameter maximum: The upper bound for the range.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static prefix func ... (maximum: Self) -> PartialRangeThrough<Self> {
    return PartialRangeThrough(maximum)
  }

  /// Returns a partial range extending upward from a lower bound.
  ///
  /// Use the postfix range operator (postfix `...`) to create a partial range
  /// of any type that conforms to the `Comparable` protocol. This example
  /// creates a `PartialRangeFrom<Double>` instance that includes any value
  /// greater than or equal to `5.0`.
  ///
  ///     let atLeastFive = 5.0...
  ///
  ///     atLeastFive.contains(4.0)     // false
  ///     atLeastFive.contains(5.0)     // true
  ///     atLeastFive.contains(6.0)     // true
  ///
  /// You can use this type of partial range of a collection's indices to
  /// represent the range from the partial range's lower bound up to the end
  /// of the collection.
  ///
  ///     let numbers = [10, 20, 30, 40, 50, 60, 70]
  ///     print(numbers[3...])
  ///     // Prints "[40, 50, 60, 70]"
  ///
  /// - Parameter minimum: The lower bound for the range.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static postfix func ... (minimum: Self) -> PartialRangeFrom<Self> {
    return PartialRangeFrom(minimum)
  }
}

extension Strideable where Stride: SignedInteger {
  /// Returns a countable half-open range that contains its lower bound but not
  /// its upper bound.
  ///
  /// Use the half-open range operator (`..<`) to create a range of any type that
  /// conforms to the `Strideable` protocol with an associated integer `Stride`
  /// type, such as any of the standard library's integer types. This example
  /// creates a `CountableRange<Int>` from zero up to, but not including, 5.
  ///
  ///     let upToFive = 0..<5
  ///     print(upToFive.contains(3))         // Prints "true"
  ///     print(upToFive.contains(5))         // Prints "false"
  ///
  /// You can use sequence or collection methods on the `upToFive` countable
  /// range.
  ///
  ///     print(upToFive.count)               // Prints "5"
  ///     print(upToFive.last)                // Prints "4"
  ///
  /// - Parameters:
  ///   - minimum: The lower bound for the range.
  ///   - maximum: The upper bound for the range.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func ..< (minimum: Self, maximum: Self) -> CountableRange<Self> {
    // FIXME: swift-3-indexing-model: tests for traps.
    _precondition(minimum <= maximum,
      "Can't form Range with upperBound < lowerBound")
    return CountableRange(uncheckedBounds: (lower: minimum, upper: maximum))
  }

  /// Returns a countable partial range extending upward from a lower bound.
  ///
  /// Use the postfix range operator (postfix `...`) to create a partial range
  /// of any type that conforms to the `Strideable` protocol with an
  /// associated integer `Stride` type, such as any of the standard library's
  /// integer types. This example creates a `CountablePartialRangeFrom<Int>`
  /// instance that includes any value greater than or equal to `5`.
  ///
  ///     let atLeastFive = 5...
  ///
  ///     atLeastFive.contains(4)       // false
  ///     atLeastFive.contains(5)       // true
  ///     atLeastFive.contains(6)       // true
  ///
  /// You can use this type of partial range of a collection's indices to
  /// represent the range from the partial range's lower bound up to the end
  /// of the collection.
  ///
  ///     let numbers = [10, 20, 30, 40, 50, 60, 70]
  ///     print(numbers[3...])
  ///     // Prints "[40, 50, 60, 70]"
  ///
  /// You can also iterate over this type of partial range using a `for`-`in`
  /// loop, or call any sequence method that doesn't require that the sequence
  /// is finite.
  ///
  ///     func isTheMagicNumber(_ x: Int) -> Bool {
  ///         return x == 3
  ///     }
  ///
  ///     for x in 1... {
  ///         if isTheMagicNumber(x) {
  ///             print("\(x) is the magic number!")
  ///             break
  ///         } else {
  ///             print("\(x) wasn't it...")
  ///         }
  ///     }
  ///     // "1 wasn't it..."
  ///     // "2 wasn't it..."
  ///     // "3 is the magic number!"
  ///
  /// Because a sequence created with the postfix range operator counts upward
  /// indefinitely, do not use one with methods such as `map(_:)`,
  /// `filter(_:)`, or `suffix(_:)` that read the entire sequence before
  /// returning. It is safe to use operations that put an upper limit on the
  /// number of elements they access, such as `prefix(_:)` or `dropFirst(_:)`,
  /// and operations that you can guarantee will terminate, such as passing a
  /// closure you know will eventually return `true` to `first(where:)`.
  ///
  /// In the following example, the `asciiTable` sequence is made by zipping
  /// together the characters in the `alphabet` string with a partial range
  /// starting at 65, the ASCII value of the capital letter A.
  /// Iterating over two zipped sequence continues only as long as the shorter
  /// of the two sequences, so the iteration stops at the end of `alphabet`.
  ///
  ///     let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  ///     let asciiTable = zip(65..., alphabet)
  ///     for (code, letter) in asciiTable {
  ///         print(code, letter)
  ///     }
  ///     // "65 A"
  ///     // "66 B"
  ///     // "67 C"
  ///     // ...
  ///     // "89 Y"
  ///     // "90 Z"
  ///
  /// The behavior of incrementing indefinitely is determined by the type of
  /// `Bound`. For example, iterating over an instance of
  /// `CountablePartialRangeFrom<Int>` traps when the sequence's next
  /// value would be above `Int.max`.
  ///
  /// - Parameter minimum: The lower bound for the range.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static postfix func ... (minimum: Self)
  -> CountablePartialRangeFrom<Self> {
    return CountablePartialRangeFrom(minimum)
  }
}

// FIXME: replace this with a computed var named `...` when the language makes
// that possible.
@_fixed_layout // FIXME(sil-serialize-all)
public enum UnboundedRange_ {
  @_inlineable // FIXME(sil-serialize-all)
  public static postfix func ... (_: UnboundedRange_) -> () {
    fatalError("uncallable")
  }
}
public typealias UnboundedRange = (UnboundedRange_)->()

extension Collection {
  @_inlineable
  public subscript<R: RangeExpression>(r: R)
  -> SubSequence where R.Bound == Index {
    return self[r.relative(to: self)]
  }
  
  @_inlineable
  public subscript(x: UnboundedRange) -> SubSequence {
    return self[startIndex...]
  }
}
extension MutableCollection {
  @_inlineable
  public subscript<R: RangeExpression>(r: R) -> SubSequence
  where R.Bound == Index {
    get {
      return self[r.relative(to: self)]
    }
    set {
      self[r.relative(to: self)] = newValue
    }
  }

  @_inlineable // FIXME(sil-serialize-all)
  public subscript(x: UnboundedRange) -> SubSequence {
    get {
      return self[startIndex...]
    }
    set {
      self[startIndex...] = newValue
    }
  }
}
