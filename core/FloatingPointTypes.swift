//===--- FloatingPointTypes.swift.gyb -------------------------*- swift -*-===//
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

import SwiftShims


// TODO: remove once integer proposal is available ----------------------------
// FIXME(integers): ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
extension UInt32 {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal var signBitIndex: Int {
    return 31 - leadingZeroBitCount
  }
}
extension UInt64 {
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal var signBitIndex: Int {
    return 63 - leadingZeroBitCount
  }
}



/// A single-precision, floating-point value type.
@_fixed_layout
public struct Float {
  public // @testable
  var _value: Builtin.FPIEEE32

  /// Creates a value initialized to zero.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init() {
    let zero: Int64 = 0
    self._value = Builtin.sitofp_Int64_FPIEEE32(zero._value)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public // @testable
  init(_bits v: Builtin.FPIEEE32) {
    self._value = v
  }
}

extension Float : CustomStringConvertible {
  /// A textual representation of the value.
  @_inlineable // FIXME(sil-serialize-all)
  public var description: String {
    return _float32ToString(self, debug: false)
  }
}

extension Float : CustomDebugStringConvertible {
  /// A textual representation of the value, suitable for debugging.
  @_inlineable // FIXME(sil-serialize-all)
  public var debugDescription: String {
    return _float32ToString(self, debug: true)
  }
}

extension Float: BinaryFloatingPoint {

  /// A type that can represent the absolute value of any possible value of
  /// this type.
  public typealias Magnitude = Float

  /// A type that can represent any written exponent.
  public typealias Exponent = Int

  /// A type that represents the encoded significand of a value.
  public typealias RawSignificand = UInt32

  /// The number of bits used to represent the type's exponent.
  ///
  /// A binary floating-point type's `exponentBitCount` imposes a limit on the
  /// range of the exponent for normal, finite values. The *exponent bias* of
  /// a type `F` can be calculated as the following, where `**` is
  /// exponentiation:
  ///
  ///     let bias = 2 ** (F.exponentBitCount - 1) - 1
  ///
  /// The least normal exponent for values of the type `F` is `1 - bias`, and
  /// the largest finite exponent is `bias`. An all-zeros exponent is reserved
  /// for subnormals and zeros, and an all-ones exponent is reserved for
  /// infinity and NaN.
  ///
  /// For example, the `Float` type has an `exponentBitCount` of 8, which gives
  /// an exponent bias of `127` by the calculation above.
  ///
  ///     let bias = 2 ** (Float.exponentBitCount - 1) - 1
  ///     // bias == 127
  ///     print(Float.greatestFiniteMagnitude.exponent)
  ///     // Prints "127"
  ///     print(Float.leastNormalMagnitude.exponent)
  ///     // Prints "-126"
  @_inlineable // FIXME(sil-serialize-all)
  public static var exponentBitCount: Int {
    return 8
  }

  /// The available number of fractional significand bits.
  ///
  /// For fixed-width floating-point types, this is the actual number of
  /// fractional significand bits.
  ///
  /// For extensible floating-point types, `significandBitCount` should be the
  /// maximum allowed significand width (without counting any leading integral
  /// bit of the significand). If there is no upper limit, then
  /// `significandBitCount` should be `Int.max`.
  @_inlineable // FIXME(sil-serialize-all)
  public static var significandBitCount: Int {
    return 23
  }

  //  Implementation details.
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  internal static var _infinityExponent: UInt {
    @inline(__always) get { return 1 &<< UInt(exponentBitCount) - 1 }
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal static var _exponentBias: UInt {
    @inline(__always) get { return _infinityExponent &>> 1 }
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal static var _significandMask: UInt32 {
    @inline(__always) get {
      return 1 &<< UInt32(significandBitCount) - 1
    }
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  internal static var _quietNaNMask: UInt32 {
    @inline(__always) get {
      return 1 &<< UInt32(significandBitCount - 1)
    }
  }

  //  Conversions to/from integer encoding.  These are not part of the
  //  BinaryFloatingPoint prototype because there's no guarantee that an
  //  integer type of the same size actually exists (e.g. Float80).
  //
  //  If we want them in a protocol at some future point, that protocol should
  //  be "InterchangeFloatingPoint" or "PortableFloatingPoint" or similar, and
  //  apply to IEEE 754 "interchange types".
  /// The bit pattern of the value's encoding.
  ///
  /// The bit pattern matches the binary interchange format defined by the
  /// [IEEE 754 specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  @_inlineable // FIXME(sil-serialize-all)
  public var bitPattern: UInt32 {
    return UInt32(Builtin.bitcast_FPIEEE32_Int32(_value))
  }

  /// Creates a new value with the given bit pattern.
  ///
  /// The value passed as `bitPattern` is interpreted in the binary interchange
  /// format defined by the [IEEE 754 specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  ///
  /// - Parameter bitPattern: The integer encoding of a `Float` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public init(bitPattern: UInt32) {
    self.init(_bits: Builtin.bitcast_Int32_FPIEEE32(bitPattern._value))
  }

  /// The sign of the floating-point value.
  ///
  /// The `sign` property is `.minus` if the value's signbit is set, and
  /// `.plus` otherwise. For example:
  ///
  ///     let x = -33.375
  ///     // x.sign == .minus
  ///
  /// Do not use this property to check whether a floating point value is
  /// negative. For a value `x`, the comparison `x.sign == .minus` is not
  /// necessarily the same as `x < 0`. In particular, `x.sign == .minus` if
  /// `x` is -0, and while `x < 0` is always `false` if `x` is NaN, `x.sign`
  /// could be either `.plus` or `.minus`.
  @_inlineable // FIXME(sil-serialize-all)
  public var sign: FloatingPointSign {
    let shift = Float.significandBitCount + Float.exponentBitCount
    return FloatingPointSign(rawValue: Int(bitPattern &>> UInt32(shift)))!
  }

  @available(*, unavailable, renamed: "sign")
  public var isSignMinus: Bool { Builtin.unreachable() }

  /// The raw encoding of the value's exponent field.
  ///
  /// This value is unadjusted by the type's exponent bias.
  @_inlineable // FIXME(sil-serialize-all)
  public var exponentBitPattern: UInt {
    return UInt(bitPattern &>> UInt32(Float.significandBitCount)) &
      Float._infinityExponent
  }

  /// The raw encoding of the value's significand field.
  ///
  /// The `significandBitPattern` property does not include the leading
  /// integral bit of the significand, even for types like `Float80` that
  /// store it explicitly.
  @_inlineable // FIXME(sil-serialize-all)
  public var significandBitPattern: UInt32 {
    return UInt32(bitPattern) & Float._significandMask
  }

  /// Creates a new instance from the specified sign and bit patterns.
  ///
  /// The values passed as `exponentBitPattern` and `significandBitPattern` are
  /// interpreted in the binary interchange format defined by the [IEEE 754
  /// specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  ///
  /// - Parameters:
  ///   - sign: The sign of the new value.
  ///   - exponentBitPattern: The bit pattern to use for the exponent field of
  ///     the new value.
  ///   - significandBitPattern: The bit pattern to use for the significand
  ///     field of the new value.
  @_inlineable // FIXME(sil-serialize-all)
  public init(sign: FloatingPointSign,
              exponentBitPattern: UInt,
              significandBitPattern: UInt32) {
    let signShift = Float.significandBitCount + Float.exponentBitCount
    let sign = UInt32(sign == .minus ? 1 : 0)
    let exponent = UInt32(
      exponentBitPattern & Float._infinityExponent)
    let significand = UInt32(
      significandBitPattern & Float._significandMask)
    self.init(bitPattern:
      sign &<< UInt32(signShift) |
      exponent &<< UInt32(Float.significandBitCount) |
      significand)
  }

  /// A Boolean value indicating whether the instance's representation is in
  /// the canonical form.
  ///
  /// The [IEEE 754 specification][spec] defines a *canonical*, or preferred,
  /// encoding of a floating-point value's representation. Every `Float` or
  /// `Double` value is canonical, but noncanonical values of the `Float80`
  /// type exist, and noncanonical values may exist for other types that
  /// conform to the `FloatingPoint` protocol.
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  @_inlineable // FIXME(sil-serialize-all)
  public var isCanonical: Bool {
    return true
  }

  /// Positive infinity.
  ///
  /// Infinity compares greater than all finite numbers and equal to other
  /// infinite values.
  ///
  ///     let x = Double.greatestFiniteMagnitude
  ///     let y = x * 2
  ///     // y == Double.infinity
  ///     // y > x
  @_inlineable // FIXME(sil-serialize-all)
  public static var infinity: Float {
    return Float(sign: .plus,
      exponentBitPattern: _infinityExponent,
      significandBitPattern: 0)
  }

  /// A quiet NaN ("not a number").
  ///
  /// A NaN compares not equal, not greater than, and not less than every
  /// value, including itself. Passing a NaN to an operation generally results
  /// in NaN.
  ///
  ///     let x = 1.21
  ///     // x > Double.nan == false
  ///     // x < Double.nan == false
  ///     // x == Double.nan == false
  ///
  /// Because a NaN always compares not equal to itself, to test whether a
  /// floating-point value is NaN, use its `isNaN` property instead of the
  /// equal-to operator (`==`). In the following example, `y` is NaN.
  ///
  ///     let y = x + Double.nan
  ///     print(y == Double.nan)
  ///     // Prints "false"
  ///     print(y.isNaN)
  ///     // Prints "true"
  @_inlineable // FIXME(sil-serialize-all)
  public static var nan: Float {
    return Float(nan: 0, signaling: false)
  }

  /// A signaling NaN ("not a number").
  ///
  /// The default IEEE 754 behavior of operations involving a signaling NaN is
  /// to raise the Invalid flag in the floating-point environment and return a
  /// quiet NaN.
  ///
  /// Operations on types conforming to the `FloatingPoint` protocol should
  /// support this behavior, but they might also support other options. For
  /// example, it would be reasonable to implement alternative operations in
  /// which operating on a signaling NaN triggers a runtime error or results
  /// in a diagnostic for debugging purposes. Types that implement alternative
  /// behaviors for a signaling NaN must document the departure.
  ///
  /// Other than these signaling operations, a signaling NaN behaves in the
  /// same manner as a quiet NaN.
  @_inlineable // FIXME(sil-serialize-all)
  public static var signalingNaN: Float {
    return Float(nan: 0, signaling: true)
  }

  @available(*, unavailable, renamed: "nan")
  public static var quietNaN: Float { Builtin.unreachable()}

  /// The greatest finite number representable by this type.
  ///
  /// This value compares greater than or equal to all finite numbers, but less
  /// than `infinity`.
  ///
  /// This value corresponds to type-specific C macros such as `FLT_MAX` and
  /// `DBL_MAX`. The naming of those macros is slightly misleading, because
  /// `infinity` is greater than this value.
  @_inlineable // FIXME(sil-serialize-all)
  public static var greatestFiniteMagnitude: Float {
    return Float(sign: .plus,
      exponentBitPattern: _infinityExponent - 1,
      significandBitPattern: _significandMask)
  }

  /// The mathematical constant pi.
  ///
  /// This value should be rounded toward zero to keep user computations with
  /// angles from inadvertently ending up in the wrong quadrant. A type that
  /// conforms to the `FloatingPoint` protocol provides the value for `pi` at
  /// its best possible precision.
  ///
  ///     print(Double.pi)
  ///     // Prints "3.14159265358979"
  @_inlineable // FIXME(sil-serialize-all)
  public static var pi: Float {
    // Note: this is not the correctly rounded (to nearest) value of pi,
    // because pi would round *up* in Float precision, which can result
    // in angles in the wrong quadrant if users aren't careful.  This is
    // not a problem for Double or Float80, as pi rounds down in both of
    // those formats.
    return 0x1.921fb4p1
  }

  /// The unit in the last place of this value.
  ///
  /// This is the unit of the least significant digit in this value's
  /// significand. For most numbers `x`, this is the difference between `x`
  /// and the next greater (in magnitude) representable number. There are some
  /// edge cases to be aware of:
  ///
  /// - If `x` is not a finite number, then `x.ulp` is NaN.
  /// - If `x` is very small in magnitude, then `x.ulp` may be a subnormal
  ///   number. If a type does not support subnormals, `x.ulp` may be rounded
  ///   to zero.
  /// - `greatestFiniteMagnitude.ulp` is a finite number, even though the next
  ///   greater representable value is `infinity`.
  ///
  /// This quantity, or a related quantity, is sometimes called *epsilon* or
  /// *machine epsilon.* Avoid that name because it has different meanings in
  /// different languages, which can lead to confusion, and because it
  /// suggests that it is a good tolerance to use for comparisons, which it
  /// almost never is.
  @_inlineable // FIXME(sil-serialize-all)
  public var ulp: Float {
    if !isFinite { return Float.nan }
    if exponentBitPattern > UInt(Float.significandBitCount) {
      // self is large enough that self.ulp is normal, so we just compute its
      // exponent and construct it with a significand of zero.
      let ulpExponent =
        exponentBitPattern - UInt(Float.significandBitCount)
      return Float(sign: .plus,
        exponentBitPattern: ulpExponent,
        significandBitPattern: 0)
    }
    if exponentBitPattern >= 1 {
      // self is normal but ulp is subnormal.
      let ulpShift = UInt32(exponentBitPattern - 1)
      return Float(sign: .plus,
        exponentBitPattern: 0,
        significandBitPattern: 1 &<< ulpShift)
    }
    return Float(sign: .plus,
      exponentBitPattern: 0,
      significandBitPattern: 1)
  }

  /// The least positive normal number.
  ///
  /// This value compares less than or equal to all positive normal numbers.
  /// There may be smaller positive numbers, but they are *subnormal*, meaning
  /// that they are represented with less precision than normal numbers.
  ///
  /// This value corresponds to type-specific C macros such as `FLT_MIN` and
  /// `DBL_MIN`. The naming of those macros is slightly misleading, because
  /// subnormals, zeros, and negative numbers are smaller than this value.
  @_inlineable // FIXME(sil-serialize-all)
  public static var leastNormalMagnitude: Float {
    return Float(sign: .plus,
      exponentBitPattern: 1,
      significandBitPattern: 0)
  }

  /// The least positive number.
  ///
  /// This value compares less than or equal to all positive numbers, but
  /// greater than zero. If the type supports subnormal values,
  /// `leastNonzeroMagnitude` is smaller than `leastNormalMagnitude`;
  /// otherwise they are equal.
  @_inlineable // FIXME(sil-serialize-all)
  public static var leastNonzeroMagnitude: Float {
#if arch(arm)
    return leastNormalMagnitude
#else
    return Float(sign: .plus,
      exponentBitPattern: 0,
      significandBitPattern: 1)
#endif
  }

  /// The exponent of the floating-point value.
  ///
  /// The *exponent* of a floating-point value is the integer part of the
  /// logarithm of the value's magnitude. For a value `x` of a floating-point
  /// type `F`, the magnitude can be calculated as the following, where `**`
  /// is exponentiation:
  ///
  ///     let magnitude = x.significand * F.radix ** x.exponent
  ///
  /// In the next example, `y` has a value of `21.5`, which is encoded as
  /// `1.34375 * 2 ** 4`. The significand of `y` is therefore 1.34375.
  ///
  ///     let y: Double = 21.5
  ///     // y.significand == 1.34375
  ///     // y.exponent == 4
  ///     // Double.radix == 2
  ///
  /// The `exponent` property has the following edge cases:
  ///
  /// - If `x` is zero, then `x.exponent` is `Int.min`.
  /// - If `x` is +/-infinity or NaN, then `x.exponent` is `Int.max`
  ///
  /// This property implements the `logB` operation defined by the [IEEE 754
  /// specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  @_inlineable // FIXME(sil-serialize-all)
  public var exponent: Int {
    if !isFinite { return .max }
    if isZero { return .min }
    let provisional = Int(exponentBitPattern) - Int(Float._exponentBias)
    if isNormal { return provisional }
    let shift = Float.significandBitCount - significandBitPattern.signBitIndex
    return provisional + 1 - Int(shift)
  }

  /// The significand of the floating-point value.
  ///
  /// The magnitude of a floating-point value `x` of type `F` can be calculated
  /// by using the following formula, where `**` is exponentiation:
  ///
  ///     let magnitude = x.significand * F.radix ** x.exponent
  ///
  /// In the next example, `y` has a value of `21.5`, which is encoded as
  /// `1.34375 * 2 ** 4`. The significand of `y` is therefore 1.34375.
  ///
  ///     let y: Double = 21.5
  ///     // y.significand == 1.34375
  ///     // y.exponent == 4
  ///     // Double.radix == 2
  ///
  /// If a type's radix is 2, then for finite nonzero numbers, the significand
  /// is in the range `1.0 ..< 2.0`. For other values of `x`, `x.significand`
  /// is defined as follows:
  ///
  /// - If `x` is zero, then `x.significand` is 0.0.
  /// - If `x` is infinity, then `x.significand` is 1.0.
  /// - If `x` is NaN, then `x.significand` is NaN.
  /// - Note: The significand is frequently also called the *mantissa*, but
  ///   significand is the preferred terminology in the [IEEE 754
  ///   specification][spec], to allay confusion with the use of mantissa for
  ///   the fractional part of a logarithm.
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  @_inlineable // FIXME(sil-serialize-all)
  public var significand: Float {
    if isNaN { return self }
    if isNormal {
      return Float(sign: .plus,
        exponentBitPattern: Float._exponentBias,
        significandBitPattern: significandBitPattern)
    }
    if isSubnormal {
      let shift = Float.significandBitCount - significandBitPattern.signBitIndex
      return Float(sign: .plus,
        exponentBitPattern: Float._exponentBias,
        significandBitPattern: significandBitPattern &<< UInt32(shift))
    }
    // zero or infinity.
    return Float(sign: .plus,
      exponentBitPattern: exponentBitPattern,
      significandBitPattern: 0)
  }

  /// Creates a new value from the given sign, exponent, and significand.
  ///
  /// The following example uses this initializer to create a new `Double`
  /// instance. `Double` is a binary floating-point type that has a radix of
  /// `2`.
  ///
  ///     let x = Double(sign: .plus, exponent: -2, significand: 1.5)
  ///     // x == 0.375
  ///
  /// This initializer is equivalent to the following calculation, where `**`
  /// is exponentiation, computed as if by a single, correctly rounded,
  /// floating-point operation:
  ///
  ///     let sign: FloatingPointSign = .plus
  ///     let exponent = -2
  ///     let significand = 1.5
  ///     let y = (sign == .minus ? -1 : 1) * significand * Double.radix ** exponent
  ///     // y == 0.375
  ///
  /// As with any basic operation, if this value is outside the representable
  /// range of the type, overflow or underflow occurs, and zero, a subnormal
  /// value, or infinity may result. In addition, there are two other edge
  /// cases:
  ///
  /// - If the value you pass to `significand` is zero or infinite, the result
  ///   is zero or infinite, regardless of the value of `exponent`.
  /// - If the value you pass to `significand` is NaN, the result is NaN.
  ///
  /// For any floating-point value `x` of type `F`, the result of the following
  /// is equal to `x`, with the distinction that the result is canonicalized
  /// if `x` is in a noncanonical encoding:
  ///
  ///     let x0 = F(sign: x.sign, exponent: x.exponent, significand: x.significand)
  ///
  /// This initializer implements the `scaleB` operation defined by the [IEEE
  /// 754 specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  ///
  /// - Parameters:
  ///   - sign: The sign to use for the new value.
  ///   - exponent: The new value's exponent.
  ///   - significand: The new value's significand.
  @_inlineable // FIXME(sil-serialize-all)
  public init(sign: FloatingPointSign, exponent: Int, significand: Float) {
    var result = significand
    if sign == .minus { result = -result }
    if significand.isFinite && !significand.isZero {
      var clamped = exponent
      let leastNormalExponent = 1 - Int(Float._exponentBias)
      let greatestFiniteExponent = Int(Float._exponentBias)
      if clamped < leastNormalExponent {
        clamped = max(clamped, 3*leastNormalExponent)
        while clamped < leastNormalExponent {
          result  *= Float.leastNormalMagnitude
          clamped -= leastNormalExponent
        }
      }
      else if clamped > greatestFiniteExponent {
        clamped = min(clamped, 3*greatestFiniteExponent)
        let step = Float(sign: .plus,
          exponentBitPattern: Float._infinityExponent - 1,
          significandBitPattern: 0)
        while clamped > greatestFiniteExponent {
          result  *= step
          clamped -= greatestFiniteExponent
        }
      }
      let scale = Float(sign: .plus,
        exponentBitPattern: UInt(Int(Float._exponentBias) + clamped),
        significandBitPattern: 0)
      result = result * scale
    }
    self = result
  }

  /// Creates a NaN ("not a number") value with the specified payload.
  ///
  /// NaN values compare not equal to every value, including themselves. Most
  /// operations with a NaN operand produce a NaN result. Don't use the
  /// equal-to operator (`==`) to test whether a value is NaN. Instead, use
  /// the value's `isNaN` property.
  ///
  ///     let x = Float(nan: 0, signaling: false)
  ///     print(x == .nan)
  ///     // Prints "false"
  ///     print(x.isNaN)
  ///     // Prints "true"
  ///
  /// - Parameters:
  ///   - payload: The payload to use for the new NaN value.
  ///   - signaling: Pass `true` to create a signaling NaN or `false` to create
  ///     a quiet NaN.
  @_inlineable // FIXME(sil-serialize-all)
  public init(nan payload: RawSignificand, signaling: Bool) {
    // We use significandBitCount - 2 bits for NaN payload.
    _precondition(payload < (Float._quietNaNMask &>> 1),
      "NaN payload is not encodable.")
    var significand = payload
    significand |= Float._quietNaNMask &>> (signaling ? 1 : 0)
    self.init(sign: .plus,
              exponentBitPattern: Float._infinityExponent,
              significandBitPattern: significand)
  }

  /// The least representable value that compares greater than this value.
  ///
  /// For any finite value `x`, `x.nextUp` is greater than `x`. For `nan` or
  /// `infinity`, `x.nextUp` is `x` itself. The following special cases also
  /// apply:
  ///
  /// - If `x` is `-infinity`, then `x.nextUp` is `-greatestFiniteMagnitude`.
  /// - If `x` is `-leastNonzeroMagnitude`, then `x.nextUp` is `-0.0`.
  /// - If `x` is zero, then `x.nextUp` is `leastNonzeroMagnitude`.
  /// - If `x` is `greatestFiniteMagnitude`, then `x.nextUp` is `infinity`.
  @_inlineable // FIXME(sil-serialize-all)
  public var nextUp: Float {
    if isNaN { return self }
    if sign == .minus {
#if arch(arm)
      // On arm, subnormals are flushed to zero.
      if (exponentBitPattern == 1 && significandBitPattern == 0) ||
         (exponentBitPattern == 0 && significandBitPattern != 0) {
        return Float(sign: .minus,
          exponentBitPattern: 0,
          significandBitPattern: 0)
      }
#endif
      if significandBitPattern == 0 {
        if exponentBitPattern == 0 {
          return .leastNonzeroMagnitude
        }
        return Float(sign: .minus,
          exponentBitPattern: exponentBitPattern - 1,
          significandBitPattern: Float._significandMask)
      }
      return Float(sign: .minus,
        exponentBitPattern: exponentBitPattern,
        significandBitPattern: significandBitPattern - 1)
    }
    if isInfinite { return self }
    if significandBitPattern == Float._significandMask {
      return Float(sign: .plus,
        exponentBitPattern: exponentBitPattern + 1,
        significandBitPattern: 0)
    }
#if arch(arm)
    // On arm, subnormals are skipped.
    if exponentBitPattern == 0 {
      return .leastNonzeroMagnitude
    }
#endif
    return Float(sign: .plus,
      exponentBitPattern: exponentBitPattern,
      significandBitPattern: significandBitPattern + 1)
  }

  /// Rounds the value to an integral value using the specified rounding rule.
  ///
  /// The following example rounds a value using four different rounding rules:
  ///
  ///     // Equivalent to the C 'round' function:
  ///     var w = 6.5
  ///     w.round(.toNearestOrAwayFromZero)
  ///     // w == 7.0
  ///
  ///     // Equivalent to the C 'trunc' function:
  ///     var x = 6.5
  ///     x.round(.towardZero)
  ///     // x == 6.0
  ///
  ///     // Equivalent to the C 'ceil' function:
  ///     var y = 6.5
  ///     y.round(.up)
  ///     // y == 7.0
  ///
  ///     // Equivalent to the C 'floor' function:
  ///     var z = 6.5
  ///     z.round(.down)
  ///     // z == 6.0
  ///
  /// For more information about the available rounding rules, see the
  /// `FloatingPointRoundingRule` enumeration. To round a value using the
  /// default "schoolbook rounding", you can use the shorter `round()` method
  /// instead.
  ///
  ///     var w1 = 6.5
  ///     w1.round()
  ///     // w1 == 7.0
  ///
  /// - Parameter rule: The rounding rule to use.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func round(_ rule: FloatingPointRoundingRule) {
    switch rule {
    case .toNearestOrAwayFromZero:
      _value = Builtin.int_round_FPIEEE32(_value)
    case .toNearestOrEven:
      _value = Builtin.int_rint_FPIEEE32(_value)
    case .towardZero:
      _value = Builtin.int_trunc_FPIEEE32(_value)
    case .awayFromZero:
      if sign == .minus {
        _value = Builtin.int_floor_FPIEEE32(_value)
      }
      else {
        _value = Builtin.int_ceil_FPIEEE32(_value)
      }
    case .up:
      _value = Builtin.int_ceil_FPIEEE32(_value)
    case .down:
      _value = Builtin.int_floor_FPIEEE32(_value)
    }
  }

  /// Replaces this value with its additive inverse.
  ///
  /// The result is always exact. This example uses the `negate()` method to
  /// negate the value of the variable `x`:
  ///
  ///     var x = 21.5
  ///     x.negate()
  ///     // x == -21.5
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func negate() {
    _value = Builtin.fneg_FPIEEE32(self._value)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func +=(_ lhs: inout Float, _ rhs: Float) {
    lhs._value = Builtin.fadd_FPIEEE32(lhs._value, rhs._value)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func -=(_ lhs: inout Float, _ rhs: Float) {
    lhs._value = Builtin.fsub_FPIEEE32(lhs._value, rhs._value)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func *=(_ lhs: inout Float, _ rhs: Float) {
    lhs._value = Builtin.fmul_FPIEEE32(lhs._value, rhs._value)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func /=(_ lhs: inout Float, _ rhs: Float) {
    lhs._value = Builtin.fdiv_FPIEEE32(lhs._value, rhs._value)
  }

  /// Replaces this value with the remainder of itself divided by the given
  /// value.
  ///
  /// For two finite values `x` and `y`, the remainder `r` of dividing `x` by
  /// `y` satisfies `x == y * q + r`, where `q` is the integer nearest to
  /// `x / y`. If `x / y` is exactly halfway between two integers, `q` is
  /// chosen to be even. Note that `q` is *not* `x / y` computed in
  /// floating-point arithmetic, and that `q` may not be representable in any
  /// available integer type.
  ///
  /// The following example calculates the remainder of dividing 8.625 by 0.75:
  ///
  ///     var x = 8.625
  ///     print(x / 0.75)
  ///     // Prints "11.5"
  ///
  ///     let q = (x / 0.75).rounded(.toNearestOrEven)
  ///     // q == 12.0
  ///     x.formRemainder(dividingBy: 0.75)
  ///     // x == -0.375
  ///
  ///     let x1 = 0.75 * q + x
  ///     // x1 == 8.625
  ///
  /// If this value and `other` are finite numbers, the remainder is in the
  /// closed range `-abs(other / 2)...abs(other / 2)`. The
  /// `formRemainder(dividingBy:)` method is always exact.
  ///
  /// - Parameter other: The value to use when dividing this value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func formRemainder(dividingBy other: Float) {
    self = _stdlib_remainderf(self, other)
  }

  /// Replaces this value with the remainder of itself divided by the given
  /// value using truncating division.
  ///
  /// Performing truncating division with floating-point values results in a
  /// truncated integer quotient and a remainder. For values `x` and `y` and
  /// their truncated integer quotient `q`, the remainder `r` satisfies
  /// `x == y * q + r`.
  ///
  /// The following example calculates the truncating remainder of dividing
  /// 8.625 by 0.75:
  ///
  ///     var x = 8.625
  ///     print(x / 0.75)
  ///     // Prints "11.5"
  ///
  ///     let q = (x / 0.75).rounded(.towardZero)
  ///     // q == 11.0
  ///     x.formTruncatingRemainder(dividingBy: 0.75)
  ///     // x == 0.375
  ///
  ///     let x1 = 0.75 * q + x
  ///     // x1 == 8.625
  ///
  /// If this value and `other` are both finite numbers, the truncating
  /// remainder has the same sign as this value and is strictly smaller in
  /// magnitude than `other`. The `formTruncatingRemainder(dividingBy:)`
  /// method is always exact.
  ///
  /// - Parameter other: The value to use when dividing this value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func formTruncatingRemainder(dividingBy other: Float) {
    _value = Builtin.frem_FPIEEE32(self._value, other._value)
  }

  /// Replaces this value with its square root, rounded to a representable
  /// value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func formSquareRoot( ) {
    self = _stdlib_squareRootf(self)
  }

  /// Adds the product of the two given values to this value in place, computed
  /// without intermediate rounding.
  ///
  /// - Parameters:
  ///   - lhs: One of the values to multiply before adding to this value.
  ///   - rhs: The other value to multiply.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func addProduct(_ lhs: Float, _ rhs: Float) {
    _value = Builtin.int_fma_FPIEEE32(lhs._value, rhs._value, _value)
  }

  /// Returns a Boolean value indicating whether this instance is equal to the
  /// given value.
  ///
  /// This method serves as the basis for the equal-to operator (`==`) for
  /// floating-point values. When comparing two values with this method, `-0`
  /// is equal to `+0`. NaN is not equal to any value, including itself. For
  /// example:
  ///
  ///     let x = 15.0
  ///     x.isEqual(to: 15.0)
  ///     // true
  ///     x.isEqual(to: .nan)
  ///     // false
  ///     Double.nan.isEqual(to: .nan)
  ///     // false
  ///
  /// The `isEqual(to:)` method implements the equality predicate defined by
  /// the [IEEE 754 specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  ///
  /// - Parameter other: The value to compare with this value.
  /// - Returns: `true` if `other` has the same value as this instance;
  ///   otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func isEqual(to other: Float) -> Bool {
    return Bool(Builtin.fcmp_oeq_FPIEEE32(self._value, other._value))
  }

