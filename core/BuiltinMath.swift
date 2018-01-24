//===--- BuiltinMath.swift.gyb --------------------------------*- swift -*-===//
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


// Unary intrinsic functions
// Note these have a corresponding LLVM intrinsic
@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _cos(_ x: Float) -> Float {
  return Float(_bits: Builtin.int_cos_FPIEEE32(x._value))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _cos(_ x: Double) -> Double {
  return Double(_bits: Builtin.int_cos_FPIEEE64(x._value))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _sin(_ x: Float) -> Float {
  return Float(_bits: Builtin.int_sin_FPIEEE32(x._value))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _sin(_ x: Double) -> Double {
  return Double(_bits: Builtin.int_sin_FPIEEE64(x._value))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _exp(_ x: Float) -> Float {
  return Float(_bits: Builtin.int_exp_FPIEEE32(x._value))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _exp(_ x: Double) -> Double {
  return Double(_bits: Builtin.int_exp_FPIEEE64(x._value))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _exp2(_ x: Float) -> Float {
  return Float(_bits: Builtin.int_exp2_FPIEEE32(x._value))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _exp2(_ x: Double) -> Double {
  return Double(_bits: Builtin.int_exp2_FPIEEE64(x._value))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _log(_ x: Float) -> Float {
  return Float(_bits: Builtin.int_log_FPIEEE32(x._value))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _log(_ x: Double) -> Double {
  return Double(_bits: Builtin.int_log_FPIEEE64(x._value))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _log10(_ x: Float) -> Float {
  return Float(_bits: Builtin.int_log10_FPIEEE32(x._value))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _log10(_ x: Double) -> Double {
  return Double(_bits: Builtin.int_log10_FPIEEE64(x._value))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _log2(_ x: Float) -> Float {
  return Float(_bits: Builtin.int_log2_FPIEEE32(x._value))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _log2(_ x: Double) -> Double {
  return Double(_bits: Builtin.int_log2_FPIEEE64(x._value))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _nearbyint(_ x: Float) -> Float {
  return Float(_bits: Builtin.int_nearbyint_FPIEEE32(x._value))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _nearbyint(_ x: Double) -> Double {
  return Double(_bits: Builtin.int_nearbyint_FPIEEE64(x._value))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _rint(_ x: Float) -> Float {
  return Float(_bits: Builtin.int_rint_FPIEEE32(x._value))
}

@_inlineable // FIXME(sil-serialize-all)
@_transparent
public func _rint(_ x: Double) -> Double {
  return Double(_bits: Builtin.int_rint_FPIEEE64(x._value))
}


// Local Variables:
// eval: (read-only-mode 1)
// End:
