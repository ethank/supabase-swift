# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Test Commands

### Building
```bash
# Build for default platform (iOS)
make xcodebuild

# Build for specific platforms
make PLATFORM=MACOS xcodebuild
make PLATFORM=TVOS xcodebuild
make PLATFORM=WATCHOS xcodebuild
make PLATFORM=VISIONOS xcodebuild
make PLATFORM=MAC_CATALYST xcodebuild

# Build with Swift Package Manager
swift build

# Build for release with library evolution
make build-for-library-evolution
```

### Testing
```bash
# Run all tests via workspace
make XCODEBUILD_ARGUMENT=test xcodebuild

# Run tests for specific platform
make XCODEBUILD_ARGUMENT=test PLATFORM=MACOS xcodebuild

# Run specific test suite
swift test --filter AuthTests
swift test --filter StorageTests

# Run integration tests (requires local Supabase)
make test-integration

# Generate code coverage
make coverage
```

### Code Quality
```bash
# Format code
make format

# Test documentation builds
make test-docs
```

## Architecture Overview

### Module Structure
The SDK is organized into independent modules that can be used separately:
- **Supabase**: Main client that coordinates all services
- **Auth**: Authentication and user management
- **Storage**: File storage operations
- **PostgREST**: Database REST API client
- **Realtime**: WebSocket subscriptions for real-time updates
- **Functions**: Edge Functions invocation
- **Helpers**: Shared utilities and protocols

### Key Design Patterns

1. **Lazy Service Initialization**: Services are created on-demand when first accessed through the main client
2. **Thread-Safe State Management**: Uses `LockIsolated` wrapper for mutable state
3. **Protocol-Based Abstractions**: Key protocols include `SupabaseLogger`, `HTTPClientType`, `AuthLocalStorage`
4. **Configuration Injection**: All services accept configuration objects with sensible defaults
5. **Modern Concurrency**: Extensive use of async/await, actors, and Sendable conformance

### Dependency Flow
```
SupabaseClient
├── auth: AuthClient
├── database: PostgrestClient  
├── storage: StorageClient
├── realtime: RealtimeClient
├── functions: FunctionsClient
└── All share: HTTPClient, Logger, Auth integration
```

### Error Handling
- Each module has domain-specific error types (AuthError, StorageError, etc.)
- HTTPError for generic HTTP failures with response details
- All errors thrown using Swift's native error mechanism

## Development Setup

### Requirements
- Xcode 15+ (CI tests on 15.2, 15.4, 16.0)
- Swift 5.9+
- iOS 13.0+ / macOS 10.15+ / tvOS 13+ / watchOS 6+ / visionOS 1+

### Local Development
1. Clone repository and open `Supabase.xcworkspace` in Xcode
2. For integration tests, install Supabase CLI and run `make test-integration`
3. Use `make format` before committing changes

### Testing Approach
- Unit tests mock network requests and don't require Supabase instance
- Integration tests in `Tests/IntegrationTests/` require local Supabase
- Use provided test credentials for local development (see DotEnv.swift)
- Snapshot testing available via swift-snapshot-testing dependency

## Common Development Tasks

### Adding New Features
1. Determine which module the feature belongs to
2. Follow existing patterns for async/await and error handling
3. Ensure Sendable conformance for all public types
4. Add corresponding tests (unit and integration if applicable)

### Modifying HTTP Requests
- All HTTP requests go through `HTTPClient` with automatic auth injection
- Use `fetchWithAuth` or `uploadWithAuth` adapters for authenticated requests
- Headers cascade: global → service-specific → request-specific

### Working with Auth State
- Auth state changes emit events through `EventEmitter`
- Other services automatically update tokens via auth state subscriptions
- Use `AsyncStream` for observing auth changes

### Platform-Specific Code
- Use conditional compilation for platform differences
- Linux/Android support is experimental
- Main platform differences are in AuthClient initialization

## Important Notes

- Always open the `.xcworkspace` file, not `.xcodeproj`
- The project uses strict concurrency checking
- No Combine dependency - uses AsyncStream for better cross-platform support
- Services can be used independently without the main SupabaseClient
- All configuration has sensible defaults - only URL and anon key are required
- **XCTest Dependencies Removed**: All XCTestDynamicOverlay and IssueReporting dependencies have been removed from production targets to prevent iOS 26+ symlink issues