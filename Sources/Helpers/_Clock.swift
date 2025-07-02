//
//  _Clock.swift
//  Supabase
//
//  Created by Guilherme Souza on 08/01/25.
//

// import Clocks - using local implementation
// import ConcurrencyExtras - using local implementation
import Foundation

package protocol _Clock: Sendable {
  func sleep(for duration: TimeInterval) async throws
}

/// `_Clock` implementation using Task.sleep
struct TaskClock: _Clock {
  func sleep(for duration: TimeInterval) async throws {
    try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
  }
}

private let __clock = LockIsolated<any _Clock>(TaskClock())

#if DEBUG
  package var _clock: any _Clock {
    get {
      __clock.value
    }
    set {
      __clock.withValue { $0 = newValue }
    }
  }
#else
  package var _clock: any _Clock {
    __clock.value
  }
#endif