  /// Returns a Boolean value indicating whether this instance is less than the
  /// given value.
  ///
  /// This method serves as the basis for the less-than operator (`<`) for
  /// floating-point values. Some special cases apply:
  ///
  /// - Because NaN compares not less than nor greater than any value, this
  ///   method returns `false` when called on NaN or when NaN is passed as
  ///   `other`.
  /// - `-infinity` compares less than all values except for itself and NaN.
  /// - Every value except for NaN and `+infinity` compares less than
  ///   `+infinity`.
  ///
  ///     let x = 15.0
  ///     x.isLess(than: 20.0)
  ///     // true
  ///     x.isLess(than: .nan)
  ///     // false
  ///     Double.nan.isLess(than: x)
  ///     // false
  ///
  /// The `isLess(than:)` method implements the less-than predicate defined by
  /// the [IEEE 754 specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  ///
  /// - Parameter other: The value to compare with this value.
  /// - Returns: `true` if `other` is less than this value; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func isLess(than other: Float) -> Bool {
    return Bool(Builtin.fcmp_olt_FPIEEE32(self._value, other._value))
  }

  /// Returns a Boolean value indicating whether this instance is less than or
  /// equal to the given value.
  ///
  /// This method serves as the basis for the less-than-or-equal-to operator
  /// (`<=`) for floating-point values. Some special cases apply:
  ///
  /// - Because NaN is incomparable with any value, this method returns `false`
  ///   when called on NaN or when NaN is passed as `other`.
  /// - `-infinity` compares less than or equal to all values except NaN.
  /// - Every value except NaN compares less than or equal to `+infinity`.
  ///
  ///     let x = 15.0
  ///     x.isLessThanOrEqualTo(20.0)
  ///     // true
  ///     x.isLessThanOrEqualTo(.nan)
  ///     // false
  ///     Double.nan.isLessThanOrEqualTo(x)
  ///     // false
  ///
  /// The `isLessThanOrEqualTo(_:)` method implements the less-than-or-equal
  /// predicate defined by the [IEEE 754 specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  ///
  /// - Parameter other: The value to compare with this value.
  /// - Returns: `true` if `other` is less than this value; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func isLessThanOrEqualTo(_ other: Float) -> Bool {
    return Bool(Builtin.fcmp_ole_FPIEEE32(self._value, other._value))
  }

  /// A Boolean value indicating whether this instance is normal.
  ///
  /// A *normal* value is a finite number that uses the full precision
  /// available to values of a type. Zero is neither a normal nor a subnormal
  /// number.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isNormal: Bool {
    return exponentBitPattern > 0 && isFinite
  }

  /// A Boolean value indicating whether this instance is finite.
  ///
  /// All values other than NaN and infinity are considered finite, whether
  /// normal or subnormal.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isFinite: Bool {
    return exponentBitPattern < Float._infinityExponent
  }

  /// A Boolean value indicating whether the instance is equal to zero.
  ///
  /// The `isZero` property of a value `x` is `true` when `x` represents either
  /// `-0.0` or `+0.0`. `x.isZero` is equivalent to the following comparison:
  /// `x == 0.0`.
  ///
  ///     let x = -0.0
  ///     x.isZero        // true
  ///     x == 0.0        // true
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isZero: Bool {
    return exponentBitPattern == 0 && significandBitPattern == 0
  }

  /// A Boolean value indicating whether the instance is subnormal.
  ///
  /// A *subnormal* value is a nonzero number that has a lesser magnitude than
  /// the smallest normal number. Subnormal values do not use the full
  /// precision available to values of a type.
  ///
  /// Zero is neither a normal nor a subnormal number. Subnormal numbers are
  /// often called *denormal* or *denormalized*---these are different names
  /// for the same concept.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isSubnormal:  Bool {
    return exponentBitPattern == 0 && significandBitPattern != 0
  }

  /// A Boolean value indicating whether the instance is infinite.
  ///
  /// Note that `isFinite` and `isInfinite` do not form a dichotomy, because
  /// they are not total: If `x` is `NaN`, then both properties are `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isInfinite:  Bool {
    return !isFinite && significandBitPattern == 0
  }

  /// A Boolean value indicating whether the instance is NaN ("not a number").
  ///
  /// Because NaN is not equal to any value, including NaN, use this property
  /// instead of the equal-to operator (`==`) or not-equal-to operator (`!=`)
  /// to test whether a value is or is not NaN. For example:
  ///
  ///     let x = 0.0
  ///     let y = x * .infinity
  ///     // y is a NaN
  ///
  ///     // Comparing with the equal-to operator never returns 'true'
  ///     print(x == Double.nan)
  ///     // Prints "false"
  ///     print(y == Double.nan)
  ///     // Prints "false"
  ///
  ///     // Test with the 'isNaN' property instead
  ///     print(x.isNaN)
  ///     // Prints "false"
  ///     print(y.isNaN)
  ///     // Prints "true"
  ///
  /// This property is `true` for both quiet and signaling NaNs.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isNaN:  Bool {
    return !isFinite && significandBitPattern != 0
  }

  /// A Boolean value indicating whether the instance is a signaling NaN.
  ///
  /// Signaling NaNs typically raise the Invalid flag when used in general
  /// computing operations.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isSignalingNaN: Bool {
    return isNaN && (significandBitPattern & Float._quietNaNMask) == 0
  }

  /// The floating-point value with the same sign and exponent as this value,
  /// but with a significand of 1.0.
  ///
  /// A *binade* is a set of binary floating-point values that all have the
  /// same sign and exponent. The `binade` property is a member of the same
  /// binade as this value, but with a unit significand.
  ///
  /// In this example, `x` has a value of `21.5`, which is stored as
  /// `1.34375 * 2**4`, where `**` is exponentiation. Therefore, `x.binade` is
  /// equal to `1.0 * 2**4`, or `16.0`.
  ///
  ///     let x = 21.5
  ///     // x.significand == 1.34375
  ///     // x.exponent == 4
  ///
  ///     let y = x.binade
  ///     // y == 16.0
  ///     // y.significand == 1.0
  ///     // y.exponent == 4
  @_inlineable // FIXME(sil-serialize-all)
  public var binade: Float {
    if !isFinite { return .nan }
    if exponentBitPattern != 0 {
      return Float(sign: sign, exponentBitPattern: exponentBitPattern,
        significandBitPattern: 0)
    }
    if significandBitPattern == 0 { return self }
    // For subnormals, we isolate the leading significand bit.
    let index = significandBitPattern.signBitIndex
    return Float(sign: sign, exponentBitPattern: 0,
      significandBitPattern: 1 &<< RawSignificand(index))
  }

  /// The number of bits required to represent the value's significand.
  ///
  /// If this value is a finite nonzero number, `significandWidth` is the
  /// number of fractional bits required to represent the value of
  /// `significand`; otherwise, `significandWidth` is -1. The value of
  /// `significandWidth` is always -1 or between zero and
  /// `significandBitCount`. For example:
  ///
  /// - For any representable power of two, `significandWidth` is zero, because
  ///   `significand` is `1.0`.
  /// - If `x` is 10, `x.significand` is `1.01` in binary, so
  ///   `x.significandWidth` is 2.
  /// - If `x` is Float.pi, `x.significand` is `1.10010010000111111011011` in
  ///   binary, and `x.significandWidth` is 23.
  @_inlineable // FIXME(sil-serialize-all)
  public var significandWidth: Int {
    let trailingZeroBits = significandBitPattern.trailingZeroBitCount
    if isNormal {
      guard significandBitPattern != 0 else { return 0 }
      return Float.significandBitCount - trailingZeroBits
    }
    if isSubnormal {
      return significandBitPattern.signBitIndex - trailingZeroBits
    }
    return -1
  }

  /// Creates a new value from the given floating-point literal.
  ///
  /// Do not call this initializer directly. It is used by the compiler when
  /// you create a new `Float` instance by using a floating-point literal.
  /// Instead, create a new value by using a literal.
  ///
  /// In this example, the assignment to the `x` constant calls this
  /// initializer behind the scenes.
  ///
  ///     let x: Float = 21.25
  ///     // x == 21.25
  ///
  /// - Parameter value: The new floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(floatLiteral value: Float) {
    self = value
  }
}

extension Float : _ExpressibleByBuiltinIntegerLiteral, ExpressibleByIntegerLiteral {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public
  init(_builtinIntegerLiteral value: Builtin.Int2048){
    self = Float(_bits: Builtin.itofp_with_overflow_Int2048_FPIEEE32(value))
  }

  /// Creates a new value from the given integer literal.
  ///
  /// Do not call this initializer directly. It is used by the compiler when
  /// you create a new `Float` instance by using an integer literal.
  /// Instead, create a new value by using a literal.
  ///
  /// In this example, the assignment to the `x` constant calls this
  /// initializer behind the scenes.
  ///
  ///     let x: Float = 100
  ///     // x == 100.0
  ///
  /// - Parameter value: The new value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(integerLiteral value: Int64) {
    self = Float(_bits: Builtin.sitofp_Int64_FPIEEE32(value._value))
  }
}

