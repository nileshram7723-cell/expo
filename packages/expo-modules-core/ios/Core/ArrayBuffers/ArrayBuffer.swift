// Copyright 2022-present 650 Industries. All rights reserved.

import ExpoModulesJSI

/**
 Represents a fixed-length raw binary data buffer backed by a `JavaScriptArrayBuffer`.
 Provides access to the underlying memory and convenience methods for copying, wrapping, and allocating buffers.
 */
public class ArrayBuffer: AnyArrayBuffer {
  /**
   The underlying JSI array buffer that manages the memory and JS runtime reference.
   Only set for buffers originating from JavaScript. `NativeArrayBuffer` manages its own memory.
   */
  private(set) var backingBuffer: JavaScriptArrayBuffer?

  /**
   Initializes the array buffer with the given JSI array buffer.
   */
  internal required init(_ backingBuffer: consuming JavaScriptArrayBuffer) {
    self.backingBuffer = backingBuffer
  }

  /**
   Internal initializer for subclasses that manage their own memory (e.g. `NativeArrayBuffer`).
   */
  internal init() {
    self.backingBuffer = nil
  }

  /**
   The length of the ArrayBuffer in bytes.
   Fixed at construction time and thus read only.
   */
  public lazy var byteLength: Int = backingBuffer!.size

  /**
   The unsafe mutable raw pointer to the start of the array buffer.
   */
  public lazy var rawPointer: UnsafeMutableRawPointer = UnsafeMutableRawPointer(backingBuffer!.data())

  /**
   Creates a copy of this ArrayBuffer with its own allocated memory.

   - Returns: A new NativeArrayBuffer containing a copy of this buffer's data
   */
  public func copy() -> NativeArrayBuffer {
    return NativeArrayBuffer.copy(of: rawPointer, count: byteLength)
  }

  /**
   Wraps this ArrayBuffer in a Data instance without performing a copy.
   The returned Data object shares the same memory as this ArrayBuffer.

   - Note: Swift `Data` is a copy-on-write type. Mutating the data
   doesn't guarantee to modify the array buffer's underlying memory.
   */
  public var data: Data {
    // Retain self to prevent deallocation while Data object exists
    let retained = Unmanaged.passRetained(self)

    return Data(
      bytesNoCopy: rawPointer,
      count: byteLength,
      deallocator: .custom({ _, _ in retained.release() }))
  }
}

// MARK: - ContiguousBytes

extension ArrayBuffer: ContiguousBytes {
  public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    return try body(UnsafeRawBufferPointer(start: self.rawPointer, count: self.byteLength))
  }
}

/**
 An exception thrown when `baseAddress` of `UnsafeMutableRawBufferPointer` is `nil`.
 */
public final class MissingBaseAddressError: Exception, @unchecked Sendable {
  override public var reason: String {
    "Cannot get baseAddress of given data"
  }
}
