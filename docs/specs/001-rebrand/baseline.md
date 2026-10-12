# 001 Rebrand: baseline

Build and test results for the unmodified fork, recorded before any rebrand change.

- Date: 2026-10-12
- Commit: `017d955413dfe411d312658f63a6eb12cc1a914a` (branch `spec/001-rebrand`)
- Swift: `swift-driver 1.168.6`, `Apple Swift version 6.4 (swiftlang-6.4.0.34.1 clang-2100.3.34.1)`, target `arm64-apple-macosx27.0.0`
- macOS: ProductName `macOS`, ProductVersion `27.0.1`, BuildVersion `26A434`

## Build

`./build.sh` exits 0 and produces `build/stage/Vorssaint.app`.

- Compiles release against `MacOSX26.sdk`.
- Protected fan helper: `fan-control-helper: ok`.
- Adaptive app icon skipped: `actool not found (adaptive icons need Xcode 26+)`. The Dock falls back to `AppIcon.icns`.
- Signing: `signing ad-hoc (no identity installed — run Tools/setup-signing.sh)`. The build is not signed with a local identity.

## Tests

`./build.sh --test` exits 0.

Final summary lines:

```
TESTS OK (115896 checks)
PREFERENCE CLEANUP TESTS OK
UNINSTALL SPACES TESTS OK
DEVELOPER INSTALL ISOLATION TESTS OK
```

No failing checks. The output contains no `TESTS FAILED` block and no `FAILED` lines.

Log noise: the test run prints 44 lines of `sandbox_extension_consume failed: 1 (Operation not permitted)`. These are not test failures.