#if !os(Windows) && (arch(i386) || arch(x86_64))

extension Float : _ExpressibleByBuiltinFloatLiteral {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public
  init(_builtinFloatLiteral value: Builtin.FPIEEE80) {
    self = Float(_bits: Builtin.fptrunc_FPIEEE80_FPIEEE32(value))
  }
}

#else

extension Float : _ExpressibleByBuiltinFloatLiteral {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public
  init(_builtinFloatLiteral value: Builtin.FPIEEE64) {
    self = Float(_bits: Builtin.fptrunc_FPIEEE64_FPIEEE32(value))
  }
}

#endif

extension Float : Hashable {
  /// The number's hash value.
  ///
  /// Hash values are not guaranteed to be equal across different executions of
  /// your program. Do not save hash values to use during a future execution.
  @_inlineable // FIXME(sil-serialize-all)
  public var hashValue: Int {
    if isZero {
      // To satisfy the axiom that equality implies hash equality, we need to
      // finesse the hash value of -0.0 to match +0.0.
      return 0
    } else {
      return Int(bitPattern: UInt(bitPattern))
    }
  }
}

extension Float {
  /// The magnitude of this value.
  ///
  /// For any value `x`, `x.magnitude.sign` is `.plus`. If `x` is not NaN,
  /// `x.magnitude` is the absolute value of `x`.
  ///
  /// The global `abs(_:)` function provides more familiar syntax when you need
  /// to find an absolute value. In addition, because `abs(_:)` always returns
  /// a value of the same type, even in a generic context, using the function
  /// instead of the `magnitude` property is encouraged.
  ///
  ///     let targetDistance: Float = 5.25
  ///     let throwDistance: Float = 5.5
  ///
  ///     let margin = targetDistance - throwDistance
  ///     // margin == -0.25
  ///     // margin.magnitude == 0.25
  ///
  ///     // Use 'abs(_:)' instead of 'magnitude'
  ///     print("Missed the target by \(abs(margin)) meters.")
  ///     // Prints "Missed the target by 0.25 meters."
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var magnitude: Float {
    return Float(_bits: Builtin.int_fabs_FPIEEE32(_value))
  }

  // FIXME(integers): implement properly
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter source: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  public init?<T : BinaryInteger>(exactly source: T) {
    fatalError()
  }
}

extension Float {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static prefix func - (x: Float) -> Float {
    return Float(_bits: Builtin.fneg_FPIEEE32(x._value))
  }
}

//===----------------------------------------------------------------------===//
// Explicit conversions between types.
//===----------------------------------------------------------------------===//

// Construction from integers.
extension Float {

  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: UInt8) {
    _value = Builtin.uitofp_Int8_FPIEEE32(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @available(*, message: "Converting UInt8 to Float will always succeed.")
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: UInt8) {
    _value = Builtin.uitofp_Int8_FPIEEE32(value._value)

  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: Int8) {
    _value = Builtin.sitofp_Int8_FPIEEE32(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @available(*, message: "Converting Int8 to Float will always succeed.")
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: Int8) {
    _value = Builtin.sitofp_Int8_FPIEEE32(value._value)

  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: UInt16) {
    _value = Builtin.uitofp_Int16_FPIEEE32(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @available(*, message: "Converting UInt16 to Float will always succeed.")
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: UInt16) {
    _value = Builtin.uitofp_Int16_FPIEEE32(value._value)

  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: Int16) {
    _value = Builtin.sitofp_Int16_FPIEEE32(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @available(*, message: "Converting Int16 to Float will always succeed.")
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: Int16) {
    _value = Builtin.sitofp_Int16_FPIEEE32(value._value)

  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: UInt32) {
    _value = Builtin.uitofp_Int32_FPIEEE32(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: UInt32) {
    _value = Builtin.uitofp_Int32_FPIEEE32(value._value)

    guard let roundTrip = UInt32(exactly: self),
      roundTrip == value else {
      return nil
    }
  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: Int32) {
    _value = Builtin.sitofp_Int32_FPIEEE32(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: Int32) {
    _value = Builtin.sitofp_Int32_FPIEEE32(value._value)

    guard let roundTrip = Int32(exactly: self),
      roundTrip == value else {
      return nil
    }
  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: UInt64) {
    _value = Builtin.uitofp_Int64_FPIEEE32(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: UInt64) {
    _value = Builtin.uitofp_Int64_FPIEEE32(value._value)

    guard let roundTrip = UInt64(exactly: self),
      roundTrip == value else {
      return nil
    }
  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: Int64) {
    _value = Builtin.sitofp_Int64_FPIEEE32(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: Int64) {
    _value = Builtin.sitofp_Int64_FPIEEE32(value._value)

    guard let roundTrip = Int64(exactly: self),
      roundTrip == value else {
      return nil
    }
  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: UInt) {
    _value = Builtin.uitofp_Int64_FPIEEE32(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: UInt) {
    _value = Builtin.uitofp_Int64_FPIEEE32(value._value)

    guard let roundTrip = UInt(exactly: self),
      roundTrip == value else {
      return nil
    }
  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: Int) {
    _value = Builtin.sitofp_Int64_FPIEEE32(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: Int) {
    _value = Builtin.sitofp_Int64_FPIEEE32(value._value)

    guard let roundTrip = Int(exactly: self),
      roundTrip == value else {
      return nil
    }
  }
}

// Construction from other floating point numbers.
extension Float {


  /// Creates a new instance initialized to the given value.
  ///
  /// The value of `other` is represented exactly by the new instance. A NaN
  /// passed as `other` results in another NaN, with a signaling NaN value
  /// converted to quiet NaN.
  ///
  ///     let x: Float = 21.25
  ///     let y = Float(x)
  ///     // y == 21.25
  ///
  ///     let z = Float(Float.nan)
  ///     // z.isNaN == true
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ other: Float) {
    _value = other._value
  }

  /// Creates a new instance initialized to the given value, if it can be
  /// represented without rounding.
  ///
  /// If `other` can't be represented as an instance of `Float` without
  /// rounding, the result of this initializer is `nil`. In particular,
  /// passing NaN as `other` always results in `nil`.
  ///
  ///     let x: Float = 21.25
  ///     let y = Float(exactly: x)
  ///     // y == Optional.some(21.25)
  ///
  ///     let z = Float(exactly: Float.nan)
  ///     // z == nil
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly other: Float) {
    self.init(other)
    // Converting the infinity value is considered value preserving.
    // In other cases, check that we can round-trip and get the same value.
    // NaN always fails.
    if Float(self) != other {
      return nil
    }
  }



  /// Creates a new instance that approximates the given value.
  ///
  /// The value of `other` is rounded to a representable value, if necessary.
  /// A NaN passed as `other` results in another NaN, with a signaling NaN
  /// value converted to quiet NaN.
  ///
  ///     let x: Double = 21.25
  ///     let y = Float(x)
  ///     // y == 21.25
  ///
  ///     let z = Float(Double.nan)
  ///     // z.isNaN == true
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ other: Double) {
    _value = Builtin.fptrunc_FPIEEE64_FPIEEE32(other._value)
  }

  /// Creates a new instance initialized to the given value, if it can be
  /// represented without rounding.
  ///
  /// If `other` can't be represented as an instance of `Float` without
  /// rounding, the result of this initializer is `nil`. In particular,
  /// passing NaN as `other` always results in `nil`.
  ///
  ///     let x: Double = 21.25
  ///     let y = Float(exactly: x)
  ///     // y == Optional.some(21.25)
  ///
  ///     let z = Float(exactly: Double.nan)
  ///     // z == nil
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly other: Double) {
    self.init(other)
    // Converting the infinity value is considered value preserving.
    // In other cases, check that we can round-trip and get the same value.
    // NaN always fails.
    if Double(self) != other {
      return nil
    }
  }


#if !os(Windows) && (arch(i386) || arch(x86_64))

  /// Creates a new instance that approximates the given value.
  ///
  /// The value of `other` is rounded to a representable value, if necessary.
  /// A NaN passed as `other` results in another NaN, with a signaling NaN
  /// value converted to quiet NaN.
  ///
  ///     let x: Float80 = 21.25
  ///     let y = Float(x)
  ///     // y == 21.25
  ///
  ///     let z = Float(Float80.nan)
  ///     // z.isNaN == true
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ other: Float80) {
    _value = Builtin.fptrunc_FPIEEE80_FPIEEE32(other._value)
  }

  /// Creates a new instance initialized to the given value, if it can be
  /// represented without rounding.
  ///
  /// If `other` can't be represented as an instance of `Float` without
  /// rounding, the result of this initializer is `nil`. In particular,
  /// passing NaN as `other` always results in `nil`.
  ///
  ///     let x: Float80 = 21.25
  ///     let y = Float(exactly: x)
  ///     // y == Optional.some(21.25)
  ///
  ///     let z = Float(exactly: Float80.nan)
  ///     // z == nil
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly other: Float80) {
    self.init(other)
    // Converting the infinity value is considered value preserving.
    // In other cases, check that we can round-trip and get the same value.
    // NaN always fails.
    if Float80(self) != other {
      return nil
    }
  }

#endif
}

//===----------------------------------------------------------------------===//
// Standard Operator Table
//===----------------------------------------------------------------------===//

//  TODO: These should not be necessary, since they're already provided by
//  <T: FloatingPoint>, but in practice they are currently needed to
//  disambiguate overloads.  We should find a way to remove them, either by
//  tweaking the overload resolution rules, or by removing the other
//  definitions in the standard lib, or both.

extension Float {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func + (lhs: Float, rhs: Float) -> Float {
    var lhs = lhs
    lhs += rhs
    return lhs
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func - (lhs: Float, rhs: Float) -> Float {
    var lhs = lhs
    lhs -= rhs
    return lhs
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func * (lhs: Float, rhs: Float) -> Float {
    var lhs = lhs
    lhs *= rhs
    return lhs
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func / (lhs: Float, rhs: Float) -> Float {
    var lhs = lhs
    lhs /= rhs
    return lhs
  }
}

//===----------------------------------------------------------------------===//
// Strideable Conformance
//===----------------------------------------------------------------------===//

extension Float : Strideable {
  /// Returns the distance from this value to the specified value.
  ///
  /// For two values `x` and `y`, the result of `x.distance(to: y)` is equal to
  /// `y - x`---a distance `d` such that `x.advanced(by: d)` approximates `y`.
  /// For example:
  ///
  ///     let x = 21.5
  ///     let d = x.distance(to: 15.0)
  ///     // d == -6.5
  ///
  ///     print(x.advanced(by: d))
  ///     // Prints "15.0"
  ///
  /// - Parameter other: A value to calculate the distance to.
  /// - Returns: The distance between this value and `other`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func distance(to other: Float) -> Float {
    return other - self
  }

  /// Returns a new value advanced by the given distance.
  ///
  /// For two values `x` and `d`, the result of a `x.advanced(by: d)` is equal
  /// to `x + d`---a new value `y` such that `x.distance(to: y)` approximates
  /// `d`. For example:
  ///
  ///     let x = 21.5
  ///     let y = x.advanced(by: -6.5)
  ///     // y == 15.0
  ///
  ///     print(x.distance(to: y))
  ///     // Prints "-6.5"
  ///
  /// - Parameter amount: The distance to advance this value.
  /// - Returns: A new value that is `amount` added to this value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func advanced(by amount: Float) -> Float {
    return self + amount
  }
}

//===----------------------------------------------------------------------===//
// Deprecated operators
//===----------------------------------------------------------------------===//

@_transparent
@available(*, unavailable, message: "use += 1")
@discardableResult
public prefix func ++ (rhs: inout Float) -> Float {
  fatalError("++ is not available")
}
@_transparent
@available(*, unavailable, message: "use -= 1")
@discardableResult
public prefix func -- (rhs: inout Float) -> Float {
  fatalError("-- is not available")
}
@_transparent
@available(*, unavailable, message: "use += 1")
@discardableResult
public postfix func ++ (lhs: inout Float) -> Float {
  fatalError("++ is not available")
}
@_transparent
@available(*, unavailable, message: "use -= 1")
@discardableResult
public postfix func -- (lhs: inout Float) -> Float {
  fatalError("-- is not available")
}

extension Float {
  @_inlineable // FIXME(sil-serialize-all)
  @available(swift, deprecated: 3.1, obsoleted: 4.0, message: "Please use the `abs(_:)` free function")
  @_transparent
  public static func abs(_ x: Float) -> Float {
    return x.magnitude
  }
}



/// A double-precision, floating-point value type.
@_fixed_layout
public struct Double {
  public // @testable
  var _value: Builtin.FPIEEE64

  /// Creates a value initialized to zero.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init() {
    let zero: Int64 = 0
    self._value = Builtin.sitofp_Int64_FPIEEE64(zero._value)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public // @testable
  init(_bits v: Builtin.FPIEEE64) {
    self._value = v
  }
}

extension Double : CustomStringConvertible {
  /// A textual representation of the value.
  @_inlineable // FIXME(sil-serialize-all)
  public var description: String {
    return _float64ToString(self, debug: false)
  }
}

extension Double : CustomDebugStringConvertible {
  /// A textual representation of the value, suitable for debugging.
  @_inlineable // FIXME(sil-serialize-all)
  public var debugDescription: String {
    return _float64ToString(self, debug: true)
  }
}

extension Double: BinaryFloatingPoint {

  /// A type that can represent the absolute value of any possible value of
  /// this type.
  public typealias Magnitude = Double

  /// A type that can represent any written exponent.
  public typealias Exponent = Int

  /// A type that represents the encoded significand of a value.
  public typealias RawSignificand = UInt64

  /// The number of bits used to represent the type's exponent.
  ///
  /// A binary floating-point type's `exponentBitCount` imposes a limit on the
  /// range of the exponent for normal, finite values. The *exponent bias* of
  /// a type `F` can be calculated as the following, where `**` is
  /// exponentiation:
  ///
  ///     let bias = 2 ** (F.exponentBitCount - 1) - 1
  ///
  /// The least normal exponent for values of the type `F` is `1 - bias`, and
  /// the largest finite exponent is `bias`. An all-zeros exponent is reserved
  /// for subnormals and zeros, and an all-ones exponent is reserved for
  /// infinity and NaN.
  ///
  /// For example, the `Float` type has an `exponentBitCount` of 8, which gives
  /// an exponent bias of `127` by the calculation above.
  ///
  ///     let bias = 2 ** (Float.exponentBitCount - 1) - 1
  ///     // bias == 127
  ///     print(Float.greatestFiniteMagnitude.exponent)
  ///     // Prints "127"
  ///     print(Float.leastNormalMagnitude.exponent)
  ///     // Prints "-126"
  @_inlineable // FIXME(sil-serialize-all)
  public static var exponentBitCount: Int {
    return 11
  }

  /// The available number of fractional significand bits.
  ///
  /// For fixed-width floating-point types, this is the actual number of
  /// fractional significand bits.
  ///
  /// For extensible floating-point types, `significandBitCount` should be the
  /// maximum allowed significand width (without counting any leading integral
  /// bit of the significand). If there is no upper limit, then
  /// `significandBitCount` should be `Int.max`.
  @_inlineable // FIXME(sil-serialize-all)
  public static var significandBitCount: Int {
    return 52
  }

  //  Implementation details.
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  internal static var _infinityExponent: UInt {
    @inline(__always) get { return 1 &<< UInt(exponentBitCount) - 1 }
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal static var _exponentBias: UInt {
    @inline(__always) get { return _infinityExponent &>> 1 }
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal static var _significandMask: UInt64 {
    @inline(__always) get {
      return 1 &<< UInt64(significandBitCount) - 1
    }
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  internal static var _quietNaNMask: UInt64 {
    @inline(__always) get {
      return 1 &<< UInt64(significandBitCount - 1)
    }
  }

  //  Conversions to/from integer encoding.  These are not part of the
  //  BinaryFloatingPoint prototype because there's no guarantee that an
  //  integer type of the same size actually exists (e.g. Float80).
  //
  //  If we want them in a protocol at some future point, that protocol should
  //  be "InterchangeFloatingPoint" or "PortableFloatingPoint" or similar, and
  //  apply to IEEE 754 "interchange types".
  /// The bit pattern of the value's encoding.
  ///
  /// The bit pattern matches the binary interchange format defined by the
  /// [IEEE 754 specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  @_inlineable // FIXME(sil-serialize-all)
  public var bitPattern: UInt64 {
    return UInt64(Builtin.bitcast_FPIEEE64_Int64(_value))
  }

  /// Creates a new value with the given bit pattern.
  ///
  /// The value passed as `bitPattern` is interpreted in the binary interchange
  /// format defined by the [IEEE 754 specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  ///
  /// - Parameter bitPattern: The integer encoding of a `Double` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public init(bitPattern: UInt64) {
    self.init(_bits: Builtin.bitcast_Int64_FPIEEE64(bitPattern._value))
  }

  /// The sign of the floating-point value.
  ///
  /// The `sign` property is `.minus` if the value's signbit is set, and
  /// `.plus` otherwise. For example:
  ///
  ///     let x = -33.375
  ///     // x.sign == .minus
  ///
  /// Do not use this property to check whether a floating point value is
  /// negative. For a value `x`, the comparison `x.sign == .minus` is not
  /// necessarily the same as `x < 0`. In particular, `x.sign == .minus` if
  /// `x` is -0, and while `x < 0` is always `false` if `x` is NaN, `x.sign`
  /// could be either `.plus` or `.minus`.
  @_inlineable // FIXME(sil-serialize-all)
  public var sign: FloatingPointSign {
    let shift = Double.significandBitCount + Double.exponentBitCount
    return FloatingPointSign(rawValue: Int(bitPattern &>> UInt64(shift)))!
  }

  @available(*, unavailable, renamed: "sign")
  public var isSignMinus: Bool { Builtin.unreachable() }

  /// The raw encoding of the value's exponent field.
  ///
  /// This value is unadjusted by the type's exponent bias.
  @_inlineable // FIXME(sil-serialize-all)
  public var exponentBitPattern: UInt {
    return UInt(bitPattern &>> UInt64(Double.significandBitCount)) &
      Double._infinityExponent
  }

  /// The raw encoding of the value's significand field.
  ///
  /// The `significandBitPattern` property does not include the leading
  /// integral bit of the significand, even for types like `Float80` that
  /// store it explicitly.
  @_inlineable // FIXME(sil-serialize-all)
  public var significandBitPattern: UInt64 {
    return UInt64(bitPattern) & Double._significandMask
  }

  /// Creates a new instance from the specified sign and bit patterns.
  ///
  /// The values passed as `exponentBitPattern` and `significandBitPattern` are
  /// interpreted in the binary interchange format defined by the [IEEE 754
  /// specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  ///
  /// - Parameters:
  ///   - sign: The sign of the new value.
  ///   - exponentBitPattern: The bit pattern to use for the exponent field of
  ///     the new value.
  ///   - significandBitPattern: The bit pattern to use for the significand
  ///     field of the new value.
  @_inlineable // FIXME(sil-serialize-all)
  public init(sign: FloatingPointSign,
              exponentBitPattern: UInt,
              significandBitPattern: UInt64) {
    let signShift = Double.significandBitCount + Double.exponentBitCount
    let sign = UInt64(sign == .minus ? 1 : 0)
    let exponent = UInt64(
      exponentBitPattern & Double._infinityExponent)
    let significand = UInt64(
      significandBitPattern & Double._significandMask)
    self.init(bitPattern:
      sign &<< UInt64(signShift) |
      exponent &<< UInt64(Double.significandBitCount) |
      significand)
  }

  /// A Boolean value indicating whether the instance's representation is in
  /// the canonical form.
  ///
  /// The [IEEE 754 specification][spec] defines a *canonical*, or preferred,
  /// encoding of a floating-point value's representation. Every `Float` or
  /// `Double` value is canonical, but noncanonical values of the `Float80`
  /// type exist, and noncanonical values may exist for other types that
  /// conform to the `FloatingPoint` protocol.
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  @_inlineable // FIXME(sil-serialize-all)
  public var isCanonical: Bool {
    return true
  }

  /// Positive infinity.
  ///
  /// Infinity compares greater than all finite numbers and equal to other
  /// infinite values.
  ///
  ///     let x = Double.greatestFiniteMagnitude
  ///     let y = x * 2
  ///     // y == Double.infinity
  ///     // y > x
  @_inlineable // FIXME(sil-serialize-all)
  public static var infinity: Double {
    return Double(sign: .plus,
      exponentBitPattern: _infinityExponent,
      significandBitPattern: 0)
  }

  /// A quiet NaN ("not a number").
  ///
  /// A NaN compares not equal, not greater than, and not less than every
  /// value, including itself. Passing a NaN to an operation generally results
  /// in NaN.
  ///
  ///     let x = 1.21
  ///     // x > Double.nan == false
  ///     // x < Double.nan == false
  ///     // x == Double.nan == false
  ///
  /// Because a NaN always compares not equal to itself, to test whether a
  /// floating-point value is NaN, use its `isNaN` property instead of the
  /// equal-to operator (`==`). In the following example, `y` is NaN.
  ///
  ///     let y = x + Double.nan
  ///     print(y == Double.nan)
  ///     // Prints "false"
  ///     print(y.isNaN)
  ///     // Prints "true"
  @_inlineable // FIXME(sil-serialize-all)
  public static var nan: Double {
    return Double(nan: 0, signaling: false)
  }

  /// A signaling NaN ("not a number").
  ///
  /// The default IEEE 754 behavior of operations involving a signaling NaN is
  /// to raise the Invalid flag in the floating-point environment and return a
  /// quiet NaN.
  ///
  /// Operations on types conforming to the `FloatingPoint` protocol should
  /// support this behavior, but they might also support other options. For
  /// example, it would be reasonable to implement alternative operations in
  /// which operating on a signaling NaN triggers a runtime error or results
  /// in a diagnostic for debugging purposes. Types that implement alternative
  /// behaviors for a signaling NaN must document the departure.
  ///
  /// Other than these signaling operations, a signaling NaN behaves in the
  /// same manner as a quiet NaN.
  @_inlineable // FIXME(sil-serialize-all)
  public static var signalingNaN: Double {
    return Double(nan: 0, signaling: true)
  }

  @available(*, unavailable, renamed: "nan")
  public static var quietNaN: Double { Builtin.unreachable()}

  /// The greatest finite number representable by this type.
  ///
  /// This value compares greater than or equal to all finite numbers, but less
  /// than `infinity`.
  ///
  /// This value corresponds to type-specific C macros such as `FLT_MAX` and
  /// `DBL_MAX`. The naming of those macros is slightly misleading, because
  /// `infinity` is greater than this value.
  @_inlineable // FIXME(sil-serialize-all)
  public static var greatestFiniteMagnitude: Double {
    return Double(sign: .plus,
      exponentBitPattern: _infinityExponent - 1,
      significandBitPattern: _significandMask)
  }

  /// The mathematical constant pi.
  ///
  /// This value should be rounded toward zero to keep user computations with
  /// angles from inadvertently ending up in the wrong quadrant. A type that
  /// conforms to the `FloatingPoint` protocol provides the value for `pi` at
  /// its best possible precision.
  ///
  ///     print(Double.pi)
  ///     // Prints "3.14159265358979"
  @_inlineable // FIXME(sil-serialize-all)
  public static var pi: Double {
    return 0x1.921fb54442d18p1
  }

  /// The unit in the last place of this value.
  ///
  /// This is the unit of the least significant digit in this value's
  /// significand. For most numbers `x`, this is the difference between `x`
  /// and the next greater (in magnitude) representable number. There are some
  /// edge cases to be aware of:
  ///
  /// - If `x` is not a finite number, then `x.ulp` is NaN.
  /// - If `x` is very small in magnitude, then `x.ulp` may be a subnormal
  ///   number. If a type does not support subnormals, `x.ulp` may be rounded
  ///   to zero.
  /// - `greatestFiniteMagnitude.ulp` is a finite number, even though the next
  ///   greater representable value is `infinity`.
  ///
  /// This quantity, or a related quantity, is sometimes called *epsilon* or
  /// *machine epsilon.* Avoid that name because it has different meanings in
  /// different languages, which can lead to confusion, and because it
  /// suggests that it is a good tolerance to use for comparisons, which it
  /// almost never is.
  @_inlineable // FIXME(sil-serialize-all)
  public var ulp: Double {
    if !isFinite { return Double.nan }
    if exponentBitPattern > UInt(Double.significandBitCount) {
      // self is large enough that self.ulp is normal, so we just compute its
      // exponent and construct it with a significand of zero.
      let ulpExponent =
        exponentBitPattern - UInt(Double.significandBitCount)
      return Double(sign: .plus,
        exponentBitPattern: ulpExponent,
        significandBitPattern: 0)
    }
    if exponentBitPattern >= 1 {
      // self is normal but ulp is subnormal.
      let ulpShift = UInt64(exponentBitPattern - 1)
      return Double(sign: .plus,
        exponentBitPattern: 0,
        significandBitPattern: 1 &<< ulpShift)
    }
    return Double(sign: .plus,
      exponentBitPattern: 0,
      significandBitPattern: 1)
  }

  /// The least positive normal number.
  ///
  /// This value compares less than or equal to all positive normal numbers.
  /// There may be smaller positive numbers, but they are *subnormal*, meaning
  /// that they are represented with less precision than normal numbers.
  ///
  /// This value corresponds to type-specific C macros such as `FLT_MIN` and
  /// `DBL_MIN`. The naming of those macros is slightly misleading, because
  /// subnormals, zeros, and negative numbers are smaller than this value.
  @_inlineable // FIXME(sil-serialize-all)
  public static var leastNormalMagnitude: Double {
    return Double(sign: .plus,
      exponentBitPattern: 1,
      significandBitPattern: 0)
  }

  /// The least positive number.
  ///
  /// This value compares less than or equal to all positive numbers, but
  /// greater than zero. If the type supports subnormal values,
  /// `leastNonzeroMagnitude` is smaller than `leastNormalMagnitude`;
  /// otherwise they are equal.
  @_inlineable // FIXME(sil-serialize-all)
  public static var leastNonzeroMagnitude: Double {
#if arch(arm)
    return leastNormalMagnitude
#else
    return Double(sign: .plus,
      exponentBitPattern: 0,
      significandBitPattern: 1)
#endif
  }

  /// The exponent of the floating-point value.
  ///
  /// The *exponent* of a floating-point value is the integer part of the
  /// logarithm of the value's magnitude. For a value `x` of a floating-point
  /// type `F`, the magnitude can be calculated as the following, where `**`
  /// is exponentiation:
  ///
  ///     let magnitude = x.significand * F.radix ** x.exponent
  ///
  /// In the next example, `y` has a value of `21.5`, which is encoded as
  /// `1.34375 * 2 ** 4`. The significand of `y` is therefore 1.34375.
  ///
  ///     let y: Double = 21.5
  ///     // y.significand == 1.34375
  ///     // y.exponent == 4
  ///     // Double.radix == 2
  ///
  /// The `exponent` property has the following edge cases:
  ///
  /// - If `x` is zero, then `x.exponent` is `Int.min`.
  /// - If `x` is +/-infinity or NaN, then `x.exponent` is `Int.max`
  ///
  /// This property implements the `logB` operation defined by the [IEEE 754
  /// specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  @_inlineable // FIXME(sil-serialize-all)
  public var exponent: Int {
    if !isFinite { return .max }
    if isZero { return .min }
    let provisional = Int(exponentBitPattern) - Int(Double._exponentBias)
    if isNormal { return provisional }
    let shift = Double.significandBitCount - significandBitPattern.signBitIndex
    return provisional + 1 - Int(shift)
  }

  /// The significand of the floating-point value.
  ///
  /// The magnitude of a floating-point value `x` of type `F` can be calculated
  /// by using the following formula, where `**` is exponentiation:
  ///
  ///     let magnitude = x.significand * F.radix ** x.exponent
  ///
  /// In the next example, `y` has a value of `21.5`, which is encoded as
  /// `1.34375 * 2 ** 4`. The significand of `y` is therefore 1.34375.
  ///
  ///     let y: Double = 21.5
  ///     // y.significand == 1.34375
  ///     // y.exponent == 4
  ///     // Double.radix == 2
  ///
  /// If a type's radix is 2, then for finite nonzero numbers, the significand
  /// is in the range `1.0 ..< 2.0`. For other values of `x`, `x.significand`
  /// is defined as follows:
  ///
  /// - If `x` is zero, then `x.significand` is 0.0.
  /// - If `x` is infinity, then `x.significand` is 1.0.
  /// - If `x` is NaN, then `x.significand` is NaN.
  /// - Note: The significand is frequently also called the *mantissa*, but
  ///   significand is the preferred terminology in the [IEEE 754
  ///   specification][spec], to allay confusion with the use of mantissa for
  ///   the fractional part of a logarithm.
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  @_inlineable // FIXME(sil-serialize-all)
  public var significand: Double {
    if isNaN { return self }
    if isNormal {
      return Double(sign: .plus,
        exponentBitPattern: Double._exponentBias,
        significandBitPattern: significandBitPattern)
    }
    if isSubnormal {
      let shift = Double.significandBitCount - significandBitPattern.signBitIndex
      return Double(sign: .plus,
        exponentBitPattern: Double._exponentBias,
        significandBitPattern: significandBitPattern &<< UInt64(shift))
    }
    // zero or infinity.
    return Double(sign: .plus,
      exponentBitPattern: exponentBitPattern,
      significandBitPattern: 0)
  }

  /// Creates a new value from the given sign, exponent, and significand.
  ///
  /// The following example uses this initializer to create a new `Double`
  /// instance. `Double` is a binary floating-point type that has a radix of
  /// `2`.
  ///
  ///     let x = Double(sign: .plus, exponent: -2, significand: 1.5)
  ///     // x == 0.375
  ///
  /// This initializer is equivalent to the following calculation, where `**`
  /// is exponentiation, computed as if by a single, correctly rounded,
  /// floating-point operation:
  ///
  ///     let sign: FloatingPointSign = .plus
  ///     let exponent = -2
  ///     let significand = 1.5
  ///     let y = (sign == .minus ? -1 : 1) * significand * Double.radix ** exponent
  ///     // y == 0.375
  ///
  /// As with any basic operation, if this value is outside the representable
  /// range of the type, overflow or underflow occurs, and zero, a subnormal
  /// value, or infinity may result. In addition, there are two other edge
  /// cases:
  ///
  /// - If the value you pass to `significand` is zero or infinite, the result
  ///   is zero or infinite, regardless of the value of `exponent`.
  /// - If the value you pass to `significand` is NaN, the result is NaN.
  ///
  /// For any floating-point value `x` of type `F`, the result of the following
  /// is equal to `x`, with the distinction that the result is canonicalized
  /// if `x` is in a noncanonical encoding:
  ///
  ///     let x0 = F(sign: x.sign, exponent: x.exponent, significand: x.significand)
  ///
  /// This initializer implements the `scaleB` operation defined by the [IEEE
  /// 754 specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  ///
  /// - Parameters:
  ///   - sign: The sign to use for the new value.
  ///   - exponent: The new value's exponent.
  ///   - significand: The new value's significand.
  @_inlineable // FIXME(sil-serialize-all)
  public init(sign: FloatingPointSign, exponent: Int, significand: Double) {
    var result = significand
    if sign == .minus { result = -result }
    if significand.isFinite && !significand.isZero {
      var clamped = exponent
      let leastNormalExponent = 1 - Int(Double._exponentBias)
      let greatestFiniteExponent = Int(Double._exponentBias)
      if clamped < leastNormalExponent {
        clamped = max(clamped, 3*leastNormalExponent)
        while clamped < leastNormalExponent {
          result  *= Double.leastNormalMagnitude
          clamped -= leastNormalExponent
        }
      }
      else if clamped > greatestFiniteExponent {
        clamped = min(clamped, 3*greatestFiniteExponent)
        let step = Double(sign: .plus,
          exponentBitPattern: Double._infinityExponent - 1,
          significandBitPattern: 0)
        while clamped > greatestFiniteExponent {
          result  *= step
          clamped -= greatestFiniteExponent
        }
      }
      let scale = Double(sign: .plus,
        exponentBitPattern: UInt(Int(Double._exponentBias) + clamped),
        significandBitPattern: 0)
      result = result * scale
    }
    self = result
  }

  /// Creates a NaN ("not a number") value with the specified payload.
  ///
  /// NaN values compare not equal to every value, including themselves. Most
  /// operations with a NaN operand produce a NaN result. Don't use the
  /// equal-to operator (`==`) to test whether a value is NaN. Instead, use
  /// the value's `isNaN` property.
  ///
  ///     let x = Double(nan: 0, signaling: false)
  ///     print(x == .nan)
  ///     // Prints "false"
  ///     print(x.isNaN)
  ///     // Prints "true"
  ///
  /// - Parameters:
  ///   - payload: The payload to use for the new NaN value.
  ///   - signaling: Pass `true` to create a signaling NaN or `false` to create
  ///     a quiet NaN.
  @_inlineable // FIXME(sil-serialize-all)
  public init(nan payload: RawSignificand, signaling: Bool) {
    // We use significandBitCount - 2 bits for NaN payload.
    _precondition(payload < (Double._quietNaNMask &>> 1),
      "NaN payload is not encodable.")
    var significand = payload
    significand |= Double._quietNaNMask &>> (signaling ? 1 : 0)
    self.init(sign: .plus,
              exponentBitPattern: Double._infinityExponent,
              significandBitPattern: significand)
  }

  /// The least representable value that compares greater than this value.
  ///
  /// For any finite value `x`, `x.nextUp` is greater than `x`. For `nan` or
  /// `infinity`, `x.nextUp` is `x` itself. The following special cases also
  /// apply:
  ///
  /// - If `x` is `-infinity`, then `x.nextUp` is `-greatestFiniteMagnitude`.
  /// - If `x` is `-leastNonzeroMagnitude`, then `x.nextUp` is `-0.0`.
  /// - If `x` is zero, then `x.nextUp` is `leastNonzeroMagnitude`.
  /// - If `x` is `greatestFiniteMagnitude`, then `x.nextUp` is `infinity`.
  @_inlineable // FIXME(sil-serialize-all)
  public var nextUp: Double {
    if isNaN { return self }
    if sign == .minus {
#if arch(arm)
      // On arm, subnormals are flushed to zero.
      if (exponentBitPattern == 1 && significandBitPattern == 0) ||
         (exponentBitPattern == 0 && significandBitPattern != 0) {
        return Double(sign: .minus,
          exponentBitPattern: 0,
          significandBitPattern: 0)
      }
#endif
      if significandBitPattern == 0 {
        if exponentBitPattern == 0 {
          return .leastNonzeroMagnitude
        }
        return Double(sign: .minus,
          exponentBitPattern: exponentBitPattern - 1,
          significandBitPattern: Double._significandMask)
      }
      return Double(sign: .minus,
        exponentBitPattern: exponentBitPattern,
        significandBitPattern: significandBitPattern - 1)
    }
    if isInfinite { return self }
    if significandBitPattern == Double._significandMask {
      return Double(sign: .plus,
        exponentBitPattern: exponentBitPattern + 1,
        significandBitPattern: 0)
    }
#if arch(arm)
    // On arm, subnormals are skipped.
    if exponentBitPattern == 0 {
      return .leastNonzeroMagnitude
    }
#endif
    return Double(sign: .plus,
      exponentBitPattern: exponentBitPattern,
      significandBitPattern: significandBitPattern + 1)
  }

  /// Rounds the value to an integral value using the specified rounding rule.
  ///
  /// The following example rounds a value using four different rounding rules:
  ///
  ///     // Equivalent to the C 'round' function:
  ///     var w = 6.5
  ///     w.round(.toNearestOrAwayFromZero)
  ///     // w == 7.0
  ///
  ///     // Equivalent to the C 'trunc' function:
  ///     var x = 6.5
  ///     x.round(.towardZero)
  ///     // x == 6.0
  ///
  ///     // Equivalent to the C 'ceil' function:
  ///     var y = 6.5
  ///     y.round(.up)
  ///     // y == 7.0
  ///
  ///     // Equivalent to the C 'floor' function:
  ///     var z = 6.5
  ///     z.round(.down)
  ///     // z == 6.0
  ///
  /// For more information about the available rounding rules, see the
  /// `FloatingPointRoundingRule` enumeration. To round a value using the
  /// default "schoolbook rounding", you can use the shorter `round()` method
  /// instead.
  ///
  ///     var w1 = 6.5
  ///     w1.round()
  ///     // w1 == 7.0
  ///
  /// - Parameter rule: The rounding rule to use.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func round(_ rule: FloatingPointRoundingRule) {
    switch rule {
    case .toNearestOrAwayFromZero:
      _value = Builtin.int_round_FPIEEE64(_value)
    case .toNearestOrEven:
      _value = Builtin.int_rint_FPIEEE64(_value)
    case .towardZero:
      _value = Builtin.int_trunc_FPIEEE64(_value)
    case .awayFromZero:
      if sign == .minus {
        _value = Builtin.int_floor_FPIEEE64(_value)
      }
      else {
        _value = Builtin.int_ceil_FPIEEE64(_value)
      }
    case .up:
      _value = Builtin.int_ceil_FPIEEE64(_value)
    case .down:
      _value = Builtin.int_floor_FPIEEE64(_value)
    }
  }

  /// Replaces this value with its additive inverse.
  ///
  /// The result is always exact. This example uses the `negate()` method to
  /// negate the value of the variable `x`:
  ///
  ///     var x = 21.5
  ///     x.negate()
  ///     // x == -21.5
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func negate() {
    _value = Builtin.fneg_FPIEEE64(self._value)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func +=(_ lhs: inout Double, _ rhs: Double) {
    lhs._value = Builtin.fadd_FPIEEE64(lhs._value, rhs._value)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func -=(_ lhs: inout Double, _ rhs: Double) {
    lhs._value = Builtin.fsub_FPIEEE64(lhs._value, rhs._value)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func *=(_ lhs: inout Double, _ rhs: Double) {
    lhs._value = Builtin.fmul_FPIEEE64(lhs._value, rhs._value)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func /=(_ lhs: inout Double, _ rhs: Double) {
    lhs._value = Builtin.fdiv_FPIEEE64(lhs._value, rhs._value)
  }

  /// Replaces this value with the remainder of itself divided by the given
  /// value.
  ///
  /// For two finite values `x` and `y`, the remainder `r` of dividing `x` by
  /// `y` satisfies `x == y * q + r`, where `q` is the integer nearest to
  /// `x / y`. If `x / y` is exactly halfway between two integers, `q` is
  /// chosen to be even. Note that `q` is *not* `x / y` computed in
  /// floating-point arithmetic, and that `q` may not be representable in any
  /// available integer type.
  ///
  /// The following example calculates the remainder of dividing 8.625 by 0.75:
  ///
  ///     var x = 8.625
  ///     print(x / 0.75)
  ///     // Prints "11.5"
  ///
  ///     let q = (x / 0.75).rounded(.toNearestOrEven)
  ///     // q == 12.0
  ///     x.formRemainder(dividingBy: 0.75)
  ///     // x == -0.375
  ///
  ///     let x1 = 0.75 * q + x
  ///     // x1 == 8.625
  ///
  /// If this value and `other` are finite numbers, the remainder is in the
  /// closed range `-abs(other / 2)...abs(other / 2)`. The
  /// `formRemainder(dividingBy:)` method is always exact.
  ///
  /// - Parameter other: The value to use when dividing this value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func formRemainder(dividingBy other: Double) {
    self = _stdlib_remainder(self, other)
  }

  /// Replaces this value with the remainder of itself divided by the given
  /// value using truncating division.
  ///
  /// Performing truncating division with floating-point values results in a
  /// truncated integer quotient and a remainder. For values `x` and `y` and
  /// their truncated integer quotient `q`, the remainder `r` satisfies
  /// `x == y * q + r`.
  ///
  /// The following example calculates the truncating remainder of dividing
  /// 8.625 by 0.75:
  ///
  ///     var x = 8.625
  ///     print(x / 0.75)
  ///     // Prints "11.5"
  ///
  ///     let q = (x / 0.75).rounded(.towardZero)
  ///     // q == 11.0
  ///     x.formTruncatingRemainder(dividingBy: 0.75)
  ///     // x == 0.375
  ///
  ///     let x1 = 0.75 * q + x
  ///     // x1 == 8.625
  ///
  /// If this value and `other` are both finite numbers, the truncating
  /// remainder has the same sign as this value and is strictly smaller in
  /// magnitude than `other`. The `formTruncatingRemainder(dividingBy:)`
  /// method is always exact.
  ///
  /// - Parameter other: The value to use when dividing this value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func formTruncatingRemainder(dividingBy other: Double) {
    _value = Builtin.frem_FPIEEE64(self._value, other._value)
  }

  /// Replaces this value with its square root, rounded to a representable
  /// value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func formSquareRoot( ) {
    self = _stdlib_squareRoot(self)
  }

  /// Adds the product of the two given values to this value in place, computed
  /// without intermediate rounding.
  ///
  /// - Parameters:
  ///   - lhs: One of the values to multiply before adding to this value.
  ///   - rhs: The other value to multiply.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func addProduct(_ lhs: Double, _ rhs: Double) {
    _value = Builtin.int_fma_FPIEEE64(lhs._value, rhs._value, _value)
  }

  /// Returns a Boolean value indicating whether this instance is equal to the
  /// given value.
  ///
  /// This method serves as the basis for the equal-to operator (`==`) for
  /// floating-point values. When comparing two values with this method, `-0`
  /// is equal to `+0`. NaN is not equal to any value, including itself. For
  /// example:
  ///
  ///     let x = 15.0
  ///     x.isEqual(to: 15.0)
  ///     // true
  ///     x.isEqual(to: .nan)
  ///     // false
  ///     Double.nan.isEqual(to: .nan)
  ///     // false
  ///
  /// The `isEqual(to:)` method implements the equality predicate defined by
  /// the [IEEE 754 specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  ///
  /// - Parameter other: The value to compare with this value.
  /// - Returns: `true` if `other` has the same value as this instance;
  ///   otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func isEqual(to other: Double) -> Bool {
    return Bool(Builtin.fcmp_oeq_FPIEEE64(self._value, other._value))
  }

  /// Returns a Boolean value indicating whether this instance is less than the
  /// given value.
  ///
  /// This method serves as the basis for the less-than operator (`<`) for
  /// floating-point values. Some special cases apply:
  ///
  /// - Because NaN compares not less than nor greater than any value, this
  ///   method returns `false` when called on NaN or when NaN is passed as
  ///   `other`.
  /// - `-infinity` compares less than all values except for itself and NaN.
  /// - Every value except for NaN and `+infinity` compares less than
  ///   `+infinity`.
  ///
  ///     let x = 15.0
  ///     x.isLess(than: 20.0)
  ///     // true
  ///     x.isLess(than: .nan)
  ///     // false
  ///     Double.nan.isLess(than: x)
  ///     // false
  ///
  /// The `isLess(than:)` method implements the less-than predicate defined by
  /// the [IEEE 754 specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  ///
  /// - Parameter other: The value to compare with this value.
  /// - Returns: `true` if `other` is less than this value; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func isLess(than other: Double) -> Bool {
    return Bool(Builtin.fcmp_olt_FPIEEE64(self._value, other._value))
  }

  /// Returns a Boolean value indicating whether this instance is less than or
  /// equal to the given value.
  ///
  /// This method serves as the basis for the less-than-or-equal-to operator
  /// (`<=`) for floating-point values. Some special cases apply:
  ///
  /// - Because NaN is incomparable with any value, this method returns `false`
  ///   when called on NaN or when NaN is passed as `other`.
  /// - `-infinity` compares less than or equal to all values except NaN.
  /// - Every value except NaN compares less than or equal to `+infinity`.
  ///
  ///     let x = 15.0
  ///     x.isLessThanOrEqualTo(20.0)
  ///     // true
  ///     x.isLessThanOrEqualTo(.nan)
  ///     // false
  ///     Double.nan.isLessThanOrEqualTo(x)
  ///     // false
  ///
  /// The `isLessThanOrEqualTo(_:)` method implements the less-than-or-equal
  /// predicate defined by the [IEEE 754 specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  ///
  /// - Parameter other: The value to compare with this value.
  /// - Returns: `true` if `other` is less than this value; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func isLessThanOrEqualTo(_ other: Double) -> Bool {
    return Bool(Builtin.fcmp_ole_FPIEEE64(self._value, other._value))
  }

  /// A Boolean value indicating whether this instance is normal.
  ///
  /// A *normal* value is a finite number that uses the full precision
  /// available to values of a type. Zero is neither a normal nor a subnormal
  /// number.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isNormal: Bool {
    return exponentBitPattern > 0 && isFinite
  }

  /// A Boolean value indicating whether this instance is finite.
  ///
  /// All values other than NaN and infinity are considered finite, whether
  /// normal or subnormal.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isFinite: Bool {
    return exponentBitPattern < Double._infinityExponent
  }

  /// A Boolean value indicating whether the instance is equal to zero.
  ///
  /// The `isZero` property of a value `x` is `true` when `x` represents either
  /// `-0.0` or `+0.0`. `x.isZero` is equivalent to the following comparison:
  /// `x == 0.0`.
  ///
  ///     let x = -0.0
  ///     x.isZero        // true
  ///     x == 0.0        // true
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isZero: Bool {
    return exponentBitPattern == 0 && significandBitPattern == 0
  }

  /// A Boolean value indicating whether the instance is subnormal.
  ///
  /// A *subnormal* value is a nonzero number that has a lesser magnitude than
  /// the smallest normal number. Subnormal values do not use the full
  /// precision available to values of a type.
  ///
  /// Zero is neither a normal nor a subnormal number. Subnormal numbers are
  /// often called *denormal* or *denormalized*---these are different names
  /// for the same concept.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isSubnormal:  Bool {
    return exponentBitPattern == 0 && significandBitPattern != 0
  }

  /// A Boolean value indicating whether the instance is infinite.
  ///
  /// Note that `isFinite` and `isInfinite` do not form a dichotomy, because
  /// they are not total: If `x` is `NaN`, then both properties are `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isInfinite:  Bool {
    return !isFinite && significandBitPattern == 0
  }

  /// A Boolean value indicating whether the instance is NaN ("not a number").
  ///
  /// Because NaN is not equal to any value, including NaN, use this property
  /// instead of the equal-to operator (`==`) or not-equal-to operator (`!=`)
  /// to test whether a value is or is not NaN. For example:
  ///
  ///     let x = 0.0
  ///     let y = x * .infinity
  ///     // y is a NaN
  ///
  ///     // Comparing with the equal-to operator never returns 'true'
  ///     print(x == Double.nan)
  ///     // Prints "false"
  ///     print(y == Double.nan)
  ///     // Prints "false"
  ///
  ///     // Test with the 'isNaN' property instead
  ///     print(x.isNaN)
  ///     // Prints "false"
  ///     print(y.isNaN)
  ///     // Prints "true"
  ///
  /// This property is `true` for both quiet and signaling NaNs.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isNaN:  Bool {
    return !isFinite && significandBitPattern != 0
  }

  /// A Boolean value indicating whether the instance is a signaling NaN.
  ///
  /// Signaling NaNs typically raise the Invalid flag when used in general
  /// computing operations.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isSignalingNaN: Bool {
    return isNaN && (significandBitPattern & Double._quietNaNMask) == 0
  }

  /// The floating-point value with the same sign and exponent as this value,
  /// but with a significand of 1.0.
  ///
  /// A *binade* is a set of binary floating-point values that all have the
  /// same sign and exponent. The `binade` property is a member of the same
  /// binade as this value, but with a unit significand.
  ///
  /// In this example, `x` has a value of `21.5`, which is stored as
  /// `1.34375 * 2**4`, where `**` is exponentiation. Therefore, `x.binade` is
  /// equal to `1.0 * 2**4`, or `16.0`.
  ///
  ///     let x = 21.5
  ///     // x.significand == 1.34375
  ///     // x.exponent == 4
  ///
  ///     let y = x.binade
  ///     // y == 16.0
  ///     // y.significand == 1.0
  ///     // y.exponent == 4
  @_inlineable // FIXME(sil-serialize-all)
  public var binade: Double {
    if !isFinite { return .nan }
    if exponentBitPattern != 0 {
      return Double(sign: sign, exponentBitPattern: exponentBitPattern,
        significandBitPattern: 0)
    }
    if significandBitPattern == 0 { return self }
    // For subnormals, we isolate the leading significand bit.
    let index = significandBitPattern.signBitIndex
    return Double(sign: sign, exponentBitPattern: 0,
      significandBitPattern: 1 &<< RawSignificand(index))
  }

  /// The number of bits required to represent the value's significand.
  ///
  /// If this value is a finite nonzero number, `significandWidth` is the
  /// number of fractional bits required to represent the value of
  /// `significand`; otherwise, `significandWidth` is -1. The value of
  /// `significandWidth` is always -1 or between zero and
  /// `significandBitCount`. For example:
  ///
  /// - For any representable power of two, `significandWidth` is zero, because
  ///   `significand` is `1.0`.
  /// - If `x` is 10, `x.significand` is `1.01` in binary, so
  ///   `x.significandWidth` is 2.
  /// - If `x` is Float.pi, `x.significand` is `1.10010010000111111011011` in
  ///   binary, and `x.significandWidth` is 23.
  @_inlineable // FIXME(sil-serialize-all)
  public var significandWidth: Int {
    let trailingZeroBits = significandBitPattern.trailingZeroBitCount
    if isNormal {
      guard significandBitPattern != 0 else { return 0 }
      return Double.significandBitCount - trailingZeroBits
    }
    if isSubnormal {
      return significandBitPattern.signBitIndex - trailingZeroBits
    }
    return -1
  }

  /// Creates a new value from the given floating-point literal.
  ///
  /// Do not call this initializer directly. It is used by the compiler when
  /// you create a new `Double` instance by using a floating-point literal.
  /// Instead, create a new value by using a literal.
  ///
  /// In this example, the assignment to the `x` constant calls this
  /// initializer behind the scenes.
  ///
  ///     let x: Double = 21.25
  ///     // x == 21.25
  ///
  /// - Parameter value: The new floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(floatLiteral value: Double) {
    self = value
  }
}

