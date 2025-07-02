import Foundation

/// A sendable wrapper for non-sendable types that provides thread-safe access.
@dynamicMemberLookup
public final class LockIsolated<Value>: @unchecked Sendable {
  private var _value: Value
  private let lock = NSLock()
  
  public init(_ value: Value) {
    self._value = value
  }
  
  public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
    lock.lock()
    defer { lock.unlock() }
    return _value[keyPath: keyPath]
  }
  
  public func withValue<T>(_ operation: (inout Value) throws -> T) rethrows -> T {
    lock.lock()
    defer { lock.unlock() }
    return try operation(&_value)
  }
  
  public var value: Value {
    lock.lock()
    defer { lock.unlock() }
    return _value
  }
  
  public func setValue(_ newValue: Value) {
    lock.lock()
    defer { lock.unlock() }
    _value = newValue
  }
}

/// A wrapper that makes non-Sendable types conform to Sendable without enforcement.
@propertyWrapper
public struct UncheckedSendable<Value>: @unchecked Sendable {
  public var wrappedValue: Value
  
  public init(_ wrappedValue: Value) {
    self.wrappedValue = wrappedValue
  }
  
  public init(wrappedValue: Value) {
    self.wrappedValue = wrappedValue
  }
}

/// A simple clock implementation for timeout operations.
public protocol ClockProtocol {
  func sleep(for duration: TimeInterval) async throws
}

public struct SystemClock: ClockProtocol {
  public init() {}
  
  public func sleep(for duration: TimeInterval) async throws {
    try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
  }
}

/// A box type for holding values that may or may not be Sendable.
public final class UncheckedBox<Value>: @unchecked Sendable {
  public var value: Value
  
  public init(_ value: Value) {
    self.value = value
  }
}

// Extension to support Result initializer pattern
extension Result {
  public init<T>(@_implicitSelfCapture _ body: () async throws -> T) async where Success == T, Failure == Error {
    do {
      self = .success(try await body())
    } catch {
      self = .failure(error)
    }
  }
}

// Extension to support AsyncStream creation from AsyncSequence
extension AsyncStream {
  public init<S: AsyncSequence>(_ asyncSequence: S) where S.Element == Element {
    self.init { continuation in
      Task {
        do {
          for try await element in asyncSequence {
            continuation.yield(element)
          }
          continuation.finish()
        } catch {
          continuation.finish()
        }
      }
    }
  }
}