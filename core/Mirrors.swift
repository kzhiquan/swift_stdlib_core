//===--- Mirrors.swift.gyb - Common _Mirror implementations ---*- swift -*-===//
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



extension Float : CustomReflectable {
  /// A mirror that reflects the `Float` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(self, unlabeledChildren: EmptyCollection<Void>())
  }
}

extension Float : CustomPlaygroundQuickLookable {
  /// A custom playground Quick Look for the `Float` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .float(self)
  }
}

extension Double : CustomReflectable {
  /// A mirror that reflects the `Double` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(self, unlabeledChildren: EmptyCollection<Void>())
  }
}

extension Double : CustomPlaygroundQuickLookable {
  /// A custom playground Quick Look for the `Double` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .double(self)
  }
}

extension Bool : CustomReflectable {
  /// A mirror that reflects the `Bool` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(self, unlabeledChildren: EmptyCollection<Void>())
  }
}

extension Bool : CustomPlaygroundQuickLookable {
  /// A custom playground Quick Look for the `Bool` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .bool(self)
  }
}

extension String : CustomReflectable {
  /// A mirror that reflects the `String` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(self, unlabeledChildren: EmptyCollection<Void>())
  }
}

extension String : CustomPlaygroundQuickLookable {
  /// A custom playground Quick Look for the `String` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .text(self)
  }
}

extension Character : CustomReflectable {
  /// A mirror that reflects the `Character` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(self, unlabeledChildren: EmptyCollection<Void>())
  }
}

extension Character : CustomPlaygroundQuickLookable {
  /// A custom playground Quick Look for the `Character` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .text(String(self))
  }
}

extension Unicode.Scalar : CustomReflectable {
  /// A mirror that reflects the `Unicode.Scalar` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(self, unlabeledChildren: EmptyCollection<Void>())
  }
}

extension Unicode.Scalar : CustomPlaygroundQuickLookable {
  /// A custom playground Quick Look for the `Unicode.Scalar` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .uInt(UInt64(self))
  }
}

extension UInt8 : CustomReflectable {
  /// A mirror that reflects the `UInt8` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(self, unlabeledChildren: EmptyCollection<Void>())
  }
}

extension UInt8 : CustomPlaygroundQuickLookable {
  /// A custom playground Quick Look for the `UInt8` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .uInt(UInt64(self))
  }
}

extension Int8 : CustomReflectable {
  /// A mirror that reflects the `Int8` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(self, unlabeledChildren: EmptyCollection<Void>())
  }
}

extension Int8 : CustomPlaygroundQuickLookable {
  /// A custom playground Quick Look for the `Int8` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .int(Int64(self))
  }
}

extension UInt16 : CustomReflectable {
  /// A mirror that reflects the `UInt16` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(self, unlabeledChildren: EmptyCollection<Void>())
  }
}

extension UInt16 : CustomPlaygroundQuickLookable {
  /// A custom playground Quick Look for the `UInt16` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .uInt(UInt64(self))
  }
}

extension Int16 : CustomReflectable {
  /// A mirror that reflects the `Int16` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(self, unlabeledChildren: EmptyCollection<Void>())
  }
}

extension Int16 : CustomPlaygroundQuickLookable {
  /// A custom playground Quick Look for the `Int16` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .int(Int64(self))
  }
}

extension UInt32 : CustomReflectable {
  /// A mirror that reflects the `UInt32` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(self, unlabeledChildren: EmptyCollection<Void>())
  }
}

extension UInt32 : CustomPlaygroundQuickLookable {
  /// A custom playground Quick Look for the `UInt32` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .uInt(UInt64(self))
  }
}

extension Int32 : CustomReflectable {
  /// A mirror that reflects the `Int32` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(self, unlabeledChildren: EmptyCollection<Void>())
  }
}

extension Int32 : CustomPlaygroundQuickLookable {
  /// A custom playground Quick Look for the `Int32` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .int(Int64(self))
  }
}

extension UInt64 : CustomReflectable {
  /// A mirror that reflects the `UInt64` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(self, unlabeledChildren: EmptyCollection<Void>())
  }
}

extension UInt64 : CustomPlaygroundQuickLookable {
  /// A custom playground Quick Look for the `UInt64` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .uInt(UInt64(self))
  }
}

extension Int64 : CustomReflectable {
  /// A mirror that reflects the `Int64` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(self, unlabeledChildren: EmptyCollection<Void>())
  }
}

extension Int64 : CustomPlaygroundQuickLookable {
  /// A custom playground Quick Look for the `Int64` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .int(Int64(self))
  }
}

extension UInt : CustomReflectable {
  /// A mirror that reflects the `UInt` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(self, unlabeledChildren: EmptyCollection<Void>())
  }
}

extension UInt : CustomPlaygroundQuickLookable {
  /// A custom playground Quick Look for the `UInt` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .uInt(UInt64(self))
  }
}

extension Int : CustomReflectable {
  /// A mirror that reflects the `Int` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customMirror: Mirror {
    return Mirror(self, unlabeledChildren: EmptyCollection<Void>())
  }
}

extension Int : CustomPlaygroundQuickLookable {
  /// A custom playground Quick Look for the `Int` instance.
  @_inlineable // FIXME(sil-serialize-all)
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .int(Int64(self))
  }
}

// Local Variables:
// eval: (read-only-mode 1)
// End:
