# Screenshot capture flow

Real captures from the iOS Simulator via an integration-test driver (no mockups).

## Steps

1. Boot the simulator:
   ```bash
   xcrun simctl boot "iPhone 17 Pro"
   open -a Simulator
   ```
2. Scaffold the iOS platform folder (only needed if `ios/` is missing) and get dependencies:
   ```bash
   flutter create . --platforms=ios --project-name flutter_analytics_sdk
   flutter pub get
   ```
3. Drive the screenshot test:
   ```bash
   flutter drive \
     --driver test_driver/integration_test.dart \
     --target integration_test/screenshot_test.dart \
     -d "iPhone 17 Pro"
   ```
4. Build the demo GIF from the PNGs:
   ```bash
   cd screenshots
   ffmpeg -y -framerate 1 -pattern_type glob -i '*.png' \
     -vf "scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
     -loop 0 demo.gif
   ```

PNGs + `demo.gif` are written to `screenshots/` and embedded in `README.md`.

## How it works

- `test_driver/integration_test.dart` - `integrationDriver(onScreenshot:)` writes each PNG to `screenshots/<name>.png`.
- `integration_test/screenshot_test.dart` - pumps each key screen wrapped in a `ProviderScope` and calls `binding.convertFlutterSurfaceToImage()` + `binding.takeScreenshot('NN-name')` at each view:
  - `01-dashboard` - `TrackingScreen` with the `eventHistoryProvider` and `consentProvider` overridden to seed eight mock Meta / Firebase events, so the stats cards and recent-events list render real content.
  - `02-event-log` - `EventLogScreen` using the same seeded event history, showing per-source badges and timestamps.
  - `03-event-builder` - `EventBuilderScreen` with its default Purchase form (value, currency, content id).
  - `04-attribution` - `AttributionScreen`, which reads mock install-attribution data (Facebook Ads campaign, UTM parameters, IDFA / GAID status).
- The Firebase and Meta SDK services are constructed lazily, so the screens render in the test without initializing a real Firebase project. Mock event data is injected through Riverpod provider overrides, never touching the network or device hardware.