extension Double : _ExpressibleByBuiltinIntegerLiteral, ExpressibleByIntegerLiteral {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public
  init(_builtinIntegerLiteral value: Builtin.Int2048){
    self = Double(_bits: Builtin.itofp_with_overflow_Int2048_FPIEEE64(value))
  }

  /// Creates a new value from the given integer literal.
  ///
  /// Do not call this initializer directly. It is used by the compiler when
  /// you create a new `Double` instance by using an integer literal.
  /// Instead, create a new value by using a literal.
  ///
  /// In this example, the assignment to the `x` constant calls this
  /// initializer behind the scenes.
  ///
  ///     let x: Double = 100
  ///     // x == 100.0
  ///
  /// - Parameter value: The new value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(integerLiteral value: Int64) {
    self = Double(_bits: Builtin.sitofp_Int64_FPIEEE64(value._value))
  }
}

#if !os(Windows) && (arch(i386) || arch(x86_64))

extension Double : _ExpressibleByBuiltinFloatLiteral {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public
  init(_builtinFloatLiteral value: Builtin.FPIEEE80) {
    self = Double(_bits: Builtin.fptrunc_FPIEEE80_FPIEEE64(value))
  }
}

#else

extension Double : _ExpressibleByBuiltinFloatLiteral {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public
  init(_builtinFloatLiteral value: Builtin.FPIEEE64) {
    self = Double(_bits: value)
  }
}

#endif

extension Double : Hashable {
  /// The number's hash value.
  ///
  /// Hash values are not guaranteed to be equal across different executions of
  /// your program. Do not save hash values to use during a future execution.
  @_inlineable // FIXME(sil-serialize-all)
  public var hashValue: Int {
    if isZero {
      // To satisfy the axiom that equality implies hash equality, we need to
      // finesse the hash value of -0.0 to match +0.0.
      return 0
    } else {
      return Int(bitPattern: UInt(bitPattern))
    }
  }
}

extension Double {
  /// The magnitude of this value.
  ///
  /// For any value `x`, `x.magnitude.sign` is `.plus`. If `x` is not NaN,
  /// `x.magnitude` is the absolute value of `x`.
  ///
  /// The global `abs(_:)` function provides more familiar syntax when you need
  /// to find an absolute value. In addition, because `abs(_:)` always returns
  /// a value of the same type, even in a generic context, using the function
  /// instead of the `magnitude` property is encouraged.
  ///
  ///     let targetDistance: Double = 5.25
  ///     let throwDistance: Double = 5.5
  ///
  ///     let margin = targetDistance - throwDistance
  ///     // margin == -0.25
  ///     // margin.magnitude == 0.25
  ///
  ///     // Use 'abs(_:)' instead of 'magnitude'
  ///     print("Missed the target by \(abs(margin)) meters.")
  ///     // Prints "Missed the target by 0.25 meters."
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var magnitude: Double {
    return Double(_bits: Builtin.int_fabs_FPIEEE64(_value))
  }

  // FIXME(integers): implement properly
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter source: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  public init?<T : BinaryInteger>(exactly source: T) {
    fatalError()
  }
}

extension Double {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static prefix func - (x: Double) -> Double {
    return Double(_bits: Builtin.fneg_FPIEEE64(x._value))
  }
}

//===----------------------------------------------------------------------===//
// Explicit conversions between types.
//===----------------------------------------------------------------------===//

