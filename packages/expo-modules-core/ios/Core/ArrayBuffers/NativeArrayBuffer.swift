// Copyright 2022-present 650 Industries. All rights reserved.

import ExpoModulesJSI

/**
 An ArrayBuffer subclass that manages its own native memory.
 Does not require a JavaScript runtime at creation time — the JSI backing buffer
 is created on demand when the buffer needs to be returned to JavaScript.
 */
public final class NativeArrayBuffer: ArrayBuffer {
  private let _rawPointer: UnsafeMutableRawPointer
  private let _byteLength: Int
  private let cleanup: (() -> Void)?

  public override lazy var byteLength: Int = _byteLength
  public override lazy var rawPointer: UnsafeMutableRawPointer = _rawPointer

  init(wrapping data: UnsafeMutableRawPointer, count: Int, cleanup: @escaping () -> Void) {
    self._rawPointer = data
    self._byteLength = count
    self.cleanup = cleanup
    super.init()
  }

  deinit {
    cleanup?()
  }

  // MARK: - JavaScript conversion

  /**
   Returns a `JavaScriptArrayBuffer` that wraps the native memory managed by this buffer.
   The native buffer is retained for the lifetime of the `JavaScriptArrayBuffer`.
   */
  func asJavaScriptArrayBuffer(runtime: JavaScriptRuntime) -> JavaScriptArrayBuffer {
    return runtime.createArrayBuffer(
      data: _rawPointer.assumingMemoryBound(to: UInt8.self),
      size: _byteLength
    ) { [self] in
      _ = self
    }
  }

  // MARK: - Allocate

  /**
   Allocates a new native ArrayBuffer of the given size with zero-initialized memory.
   */
  public static func allocate(size: Int, initializeToZero: Bool = true) -> NativeArrayBuffer {
    let data = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
    if initializeToZero {
      data.initialize(repeating: 0, count: size)
    }
    return NativeArrayBuffer(wrapping: data, count: size, cleanup: { data.deallocate() })
  }

  // MARK: - Copy

  /**
   Copies the given raw pointer into a new native ArrayBuffer.
   */
  public static func copy(of other: UnsafeRawPointer, count: Int) -> NativeArrayBuffer {
    let copy = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
    copy.initialize(from: other.assumingMemoryBound(to: UInt8.self), count: count)
    return NativeArrayBuffer(wrapping: copy, count: count, cleanup: { copy.deallocate() })
  }

  /**
   Copies the given Data into a new native ArrayBuffer.
   */
  public static func copy(data: Data) throws -> NativeArrayBuffer {
    let size = data.count
    let arrayBuffer = NativeArrayBuffer.allocate(size: size, initializeToZero: false)

    try data.withUnsafeBytes { rawPointer in
      guard let baseAddress = rawPointer.baseAddress else {
        throw MissingBaseAddressError()
      }
      memcpy(arrayBuffer.rawPointer, baseAddress, size)
    }
    return arrayBuffer
  }

  // MARK: - Wrap

  /**
   Wraps the given raw buffer pointer in an ArrayBuffer without copying data.
   */
  public static func wrap(
    dataWithoutCopy data: UnsafeMutableRawBufferPointer,
    cleanup: @escaping () -> Void
  ) throws -> NativeArrayBuffer {
    guard let baseAddress = data.baseAddress else {
      throw MissingBaseAddressError()
    }
    return NativeArrayBuffer(wrapping: baseAddress, count: data.count, cleanup: cleanup)
  }
}