// Construction from integers.
extension Double {

  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: UInt8) {
    _value = Builtin.uitofp_Int8_FPIEEE64(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @available(*, message: "Converting UInt8 to Double will always succeed.")
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: UInt8) {
    _value = Builtin.uitofp_Int8_FPIEEE64(value._value)

  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: Int8) {
    _value = Builtin.sitofp_Int8_FPIEEE64(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @available(*, message: "Converting Int8 to Double will always succeed.")
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: Int8) {
    _value = Builtin.sitofp_Int8_FPIEEE64(value._value)

  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: UInt16) {
    _value = Builtin.uitofp_Int16_FPIEEE64(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @available(*, message: "Converting UInt16 to Double will always succeed.")
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: UInt16) {
    _value = Builtin.uitofp_Int16_FPIEEE64(value._value)

  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: Int16) {
    _value = Builtin.sitofp_Int16_FPIEEE64(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @available(*, message: "Converting Int16 to Double will always succeed.")
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: Int16) {
    _value = Builtin.sitofp_Int16_FPIEEE64(value._value)

  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: UInt32) {
    _value = Builtin.uitofp_Int32_FPIEEE64(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @available(*, message: "Converting UInt32 to Double will always succeed.")
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: UInt32) {
    _value = Builtin.uitofp_Int32_FPIEEE64(value._value)

  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: Int32) {
    _value = Builtin.sitofp_Int32_FPIEEE64(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @available(*, message: "Converting Int32 to Double will always succeed.")
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: Int32) {
    _value = Builtin.sitofp_Int32_FPIEEE64(value._value)

  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: UInt64) {
    _value = Builtin.uitofp_Int64_FPIEEE64(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: UInt64) {
    _value = Builtin.uitofp_Int64_FPIEEE64(value._value)

    guard let roundTrip = UInt64(exactly: self),
      roundTrip == value else {
      return nil
    }
  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: Int64) {
    _value = Builtin.sitofp_Int64_FPIEEE64(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: Int64) {
    _value = Builtin.sitofp_Int64_FPIEEE64(value._value)

    guard let roundTrip = Int64(exactly: self),
      roundTrip == value else {
      return nil
    }
  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: UInt) {
    _value = Builtin.uitofp_Int64_FPIEEE64(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: UInt) {
    _value = Builtin.uitofp_Int64_FPIEEE64(value._value)

    guard let roundTrip = UInt(exactly: self),
      roundTrip == value else {
      return nil
    }
  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: Int) {
    _value = Builtin.sitofp_Int64_FPIEEE64(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: Int) {
    _value = Builtin.sitofp_Int64_FPIEEE64(value._value)

    guard let roundTrip = Int(exactly: self),
      roundTrip == value else {
      return nil
    }
  }
}

// Construction from other floating point numbers.
extension Double {


  /// Creates a new instance that approximates the given value.
  ///
  /// The value of `other` is rounded to a representable value, if necessary.
  /// A NaN passed as `other` results in another NaN, with a signaling NaN
  /// value converted to quiet NaN.
  ///
  ///     let x: Float = 21.25
  ///     let y = Double(x)
  ///     // y == 21.25
  ///
  ///     let z = Double(Float.nan)
  ///     // z.isNaN == true
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ other: Float) {
    _value = Builtin.fpext_FPIEEE32_FPIEEE64(other._value)
  }

  /// Creates a new instance initialized to the given value, if it can be
  /// represented without rounding.
  ///
  /// If `other` can't be represented as an instance of `Double` without
  /// rounding, the result of this initializer is `nil`. In particular,
  /// passing NaN as `other` always results in `nil`.
  ///
  ///     let x: Float = 21.25
  ///     let y = Double(exactly: x)
  ///     // y == Optional.some(21.25)
  ///
  ///     let z = Double(exactly: Float.nan)
  ///     // z == nil
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly other: Float) {
    self.init(other)
    // Converting the infinity value is considered value preserving.
    // In other cases, check that we can round-trip and get the same value.
    // NaN always fails.
    if Float(self) != other {
      return nil
    }
  }



  /// Creates a new instance initialized to the given value.
  ///
  /// The value of `other` is represented exactly by the new instance. A NaN
  /// passed as `other` results in another NaN, with a signaling NaN value
  /// converted to quiet NaN.
  ///
  ///     let x: Double = 21.25
  ///     let y = Double(x)
  ///     // y == 21.25
  ///
  ///     let z = Double(Double.nan)
  ///     // z.isNaN == true
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ other: Double) {
    _value = other._value
  }

  /// Creates a new instance initialized to the given value, if it can be
  /// represented without rounding.
  ///
  /// If `other` can't be represented as an instance of `Double` without
  /// rounding, the result of this initializer is `nil`. In particular,
  /// passing NaN as `other` always results in `nil`.
  ///
  ///     let x: Double = 21.25
  ///     let y = Double(exactly: x)
  ///     // y == Optional.some(21.25)
  ///
  ///     let z = Double(exactly: Double.nan)
  ///     // z == nil
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly other: Double) {
    self.init(other)
    // Converting the infinity value is considered value preserving.
    // In other cases, check that we can round-trip and get the same value.
    // NaN always fails.
    if Double(self) != other {
      return nil
    }
  }


#if !os(Windows) && (arch(i386) || arch(x86_64))

  /// Creates a new instance that approximates the given value.
  ///
  /// The value of `other` is rounded to a representable value, if necessary.
  /// A NaN passed as `other` results in another NaN, with a signaling NaN
  /// value converted to quiet NaN.
  ///
  ///     let x: Float80 = 21.25
  ///     let y = Double(x)
  ///     // y == 21.25
  ///
  ///     let z = Double(Float80.nan)
  ///     // z.isNaN == true
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ other: Float80) {
    _value = Builtin.fptrunc_FPIEEE80_FPIEEE64(other._value)
  }

  /// Creates a new instance initialized to the given value, if it can be
  /// represented without rounding.
  ///
  /// If `other` can't be represented as an instance of `Double` without
  /// rounding, the result of this initializer is `nil`. In particular,
  /// passing NaN as `other` always results in `nil`.
  ///
  ///     let x: Float80 = 21.25
  ///     let y = Double(exactly: x)
  ///     // y == Optional.some(21.25)
  ///
  ///     let z = Double(exactly: Float80.nan)
  ///     // z == nil
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly other: Float80) {
    self.init(other)
    // Converting the infinity value is considered value preserving.
    // In other cases, check that we can round-trip and get the same value.
    // NaN always fails.
    if Float80(self) != other {
      return nil
    }
  }

#endif
}

//===----------------------------------------------------------------------===//
// Standard Operator Table
//===----------------------------------------------------------------------===//

//  TODO: These should not be necessary, since they're already provided by
//  <T: FloatingPoint>, but in practice they are currently needed to
//  disambiguate overloads.  We should find a way to remove them, either by
//  tweaking the overload resolution rules, or by removing the other
//  definitions in the standard lib, or both.

extension Double {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func + (lhs: Double, rhs: Double) -> Double {
    var lhs = lhs
    lhs += rhs
    return lhs
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func - (lhs: Double, rhs: Double) -> Double {
    var lhs = lhs
    lhs -= rhs
    return lhs
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func * (lhs: Double, rhs: Double) -> Double {
    var lhs = lhs
    lhs *= rhs
    return lhs
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func / (lhs: Double, rhs: Double) -> Double {
    var lhs = lhs
    lhs /= rhs
    return lhs
  }
}

//===----------------------------------------------------------------------===//
// Strideable Conformance
//===----------------------------------------------------------------------===//

extension Double : Strideable {
  /// Returns the distance from this value to the specified value.
  ///
  /// For two values `x` and `y`, the result of `x.distance(to: y)` is equal to
  /// `y - x`---a distance `d` such that `x.advanced(by: d)` approximates `y`.
  /// For example:
  ///
  ///     let x = 21.5
  ///     let d = x.distance(to: 15.0)
  ///     // d == -6.5
  ///
  ///     print(x.advanced(by: d))
  ///     // Prints "15.0"
  ///
  /// - Parameter other: A value to calculate the distance to.
  /// - Returns: The distance between this value and `other`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func distance(to other: Double) -> Double {
    return other - self
  }

  /// Returns a new value advanced by the given distance.
  ///
  /// For two values `x` and `d`, the result of a `x.advanced(by: d)` is equal
  /// to `x + d`---a new value `y` such that `x.distance(to: y)` approximates
  /// `d`. For example:
  ///
  ///     let x = 21.5
  ///     let y = x.advanced(by: -6.5)
  ///     // y == 15.0
  ///
  ///     print(x.distance(to: y))
  ///     // Prints "-6.5"
  ///
  /// - Parameter amount: The distance to advance this value.
  /// - Returns: A new value that is `amount` added to this value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func advanced(by amount: Double) -> Double {
    return self + amount
  }
}

//===----------------------------------------------------------------------===//
// Deprecated operators
//===----------------------------------------------------------------------===//

@_transparent
@available(*, unavailable, message: "use += 1")
@discardableResult
public prefix func ++ (rhs: inout Double) -> Double {
  fatalError("++ is not available")
}
@_transparent
@available(*, unavailable, message: "use -= 1")
@discardableResult
public prefix func -- (rhs: inout Double) -> Double {
  fatalError("-- is not available")
}
@_transparent
@available(*, unavailable, message: "use += 1")
@discardableResult
public postfix func ++ (lhs: inout Double) -> Double {
  fatalError("++ is not available")
}
@_transparent
@available(*, unavailable, message: "use -= 1")
@discardableResult
public postfix func -- (lhs: inout Double) -> Double {
  fatalError("-- is not available")
}

extension Double {
  @_inlineable // FIXME(sil-serialize-all)
  @available(swift, deprecated: 3.1, obsoleted: 4.0, message: "Please use the `abs(_:)` free function")
  @_transparent
  public static func abs(_ x: Double) -> Double {
    return x.magnitude
  }
}


#if !os(Windows) && (arch(i386) || arch(x86_64))

/// An extended-precision, floating-point value type.
@_fixed_layout
public struct Float80 {
  public // @testable
  var _value: Builtin.FPIEEE80

  /// Creates a value initialized to zero.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init() {
    let zero: Int64 = 0
    self._value = Builtin.sitofp_Int64_FPIEEE80(zero._value)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public // @testable
  init(_bits v: Builtin.FPIEEE80) {
    self._value = v
  }
}

extension Float80 : CustomStringConvertible {
  /// A textual representation of the value.
  @_inlineable // FIXME(sil-serialize-all)
  public var description: String {
    return _float80ToString(self, debug: false)
  }
}

extension Float80 : CustomDebugStringConvertible {
  /// A textual representation of the value, suitable for debugging.
  @_inlineable // FIXME(sil-serialize-all)
  public var debugDescription: String {
    return _float80ToString(self, debug: true)
  }
}

extension Float80: BinaryFloatingPoint {

  /// A type that can represent the absolute value of any possible value of
  /// this type.
  public typealias Magnitude = Float80

  /// A type that can represent any written exponent.
  public typealias Exponent = Int

  /// A type that represents the encoded significand of a value.
  public typealias RawSignificand = UInt64

  /// The number of bits used to represent the type's exponent.
  ///
  /// A binary floating-point type's `exponentBitCount` imposes a limit on the
  /// range of the exponent for normal, finite values. The *exponent bias* of
  /// a type `F` can be calculated as the following, where `**` is
  /// exponentiation:
  ///
  ///     let bias = 2 ** (F.exponentBitCount - 1) - 1
  ///
  /// The least normal exponent for values of the type `F` is `1 - bias`, and
  /// the largest finite exponent is `bias`. An all-zeros exponent is reserved
  /// for subnormals and zeros, and an all-ones exponent is reserved for
  /// infinity and NaN.
  ///
  /// For example, the `Float` type has an `exponentBitCount` of 8, which gives
  /// an exponent bias of `127` by the calculation above.
  ///
  ///     let bias = 2 ** (Float.exponentBitCount - 1) - 1
  ///     // bias == 127
  ///     print(Float.greatestFiniteMagnitude.exponent)
  ///     // Prints "127"
  ///     print(Float.leastNormalMagnitude.exponent)
  ///     // Prints "-126"
  @_inlineable // FIXME(sil-serialize-all)
  public static var exponentBitCount: Int {
    return 15
  }

  /// The available number of fractional significand bits.
  ///
  /// For fixed-width floating-point types, this is the actual number of
  /// fractional significand bits.
  ///
  /// For extensible floating-point types, `significandBitCount` should be the
  /// maximum allowed significand width (without counting any leading integral
  /// bit of the significand). If there is no upper limit, then
  /// `significandBitCount` should be `Int.max`.
  ///
  /// `Float80.significandBitCount` is 63, even though 64 bits are used to
  /// store the significand in the memory representation of a `Float80`
  /// instance. Unlike other floating-point types, the `Float80` type
  /// explicitly stores the leading integral significand bit.
  @_inlineable // FIXME(sil-serialize-all)
  public static var significandBitCount: Int {
    return 63
  }

  //  Implementation details.
  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  internal static var _infinityExponent: UInt {
    @inline(__always) get { return 1 &<< UInt(exponentBitCount) - 1 }
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal static var _exponentBias: UInt {
    @inline(__always) get { return _infinityExponent &>> 1 }
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal static var _significandMask: UInt64 {
    @inline(__always) get {
      return 1 &<< UInt64(significandBitCount) - 1
    }
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned
  internal static var _quietNaNMask: UInt64 {
    @inline(__always) get {
      return 1 &<< UInt64(significandBitCount - 1)
    }
  }

  // Internal implementation details of x86 Float80
  @_fixed_layout // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal struct _Float80Representation {
    @_versioned // FIXME(sil-serialize-all)
    internal var explicitSignificand: UInt64
    @_versioned // FIXME(sil-serialize-all)
    internal var signAndExponent: UInt16
    @_versioned // FIXME(sil-serialize-all)
    internal var _padding: (UInt16, UInt16, UInt16) = (0, 0, 0)
    @_inlineable // FIXME(sil-serialize-all)
    @_versioned // FIXME(sil-serialize-all)
    internal var sign: FloatingPointSign {
      return FloatingPointSign(rawValue: Int(signAndExponent &>> 15))!
    }
    @_inlineable // FIXME(sil-serialize-all)
    @_versioned // FIXME(sil-serialize-all)
    internal var exponentBitPattern: UInt {
      return UInt(signAndExponent) & 0x7fff
    }
    @_inlineable // FIXME(sil-serialize-all)
    @_versioned // FIXME(sil-serialize-all)
    internal init(explicitSignificand: UInt64, signAndExponent: UInt16) {
      self.explicitSignificand = explicitSignificand
      self.signAndExponent = signAndExponent
    }
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal var _representation: _Float80Representation {
    return unsafeBitCast(self, to: _Float80Representation.self)
  }

  /// The sign of the floating-point value.
  ///
  /// The `sign` property is `.minus` if the value's signbit is set, and
  /// `.plus` otherwise. For example:
  ///
  ///     let x = -33.375
  ///     // x.sign == .minus
  ///
  /// Do not use this property to check whether a floating point value is
  /// negative. For a value `x`, the comparison `x.sign == .minus` is not
  /// necessarily the same as `x < 0`. In particular, `x.sign == .minus` if
  /// `x` is -0, and while `x < 0` is always `false` if `x` is NaN, `x.sign`
  /// could be either `.plus` or `.minus`.
  @_inlineable // FIXME(sil-serialize-all)
  public var sign: FloatingPointSign {
    return _representation.sign
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_versioned // FIXME(sil-serialize-all)
  internal static var _explicitBitMask: UInt64 {
    @inline(__always) get { return 1 &<< 63 }
  }

  /// The raw encoding of the value's exponent field.
  ///
  /// This value is unadjusted by the type's exponent bias.
  @_inlineable // FIXME(sil-serialize-all)
  public var exponentBitPattern: UInt {
    let provisional = _representation.exponentBitPattern
    if provisional == 0 {
      if _representation.explicitSignificand >= Float80._explicitBitMask {
        //  Pseudo-denormals have an exponent of 0 but the leading bit of the
        //  significand field is set.  These are noncanonical encodings of the
        //  same significand with an exponent of 1.
        return 1
      }
      //  Exponent is zero, leading bit of significand is clear, so this is
      //  a canonical zero or subnormal number.
      return 0
    }
    if _representation.explicitSignificand < Float80._explicitBitMask {
      //  If the exponent is not-zero but the leading bit of the significand
      //  is clear, then we have an invalid operand (unnormal, pseudo-inf, or
      //  pseudo-NaN).  All of these are noncanonical encodings of NaN.
      return Float80._infinityExponent
    }
    //  We have a canonical number, so the provisional exponent is correct.
    return provisional
  }

  /// The raw encoding of the value's significand field.
  ///
  /// The `significandBitPattern` property does not include the leading
  /// integral bit of the significand, even for types like `Float80` that
  /// store it explicitly.
  @_inlineable // FIXME(sil-serialize-all)
  public var significandBitPattern: UInt64 {
    if _representation.exponentBitPattern > 0 &&
      _representation.explicitSignificand < Float80._explicitBitMask {
        //  If the exponent is nonzero and the leading bit of the significand
        //  is clear, then we have an invalid operand (unnormal, pseudo-inf, or
        //  pseudo-NaN).  All of these are noncanonical encodings of qNaN.
        return _representation.explicitSignificand | Float80._quietNaNMask
    }
    //  Otherwise we always get the "right" significand by simply clearing the
    //  integral bit.
    return _representation.explicitSignificand & Float80._significandMask
  }

  /// Creates a new instance from the specified sign and bit patterns.
  ///
  /// The values passed as `exponentBitPattern` and `significandBitPattern` are
  /// interpreted in the binary interchange format defined by the [IEEE 754
  /// specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  ///
  /// - Parameters:
  ///   - sign: The sign of the new value.
  ///   - exponentBitPattern: The bit pattern to use for the exponent field of
  ///     the new value.
  ///   - significandBitPattern: The bit pattern to use for the significand
  ///     field of the new value.
  @_inlineable // FIXME(sil-serialize-all)
  public init(sign: FloatingPointSign,
              exponentBitPattern: UInt,
              significandBitPattern: UInt64) {
    let signBit = UInt16(sign == .minus ? 0x8000 : 0)
    let exponent = UInt16(exponentBitPattern)
    var significand = significandBitPattern
    if exponent != 0 { significand |= Float80._explicitBitMask }
    let rep = _Float80Representation(explicitSignificand: significand,
      signAndExponent: signBit|exponent)
    self = unsafeBitCast(rep, to: Float80.self)
  }

  /// A Boolean value indicating whether the instance's representation is in
  /// the canonical form.
  ///
  /// The [IEEE 754 specification][spec] defines a *canonical*, or preferred,
  /// encoding of a floating-point value's representation. Every `Float` or
  /// `Double` value is canonical, but noncanonical values of the `Float80`
  /// type exist, and noncanonical values may exist for other types that
  /// conform to the `FloatingPoint` protocol.
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  @_inlineable // FIXME(sil-serialize-all)
  public var isCanonical: Bool {
    if exponentBitPattern == 0 {
      // If exponent field is zero, canonical numbers have the explicit
      // significand bit clear.
      return _representation.explicitSignificand < Float80._explicitBitMask
    }
    // If exponent is nonzero, canonical values have the explicit significand
    // bit set.
    return _representation.explicitSignificand >= Float80._explicitBitMask
  }

  /// Positive infinity.
  ///
  /// Infinity compares greater than all finite numbers and equal to other
  /// infinite values.
  ///
  ///     let x = Double.greatestFiniteMagnitude
  ///     let y = x * 2
  ///     // y == Double.infinity
  ///     // y > x
  @_inlineable // FIXME(sil-serialize-all)
  public static var infinity: Float80 {
    return Float80(sign: .plus,
      exponentBitPattern: _infinityExponent,
      significandBitPattern: 0)
  }

  /// A quiet NaN ("not a number").
  ///
  /// A NaN compares not equal, not greater than, and not less than every
  /// value, including itself. Passing a NaN to an operation generally results
  /// in NaN.
  ///
  ///     let x = 1.21
  ///     // x > Double.nan == false
  ///     // x < Double.nan == false
  ///     // x == Double.nan == false
  ///
  /// Because a NaN always compares not equal to itself, to test whether a
  /// floating-point value is NaN, use its `isNaN` property instead of the
  /// equal-to operator (`==`). In the following example, `y` is NaN.
  ///
  ///     let y = x + Double.nan
  ///     print(y == Double.nan)
  ///     // Prints "false"
  ///     print(y.isNaN)
  ///     // Prints "true"
  @_inlineable // FIXME(sil-serialize-all)
  public static var nan: Float80 {
    return Float80(nan: 0, signaling: false)
  }

  /// A signaling NaN ("not a number").
  ///
  /// The default IEEE 754 behavior of operations involving a signaling NaN is
  /// to raise the Invalid flag in the floating-point environment and return a
  /// quiet NaN.
  ///
  /// Operations on types conforming to the `FloatingPoint` protocol should
  /// support this behavior, but they might also support other options. For
  /// example, it would be reasonable to implement alternative operations in
  /// which operating on a signaling NaN triggers a runtime error or results
  /// in a diagnostic for debugging purposes. Types that implement alternative
  /// behaviors for a signaling NaN must document the departure.
  ///
  /// Other than these signaling operations, a signaling NaN behaves in the
  /// same manner as a quiet NaN.
  @_inlineable // FIXME(sil-serialize-all)
  public static var signalingNaN: Float80 {
    return Float80(nan: 0, signaling: true)
  }

  @available(*, unavailable, renamed: "nan")
  public static var quietNaN: Float80 { Builtin.unreachable()}

  /// The greatest finite number representable by this type.
  ///
  /// This value compares greater than or equal to all finite numbers, but less
  /// than `infinity`.
  ///
  /// This value corresponds to type-specific C macros such as `FLT_MAX` and
  /// `DBL_MAX`. The naming of those macros is slightly misleading, because
  /// `infinity` is greater than this value.
  @_inlineable // FIXME(sil-serialize-all)
  public static var greatestFiniteMagnitude: Float80 {
    return Float80(sign: .plus,
      exponentBitPattern: _infinityExponent - 1,
      significandBitPattern: _significandMask)
  }

  /// The mathematical constant pi.
  ///
  /// This value should be rounded toward zero to keep user computations with
  /// angles from inadvertently ending up in the wrong quadrant. A type that
  /// conforms to the `FloatingPoint` protocol provides the value for `pi` at
  /// its best possible precision.
  ///
  ///     print(Double.pi)
  ///     // Prints "3.14159265358979"
  @_inlineable // FIXME(sil-serialize-all)
  public static var pi: Float80 {
    return 0x1.921fb54442d1846ap1
  }

  /// The unit in the last place of this value.
  ///
  /// This is the unit of the least significant digit in this value's
  /// significand. For most numbers `x`, this is the difference between `x`
  /// and the next greater (in magnitude) representable number. There are some
  /// edge cases to be aware of:
  ///
  /// - If `x` is not a finite number, then `x.ulp` is NaN.
  /// - If `x` is very small in magnitude, then `x.ulp` may be a subnormal
  ///   number. If a type does not support subnormals, `x.ulp` may be rounded
  ///   to zero.
  /// - `greatestFiniteMagnitude.ulp` is a finite number, even though the next
  ///   greater representable value is `infinity`.
  ///
  /// This quantity, or a related quantity, is sometimes called *epsilon* or
  /// *machine epsilon.* Avoid that name because it has different meanings in
  /// different languages, which can lead to confusion, and because it
  /// suggests that it is a good tolerance to use for comparisons, which it
  /// almost never is.
  @_inlineable // FIXME(sil-serialize-all)
  public var ulp: Float80 {
    if !isFinite { return Float80.nan }
    if exponentBitPattern > UInt(Float80.significandBitCount) {
      // self is large enough that self.ulp is normal, so we just compute its
      // exponent and construct it with a significand of zero.
      let ulpExponent =
        exponentBitPattern - UInt(Float80.significandBitCount)
      return Float80(sign: .plus,
        exponentBitPattern: ulpExponent,
        significandBitPattern: 0)
    }
    if exponentBitPattern >= 1 {
      // self is normal but ulp is subnormal.
      let ulpShift = UInt64(exponentBitPattern - 1)
      return Float80(sign: .plus,
        exponentBitPattern: 0,
        significandBitPattern: 1 &<< ulpShift)
    }
    return Float80(sign: .plus,
      exponentBitPattern: 0,
      significandBitPattern: 1)
  }

  /// The least positive normal number.
  ///
  /// This value compares less than or equal to all positive normal numbers.
  /// There may be smaller positive numbers, but they are *subnormal*, meaning
  /// that they are represented with less precision than normal numbers.
  ///
  /// This value corresponds to type-specific C macros such as `FLT_MIN` and
  /// `DBL_MIN`. The naming of those macros is slightly misleading, because
  /// subnormals, zeros, and negative numbers are smaller than this value.
  @_inlineable // FIXME(sil-serialize-all)
  public static var leastNormalMagnitude: Float80 {
    return Float80(sign: .plus,
      exponentBitPattern: 1,
      significandBitPattern: 0)
  }

  /// The least positive number.
  ///
  /// This value compares less than or equal to all positive numbers, but
  /// greater than zero. If the type supports subnormal values,
  /// `leastNonzeroMagnitude` is smaller than `leastNormalMagnitude`;
  /// otherwise they are equal.
  @_inlineable // FIXME(sil-serialize-all)
  public static var leastNonzeroMagnitude: Float80 {
#if arch(arm)
    return leastNormalMagnitude
#else
    return Float80(sign: .plus,
      exponentBitPattern: 0,
      significandBitPattern: 1)
#endif
  }

  /// The exponent of the floating-point value.
  ///
  /// The *exponent* of a floating-point value is the integer part of the
  /// logarithm of the value's magnitude. For a value `x` of a floating-point
  /// type `F`, the magnitude can be calculated as the following, where `**`
  /// is exponentiation:
  ///
  ///     let magnitude = x.significand * F.radix ** x.exponent
  ///
  /// In the next example, `y` has a value of `21.5`, which is encoded as
  /// `1.34375 * 2 ** 4`. The significand of `y` is therefore 1.34375.
  ///
  ///     let y: Double = 21.5
  ///     // y.significand == 1.34375
  ///     // y.exponent == 4
  ///     // Double.radix == 2
  ///
  /// The `exponent` property has the following edge cases:
  ///
  /// - If `x` is zero, then `x.exponent` is `Int.min`.
  /// - If `x` is +/-infinity or NaN, then `x.exponent` is `Int.max`
  ///
  /// This property implements the `logB` operation defined by the [IEEE 754
  /// specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  @_inlineable // FIXME(sil-serialize-all)
  public var exponent: Int {
    if !isFinite { return .max }
    if isZero { return .min }
    let provisional = Int(exponentBitPattern) - Int(Float80._exponentBias)
    if isNormal { return provisional }
    let shift = Float80.significandBitCount - significandBitPattern.signBitIndex
    return provisional + 1 - Int(shift)
  }

  /// The significand of the floating-point value.
  ///
  /// The magnitude of a floating-point value `x` of type `F` can be calculated
  /// by using the following formula, where `**` is exponentiation:
  ///
  ///     let magnitude = x.significand * F.radix ** x.exponent
  ///
  /// In the next example, `y` has a value of `21.5`, which is encoded as
  /// `1.34375 * 2 ** 4`. The significand of `y` is therefore 1.34375.
  ///
  ///     let y: Double = 21.5
  ///     // y.significand == 1.34375
  ///     // y.exponent == 4
  ///     // Double.radix == 2
  ///
  /// If a type's radix is 2, then for finite nonzero numbers, the significand
  /// is in the range `1.0 ..< 2.0`. For other values of `x`, `x.significand`
  /// is defined as follows:
  ///
  /// - If `x` is zero, then `x.significand` is 0.0.
  /// - If `x` is infinity, then `x.significand` is 1.0.
  /// - If `x` is NaN, then `x.significand` is NaN.
  /// - Note: The significand is frequently also called the *mantissa*, but
  ///   significand is the preferred terminology in the [IEEE 754
  ///   specification][spec], to allay confusion with the use of mantissa for
  ///   the fractional part of a logarithm.
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  @_inlineable // FIXME(sil-serialize-all)
  public var significand: Float80 {
    if isNaN { return self }
    if isNormal {
      return Float80(sign: .plus,
        exponentBitPattern: Float80._exponentBias,
        significandBitPattern: significandBitPattern)
    }
    if isSubnormal {
      let shift = Float80.significandBitCount - significandBitPattern.signBitIndex
      return Float80(sign: .plus,
        exponentBitPattern: Float80._exponentBias,
        significandBitPattern: significandBitPattern &<< UInt64(shift))
    }
    // zero or infinity.
    return Float80(sign: .plus,
      exponentBitPattern: exponentBitPattern,
      significandBitPattern: 0)
  }

  /// Creates a new value from the given sign, exponent, and significand.
  ///
  /// The following example uses this initializer to create a new `Double`
  /// instance. `Double` is a binary floating-point type that has a radix of
  /// `2`.
  ///
  ///     let x = Double(sign: .plus, exponent: -2, significand: 1.5)
  ///     // x == 0.375
  ///
  /// This initializer is equivalent to the following calculation, where `**`
  /// is exponentiation, computed as if by a single, correctly rounded,
  /// floating-point operation:
  ///
  ///     let sign: FloatingPointSign = .plus
  ///     let exponent = -2
  ///     let significand = 1.5
  ///     let y = (sign == .minus ? -1 : 1) * significand * Double.radix ** exponent
  ///     // y == 0.375
  ///
  /// As with any basic operation, if this value is outside the representable
  /// range of the type, overflow or underflow occurs, and zero, a subnormal
  /// value, or infinity may result. In addition, there are two other edge
  /// cases:
  ///
  /// - If the value you pass to `significand` is zero or infinite, the result
  ///   is zero or infinite, regardless of the value of `exponent`.
  /// - If the value you pass to `significand` is NaN, the result is NaN.
  ///
  /// For any floating-point value `x` of type `F`, the result of the following
  /// is equal to `x`, with the distinction that the result is canonicalized
  /// if `x` is in a noncanonical encoding:
  ///
  ///     let x0 = F(sign: x.sign, exponent: x.exponent, significand: x.significand)
  ///
  /// This initializer implements the `scaleB` operation defined by the [IEEE
  /// 754 specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  ///
  /// - Parameters:
  ///   - sign: The sign to use for the new value.
  ///   - exponent: The new value's exponent.
  ///   - significand: The new value's significand.
  @_inlineable // FIXME(sil-serialize-all)
  public init(sign: FloatingPointSign, exponent: Int, significand: Float80) {
    var result = significand
    if sign == .minus { result = -result }
    if significand.isFinite && !significand.isZero {
      var clamped = exponent
      let leastNormalExponent = 1 - Int(Float80._exponentBias)
      let greatestFiniteExponent = Int(Float80._exponentBias)
      if clamped < leastNormalExponent {
        clamped = max(clamped, 3*leastNormalExponent)
        while clamped < leastNormalExponent {
          result  *= Float80.leastNormalMagnitude
          clamped -= leastNormalExponent
        }
      }
      else if clamped > greatestFiniteExponent {
        clamped = min(clamped, 3*greatestFiniteExponent)
        let step = Float80(sign: .plus,
          exponentBitPattern: Float80._infinityExponent - 1,
          significandBitPattern: 0)
        while clamped > greatestFiniteExponent {
          result  *= step
          clamped -= greatestFiniteExponent
        }
      }
      let scale = Float80(sign: .plus,
        exponentBitPattern: UInt(Int(Float80._exponentBias) + clamped),
        significandBitPattern: 0)
      result = result * scale
    }
    self = result
  }

  /// Creates a NaN ("not a number") value with the specified payload.
  ///
  /// NaN values compare not equal to every value, including themselves. Most
  /// operations with a NaN operand produce a NaN result. Don't use the
  /// equal-to operator (`==`) to test whether a value is NaN. Instead, use
  /// the value's `isNaN` property.
  ///
  ///     let x = Float80(nan: 0, signaling: false)
  ///     print(x == .nan)
  ///     // Prints "false"
  ///     print(x.isNaN)
  ///     // Prints "true"
  ///
  /// - Parameters:
  ///   - payload: The payload to use for the new NaN value.
  ///   - signaling: Pass `true` to create a signaling NaN or `false` to create
  ///     a quiet NaN.
  @_inlineable // FIXME(sil-serialize-all)
  public init(nan payload: RawSignificand, signaling: Bool) {
    // We use significandBitCount - 2 bits for NaN payload.
    _precondition(payload < (Float80._quietNaNMask &>> 1),
      "NaN payload is not encodable.")
    var significand = payload
    significand |= Float80._quietNaNMask &>> (signaling ? 1 : 0)
    self.init(sign: .plus,
              exponentBitPattern: Float80._infinityExponent,
              significandBitPattern: significand)
  }

  /// The least representable value that compares greater than this value.
  ///
  /// For any finite value `x`, `x.nextUp` is greater than `x`. For `nan` or
  /// `infinity`, `x.nextUp` is `x` itself. The following special cases also
  /// apply:
  ///
  /// - If `x` is `-infinity`, then `x.nextUp` is `-greatestFiniteMagnitude`.
  /// - If `x` is `-leastNonzeroMagnitude`, then `x.nextUp` is `-0.0`.
  /// - If `x` is zero, then `x.nextUp` is `leastNonzeroMagnitude`.
  /// - If `x` is `greatestFiniteMagnitude`, then `x.nextUp` is `infinity`.
  @_inlineable // FIXME(sil-serialize-all)
  public var nextUp: Float80 {
    if isNaN { return self }
    if sign == .minus {
#if arch(arm)
      // On arm, subnormals are flushed to zero.
      if (exponentBitPattern == 1 && significandBitPattern == 0) ||
         (exponentBitPattern == 0 && significandBitPattern != 0) {
        return Float80(sign: .minus,
          exponentBitPattern: 0,
          significandBitPattern: 0)
      }
#endif
      if significandBitPattern == 0 {
        if exponentBitPattern == 0 {
          return .leastNonzeroMagnitude
        }
        return Float80(sign: .minus,
          exponentBitPattern: exponentBitPattern - 1,
          significandBitPattern: Float80._significandMask)
      }
      return Float80(sign: .minus,
        exponentBitPattern: exponentBitPattern,
        significandBitPattern: significandBitPattern - 1)
    }
    if isInfinite { return self }
    if significandBitPattern == Float80._significandMask {
      return Float80(sign: .plus,
        exponentBitPattern: exponentBitPattern + 1,
        significandBitPattern: 0)
    }
#if arch(arm)
    // On arm, subnormals are skipped.
    if exponentBitPattern == 0 {
      return .leastNonzeroMagnitude
    }
#endif
    return Float80(sign: .plus,
      exponentBitPattern: exponentBitPattern,
      significandBitPattern: significandBitPattern + 1)
  }

  /// Rounds the value to an integral value using the specified rounding rule.
  ///
  /// The following example rounds a value using four different rounding rules:
  ///
  ///     // Equivalent to the C 'round' function:
  ///     var w = 6.5
  ///     w.round(.toNearestOrAwayFromZero)
  ///     // w == 7.0
  ///
  ///     // Equivalent to the C 'trunc' function:
  ///     var x = 6.5
  ///     x.round(.towardZero)
  ///     // x == 6.0
  ///
  ///     // Equivalent to the C 'ceil' function:
  ///     var y = 6.5
  ///     y.round(.up)
  ///     // y == 7.0
  ///
  ///     // Equivalent to the C 'floor' function:
  ///     var z = 6.5
  ///     z.round(.down)
  ///     // z == 6.0
  ///
  /// For more information about the available rounding rules, see the
  /// `FloatingPointRoundingRule` enumeration. To round a value using the
  /// default "schoolbook rounding", you can use the shorter `round()` method
  /// instead.
  ///
  ///     var w1 = 6.5
  ///     w1.round()
  ///     // w1 == 7.0
  ///
  /// - Parameter rule: The rounding rule to use.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func round(_ rule: FloatingPointRoundingRule) {
    switch rule {
    case .toNearestOrAwayFromZero:
      _value = Builtin.int_round_FPIEEE80(_value)
    case .toNearestOrEven:
      _value = Builtin.int_rint_FPIEEE80(_value)
    case .towardZero:
      _value = Builtin.int_trunc_FPIEEE80(_value)
    case .awayFromZero:
      if sign == .minus {
        _value = Builtin.int_floor_FPIEEE80(_value)
      }
      else {
        _value = Builtin.int_ceil_FPIEEE80(_value)
      }
    case .up:
      _value = Builtin.int_ceil_FPIEEE80(_value)
    case .down:
      _value = Builtin.int_floor_FPIEEE80(_value)
    }
  }

  /// Replaces this value with its additive inverse.
  ///
  /// The result is always exact. This example uses the `negate()` method to
  /// negate the value of the variable `x`:
  ///
  ///     var x = 21.5
  ///     x.negate()
  ///     // x == -21.5
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func negate() {
    _value = Builtin.fneg_FPIEEE80(self._value)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func +=(_ lhs: inout Float80, _ rhs: Float80) {
    lhs._value = Builtin.fadd_FPIEEE80(lhs._value, rhs._value)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func -=(_ lhs: inout Float80, _ rhs: Float80) {
    lhs._value = Builtin.fsub_FPIEEE80(lhs._value, rhs._value)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func *=(_ lhs: inout Float80, _ rhs: Float80) {
    lhs._value = Builtin.fmul_FPIEEE80(lhs._value, rhs._value)
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func /=(_ lhs: inout Float80, _ rhs: Float80) {
    lhs._value = Builtin.fdiv_FPIEEE80(lhs._value, rhs._value)
  }

  /// Replaces this value with the remainder of itself divided by the given
  /// value.
  ///
  /// For two finite values `x` and `y`, the remainder `r` of dividing `x` by
  /// `y` satisfies `x == y * q + r`, where `q` is the integer nearest to
  /// `x / y`. If `x / y` is exactly halfway between two integers, `q` is
  /// chosen to be even. Note that `q` is *not* `x / y` computed in
  /// floating-point arithmetic, and that `q` may not be representable in any
  /// available integer type.
  ///
  /// The following example calculates the remainder of dividing 8.625 by 0.75:
  ///
  ///     var x = 8.625
  ///     print(x / 0.75)
  ///     // Prints "11.5"
  ///
  ///     let q = (x / 0.75).rounded(.toNearestOrEven)
  ///     // q == 12.0
  ///     x.formRemainder(dividingBy: 0.75)
  ///     // x == -0.375
  ///
  ///     let x1 = 0.75 * q + x
  ///     // x1 == 8.625
  ///
  /// If this value and `other` are finite numbers, the remainder is in the
  /// closed range `-abs(other / 2)...abs(other / 2)`. The
  /// `formRemainder(dividingBy:)` method is always exact.
  ///
  /// - Parameter other: The value to use when dividing this value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func formRemainder(dividingBy other: Float80) {
    var other = other
    _stdlib_remainderl(&self, &other)
  }

  /// Replaces this value with the remainder of itself divided by the given
  /// value using truncating division.
  ///
  /// Performing truncating division with floating-point values results in a
  /// truncated integer quotient and a remainder. For values `x` and `y` and
  /// their truncated integer quotient `q`, the remainder `r` satisfies
  /// `x == y * q + r`.
  ///
  /// The following example calculates the truncating remainder of dividing
  /// 8.625 by 0.75:
  ///
  ///     var x = 8.625
  ///     print(x / 0.75)
  ///     // Prints "11.5"
  ///
  ///     let q = (x / 0.75).rounded(.towardZero)
  ///     // q == 11.0
  ///     x.formTruncatingRemainder(dividingBy: 0.75)
  ///     // x == 0.375
  ///
  ///     let x1 = 0.75 * q + x
  ///     // x1 == 8.625
  ///
  /// If this value and `other` are both finite numbers, the truncating
  /// remainder has the same sign as this value and is strictly smaller in
  /// magnitude than `other`. The `formTruncatingRemainder(dividingBy:)`
  /// method is always exact.
  ///
  /// - Parameter other: The value to use when dividing this value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func formTruncatingRemainder(dividingBy other: Float80) {
    _value = Builtin.frem_FPIEEE80(self._value, other._value)
  }

  /// Replaces this value with its square root, rounded to a representable
  /// value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func formSquareRoot( ) {
    _stdlib_squareRootl(&self)
  }

  /// Adds the product of the two given values to this value in place, computed
  /// without intermediate rounding.
  ///
  /// - Parameters:
  ///   - lhs: One of the values to multiply before adding to this value.
  ///   - rhs: The other value to multiply.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public mutating func addProduct(_ lhs: Float80, _ rhs: Float80) {
    _value = Builtin.int_fma_FPIEEE80(lhs._value, rhs._value, _value)
  }

  /// Returns a Boolean value indicating whether this instance is equal to the
  /// given value.
  ///
  /// This method serves as the basis for the equal-to operator (`==`) for
  /// floating-point values. When comparing two values with this method, `-0`
  /// is equal to `+0`. NaN is not equal to any value, including itself. For
  /// example:
  ///
  ///     let x = 15.0
  ///     x.isEqual(to: 15.0)
  ///     // true
  ///     x.isEqual(to: .nan)
  ///     // false
  ///     Double.nan.isEqual(to: .nan)
  ///     // false
  ///
  /// The `isEqual(to:)` method implements the equality predicate defined by
  /// the [IEEE 754 specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  ///
  /// - Parameter other: The value to compare with this value.
  /// - Returns: `true` if `other` has the same value as this instance;
  ///   otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func isEqual(to other: Float80) -> Bool {
    return Bool(Builtin.fcmp_oeq_FPIEEE80(self._value, other._value))
  }

  /// Returns a Boolean value indicating whether this instance is less than the
  /// given value.
  ///
  /// This method serves as the basis for the less-than operator (`<`) for
  /// floating-point values. Some special cases apply:
  ///
  /// - Because NaN compares not less than nor greater than any value, this
  ///   method returns `false` when called on NaN or when NaN is passed as
  ///   `other`.
  /// - `-infinity` compares less than all values except for itself and NaN.
  /// - Every value except for NaN and `+infinity` compares less than
  ///   `+infinity`.
  ///
  ///     let x = 15.0
  ///     x.isLess(than: 20.0)
  ///     // true
  ///     x.isLess(than: .nan)
  ///     // false
  ///     Double.nan.isLess(than: x)
  ///     // false
  ///
  /// The `isLess(than:)` method implements the less-than predicate defined by
  /// the [IEEE 754 specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  ///
  /// - Parameter other: The value to compare with this value.
  /// - Returns: `true` if `other` is less than this value; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func isLess(than other: Float80) -> Bool {
    return Bool(Builtin.fcmp_olt_FPIEEE80(self._value, other._value))
  }

  /// Returns a Boolean value indicating whether this instance is less than or
  /// equal to the given value.
  ///
  /// This method serves as the basis for the less-than-or-equal-to operator
  /// (`<=`) for floating-point values. Some special cases apply:
  ///
  /// - Because NaN is incomparable with any value, this method returns `false`
  ///   when called on NaN or when NaN is passed as `other`.
  /// - `-infinity` compares less than or equal to all values except NaN.
  /// - Every value except NaN compares less than or equal to `+infinity`.
  ///
  ///     let x = 15.0
  ///     x.isLessThanOrEqualTo(20.0)
  ///     // true
  ///     x.isLessThanOrEqualTo(.nan)
  ///     // false
  ///     Double.nan.isLessThanOrEqualTo(x)
  ///     // false
  ///
  /// The `isLessThanOrEqualTo(_:)` method implements the less-than-or-equal
  /// predicate defined by the [IEEE 754 specification][spec].
  ///
  /// [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933
  ///
  /// - Parameter other: The value to compare with this value.
  /// - Returns: `true` if `other` is less than this value; otherwise, `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func isLessThanOrEqualTo(_ other: Float80) -> Bool {
    return Bool(Builtin.fcmp_ole_FPIEEE80(self._value, other._value))
  }

  /// A Boolean value indicating whether this instance is normal.
  ///
  /// A *normal* value is a finite number that uses the full precision
  /// available to values of a type. Zero is neither a normal nor a subnormal
  /// number.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isNormal: Bool {
    return exponentBitPattern > 0 && isFinite
  }

  /// A Boolean value indicating whether this instance is finite.
  ///
  /// All values other than NaN and infinity are considered finite, whether
  /// normal or subnormal.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isFinite: Bool {
    return exponentBitPattern < Float80._infinityExponent
  }

  /// A Boolean value indicating whether the instance is equal to zero.
  ///
  /// The `isZero` property of a value `x` is `true` when `x` represents either
  /// `-0.0` or `+0.0`. `x.isZero` is equivalent to the following comparison:
  /// `x == 0.0`.
  ///
  ///     let x = -0.0
  ///     x.isZero        // true
  ///     x == 0.0        // true
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isZero: Bool {
    return exponentBitPattern == 0 && significandBitPattern == 0
  }

  /// A Boolean value indicating whether the instance is subnormal.
  ///
  /// A *subnormal* value is a nonzero number that has a lesser magnitude than
  /// the smallest normal number. Subnormal values do not use the full
  /// precision available to values of a type.
  ///
  /// Zero is neither a normal nor a subnormal number. Subnormal numbers are
  /// often called *denormal* or *denormalized*---these are different names
  /// for the same concept.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isSubnormal:  Bool {
    return exponentBitPattern == 0 && significandBitPattern != 0
  }

  /// A Boolean value indicating whether the instance is infinite.
  ///
  /// Note that `isFinite` and `isInfinite` do not form a dichotomy, because
  /// they are not total: If `x` is `NaN`, then both properties are `false`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isInfinite:  Bool {
    return !isFinite && significandBitPattern == 0
  }

  /// A Boolean value indicating whether the instance is NaN ("not a number").
  ///
  /// Because NaN is not equal to any value, including NaN, use this property
  /// instead of the equal-to operator (`==`) or not-equal-to operator (`!=`)
  /// to test whether a value is or is not NaN. For example:
  ///
  ///     let x = 0.0
  ///     let y = x * .infinity
  ///     // y is a NaN
  ///
  ///     // Comparing with the equal-to operator never returns 'true'
  ///     print(x == Double.nan)
  ///     // Prints "false"
  ///     print(y == Double.nan)
  ///     // Prints "false"
  ///
  ///     // Test with the 'isNaN' property instead
  ///     print(x.isNaN)
  ///     // Prints "false"
  ///     print(y.isNaN)
  ///     // Prints "true"
  ///
  /// This property is `true` for both quiet and signaling NaNs.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isNaN:  Bool {
    return !isFinite && significandBitPattern != 0
  }

  /// A Boolean value indicating whether the instance is a signaling NaN.
  ///
  /// Signaling NaNs typically raise the Invalid flag when used in general
  /// computing operations.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var isSignalingNaN: Bool {
    return isNaN && (significandBitPattern & Float80._quietNaNMask) == 0
  }

  /// The floating-point value with the same sign and exponent as this value,
  /// but with a significand of 1.0.
  ///
  /// A *binade* is a set of binary floating-point values that all have the
  /// same sign and exponent. The `binade` property is a member of the same
  /// binade as this value, but with a unit significand.
  ///
  /// In this example, `x` has a value of `21.5`, which is stored as
  /// `1.34375 * 2**4`, where `**` is exponentiation. Therefore, `x.binade` is
  /// equal to `1.0 * 2**4`, or `16.0`.
  ///
  ///     let x = 21.5
  ///     // x.significand == 1.34375
  ///     // x.exponent == 4
  ///
  ///     let y = x.binade
  ///     // y == 16.0
  ///     // y.significand == 1.0
  ///     // y.exponent == 4
  @_inlineable // FIXME(sil-serialize-all)
  public var binade: Float80 {
    if !isFinite { return .nan }
    if exponentBitPattern != 0 {
      return Float80(sign: sign, exponentBitPattern: exponentBitPattern,
        significandBitPattern: 0)
    }
    if significandBitPattern == 0 { return self }
    // For subnormals, we isolate the leading significand bit.
    let index = significandBitPattern.signBitIndex
    return Float80(sign: sign, exponentBitPattern: 0,
      significandBitPattern: 1 &<< RawSignificand(index))
  }

  /// The number of bits required to represent the value's significand.
  ///
  /// If this value is a finite nonzero number, `significandWidth` is the
  /// number of fractional bits required to represent the value of
  /// `significand`; otherwise, `significandWidth` is -1. The value of
  /// `significandWidth` is always -1 or between zero and
  /// `significandBitCount`. For example:
  ///
  /// - For any representable power of two, `significandWidth` is zero, because
  ///   `significand` is `1.0`.
  /// - If `x` is 10, `x.significand` is `1.01` in binary, so
  ///   `x.significandWidth` is 2.
  /// - If `x` is Float.pi, `x.significand` is `1.10010010000111111011011` in
  ///   binary, and `x.significandWidth` is 23.
  @_inlineable // FIXME(sil-serialize-all)
  public var significandWidth: Int {
    let trailingZeroBits = significandBitPattern.trailingZeroBitCount
    if isNormal {
      guard significandBitPattern != 0 else { return 0 }
      return Float80.significandBitCount - trailingZeroBits
    }
    if isSubnormal {
      return significandBitPattern.signBitIndex - trailingZeroBits
    }
    return -1
  }

  /// Creates a new value from the given floating-point literal.
  ///
  /// Do not call this initializer directly. It is used by the compiler when
  /// you create a new `Float80` instance by using a floating-point literal.
  /// Instead, create a new value by using a literal.
  ///
  /// In this example, the assignment to the `x` constant calls this
  /// initializer behind the scenes.
  ///
  ///     let x: Float80 = 21.25
  ///     // x == 21.25
  ///
  /// - Parameter value: The new floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(floatLiteral value: Float80) {
    self = value
  }
}

extension Float80 : _ExpressibleByBuiltinIntegerLiteral, ExpressibleByIntegerLiteral {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public
  init(_builtinIntegerLiteral value: Builtin.Int2048){
    self = Float80(_bits: Builtin.itofp_with_overflow_Int2048_FPIEEE80(value))
  }

  /// Creates a new value from the given integer literal.
  ///
  /// Do not call this initializer directly. It is used by the compiler when
  /// you create a new `Float80` instance by using an integer literal.
  /// Instead, create a new value by using a literal.
  ///
  /// In this example, the assignment to the `x` constant calls this
  /// initializer behind the scenes.
  ///
  ///     let x: Float80 = 100
  ///     // x == 100.0
  ///
  /// - Parameter value: The new value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(integerLiteral value: Int64) {
    self = Float80(_bits: Builtin.sitofp_Int64_FPIEEE80(value._value))
  }
}


extension Float80 : _ExpressibleByBuiltinFloatLiteral {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public
  init(_builtinFloatLiteral value: Builtin.FPIEEE80) {
    self = Float80(_bits: value)
  }
}


extension Float80 : Hashable {
  /// The number's hash value.
  ///
  /// Hash values are not guaranteed to be equal across different executions of
  /// your program. Do not save hash values to use during a future execution.
  @_inlineable // FIXME(sil-serialize-all)
  public var hashValue: Int {
    if isZero {
      // To satisfy the axiom that equality implies hash equality, we need to
      // finesse the hash value of -0.0 to match +0.0.
      return 0
    } else {
      return Int(bitPattern: UInt(significandBitPattern)) ^
             Int(_representation.signAndExponent)
    }
  }
}

extension Float80 {
  /// The magnitude of this value.
  ///
  /// For any value `x`, `x.magnitude.sign` is `.plus`. If `x` is not NaN,
  /// `x.magnitude` is the absolute value of `x`.
  ///
  /// The global `abs(_:)` function provides more familiar syntax when you need
  /// to find an absolute value. In addition, because `abs(_:)` always returns
  /// a value of the same type, even in a generic context, using the function
  /// instead of the `magnitude` property is encouraged.
  ///
  ///     let targetDistance: Float80 = 5.25
  ///     let throwDistance: Float80 = 5.5
  ///
  ///     let margin = targetDistance - throwDistance
  ///     // margin == -0.25
  ///     // margin.magnitude == 0.25
  ///
  ///     // Use 'abs(_:)' instead of 'magnitude'
  ///     print("Missed the target by \(abs(margin)) meters.")
  ///     // Prints "Missed the target by 0.25 meters."
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public var magnitude: Float80 {
    return Float80(_bits: Builtin.int_fabs_FPIEEE80(_value))
  }

  // FIXME(integers): implement properly
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter source: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  public init?<T : BinaryInteger>(exactly source: T) {
    fatalError()
  }
}

extension Float80 {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static prefix func - (x: Float80) -> Float80 {
    return Float80(_bits: Builtin.fneg_FPIEEE80(x._value))
  }
}

//===----------------------------------------------------------------------===//
// Explicit conversions between types.
//===----------------------------------------------------------------------===//

// Construction from integers.
extension Float80 {

  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: UInt8) {
    _value = Builtin.uitofp_Int8_FPIEEE80(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @available(*, message: "Converting UInt8 to Float80 will always succeed.")
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: UInt8) {
    _value = Builtin.uitofp_Int8_FPIEEE80(value._value)

  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: Int8) {
    _value = Builtin.sitofp_Int8_FPIEEE80(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @available(*, message: "Converting Int8 to Float80 will always succeed.")
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: Int8) {
    _value = Builtin.sitofp_Int8_FPIEEE80(value._value)

  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: UInt16) {
    _value = Builtin.uitofp_Int16_FPIEEE80(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @available(*, message: "Converting UInt16 to Float80 will always succeed.")
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: UInt16) {
    _value = Builtin.uitofp_Int16_FPIEEE80(value._value)

  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: Int16) {
    _value = Builtin.sitofp_Int16_FPIEEE80(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @available(*, message: "Converting Int16 to Float80 will always succeed.")
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: Int16) {
    _value = Builtin.sitofp_Int16_FPIEEE80(value._value)

  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: UInt32) {
    _value = Builtin.uitofp_Int32_FPIEEE80(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @available(*, message: "Converting UInt32 to Float80 will always succeed.")
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: UInt32) {
    _value = Builtin.uitofp_Int32_FPIEEE80(value._value)

  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: Int32) {
    _value = Builtin.sitofp_Int32_FPIEEE80(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @available(*, message: "Converting Int32 to Float80 will always succeed.")
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: Int32) {
    _value = Builtin.sitofp_Int32_FPIEEE80(value._value)

  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: UInt64) {
    _value = Builtin.uitofp_Int64_FPIEEE80(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: UInt64) {
    _value = Builtin.uitofp_Int64_FPIEEE80(value._value)

    guard let roundTrip = UInt64(exactly: self),
      roundTrip == value else {
      return nil
    }
  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: Int64) {
    _value = Builtin.sitofp_Int64_FPIEEE80(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: Int64) {
    _value = Builtin.sitofp_Int64_FPIEEE80(value._value)

    guard let roundTrip = Int64(exactly: self),
      roundTrip == value else {
      return nil
    }
  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: UInt) {
    _value = Builtin.uitofp_Int64_FPIEEE80(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: UInt) {
    _value = Builtin.uitofp_Int64_FPIEEE80(value._value)

    guard let roundTrip = UInt(exactly: self),
      roundTrip == value else {
      return nil
    }
  }
  /// Creates the closest representable value to the given integer.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ v: Int) {
    _value = Builtin.sitofp_Int64_FPIEEE80(v._value)
  }
  
  /// Creates a value that exactly represents the given integer.
  ///
  /// If the given integer is outside the representable range of this type or
  /// can't be represented exactly, the result is `nil`.
  ///
  /// - Parameter value: The integer to represent as a floating-point value.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly value: Int) {
    _value = Builtin.sitofp_Int64_FPIEEE80(value._value)

    guard let roundTrip = Int(exactly: self),
      roundTrip == value else {
      return nil
    }
  }
}

// Construction from other floating point numbers.
extension Float80 {


  /// Creates a new instance that approximates the given value.
  ///
  /// The value of `other` is rounded to a representable value, if necessary.
  /// A NaN passed as `other` results in another NaN, with a signaling NaN
  /// value converted to quiet NaN.
  ///
  ///     let x: Float = 21.25
  ///     let y = Float80(x)
  ///     // y == 21.25
  ///
  ///     let z = Float80(Float.nan)
  ///     // z.isNaN == true
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ other: Float) {
    _value = Builtin.fpext_FPIEEE32_FPIEEE80(other._value)
  }

  /// Creates a new instance initialized to the given value, if it can be
  /// represented without rounding.
  ///
  /// If `other` can't be represented as an instance of `Float80` without
  /// rounding, the result of this initializer is `nil`. In particular,
  /// passing NaN as `other` always results in `nil`.
  ///
  ///     let x: Float = 21.25
  ///     let y = Float80(exactly: x)
  ///     // y == Optional.some(21.25)
  ///
  ///     let z = Float80(exactly: Float.nan)
  ///     // z == nil
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly other: Float) {
    self.init(other)
    // Converting the infinity value is considered value preserving.
    // In other cases, check that we can round-trip and get the same value.
    // NaN always fails.
    if Float(self) != other {
      return nil
    }
  }



  /// Creates a new instance that approximates the given value.
  ///
  /// The value of `other` is rounded to a representable value, if necessary.
  /// A NaN passed as `other` results in another NaN, with a signaling NaN
  /// value converted to quiet NaN.
  ///
  ///     let x: Double = 21.25
  ///     let y = Float80(x)
  ///     // y == 21.25
  ///
  ///     let z = Float80(Double.nan)
  ///     // z.isNaN == true
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ other: Double) {
    _value = Builtin.fpext_FPIEEE64_FPIEEE80(other._value)
  }

  /// Creates a new instance initialized to the given value, if it can be
  /// represented without rounding.
  ///
  /// If `other` can't be represented as an instance of `Float80` without
  /// rounding, the result of this initializer is `nil`. In particular,
  /// passing NaN as `other` always results in `nil`.
  ///
  ///     let x: Double = 21.25
  ///     let y = Float80(exactly: x)
  ///     // y == Optional.some(21.25)
  ///
  ///     let z = Float80(exactly: Double.nan)
  ///     // z == nil
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly other: Double) {
    self.init(other)
    // Converting the infinity value is considered value preserving.
    // In other cases, check that we can round-trip and get the same value.
    // NaN always fails.
    if Double(self) != other {
      return nil
    }
  }



  /// Creates a new instance initialized to the given value.
  ///
  /// The value of `other` is represented exactly by the new instance. A NaN
  /// passed as `other` results in another NaN, with a signaling NaN value
  /// converted to quiet NaN.
  ///
  ///     let x: Float80 = 21.25
  ///     let y = Float80(x)
  ///     // y == 21.25
  ///
  ///     let z = Float80(Float80.nan)
  ///     // z.isNaN == true
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init(_ other: Float80) {
    _value = other._value
  }

  /// Creates a new instance initialized to the given value, if it can be
  /// represented without rounding.
  ///
  /// If `other` can't be represented as an instance of `Float80` without
  /// rounding, the result of this initializer is `nil`. In particular,
  /// passing NaN as `other` always results in `nil`.
  ///
  ///     let x: Float80 = 21.25
  ///     let y = Float80(exactly: x)
  ///     // y == Optional.some(21.25)
  ///
  ///     let z = Float80(exactly: Float80.nan)
  ///     // z == nil
  ///
  /// - Parameter other: The value to use for the new instance.
  @_inlineable // FIXME(sil-serialize-all)
  @inline(__always)
  public init?(exactly other: Float80) {
    self.init(other)
    // Converting the infinity value is considered value preserving.
    // In other cases, check that we can round-trip and get the same value.
    // NaN always fails.
    if Float80(self) != other {
      return nil
    }
  }

}

//===----------------------------------------------------------------------===//
// Standard Operator Table
//===----------------------------------------------------------------------===//

//  TODO: These should not be necessary, since they're already provided by
//  <T: FloatingPoint>, but in practice they are currently needed to
//  disambiguate overloads.  We should find a way to remove them, either by
//  tweaking the overload resolution rules, or by removing the other
//  definitions in the standard lib, or both.

extension Float80 {
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func + (lhs: Float80, rhs: Float80) -> Float80 {
    var lhs = lhs
    lhs += rhs
    return lhs
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func - (lhs: Float80, rhs: Float80) -> Float80 {
    var lhs = lhs
    lhs -= rhs
    return lhs
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func * (lhs: Float80, rhs: Float80) -> Float80 {
    var lhs = lhs
    lhs *= rhs
    return lhs
  }

  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public static func / (lhs: Float80, rhs: Float80) -> Float80 {
    var lhs = lhs
    lhs /= rhs
    return lhs
  }
}

//===----------------------------------------------------------------------===//
// Strideable Conformance
//===----------------------------------------------------------------------===//

extension Float80 : Strideable {
  /// Returns the distance from this value to the specified value.
  ///
  /// For two values `x` and `y`, the result of `x.distance(to: y)` is equal to
  /// `y - x`---a distance `d` such that `x.advanced(by: d)` approximates `y`.
  /// For example:
  ///
  ///     let x = 21.5
  ///     let d = x.distance(to: 15.0)
  ///     // d == -6.5
  ///
  ///     print(x.advanced(by: d))
  ///     // Prints "15.0"
  ///
  /// - Parameter other: A value to calculate the distance to.
  /// - Returns: The distance between this value and `other`.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func distance(to other: Float80) -> Float80 {
    return other - self
  }

  /// Returns a new value advanced by the given distance.
  ///
  /// For two values `x` and `d`, the result of a `x.advanced(by: d)` is equal
  /// to `x + d`---a new value `y` such that `x.distance(to: y)` approximates
  /// `d`. For example:
  ///
  ///     let x = 21.5
  ///     let y = x.advanced(by: -6.5)
  ///     // y == 15.0
  ///
  ///     print(x.distance(to: y))
  ///     // Prints "-6.5"
  ///
  /// - Parameter amount: The distance to advance this value.
  /// - Returns: A new value that is `amount` added to this value.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public func advanced(by amount: Float80) -> Float80 {
    return self + amount
  }
}

//===----------------------------------------------------------------------===//
// Deprecated operators
//===----------------------------------------------------------------------===//

@_transparent
@available(*, unavailable, message: "use += 1")
@discardableResult
public prefix func ++ (rhs: inout Float80) -> Float80 {
  fatalError("++ is not available")
}
@_transparent
@available(*, unavailable, message: "use -= 1")
@discardableResult
public prefix func -- (rhs: inout Float80) -> Float80 {
  fatalError("-- is not available")
}
@_transparent
@available(*, unavailable, message: "use += 1")
@discardableResult
public postfix func ++ (lhs: inout Float80) -> Float80 {
  fatalError("++ is not available")
}
@_transparent
@available(*, unavailable, message: "use -= 1")
@discardableResult
public postfix func -- (lhs: inout Float80) -> Float80 {
  fatalError("-- is not available")
}

extension Float80 {
  @_inlineable // FIXME(sil-serialize-all)
  @available(swift, deprecated: 3.1, obsoleted: 4.0, message: "Please use the `abs(_:)` free function")
  @_transparent
  public static func abs(_ x: Float80) -> Float80 {
    return x.magnitude
  }
}

#else

/// An extended-precision, floating-point value type.
@_fixed_layout
@available(*, unavailable, message: "Float80 is only available on non-Windows x86 targets.")
public struct Float80 {
  /// Creates a value initialized to zero.
  @_inlineable // FIXME(sil-serialize-all)
  @_transparent
  public init() {
    fatalError("Float80 is not available")
  }
}

#endif

@_transparent
@available(*, unavailable,
  message: "For floating point numbers use truncatingRemainder instead")
public func % <T : BinaryFloatingPoint>(lhs: T, rhs: T) -> T {
  fatalError("% is not available.")
}

@_transparent
@available(*, unavailable,
  message: "For floating point numbers use formTruncatingRemainder instead")
public func %= <T : BinaryFloatingPoint> (lhs: inout T, rhs: T) {
  fatalError("%= is not available.")
}
